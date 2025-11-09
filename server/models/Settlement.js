const mongoose = require("mongoose");
const { Schema, Types } = mongoose;

const ParticipantSchema = new Schema({
  id: { type: String, required: true },          // client-side id for card
  name: { type: String, required: true },
  initials: { type: String, default: "" },
  amount: { type: Number, required: true, default: 0 },
  type: { type: String, enum: ["owed", "owing"], required: true },
  note: { type: String, default: "" },
}, { _id: false });

const SettlementSchema = new Schema({
  userId: { type: Types.ObjectId, ref: "User", required: true, index: true },
  title: { type: String, default: "Connected Settlements" },
  participants: { type: [ParticipantSchema], default: [] },
}, { timestamps: true }); // adds createdAt / updatedAt

module.exports = mongoose.model("Settlement", SettlementSchema);
