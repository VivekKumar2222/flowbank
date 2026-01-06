const mongoose = require("mongoose");

const ledgerAssignedMemberSchema = new mongoose.Schema(
  {
    dashboardId: {
      type: String,
      ref: "Dashboard",
      required: true,
    },
    memberId: {
      type: String,
      ref: "User",
      required: true,
    },
    membersAssigned: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  { timestamps: true }
);

// Prevent duplicate membership per dashboard per member
ledgerAssignedMemberSchema.index(
  { dashboardId: 1, memberId: 1 },
  { unique: true }
);

module.exports = mongoose.model("AssignedMember", ledgerAssignedMemberSchema);
