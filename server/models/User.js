const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  isVerified: { type: Boolean, default: false },
  phone: { type: String, default: "" },
  city: { type: String, default: "" },
  country: { type: String, default: "" },
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
