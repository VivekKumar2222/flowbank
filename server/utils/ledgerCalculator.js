// utils/ledgerCalculator.js
const Notification = require("../models/notifications");
const  sendEmail  = require("../utils/mailer.js"); // make sure you export {sendEmail} properly


function getCyclesPassed(from, to, cycle) {
  const diff = to - from;

  if (cycle === "weekly") {
    return Math.floor(diff / (7 * 24 * 60 * 60 * 1000));
  }

  if (cycle === "monthly") {
    return Math.floor(diff / (30 * 24 * 60 * 60 * 1000));
  }

  if (cycle === "yearly") {
    return Math.floor(diff / (365 * 24 * 60 * 60 * 1000));
  }

  return 0;
}

async function updateLedgerAmounts(ledger) {
  // 🛑 STOP if already paid
  if (ledger.status === "paid") return ledger;

  const now = new Date();

  // 📅 Decide calculation start date
  const lastDate =
    ledger.lastInterestAppliedAt || ledger.createdAt;

  // 🔁 INTEREST CALCULATION
  const cycles = getCyclesPassed(
    lastDate,
    now,
    ledger.interestCycle
  );

  if (cycles > 0 && ledger.interestRate > 0) {
    const interest =
      ledger.totalAmount * (ledger.interestRate / 100) * cycles;

    ledger.totalAmount += interest;
  }

  // 🚨 PENALTY (only once)
  let penaltyWasApplied = false;

  if (
    !ledger.penaltyApplied &&
    ledger.dueDate &&
    now > ledger.dueDate
  ) {
    if (ledger.penaltyType === "fixed") {
      ledger.totalAmount += ledger.penaltyAmount;
    }

    if (ledger.penaltyType === "percentage") {
      ledger.totalAmount +=
        ledger.totalAmount * (ledger.penaltyAmount / 100);
    }

    ledger.penaltyApplied = true;
    penaltyWasApplied = true;

    await Notification.create({
    userId: ledger.memberId, // 👈 who needs to pay
    type: "Penalty",
    title: "Payment Overdue",
    body: `Your payment was due on ${
      ledger.dueDate.toISOString().split("T")[0]
    }. A penalty has been applied.`,
    dueDate: ledger.dueDate,
    relatedId: ledger._id,
  });

  const html = `
        <p>You missed an assignment,</p>
        <p>Your payment was due on <b>${ledger.dueDate.toISOString().split("T")[0]}</b></p>
        <p>A penalty has been applied.</p>
        <p>Penalty applied: ${ledger.penaltyAmount} ${ledger.penaltyType === "percentage" ? '%' : ''}</p>
        <p>New total amount: ${ledger.totalAmount.toFixed(2)}</p>

      `;
      await sendEmail(ledger.memberId, "FlowBank Alert Notification", html);
  }

  // 💾 SAVE if anything changed
  if (cycles > 0 || penaltyWasApplied) {
    ledger.lastInterestAppliedAt = now;
    await ledger.save();
  }

  return ledger;
}

module.exports = {
  updateLedgerAmounts,
};
