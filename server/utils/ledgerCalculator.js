// utils/ledgerCalculator.js

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
