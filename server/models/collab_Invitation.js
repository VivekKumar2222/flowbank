const mongoose = require("mongoose");

const invitationSchema = new mongoose.Schema(
  {
    dashboardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Dashboard",
      required: true,
    },

    fromUser: {
      type: String,
      ref: "User",
    },

    toUser: {
      type: String,
      ref: "User",
    },

    status: {
      type: String,
      enum: ["pending", "accepted", "rejected"],
      default: "pending",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Invitation", invitationSchema);
