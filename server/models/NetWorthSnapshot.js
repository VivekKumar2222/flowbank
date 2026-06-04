const mongoose = require('mongoose');

const netWorthSnapshotSchema = new mongoose.Schema({
  userId:          { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  bankBalance:     { type: Number, default: 0 },
  investmentValue: { type: Number, default: 0 },
  goalSavings:     { type: Number, default: 0 },
  totalAssets:     { type: Number, default: 0 },
  totalLiabilities:{ type: Number, default: 0 },
  netWorth:        { type: Number, default: 0 },
  recordedAt:      { type: Date, default: Date.now },
});

module.exports = mongoose.model('NetWorthSnapshot', netWorthSnapshotSchema);
