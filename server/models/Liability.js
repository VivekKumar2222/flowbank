const mongoose = require('mongoose');

const liabilitySchema = new mongoose.Schema({
  userId:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name:      { type: String, required: true },
  type:      { type: String, enum: ['credit_card', 'loan', 'mortgage', 'other'], default: 'other' },
  amount:    { type: Number, required: true },
}, { timestamps: true });

module.exports = mongoose.model('Liability', liabilitySchema);
