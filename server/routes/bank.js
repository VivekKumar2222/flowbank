const express = require("express");
const router = express.Router();
const { PlaidApi, Configuration, PlaidEnvironments } = require("plaid");
const User = require("../models/User");
const BankAccount = require("../models/user_BankAccount");

const {HighLimiter, MediumLimiter, ModerateLimiter} = require('./rateLimiter.js');

const configuration = new Configuration({
  basePath: PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID,
      "PLAID-SECRET": process.env.PLAID_SECRET,
    },
  },
});

const plaidClient = new PlaidApi(configuration);

router.get("/all-data/:email", MediumLimiter, async (req, res) => {
  try {
    const email = req.params.email;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: "User not found" });

    const bankAccounts = await BankAccount.find({ user: user._id });
    if (!bankAccounts.length)
      return res.json({ accounts: [], historical: [], realtime: [], totalBalance: 0 });

    let totalBalance = 0;

    // 1️⃣ Map bank accounts to promises
    const accountPromises = bankAccounts.map(async (bankRecord) => {
      const accessToken = bankRecord.plaidAccessToken;

      const endDate = new Date();
      const startDate = new Date();
      startDate.setMonth(endDate.getMonth() - 3);

      // Parallel calls for historical, realtime, and balance
      const [historicalResponse, syncResponse, balanceResponse, itemResponse] = await Promise.all([
        plaidClient.transactionsGet({
          access_token: accessToken,
          start_date: startDate.toISOString().split("T")[0],
          end_date: endDate.toISOString().split("T")[0],
        }),
        plaidClient.transactionsSync({ access_token: accessToken }),
        plaidClient.accountsBalanceGet({ access_token: accessToken }),
        plaidClient.itemGet({ access_token: accessToken }),
      ]);

      // 2️⃣ Fetch institution name from cached or Plaid
      let institutionName = bankRecord.institutionName;
      try {
        if (!institutionName && itemResponse.data.item.institution_id) {
          const instResp = await plaidClient.institutionsGetById({
            institution_id: itemResponse.data.item.institution_id,
            country_codes: ["US"],
          });
          institutionName = instResp.data.institution.name;

          // Save to DB for next time
          bankRecord.institutionName = institutionName;
          await bankRecord.save();
        }
      } catch (e) {
        console.error("Failed to fetch institution name:", e.message);
      }

      // 3️⃣ Prepare accounts
      const subAccounts = balanceResponse.data.accounts.map((acc) => {
        const currentBalance = acc.balances.current || 0;
        totalBalance += currentBalance;

        return {
          accountId: acc.account_id,
          name: acc.official_name || acc.name,
          subtype: acc.subtype,
          balance: currentBalance,
          currency: acc.balances.iso_currency_code || "USD",
        };
      });

      return {
        institutionName,
        totalBalance: subAccounts.reduce((sum, a) => sum + a.balance, 0),
        subAccounts,
        historical: historicalResponse.data.transactions,
        realtime: syncResponse.data.added,
        dateConnected: bankRecord.createdAt,
      };
    });

    // 4️⃣ Wait for all accounts to finish
    const allAccounts = await Promise.all(accountPromises);

    // 5️⃣ Combine all historical & realtime
    const allHistorical = allAccounts.flatMap((a) => a.historical);
    const allRealtime = allAccounts.flatMap((a) => a.realtime);

    res.json({ accounts: allAccounts, historical: allHistorical, realtime: allRealtime, totalBalance });
  } catch (error) {
    console.error("Error fetching bank data:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;