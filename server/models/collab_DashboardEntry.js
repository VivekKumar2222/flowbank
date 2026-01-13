const mongoose = require("mongoose");

const dashboardEntrySchema = new mongoose.Schema(
  {
    dashboardId: {
      type: String,
      ref: "Dashboard",
      required: true,
    },

    userId: {
      type: String,
      ref: "User",
      required: true,
    },


    amount: { type: Number, required: true },


    verificationImage: {
      type: String, // URL or file path
      default: null,
    },

        ocrVerified: {
      type: Boolean,
      default: false,
    },

    ocrVerification: {
      type: Object, // stores full OCR response
      default: null,
    },

    assignmentId: {
          type: mongoose.Schema.Types.ObjectId,
    ref: "LedgerAssignment",
    default: null,

    },


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
