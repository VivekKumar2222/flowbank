const mongoose = require("mongoose");

const dashboardMemberSchema = new mongoose.Schema(
  {
    dashboardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Dashboard",
      required: true,
    },

    userId: {
      type: String,
      ref: "User",
      required: true,
    },

    // userName:{
    //   type: String,
    // },

    role: {
      type: String,
      enum: ["owner", "admin", "member"],
      default: "member",
    },
  },
  { timestamps: true }
);

// Prevent duplicate membership
dashboardMemberSchema.index(
  { dashboardId: 1, userId: 1 },
  { unique: true }
);

module.exports = mongoose.model("DashboardMember", dashboardMemberSchema);
