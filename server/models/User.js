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
    required: false,
  },
  isVerified: { type: Boolean, default: false },
  phone: { type: String, default: "" },
  city: { type: String, default: "" },
  country: { type: String, default: "" },
  postalCode: {type: String, default: "" },

  googleId: {
  type: String,
  default: null,
},
avatar: {
  type: String,
  default: null,
},
authProvider: {
  type: String,
  enum: ['local', 'google'],
  default: 'local',
},

  // plaidAccessToken: { type: String, default: null },
  // plaidItemId: { type: String, default: null }, 
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
