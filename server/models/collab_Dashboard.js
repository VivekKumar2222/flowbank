const mongoose = require("mongoose");

const dashboardSchema = new mongoose.Schema({
  name: { type: String, required: true },

  type: {
    type: String,
    enum: ["shared_expense", "bill_split", "ledger_track"],
    required: true,
  },

  // 🔥 CHANGE HERE
  ownerId: {
    type: String, // email
    required: true,
  },

  currency: {
    type: String,
    enum: ["USD", "PKR"],
    default: "USD",
  },

  settings: {
    requireVerification: {
      type: Boolean,
      default: false,
    },
  },
}, { timestamps: true });

module.exports = mongoose.model("Dashboard", dashboardSchema);
