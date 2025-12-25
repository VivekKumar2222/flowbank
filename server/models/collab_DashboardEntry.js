const mongoose = require("mongoose");

const dashboardEntrySchema = new mongoose.Schema(
  {
    dashboardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Dashboard",
      required: true,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    entryType: {
      type: String,
      enum: ["expense", "bill_share", "loan"],
      required: true,
    },

    amount: { type: Number, required: true },

    // for bill splitting & ledger
    participants: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
        shareAmount: Number,
        status: {
          type: String,
          enum: ["pending", "paid"],
          default: "pending",
        },
      },
    ],

    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "settled"],
      default: "pending",
    },

    dueDate: Date,
    description: String,
  },
  { timestamps: true }
);

module.exports = mongoose.model("DashboardEntry", dashboardEntrySchema);
