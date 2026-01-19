const jwt = require("jsonwebtoken");
const User = require("../models/User");

const protect = async (req, res, next) => {
  let token;

  // Get token from Authorization header
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer ")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({
      message: "No token provided. Please login again.",
    });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user
    const user = await User.findById(decoded.id).select("-password");
    if (!user) {
      return res.status(401).json({
        message: "User not found. Please login again.",
      });
    }

    req.user = user;
    return next();
  } catch (error) {
    // Token expired or invalid
    return res.status(401).json({
      message: "Session expired. Please login again.",
    });
  }
};

module.exports = protect;
