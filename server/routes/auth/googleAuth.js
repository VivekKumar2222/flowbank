const express = require('express');
const router = express.Router();
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const User = require('../../models/User'); // adjust path to your User model

const client = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

router.post('/google', async (req, res) => {
  const { idToken, accessToken } = req.body;

  if (!idToken && !accessToken) {
    return res.status(400).json({ message: 'idToken or accessToken is required' });
  }

  try {
    let email, name, picture, googleId;

    if (idToken) {
      // Mobile: verify idToken directly
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_WEB_CLIENT_ID,
      });
      const payload = ticket.getPayload();
      ({ email, name, picture, sub: googleId } = payload);
    } else {
      // Web: use accessToken to fetch user info from Google
      const { data } = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      email = data.email;
      name = data.name;
      picture = data.picture;
      googleId = data.sub;
    }

    // 2. Find or create user in MongoDB
    let user = await User.findOne({ email });

    if (!user) {
      // New user — create without password (Google users don't need one)
      user = await User.create({
        name,
        email,
        googleId,
        avatar: picture,
        isVerified: true, // Google already verified the email
        authProvider: 'google',
      });
    } else if (!user.googleId) {
      // Existing email-password user — link Google to their account
      user.googleId = googleId;
      user.isVerified = true;
      if (!user.avatar) user.avatar = picture;
      await user.save();
    }

    // 3. Issue your app's JWT (same as your existing login)
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar || null,
      },
    });
  } catch (error) {
    console.error('Google auth error:', error);
    return res.status(401).json({ message: 'Invalid Google token' });
  }
});

module.exports = router;