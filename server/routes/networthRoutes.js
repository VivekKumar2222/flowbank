const router = require('express').Router();
const axios = require('axios');
const protect = require('../middleware/middleware.js');
const Liability = require('../models/Liability.js');
const NetWorthSnapshot = require('../models/NetWorthSnapshot.js');
const Investment = require('../models/Investment.js');
const BudgetGoal = require('../models/BudgetGoal.js');
const BankAccount = require('../models/user_BankAccount.js');
const { PlaidApi, Configuration, PlaidEnvironments } = require('plaid');

const TD_KEY = process.env.TWELVE_DATA_API_KEY;
const TD_BASE = 'https://api.twelvedata.com';

const plaidClient = new PlaidApi(new Configuration({
  basePath: PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
}));

// ─── GET /api/networth ────────────────────────────────────────────────────────

router.get('/', protect, async (req, res) => {
  try {
    const userId = req.user._id;

    // 1. Bank balance from Plaid
    let bankBalance = 0;
    const bankAccounts = await BankAccount.find({ user: userId });
    await Promise.all(bankAccounts.map(async (account) => {
      try {
        const r = await plaidClient.accountsBalanceGet({ access_token: account.plaidAccessToken });
        bankBalance += r.data.accounts
          .filter(a => a.type === 'depository')
          .reduce((s, a) => s + (a.balances.current || 0), 0);
      } catch (_) {}
    }));

    // 2. Investment portfolio value (live price for tickers, last buy price for manual)
    const investments = await Investment.find({ userId: userId.toString(), status: 'active' });
    let investmentValue = 0;

    await Promise.all(investments.map(async (inv) => {
      const totalUnits = (inv.buyEntries || []).reduce((s, e) => s + e.unitsAcquired, 0)
                       - (inv.withdrawalEntries || []).reduce((s, e) => s + e.unitsWithdrawn, 0);
      if (totalUnits <= 0) return;

      if (inv.ticker && !inv.requiresManualPrice) {
        try {
          const r = await axios.get(`${TD_BASE}/price`, {
            params: { symbol: inv.ticker, apikey: TD_KEY },
          });
          const price = parseFloat(r.data.price);
          if (price > 0) { investmentValue += totalUnits * price; return; }
        } catch (_) {}
      }
      // fallback: last buy price
      const lastBuy = (inv.buyEntries || [])[inv.buyEntries.length - 1];
      if (lastBuy) investmentValue += totalUnits * lastBuy.priceAtPurchase;
    }));

    // 3. Goal savings (savings-type goals only — currentSpend = amount saved so far)
    const goals = await BudgetGoal.find({ userId });
    const goalSavings = goals
      .filter(g => (g.category || '').toLowerCase().includes('saving'))
      .reduce((s, g) => s + (g.currentSpend || 0), 0);

    // 4. Liabilities
    const liabilities = await Liability.find({ userId });
    const totalLiabilities = liabilities.reduce((s, l) => s + l.amount, 0);

    const totalAssets = bankBalance + investmentValue + goalSavings;
    const netWorth = totalAssets - totalLiabilities;

    // 5. Save snapshot (max 1 per day — skip if already have one today)
    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const alreadyToday = await NetWorthSnapshot.findOne({ userId, recordedAt: { $gte: todayStart } });
    if (!alreadyToday) {
      await NetWorthSnapshot.create({ userId, bankBalance, investmentValue, goalSavings, totalAssets, totalLiabilities, netWorth });
    }

    // 6. History — last 12 snapshots
    const history = await NetWorthSnapshot.find({ userId }).sort({ recordedAt: -1 }).limit(12);
    history.reverse();

    res.json({
      current: { bankBalance, investmentValue, goalSavings, totalAssets, totalLiabilities, netWorth },
      liabilities,
      history,
    });
  } catch (e) {
    console.error('Net worth error:', e.message);
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/networth/liability ─────────────────────────────────────────────

router.post('/liability', protect, async (req, res) => {
  try {
    const { name, type, amount } = req.body;
    if (!name || !amount || amount <= 0) return res.status(400).json({ message: 'name and amount required' });
    const l = await Liability.create({ userId: req.user._id, name, type: type || 'other', amount });
    res.status(201).json(l);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ─── PUT /api/networth/liability/:id ──────────────────────────────────────────

router.put('/liability/:id', protect, async (req, res) => {
  try {
    const { name, type, amount } = req.body;
    const l = await Liability.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { name, type, amount },
      { new: true }
    );
    if (!l) return res.status(404).json({ message: 'Not found' });
    res.json(l);
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ─── DELETE /api/networth/liability/:id ───────────────────────────────────────

router.delete('/liability/:id', protect, async (req, res) => {
  try {
    await Liability.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ message: e.message }); }
});

// ─── GET /api/networth/benchmark ──────────────────────────────────────────────

router.get('/benchmark', protect, async (req, res) => {
  try {
    const userId = req.user._id;
    const investments = await Investment.find({
      userId: userId.toString(),
      ticker: { $exists: true, $ne: null },
      requiresManualPrice: false,
    });

    if (!investments.length) return res.json({ hasBenchmark: false });

    // Collect all buy entries with date + amount
    const allBuys = [];
    investments.forEach(inv => {
      inv.buyEntries.forEach(e => {
        allBuys.push({ date: new Date(e.date), amount: e.amount });
      });
    });
    if (!allBuys.length) return res.json({ hasBenchmark: false });

    allBuys.sort((a, b) => a.date - b.date);
    const earliestDate = allBuys[0].date;

    // Fetch SPY monthly history from Twelve Data
    const monthsBack = Math.ceil((Date.now() - earliestDate.getTime()) / (1000 * 60 * 60 * 24 * 30)) + 2;
    const outputsize = Math.min(Math.max(monthsBack, 12), 60);

    const spyRes = await axios.get(`${TD_BASE}/time_series`, {
      params: { symbol: 'SPY', interval: '1month', outputsize, apikey: TD_KEY },
    });

    if (!spyRes.data.values) return res.json({ hasBenchmark: false, reason: 'SPY data unavailable' });

    const spyPrices = spyRes.data.values.map(v => ({
      date: new Date(v.datetime),
      close: parseFloat(v.close),
    })).sort((a, b) => a.date - b.date);

    const spyToday = spyPrices[spyPrices.length - 1]?.close || 1;

    // For each buy, find nearest SPY price on/after that date
    let hypotheticalValue = 0;
    let totalInvested = 0;
    allBuys.forEach(buy => {
      const spyAtBuy = spyPrices.find(p => p.date >= buy.date)?.close;
      if (!spyAtBuy) return;
      const units = buy.amount / spyAtBuy;
      hypotheticalValue += units * spyToday;
      totalInvested += buy.amount;
    });

    // Current portfolio value
    let portfolioValue = 0;
    await Promise.all(investments.map(async inv => {
      const totalUnits = (inv.buyEntries || []).reduce((s, e) => s + e.unitsAcquired, 0)
                       - (inv.withdrawalEntries || []).reduce((s, e) => s + e.unitsWithdrawn, 0);
      if (totalUnits <= 0) return;
      try {
        const r = await axios.get(`${TD_BASE}/price`, { params: { symbol: inv.ticker, apikey: TD_KEY } });
        const price = parseFloat(r.data.price);
        if (price > 0) portfolioValue += totalUnits * price;
      } catch (_) {
        const lastBuy = (inv.buyEntries || [])[inv.buyEntries.length - 1];
        if (lastBuy) portfolioValue += totalUnits * lastBuy.priceAtPurchase;
      }
    }));

    const portfolioReturn = totalInvested > 0 ? ((portfolioValue - totalInvested) / totalInvested) * 100 : 0;
    const benchmarkReturn = totalInvested > 0 ? ((hypotheticalValue - totalInvested) / totalInvested) * 100 : 0;
    const alpha = portfolioReturn - benchmarkReturn;

    // Build monthly chart data — portfolio invested value vs SPY hypothetical
    const chartMonths = spyPrices.slice(-12).map(sp => {
      // cumulative invested up to this month
      const invested = allBuys.filter(b => b.date <= sp.date).reduce((s, b) => s + b.amount, 0);
      // hypothetical SPY value of those buys at this month's price
      let spyVal = 0;
      allBuys.filter(b => b.date <= sp.date).forEach(buy => {
        const spyAtBuy = spyPrices.find(p => p.date >= buy.date)?.close;
        if (spyAtBuy) spyVal += (buy.amount / spyAtBuy) * sp.close;
      });
      return {
        date: sp.date.toISOString().slice(0, 7),
        invested,
        spyValue: Math.round(spyVal),
      };
    });

    res.json({
      hasBenchmark: true,
      totalInvested: Math.round(totalInvested),
      portfolioValue: Math.round(portfolioValue),
      benchmarkValue: Math.round(hypotheticalValue),
      portfolioReturn: Math.round(portfolioReturn * 10) / 10,
      benchmarkReturn: Math.round(benchmarkReturn * 10) / 10,
      alpha: Math.round(alpha * 10) / 10,
      chartData: chartMonths,
    });
  } catch (e) {
    console.error('Benchmark error:', e.message);
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
