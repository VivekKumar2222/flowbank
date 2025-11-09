const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: process.env.SMTP_SECURE === 'true', // true for 465, false for others
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const sendEmail = async (to, subject, html) => {
  try {
    await transporter.sendMail({
      from: `"FlowBank Support" <${process.env.SMTP_USER}>`,
      to,
      subject,
      html,
    });
    console.log('📧 Email sent to', to);
  } catch (error) {
    console.error('Email error:', error);
    throw new Error(error.message);
  }
};

module.exports = sendEmail;
