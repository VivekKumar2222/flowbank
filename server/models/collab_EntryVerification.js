const mongoose = require("mongoose");

const entryVerificationSchema = new mongoose.Schema(
  {
    entryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DashboardEntry",
      required: true,
    },

    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    type: {
      type: String,
      enum: ["receipt", "bank_transaction", "manual_note"],
    },

    fileUrl: String,
    note: String,

    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    verifiedAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model("EntryVerification", entryVerificationSchema);
