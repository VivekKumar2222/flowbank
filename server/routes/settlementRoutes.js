const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Settlement = require("../models/Settlement");

// TEMP auth: read current user id from header `x-user-id`.
// Replace this with your real auth middleware when ready.
router.use((req, res, next) => {
  const id = req.header("x-user-id");
  if (!id) return res.status(401).json({ error: "Missing x-user-id header" });
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid x-user-id" });
  }
  req.userId = new mongoose.Types.ObjectId(id);
  next();
});

// GET /api/settlements
router.get("/", async (req, res) => {
  const items = await Settlement.find({ userId: req.userId })
    .sort({ updatedAt: -1 })
    .lean();
  res.json(items);
});

// POST /api/settlements
router.post("/", async (req, res) => {
  const { title = "Connected Settlements", participants = [] } = req.body || {};
  if (!Array.isArray(participants)) {
    return res.status(400).json({ error: "`participants` must be an array" });
  }

  // normalize participants
  const clean = participants.map((p, i) => ({
    id: String(p.id ?? i + 1),
    name: String(p.name ?? ""),
    initials: String(p.initials ?? ""),
    amount: Number(p.amount ?? 0),
    type: p.type === "owed" ? "owed" : "owing",
    note: String(p.note ?? ""),
  }));

  const doc = await Settlement.create({
    userId: req.userId,
    title: String(title),
    participants: clean,
  });

  res.status(201).json(doc);
});

// PUT /api/settlements/:id
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid settlement id" });
  }

  const update = {};
  if (typeof req.body?.title === "string") update.title = req.body.title;

  if (Array.isArray(req.body?.participants)) {
    update.participants = req.body.participants.map((p, i) => ({
      id: String(p.id ?? i + 1),
      name: String(p.name ?? ""),
      initials: String(p.initials ?? ""),
      amount: Number(p.amount ?? 0),
      type: p.type === "owed" ? "owed" : "owing",
      note: String(p.note ?? ""),
    }));
  }

  const doc = await Settlement.findOneAndUpdate(
    { _id: id, userId: req.userId },
    { $set: update },
    { new: true }
  );

  if (!doc) return res.status(404).json({ error: "Not found" });
  res.json(doc);
});

// DELETE /api/settlements/:id
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid settlement id" });
  }

  const result = await Settlement.deleteOne({ _id: id, userId: req.userId });
  if (result.deletedCount === 0) return res.status(404).json({ error: "Not found" });

  res.status(204).end();
});

module.exports = router;
