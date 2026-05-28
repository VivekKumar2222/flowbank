// models/BudgetGoal.js
const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  userId:        { type: String, required: true },
  goalName:      { type: String, required: true },
  amount:        { type: Number, required: true },
  resetDuration: { type: String, enum: ['weekly','monthly','yearly'] },
  category:      { type: String },
  currentSpend:  { type: Number, default: 0 },
  goalType:      { type: String, enum: ['spending', 'savings'], default: 'spending' },
  createdAt:     { type: Date, default: Date.now },
});
module.exports = mongoose.model('BudgetGoal', schema);