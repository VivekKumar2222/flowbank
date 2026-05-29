const mongoose = require('mongoose');

const buyEntrySchema = new mongoose.Schema({
  amount:          { type: Number, required: true }, // dollars invested
  priceAtPurchase: { type: Number, required: true }, // price per unit at time of buy
  unitsAcquired:   { type: Number, required: true }, // amount / priceAtPurchase
  date:            { type: Date, default: Date.now },
  note:            { type: String },
});

const withdrawalEntrySchema = new mongoose.Schema({
  unitsWithdrawn:    { type: Number, required: true },
  priceAtWithdrawal: { type: Number, required: true },
  amountReceived:    { type: Number, required: true }, // unitsWithdrawn * priceAtWithdrawal
  profitLoss:        { type: Number, required: true }, // (priceAtWithdrawal - avgCostPerUnit) * unitsWithdrawn
  date:              { type: Date, default: Date.now },
  note:              { type: String },
});

const investmentSchema = new mongoose.Schema({
  userId:   { type: String, required: true },
  name:     { type: String, required: true }, // "Apple Inc.", "Bitcoin"
  ticker:   { type: String },                 // "AAPL", "BTC/USD" — used for API price lookups
  type: {
    type: String,
    enum: ['stock', 'crypto', 'real_estate', 'business', 'other'],
    required: true,
  },
  frequency: {
    type: String,
    enum: ['weekly', 'monthly', 'yearly', 'one_time', 'whenever'],
    required: true,
  },
  targetAmount:       { type: Number, required: true }, // planned investment per period
  requiresManualPrice: { type: Boolean, default: false }, // true for real_estate, business

  buyEntries:        [buyEntrySchema],
  withdrawalEntries: [withdrawalEntrySchema],

  status:          { type: String, enum: ['active', 'closed'], default: 'active' },
  closedAt:        { type: Date },
  closingPrice:    { type: Number },
  totalProfitLoss: { type: Number },
}, { timestamps: true });

module.exports = mongoose.model('Investment', investmentSchema);
