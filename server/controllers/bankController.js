const BankAccount = require('../models/BankAccount');
const plaidClient = require('../config/plaid');

exports.fetchHistoricalTransactions = async (userId) => {
  const accounts = await BankAccount.find({ user: userId });

  const today = new Date();
  const past = new Date();
  past.setMonth(today.getMonth() - 3); // last 3 months

  let allTransactions = [];

  for (const acc of accounts) {
    const response = await plaidClient.transactionsGet({
      access_token: acc.plaidAccessToken,
      start_date: past.toISOString().split('T')[0],
      end_date: today.toISOString().split('T')[0],
    });

    allTransactions = allTransactions.concat(response.data.transactions);
  }

  return allTransactions;
};

exports.fetchRealTimeTransactions = async (userId, cursorMap) => {
  // cursorMap = { bankAccountId: lastCursor } from your DB
  const accounts = await BankAccount.find({ user: userId });
  let newTransactions = [];

  for (const acc of accounts) {
    let cursor = cursorMap[acc._id] || null;
    let hasMore = true;

    while (hasMore) {
      const res = await plaidClient.transactionsSync({
        access_token: acc.plaidAccessToken,
        cursor: cursor,
      });

      // Add new and modified transactions
      newTransactions = newTransactions.concat(res.data.added);
      newTransactions = newTransactions.concat(res.data.modified);

      // Update cursor
      cursor = res.data.next_cursor;
      hasMore = res.data.has_more;

      // Save cursor back to DB for next incremental sync
      await BankAccount.findByIdAndUpdate(acc._id, { lastCursor: cursor });
    }
  }

  return newTransactions;
};

exports.fetchTotalBalance = async (userId) => {
  const accounts = await BankAccount.find({ user: userId });
  let totalBalance = 0;

  for (const acc of accounts) {
    const response = await plaidClient.accountsBalanceGet({
      access_token: acc.plaidAccessToken,
    });

    response.data.accounts.forEach(account => {
      totalBalance += account.balances.current;
    });
  }

  return totalBalance;
};