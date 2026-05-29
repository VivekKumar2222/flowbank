const router = require('express').Router();
const axios = require('axios');
const protect = require('../middleware/middleware.js');
const { ModerateLimiter, MediumLimiter } = require('./rateLimiter.js');
const Investment = require('../models/Investment.js');

const TD_KEY = process.env.TWELVE_DATA_API_KEY;
const TD_BASE = 'https://api.twelvedata.com';

// ─── helpers ─────────────────────────────────────────────────────────────────

function periodWindow(frequency) {
  const now = new Date();
  const start = new Date(now);
  const prevStart = new Date(now);
  const prevEnd = new Date(now);

  switch (frequency) {
    case 'weekly':
      const day = now.getDay(); // 0=Sun
      start.setDate(now.getDate() - day);
      start.setHours(0, 0, 0, 0);
      prevEnd.setDate(start.getDate() - 1);
      prevEnd.setHours(23, 59, 59, 999);
      prevStart.setDate(prevEnd.getDate() - 6);
      prevStart.setHours(0, 0, 0, 0);
      break;
    case 'monthly':
      start.setDate(1); start.setHours(0, 0, 0, 0);
      prevStart.setMonth(now.getMonth() - 1, 1); prevStart.setHours(0, 0, 0, 0);
      prevEnd.setDate(0); prevEnd.setHours(23, 59, 59, 999); // last day of prev month
      break;
    case 'yearly':
      start.setMonth(0, 1); start.setHours(0, 0, 0, 0);
      prevStart.setFullYear(now.getFullYear() - 1, 0, 1); prevStart.setHours(0, 0, 0, 0);
      prevEnd.setMonth(0, 0); prevEnd.setHours(23, 59, 59, 999);
      break;
    default:
      return null; // one_time / whenever — no periods
  }
  return { currentStart: start, prevStart, prevEnd };
}

function calcStats(investment, currentPrice) {
  const buys = investment.buyEntries;
  const withdrawals = investment.withdrawalEntries;

  const totalUnits = buys.reduce((s, e) => s + e.unitsAcquired, 0)
    - withdrawals.reduce((s, e) => s + e.unitsWithdrawn, 0);

  const totalInvested = buys.reduce((s, e) => s + e.amount, 0);
  const totalWithdrawnValue = withdrawals.reduce((s, e) => s + e.amountReceived, 0);
  const totalWithdrawnPL = withdrawals.reduce((s, e) => s + e.profitLoss, 0);

  // Cost basis of remaining units (FIFO would be complex; use avg cost)
  const avgCostPerUnit = totalUnits > 0
    ? (totalInvested - withdrawals.reduce((s, e) => s + (e.unitsWithdrawn * (totalInvested / (totalUnits + withdrawals.reduce((ss, ee) => ss + ee.unitsWithdrawn, 0)))), 0)) / totalUnits
    : 0;

  const remainingCostBasis = avgCostPerUnit * totalUnits;
  const currentValue = currentPrice !== null ? currentPrice * totalUnits : null;
  const unrealisedPL = currentValue !== null ? currentValue - remainingCostBasis : null;
  const unrealisedROI = remainingCostBasis > 0 && unrealisedPL !== null
    ? (unrealisedPL / remainingCostBasis) * 100 : null;
  const totalROI = (remainingCostBasis > 0 || totalWithdrawnPL !== 0) && unrealisedPL !== null
    ? ((unrealisedPL + totalWithdrawnPL) / totalInvested) * 100 : null;

  // Period breakdown
  const window = periodWindow(investment.frequency);
  let thisperiodInvested = null, lastPeriodInvested = null;
  if (window) {
    thisperiodInvested = buys
      .filter(e => new Date(e.date) >= window.currentStart)
      .reduce((s, e) => s + e.amount, 0);
    lastPeriodInvested = buys
      .filter(e => new Date(e.date) >= window.prevStart && new Date(e.date) <= window.prevEnd)
      .reduce((s, e) => s + e.amount, 0);
  }

  return {
    totalUnits,
    totalInvested,
    avgCostPerUnit,
    currentValue,
    unrealisedPL,
    unrealisedROI,
    totalROI,
    thisperiodInvested,
    lastPeriodInvested,
    totalWithdrawnValue,
    totalWithdrawnPL,
  };
}

// ─── GET /api/investments/search ─────────────────────────────────────────────
// Autocomplete: query Twelve Data symbol search
router.get('/search', protect, ModerateLimiter, async (req, res) => {
  try {
    const { query, type } = req.query;
    if (!query || query.length < 1) return res.json([]);

    let results = [];

    if (type === 'crypto') {
      const r = await axios.get(`${TD_BASE}/cryptocurrency_exchanges`, {
        params: { apikey: TD_KEY },
      });
      // Use symbol_search for crypto too
      const sr = await axios.get(`${TD_BASE}/symbol_search`, {
        params: { symbol: query, outputsize: 8, apikey: TD_KEY },
      });
      results = (sr.data.data || [])
        .filter(s => s.instrument_type === 'Digital Currency')
        .slice(0, 6)
        .map(s => ({ name: s.instrument_name, ticker: s.symbol, exchange: s.exchange }));
    } else if (type === 'stock') {
      const sr = await axios.get(`${TD_BASE}/symbol_search`, {
        params: { symbol: query, outputsize: 8, apikey: TD_KEY },
      });
      results = (sr.data.data || [])
        .filter(s => s.instrument_type === 'Common Stock' || s.instrument_type === 'ETF')
        .slice(0, 6)
        .map(s => ({ name: s.instrument_name, ticker: s.symbol, exchange: s.exchange }));
    }
    // real_estate, business, other — no search, user types freely
    res.json(results);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── GET /api/investments/price ───────────────────────────────────────────────
// Fetch current price for a ticker
router.get('/price', protect, ModerateLimiter, async (req, res) => {
  try {
    const { ticker } = req.query;
    if (!ticker) return res.status(400).json({ message: 'ticker required' });

    const r = await axios.get(`${TD_BASE}/price`, {
      params: { symbol: ticker, apikey: TD_KEY },
    });

    if (r.data.status === 'error' || !r.data.price) {
      return res.status(404).json({ message: 'Price not found. Please enter manually.' });
    }

    res.json({ ticker, price: parseFloat(r.data.price) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/investments ────────────────────────────────────────────────────
router.post('/', protect, MediumLimiter, async (req, res) => {
  try {
    const { name, ticker, type, frequency, targetAmount,
            initialAmount, initialPrice } = req.body;

    if (!name || !type || !frequency || !targetAmount) {
      return res.status(400).json({ message: 'name, type, frequency, targetAmount required' });
    }

    const requiresManualPrice = ['real_estate', 'business', 'other'].includes(type);
    const unitsAcquired = initialPrice > 0 ? initialAmount / initialPrice : 0;

    const investment = await Investment.create({
      userId: req.user._id.toString(),
      name,
      ticker: ticker || null,
      type,
      frequency,
      targetAmount,
      requiresManualPrice,
      buyEntries: initialAmount > 0 && initialPrice > 0 ? [{
        amount: initialAmount,
        priceAtPurchase: initialPrice,
        unitsAcquired,
      }] : [],
    });

    res.status(201).json(investment);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── GET /api/investments/active ─────────────────────────────────────────────
router.get('/active', protect, async (req, res) => {
  try {
    const investments = await Investment.find({
      userId: req.user._id.toString(), status: 'active',
    }).sort({ createdAt: -1 });
    res.json(investments);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── GET /api/investments/closed ─────────────────────────────────────────────
router.get('/closed', protect, async (req, res) => {
  try {
    const investments = await Investment.find({
      userId: req.user._id.toString(), status: 'closed',
    }).sort({ closedAt: -1 });
    res.json(investments);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── GET /api/investments/:id ─────────────────────────────────────────────────
router.get('/:id', protect, async (req, res) => {
  try {
    const inv = await Investment.findOne({
      _id: req.params.id, userId: req.user._id.toString(),
    });
    if (!inv) return res.status(404).json({ message: 'Investment not found' });
    res.json(inv);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/investments/:id/buy ───────────────────────────────────────────
router.post('/:id/buy', protect, ModerateLimiter, async (req, res) => {
  try {
    const { amount, priceAtPurchase, note } = req.body;
    if (!amount || !priceAtPurchase || amount <= 0 || priceAtPurchase <= 0) {
      return res.status(400).json({ message: 'amount and priceAtPurchase required and must be positive' });
    }

    const inv = await Investment.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id.toString(), status: 'active' },
      { $push: { buyEntries: {
        amount,
        priceAtPurchase,
        unitsAcquired: amount / priceAtPurchase,
        note,
      }}},
      { new: true }
    );
    if (!inv) return res.status(404).json({ message: 'Investment not found' });
    res.json(inv);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/investments/:id/withdraw ──────────────────────────────────────
router.post('/:id/withdraw', protect, ModerateLimiter, async (req, res) => {
  try {
    const { unitsWithdrawn, priceAtWithdrawal, note } = req.body;
    if (!unitsWithdrawn || !priceAtWithdrawal || unitsWithdrawn <= 0 || priceAtWithdrawal <= 0) {
      return res.status(400).json({ message: 'unitsWithdrawn and priceAtWithdrawal required' });
    }

    const inv = await Investment.findOne({
      _id: req.params.id, userId: req.user._id.toString(), status: 'active',
    });
    if (!inv) return res.status(404).json({ message: 'Investment not found' });

    // calc avg cost per unit across all buys
    const totalUnits = inv.buyEntries.reduce((s, e) => s + e.unitsAcquired, 0)
      - inv.withdrawalEntries.reduce((s, e) => s + e.unitsWithdrawn, 0);

    if (unitsWithdrawn > totalUnits) {
      return res.status(400).json({ message: 'Cannot withdraw more units than held' });
    }

    const totalCost = inv.buyEntries.reduce((s, e) => s + e.amount, 0);
    const totalBoughtUnits = inv.buyEntries.reduce((s, e) => s + e.unitsAcquired, 0);
    const avgCostPerUnit = totalBoughtUnits > 0 ? totalCost / totalBoughtUnits : 0;

    const amountReceived = unitsWithdrawn * priceAtWithdrawal;
    const profitLoss = (priceAtWithdrawal - avgCostPerUnit) * unitsWithdrawn;

    inv.withdrawalEntries.push({ unitsWithdrawn, priceAtWithdrawal, amountReceived, profitLoss, note });
    await inv.save();

    res.json({ investment: inv, withdrawal: { unitsWithdrawn, priceAtWithdrawal, amountReceived, profitLoss } });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/investments/:id/close ─────────────────────────────────────────
router.post('/:id/close', protect, MediumLimiter, async (req, res) => {
  try {
    const { closingPrice } = req.body;
    if (!closingPrice || closingPrice <= 0) {
      return res.status(400).json({ message: 'closingPrice required' });
    }

    const inv = await Investment.findOne({
      _id: req.params.id, userId: req.user._id.toString(), status: 'active',
    });
    if (!inv) return res.status(404).json({ message: 'Investment not found' });

    const stats = calcStats(inv, closingPrice);

    inv.status = 'closed';
    inv.closedAt = new Date();
    inv.closingPrice = closingPrice;
    inv.totalProfitLoss = stats.unrealisedPL + (stats.totalWithdrawnPL || 0);
    await inv.save();

    res.json({ investment: inv, summary: stats });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ─── POST /api/investments/:id/roi ───────────────────────────────────────────
// Returns ROI stats given a current price (from API or manually entered)
router.post('/:id/roi', protect, ModerateLimiter, async (req, res) => {
  try {
    const { currentPrice } = req.body;
    if (currentPrice == null || currentPrice < 0) {
      return res.status(400).json({ message: 'currentPrice required' });
    }

    const inv = await Investment.findOne({
      _id: req.params.id, userId: req.user._id.toString(),
    });
    if (!inv) return res.status(404).json({ message: 'Investment not found' });

    const stats = calcStats(inv, currentPrice);
    res.json(stats);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
