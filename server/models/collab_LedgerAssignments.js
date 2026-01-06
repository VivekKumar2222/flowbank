const mongoose = require("mongoose");

const ledgerAssignmentSchema = new mongoose.Schema(
  {
    dashboardId: {
      type: String,
      ref: "Dashboard",
      required: true,
    },

    memberId: {
      type: String,
      ref: "DashboardMember",
      required: true,
    },

    assignedBy: {
      type: String, // owner/admin userId
      ref: "User",
      required: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      trim: true,
    },

    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },

    paidAmount: {
      type: Number,
      required: true,
      min: 0,
    },

    interestRate: {
      type: Number, // percentage
      default: 0,
      min: 0,
    },

    interestCycle: {
      type: String,
      enum: ["weekly", "monthly", "yearly", null],
      default: null,
    },

    lastInterestAppliedAt: {
      type: Date,
      default: null,
    },

    penaltyAmount: {
      type: Number,
      default: 0,
      min: 0,
    },

    penaltyType: {
      type: String,
      enum: ["fixed", "percentage", null],
      default: null,
    },

    penaltyApplied: {
      type: Boolean,
      default: false,
    },

    dueDate: {
      type: Date,
      required: true,
    },

    status: {
      type: String,
      enum: ["active", "paid", "overdue"],
      default: "active",
    },

    verificationSource: {
      type: String, // text / receipt URL / file id
      trim: true,
    },
  },
  { timestamps: true }
);

// Indexes for fast queries
ledgerAssignmentSchema.index({ dashboardId: 1 });
ledgerAssignmentSchema.index({ memberId: 1 });
ledgerAssignmentSchema.index({ status: 1 });

module.exports = mongoose.model("LedgerAssignment", ledgerAssignmentSchema);
