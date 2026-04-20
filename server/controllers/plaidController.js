exports.createLinkToken = async (req, res) => {
  try {
    const products = process.env.PLAID_PRODUCTS.split(',');

    const countryCodes = process.env.PLAID_COUNTRY_CODES.split(',');

    const response = await client.linkTokenCreate({
      user: { 
        client_user_id: req.user?.id || "test-user"
      },

      client_name: "FlowBank",
      products: products,
      country_codes: countryCodes,
      language: "en",
    });

    res.json({ link_token: response.data.link_token });
    

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.exchangeToken = async (req, res) => {
  try {
    const { public_token } = req.body;
    // 👆 This comes from Flutter after user logs in via Plaid

    const response = await client.itemPublicTokenExchange({
      public_token,
    });

    const access_token = response.data.access_token;
    // 🔥 THIS IS THE MAIN TOKEN
    // You will use this forever to fetch data

    // ✅ SAVE THIS IN DATABASE (MongoDB)
    // Example:
    /*
    await User.findByIdAndUpdate(req.user.id, {
      access_token: access_token,
    });
    */

    console.log("Access Token:", access_token);
    // 👆 For now just log it (testing phase)

    res.json({ success: true });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getTransactions = async (req, res) => {
  try {
    // ❌ WRONG (temporary only)
    const access_token = "PASTE_TOKEN";

    // ✅ CORRECT (when MongoDB ready)
    /*
    const user = await User.findById(req.user.id);
    const access_token = user.access_token;
    */

    // 👆 This is how you retrieve stored token

    // Dynamic date (last 3 months)
    const today = new Date();
    const past = new Date();
    past.setMonth(today.getMonth() - 3);

    const response = await client.transactionsGet({
      access_token,

      start_date: past.toISOString().split('T')[0],
      // 👆 convert JS date → "YYYY-MM-DD"

      end_date: today.toISOString().split('T')[0],
    });

    res.json(response.data.transactions);
    // 👆 Send to Flutter OR Python AI

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getBalance = async (req, res) => {
  try {
    const access_token = "PASTE_TOKEN"; 
    // 👆 Replace with DB value later (same as above)

    const response = await client.accountsBalanceGet({
      access_token,
    });

    res.json(response.data.accounts);
    // 👆 Contains:
    // - current balance
    // - available balance

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};