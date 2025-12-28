const mongoose = require("mongoose");

const dashboardBillSplitSchema = new mongoose.Schema(
  {
    dashboardId: {
      type: String,
      required: true,
      unique: true, // one split config per dashboard
    },

    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("DashboardBillSplit", dashboardBillSplitSchema);
