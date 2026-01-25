const mongoose = require("mongoose");

const exitRequestSchema = new mongoose.Schema(
  {

    dashboardId: {
        type: String,
        ref: "Dashboard",
        required: true,
    },

    toUserId: {  //this will store for who this exitRequest will be for
      type: String, 
      ref: "to User",
      required: true,
    },

    fromUserId: {  //this will store for who this exitRequest will be for
      type: String, 
      ref: "from User",
      required: true,
    },

    title: {
      type: String, // for GPT: this will say "Invitation for you"
    },

    body: {
      type: String, // for GPT: you got an invitation from {fromUser Name which will be fetched using fromUser ID by searching it in user model} for {dashboad Name which will be fetched using dashboad ID by searching it in collab_dashboad model}
    },

    status: {
        type: String,
        enum: ["pending", "approved", "rejected"],
        default: "pending",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("ExitRequest", exitRequestSchema);
