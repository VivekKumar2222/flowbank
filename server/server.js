// server.js (fixed)
const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");
const morgan = require("morgan");

const authRoutes = require("./routes/authRoutes");
const settlementRoutes = require("./routes/settlementRoutes"); // ⬅️ NEW

dotenv.config();

// ✅ Create app FIRST before using it
const app = express();

// ✅ Middleware
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow Flutter web origins like http://localhost:xxxx or http://127.0.0.1:xxxx
      if (!origin || origin.startsWith("http://localhost:") || origin.startsWith("http://127.0.0.1:")) {
        callback(null, true);
      } else {
        callback(new Error("CORS blocked this origin"));
      }
    },
    credentials: true,
    exposedHeaders: ["x-access-token"],
  })
);

app.use(express.json());
app.use(morgan("dev"));

// ✅ Connect MongoDB
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch((err) => console.error("❌ MongoDB connection error:", err));

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/settlements", settlementRoutes); // ⬅️ NEW

// ✅ Test route
app.get("/", (req, res) => res.send("API is running..."));

// ✅ Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
