const mongoose = require("mongoose");

const dashboardSchema = new mongoose.Schema({
  name: { type: String, required: true },

  type: {
    type: String,
    enum: ["Shared Expense", "Bill Splitting", "Ledger Tracking"],
    required: true,
  },

  // 🔥 CHANGE HERE
  ownerId: {
    type: String, // email
    required: true,
  },

  // ownerName: {
  //   type: String,
  //   // required: false,
  // },

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
