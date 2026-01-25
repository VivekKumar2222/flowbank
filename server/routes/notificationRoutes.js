// server/routes/notificationRoutes.js
const express = require("express");
const Notification = require("../models/notifications");
const router = express.Router();
const jwt = require("jsonwebtoken");
const {generateAccessToken, generateRefreshToken} = require("../utils/jwt.js");
const protect = require("../middleware/middleware.js")

// GET all notifications for a user
router.get("/:userId", protect, async (req, res) => {
  try {
    const { userId } = req.params;

    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 }); // latest first

    res.status(200).json(notifications);
  } catch (err) {
    console.error("Fetch notifications error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
