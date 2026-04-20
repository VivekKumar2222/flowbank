// routes/budgetGoals.js
const express = require("express");
const router = require('express').Router();

const BudgetGoal = require('../models/BudgetGoal.js');

router.post('/goal-set', async (req, res) => {
  try {
    const goal = await BudgetGoal.create(req.body);
    res.status(201).json(goal);
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
});

module.exports = router;