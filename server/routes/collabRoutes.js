const express = require("express");
const Dashboard = require("../models/collab_Dashboard");
const DashboardEntry = require("../models/collab_DashboardEntry");
const DashboardMember = require("../models/collab_DashboardMember");
const EntryVerification = require("../models/collab_EntryVerification");
const Invitation = require("../models/collab_Invitation");
const User = require("../models/User");
const DashboardBillSplit = require("../models/collab_BillSplitTotal");


const router = express.Router();

// TEST ROUTE - dynamic
router.post("/create-dashboard", async (req, res) => {
  try {
    const { name, type, ownerId, currency, settings } = req.body;

    // Validate required fields
    if (!name || !type || !ownerId) {
      return res
        .status(400)
        .json({ error: "name, type, and ownerId are required" });
    }

    // Create dashboard using the data from request body
    const dashboard = await Dashboard.create({
      name,
      type,
      ownerId,
      // ownerName,
      currency, // optional, will use default if not provided
      settings, // optional, will use defaults if not provided
    });

    res.status(201).json({
      message: "Dashboard created",
      dashboard,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.post("/create-entry", async (req, res) => {
  try {
    const {
      dashboardId,
      createdBy,
      entryType,
      amount,
      participants,
      status,
      dueDate,
      description,
    } = req.body;

    if (!dashboardId || !createdBy || !entryType || !amount) {
      return res.status(400).json({
        error: "dashboardId, createdBy, entryType, and amount are required",
      });
    }

    const entry = await DashboardEntry.create({
      dashboardId,
      createdBy,
      entryType,
      amount,
      participants,
      status,
      dueDate,
      description,
    });

    res.status(201).json({ message: "Dashboard entry created", entry });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

/// ─── Dashboard Member ───────────────────
router.post("/add-member", async (req, res) => {
  try {
    const { dashboardId, userId, role } = req.body;

    if (!dashboardId || !userId) {
      return res
        .status(400)
        .json({ error: "dashboardId and userId are required" });
    }

    const member = await DashboardMember.create({ dashboardId, userId, role });
    res.status(201).json({ message: "Member added", member });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

/// ─── Entry Verification ─────────────────
router.post("/verify-entry", async (req, res) => {
  try {
    const { entryId, uploadedBy, type, fileUrl, note, verifiedBy, verifiedAt } =
      req.body;

    if (!entryId) {
      return res.status(400).json({ error: "entryId is required" });
    }

    const verification = await EntryVerification.create({
      entryId,
      uploadedBy,
      type,
      fileUrl,
      note,
      verifiedBy,
      verifiedAt,
    });

    res
      .status(201)
      .json({ message: "Entry verification created", verification });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

/// ─── Invitation ─────────────────────────
router.post("/invite", async (req, res) => {
  try {
    const { dashboardId, fromUser, toUser, status } = req.body;

    if (!dashboardId || !fromUser || !toUser) {
      return res
        .status(400)
        .json({ error: "dashboardId, fromUser, and toUser are required" });
    }

    const invitation = await Invitation.create({
      dashboardId,
      fromUser,
      toUser,
      status,
    });
    res.status(201).json({ message: "Invitation created", invitation });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// GET dashboards for a user
router.get("/dashboard-members", async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ error: "userId is required" });

    const members = await DashboardMember.find({ userId });
    res.json(members);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post("/dashboards-by-ids", async (req, res) => {
  try {
    const { ids } = req.body;
    if (!ids || !Array.isArray(ids))
      return res.status(400).json({ error: "Invalid IDs" });

    // Fetch dashboards
    const dashboards = await Dashboard.find({ _id: { $in: ids } });

    // Fetch owners' names in one query
    const ownerEmails = dashboards.map((d) => d.ownerId);
    const owners = await User.find({ email: { $in: ownerEmails } });

    // Map email -> name for easy lookup
    const ownerMap = {};
    owners.forEach((u) => {
      ownerMap[u.email] = u.name;
    });

    // Add ownerName to dashboard objects
    const dashboardsWithOwner = dashboards.map((d) => ({
      ...d.toObject(),
      ownerName: ownerMap[d.ownerId] || d.ownerId, // fallback to email if not found
    }));

    res.json(dashboardsWithOwner);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post("/accept-invitation", async (req, res) => {
  try {
    const { invitationId, dashboardId, userId } = req.body;

    await DashboardMember.findOneAndUpdate(
      { dashboardId, userId },
      { dashboardId, userId, role: "member" },
      { upsert: true, new: true }
    );

    await Invitation.findByIdAndUpdate(invitationId, {
      status: "accepted",
    });

    res.json({ message: "Invitation accepted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET Invitations for User ─────────────────
// ─── GET Invitations for User (EMAIL-based) ─────────────────
router.get("/invitations", async (req, res) => {
  try {
    const { userId } = req.query; // userId === email

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    const invitations = await Invitation.find({
      toUser: userId,
      status: "pending", // ONLY pending invitations
    });

    res.json(invitations);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post("/reject-invitation", async (req, res) => {
  try {
    const { invitationId } = req.body;

    await Invitation.findByIdAndUpdate(invitationId, {
      status: "rejected",
    });

    res.json({ message: "Invitation rejected" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Get Invited Dashboards With Members ─────────────────
router.get("/invited-dashboards", async (req, res) => {
  try {
    const { userId } = req.query; // logged-in email

    if (!userId) {
      return res.status(400).json({ error: "userId required" });
    }

        const invitations = await Invitation.find({
      toUser: userId,
      status: "pending",
    });

    if (!invitations.length) return res.json([]);

    const invitationMap = {};
    invitations.forEach((inv) => {
      invitationMap[inv.dashboardId.toString()] = inv._id.toString();
    });

    // 1️⃣ Invitations


    const dashboardIds = invitations.map((i) => i.dashboardId);

    // 2️⃣ Dashboards
    const dashboards = await Dashboard.find({
      _id: { $in: dashboardIds },
    });

    // 3️⃣ Collect owner emails
    const ownerEmails = dashboards.map((d) => d.ownerId);

    // 4️⃣ Fetch owners
    const owners = await User.find(
      { email: { $in: ownerEmails } },
      { email: 1, name: 1 }
    );

    const ownerMap = {};
    owners.forEach((o) => {
      ownerMap[o.email] = o.name;
    });

    // 5️⃣ Members
    const members = await DashboardMember.find({
      dashboardId: { $in: dashboardIds },
    });

    const users = await User.find(
      { email: { $in: members.map((m) => m.userId) } },
      { email: 1, name: 1 }
    );

    const userMap = {};
    users.forEach((u) => (userMap[u.email] = u.name));

    const membersByDashboard = {};
    members.forEach((m) => {
      if (!membersByDashboard[m.dashboardId]) {
        membersByDashboard[m.dashboardId] = [];
      }
      membersByDashboard[m.dashboardId].push(userMap[m.userId] || m.userId);
    });

    // 6️⃣ FINAL RESPONSE
    const result = dashboards.map((d) => ({
      ...d.toObject(),
      invitationId: invitationMap[d._id.toString()], // ✅ ADD THIS
      ownerName: ownerMap[d.ownerId] || d.ownerId,
      members: membersByDashboard[d._id] || [],
    }));

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.get(
  "/dashboard-members-by-dashboard",
  async (req, res) => {
    try {
      const { dashboardId } = req.query;

      if (!dashboardId) {
        return res.status(400).json({
          message: "dashboardId is required",
        });
      }

      const members = await DashboardMember.find({
        dashboardId: dashboardId,
      });

      res.status(200).json(members);
    } catch (error) {
      console.error(error);
      res.status(500).json({
        message: "Failed to fetch dashboard members",
      });
    }
  }

  
);

// ─── Set Bill Split Total (ONE-TIME) ─────────────────
router.post("/set-bill-split-total", async (req, res) => {
  try {
    const { dashboardId, totalAmount } = req.body;

    if (!dashboardId || totalAmount === undefined) {
      return res.status(400).json({
        message: "dashboardId and totalAmount are required",
      });
    }

    // 🔒 One-time lock check
    const existing = await DashboardBillSplit.findOne({ dashboardId });

    if (existing) {
      return res.status(400).json({
        message: "Splitting amount already set and cannot be changed",
      });
    }

    const record = await DashboardBillSplit.create({
      dashboardId,
      totalAmount,
    });

    res.status(201).json({
      message: "Bill split total saved successfully",
      record,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to save bill split total",
    });
  }
});



module.exports = router;
