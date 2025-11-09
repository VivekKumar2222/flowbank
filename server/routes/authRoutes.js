const express = require("express");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const  sendEmail  = require("../utils/mailer.js"); // make sure you export {sendEmail} properly
const router = express.Router();
const otpGenerator = require("otp-generator");

// OTP storage in memory
const otpStore = new Map();

// Helper to generate 4-digit OTP
const generateOTP = () => Math.floor(1000 + Math.random() * 9000).toString();

// =================== SIGNUP ROUTE ===================
router.post("/signup", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user (unverified initially)
    const newUser = new User({ name, email, password: hashedPassword, isVerified: false });
    await newUser.save();

    // Generate OTP and set expiry (5 minutes)
    const otp = generateOTP();
    const expiry = Date.now() + 5 * 60 * 1000; // 5 minutes
    otpStore.set(email, { otp, expiry });

    // Send OTP via email
    const html = `<p>Hello ${name},</p>
                  <p>Your OTP for FlowBank signup is: <b>${otp}</b></p>
                  <p>This code will expire in 5 minutes.</p>`;
    await sendEmail(email, "FlowBank Signup OTP", html);

    res.status(201).json({ message: "User registered successfully. OTP sent to email." });

  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// =================== VERIFY OTP ROUTE ===================
router.post("/verify-otp", async (req, res) => {
  try {
    const { email, otp } = req.body;

    // Check if OTP exists for this email
    if (!otpStore.has(email)) {
      return res.status(400).json({ message: "OTP not found. Request again." });
    }

    const record = otpStore.get(email);

    // Check if OTP expired
    if (Date.now() > record.expiry) {
      otpStore.delete(email);
      return res.status(400).json({ message: "OTP expired. Please request a new one." });
    }

    // Check if OTP matches
    if (otp !== record.otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    // Mark user as verified
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }
    user.isVerified = true;
    await user.save();

    // Delete OTP after verification
    otpStore.delete(email);

    res.json({ message: "OTP verified successfully. You can now login." });

  } catch (err) {
    console.error("Verify OTP error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// module.exports = router;


// Login Route
// router.post("/login", async (req, res) => {
//   try {
//     const { email, password } = req.body;

//     const user = await User.findOne({ email });
//     if (!user) return res.status(400).json({ message: "Invalid credentials" });

//     const isMatch = await bcrypt.compare(password, user.password);
//     if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

//     // Create JWT Token
//     const token = jwt.sign({ id: user._id }, "jwt_secret_key", { expiresIn: "1h" });

//     res.json({ message: "Login successful", token });
//   } catch (err) {
//     res.status(500).json({ message: "Server error", error: err.message });
//   }
// });

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "Invalid credentials" });

    // Check if user is verified
    if (!user.isVerified) {
      return res.status(400).json({ message: "Email not verified. Please complete OTP verification first." });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

    // Generate OTP for login (optional extra layer)
    const otp = generateOTP();
    const expiry = Date.now() + 5 * 60 * 1000; // 5 minutes
    otpStore.set(email, { otp, expiry });

    // Send OTP via email
    const html = `<p>Hello ${user.name},</p>
                  <p>Your OTP for FlowBank login is: <b>${otp}</b></p>
                  <p>This code will expire in 5 minutes.</p>`;
    await sendEmail(email, "FlowBank Login OTP", html);

    res.json({ message: "OTP sent to your email. Please verify to complete login." });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// router.post("/login", async (req, res) => {
//   try {
//     const { email, password } = req.body;
//     const user = await User.findOne({ email });
//     if (!user) return res.status(400).json({ message: "Invalid credentials" });

//     const isMatch = await bcrypt.compare(password, user.password);
//     if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

//     // Generate OTP
//     const otp = otpGenerator.generate(6, { upperCaseAlphabets: false, specialChars: false, alphabets: false });
//     otpStore[email] = otp;

//     // Send OTP via email
//     await transporter.sendMail({
//       from: process.env.EMAIL_USER,
//       to: email,
//       subject: "Your OTP for FlowBank Login",
//       text: `Your OTP is: ${otp}`,
//     });

//     res.json({ message: "OTP sent to your email" });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: "Server error" });
//   }
// });

// router.post("/verify-otp", async (req, res) => {
//   try {
//     const { email, otp } = req.body;
//     const user = await User.findOne({ email });
//     if (!user) return res.status(400).json({ message: "Invalid credentials" });

//     if (otpStore[email] !== otp) {
//       return res.status(400).json({ message: "Invalid OTP" });
//     }

//     // OTP is valid → create JWT token
//     const token = jwt.sign({ id: user._id }, "jwt_secret_key", { expiresIn: "1h" });

//     // Delete OTP after verification
//     delete otpStore[email];

//     res.json({ message: "Login successful", token });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ message: "Server error" });
//   }
// });

module.exports = router;
