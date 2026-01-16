const cron = require("node-cron");
const LedgerAssignment = require("../models/collab_LedgerAssignments");
const { updateLedgerAmounts } = require("../utils/ledgerCalculator");

// 🕛 Runs EVERY DAY at 12:05 AM
cron.schedule("5 0 * * *", async () => {
  console.log("🔁 Ledger cron started");

  try {
    // Get all unpaid ledgers
    const ledgers = await LedgerAssignment.find({
      status: { $ne: "paid" },
    });

    for (const ledger of ledgers) {
      await updateLedgerAmounts(ledger);
    }

    console.log("✅ Ledger cron completed");
  } catch (error) {
    console.error("❌ Ledger cron error:", error);
  }
});
