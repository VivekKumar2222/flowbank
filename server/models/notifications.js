const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    userId: {  // for GPT: this will store for who this notification will be for
      type: String, 
      ref: "User",
      required: true,
    },

    type: {
      type: String,  // for GPT: this will be 'invite' for now
      enum: ["Reminder", "Invite", "Entry Update"],
      required: true,
    },

    title: {
      type: String, // for GPT: this will say "Invitation for you"
      required: true,
    },

    body: {
      type: String, // for GPT: you got an invitation from {fromUser Name which will be fetched using fromUser ID by searching it in user model} for {dashboad Name which will be fetched using dashboad ID by searching it in collab_dashboad model}
      required: true,
    },

    dueDate: {
      type: Date, // VERY IMPORTANT for reminders  // for GPT: no due date
    },

    relatedId: {
      type: mongoose.Schema.Types.ObjectId, // optional but recommended
    },

    isRead: {
      type: Boolean,
      default: false,
    },

    isTriggered: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Notification", notificationSchema);
