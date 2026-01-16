import jwt from "jsonwebtoken";
import User from "../models/User.js";
import { generateAccessToken } from "../utils/jwt.js";

export const protect = async (req, res, next) => {
  let token;

  //Get access token from Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({ message: "No token, authorization denied" });
  }

  try {
    //Verify access token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id).select("-password");

    if (!req.user) {
      return res.status(401).json({ message: "User not found" });
    }

    return next(); 
  } catch (error) {
    //If access token expired -> try refresh
    if (error.name === "TokenExpiredError") {
      try {
        //Get refresh token from cookies
        const refreshToken = req.cookies?.refreshToken;
        if (!refreshToken) {
          return res.status(401).json({ message: "Refresh token required" });
        }

        // Verify refresh token
        const decodedRefresh = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const user = await User.findById(decodedRefresh.id).select("-password");

        if (!user) {
          return res.status(401).json({ message: "User not found" });
        }

        //Issue new access token
        const newAccessToken = generateAccessToken(user);

        // Set in cookie
    // Set cookies
      res.cookie("accessToken", newAccessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 60 * 1000, // 30 min
    });
//console.log(`New access token issued via refresh token: ${newAccessToken}`);
        // Send new token in response header
        res.setHeader("x-access-token", newAccessToken);

        // Attach user to request
        req.user = user;

        return next(); //Continue with refreshed token
      } catch (refreshErr) {
        return res.status(401).json({ message: "Invalid refresh token" });
      }
    }

    return res.status(401).json({ message: "Not authorized, token failed" });
  }
};


export const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: "Access denied" });
    }
    next();
  };
};