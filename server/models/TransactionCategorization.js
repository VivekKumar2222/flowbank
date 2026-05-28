const mongoose = require('mongoose');

const schema = new mongoose.Schema({
  transactionId:   { type: String, required: true },
  userId:          { type: String, required: true },
  categorizedTo:   { type: String, enum: ['goal', 'collaboration'], required: true },
  categoryRefId:   { type: String, required: true },
  categoryRefName: { type: String },
  amount:          { type: Number, required: true },
  transactionName: { type: String },
  categorizedAt:   { type: Date, default: Date.now },
});

// One transaction can only be categorized once per user
schema.index({ transactionId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('TransactionCategorization', schema);
