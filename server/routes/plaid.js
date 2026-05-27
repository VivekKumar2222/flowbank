const express = require('express');
const router = express.Router();
const plaidClient = require('../config/plaid');
const User = require('../models/User');
const { Products, CountryCode } = require('plaid');
const BankAccount = require('../models/user_BankAccount');
const {HighLimiter, MediumLimiter, ModerateLimiter} = require('./rateLimiter.js');



// 1. Create Link Token — called when Connect Bank page loads
router.post('/create-link-token', HighLimiter, async (req, res) => {
  try {
    const { userId } = req.body;

    const response = await plaidClient.linkTokenCreate({
      user: { client_user_id: userId },
      client_name: 'FlowBank',
      products: process.env.PLAID_PRODUCTS.split(',').map(p => p.trim()),
      country_codes: process.env.PLAID_COUNTRY_CODES.split(',').map(c => c.trim()),
      language: 'en',
      redirect_uri: process.env.PLAID_REDIRECT_URI || undefined,
    });

    res.json({ link_token: response.data.link_token });
  } catch (err) {
    console.error('Plaid create-link-token error:', err.response?.data || err.message);
    res.status(500).json({ message: 'Failed to create link token' });
  }
});

// 2. Exchange Public Token — called after user connects bank
router.post('/exchange-token', HighLimiter, async (req, res) => {
  try {
    const { public_token, userId } = req.body;

    const response = await plaidClient.itemPublicTokenExchange({ public_token });

    const accessToken = response.data.access_token;
    const itemId = response.data.item_id;

    // Save to MongoDB
    await BankAccount.create({
  user: userId,
  plaidAccessToken: accessToken,
  plaidItemId: itemId,
});

    res.json({ message: 'Bank connected successfully' });
  } catch (err) {
    console.error('Plaid exchange-token error:', err.response?.data || err.message);
    res.status(500).json({ message: 'Failed to exchange token' });
  }
});

module.exports = router;