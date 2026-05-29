const router = require('express').Router();
const protect = require('../middleware/middleware.js');
const { ModerateLimiter } = require('./rateLimiter.js');
const { encrypt } = require('../utils/mediaCrypto');

const TransactionCategorization = require('../models/TransactionCategorization.js');
const BudgetGoal = require('../models/BudgetGoal.js');
const DashboardEntry = require('../models/collab_DashboardEntry.js');

// ─── POST /api/categorize ─────────────────────────────────────────────────────
// Creates a categorization record and triggers the relevant module side effect
router.post('/', protect, ModerateLimiter, async (req, res) => {
  try {
    const {
      transactionId,
      categorizedTo,
      categoryRefId,
      categoryRefName,
      amount,
      transactionName,
      verificationImage,
    } = req.body;

    if (!transactionId || !categorizedTo || !categoryRefId || !amount) {
      return res.status(400).json({ message: 'transactionId, categorizedTo, categoryRefId and amount are required' });
    }

    const userId = req.user._id.toString();

    // Prevent duplicate categorizations
    const existing = await TransactionCategorization.findOne({ transactionId, userId });
    if (existing) {
      return res.status(409).json({ message: 'Transaction already categorized' });
    }

    // ── Side effects ──────────────────────────────────────────────────────────
    if (categorizedTo === 'goal') {
      const goal = await BudgetGoal.findOneAndUpdate(
        { _id: categoryRefId, userId },
        { $inc: { currentSpend: amount } },
        { new: true }
      );
      if (!goal) return res.status(404).json({ message: 'Goal not found' });

    } else if (categorizedTo === 'collaboration') {
      const encryptedImage = verificationImage ? encrypt(verificationImage) : null;
      await DashboardEntry.create({
        dashboardId: categoryRefId,
        userId: req.user.email,
        amount,
        status: 'pending',
        verificationImage: encryptedImage,
      });
    }

    // ── Save categorization record ────────────────────────────────────────────
    const record = await TransactionCategorization.create({
      transactionId,
      userId,
      categorizedTo,
      categoryRefId,
      categoryRefName,
      amount,
      transactionName,
    });

    res.status(201).json({ message: 'Categorized successfully', record });
  } catch (e) {
    if (e.code === 11000) {
      return res.status(409).json({ message: 'Transaction already categorized' });
    }
    res.status(500).json({ message: e.message });
  }
});

// ─── GET /api/categorize/my-categorizations ───────────────────────────────────
// Returns all categorized transaction IDs + details for the logged-in user
router.get('/my-categorizations', protect, async (req, res) => {
  try {
    const userId = req.user._id.toString();
    const records = await TransactionCategorization.find({ userId })
      .select('transactionId categorizedTo categoryRefId categoryRefName amount transactionName categorizedAt')
      .lean();
    res.json(records);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;
