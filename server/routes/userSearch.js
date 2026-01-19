const express = require("express");
const router = express.Router();
const User = require("../models/User");
const jwt = require("jsonwebtoken");
const {generateAccessToken, generateRefreshToken} = require("../utils/jwt.js");
const protect = require("../middleware/middleware.js")

/// SEARCH USERS BY NAME
/// GET /users/search?name=char
router.get("/search", protect, async (req, res) => {
  try {
    const { name } = req.query;

    if (!name) {
      return res.status(400).json({ message: "Name is required" });
    }

    const users = await User.find({
      name: { $regex: name, $options: "i" }, // case-insensitive search
    }).select("name email"); // only send required fields

    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
