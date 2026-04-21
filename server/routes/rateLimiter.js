const rateLimit = require('express-rate-limit');
const HighLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });
const MediumLimiter = rateLimit({ windowMs: 5 * 60 * 1000, max: 100 });
const ModerateLimiter = rateLimit({ windowMs: 2 * 60 * 1000, max: 200 });

module.exports = {
  HighLimiter,
  MediumLimiter,
  ModerateLimiter
};