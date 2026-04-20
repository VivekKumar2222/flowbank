const mongoose = require("mongoose");

const bankAccountSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },

  plaidAccessToken: {
    type: String,
    required: true,
  },

  plaidItemId: {
    type: String,
    required: true,
  },

  institutionName: {
    type: String,
  },

  lastCursor: {
    type: String,
    default: null,
  },

}, { timestamps: true });

module.exports = mongoose.model("BankAccount", bankAccountSchema);