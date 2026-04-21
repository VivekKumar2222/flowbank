// routes/budgetGoals.js
const express = require("express");
const router = require('express').Router();
const {HighLimiter, MediumLimiter, ModerateLimiter} = require('./rateLimiter.js');
const protect = require('../middleware/middleware.js');

const BudgetGoal = require('../models/BudgetGoal.js');

router.post('/goal-set', protect, ModerateLimiter,async (req, res) => {
  try {
    const goal = await BudgetGoal.create(req.body);
    res.status(201).json(goal);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

router.get('/my-goals', protect, async (req, res) => {
  try {
    const goals = await BudgetGoal.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json(goals);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

module.exports = router;