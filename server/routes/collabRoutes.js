const axios = require("axios");

const express = require("express");
const Dashboard = require("../models/collab_Dashboard");
const DashboardEntry = require("../models/collab_DashboardEntry");
const DashboardMember = require("../models/collab_DashboardMember");
const EntryVerification = require("../models/collab_EntryVerification");
const Invitation = require("../models/collab_Invitation");
const User = require("../models/User");
const DashboardBillSplit = require("../models/collab_BillSplitTotal");
const LedgerAssignment = require("../models/collab_LedgerAssignments");
const AssignedMembers = require("../models/collab_LedgerAssignedMembers");
const { updateLedgerAmounts } = require("../utils/ledgerCalculator");
const jwt = require("jsonwebtoken");
const {generateAccessToken, generateRefreshToken} = require("../utils/jwt.js");
const protect = require("../middleware/middleware.js")
const Notification = require("../models/notifications.js")
const  sendEmail  = require("../utils/mailer.js"); // make sure you export {sendEmail} properly
const { encrypt, decrypt } = require("../utils/mediaCrypto");
const ExitRequest = require("../models/collab_ExitRequest");

const {HighLimiter, MediumLimiter, ModerateLimiter} = require('./rateLimiter.js');




const router = express.Router();

// TEST ROUTE - dynamic
router.post("/create-dashboard", protect, MediumLimiter, async (req, res) => {
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

router.post("/create-entry", MediumLimiter,async (req, res) => {
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
router.post("/add-member", MediumLimiter,protect, async (req, res) => {
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
router.post("/verify-entry", MediumLimiter, async (req, res) => {
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
router.post("/invite", MediumLimiter, protect, async (req, res) => {
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

    const sender = await User.findOne(
      { email: fromUser },
      { name: 1 }
    );

    const senderName = sender?.name || fromUser;

    // 3️⃣ Fetch dashboard name
    const dashboard = await Dashboard.findById(
      dashboardId,
      { name: 1 }
    );

    const dashboardName = dashboard?.name || "a dashboard";

    // 4️⃣ Create notification 🔔
    await Notification.create({
      userId: toUser, // 👈 invited user
      type: "Invite",
      title: "Invitation for you",
      body: `You got an invitation from ${senderName} for ${dashboardName}`,
      relatedId: invitation._id, // 🔥 link notification to invitation
    });

    const html = `
        <p>You got an invitation from <b>${senderName}</b> for <b>${dashboardName}</b></p>
        <p>Check the FlowBank application to join</p>
        
      `;
      await sendEmail(toUser, "FlowBank Invitation Notification", html);
    
    res.status(201).json({ message: "Invitation created", invitation });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// GET dashboards for a user
router.get("/dashboard-members", ModerateLimiter, protect, async (req, res) => {
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

router.post("/dashboards-by-ids", ModerateLimiter, protect, async (req, res) => {
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

router.post("/accept-invitation", ModerateLimiter, protect, async (req, res) => {
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
router.get("/invitations", ModerateLimiter, async (req, res) => {
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

router.post("/reject-invitation", MediumLimiter, protect, async (req, res) => {
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
router.get("/invited-dashboards", ModerateLimiter, protect, async (req, res) => {
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
  "/dashboard-members-by-dashboard", ModerateLimiter, protect,
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
router.post("/set-bill-split-total", ModerateLimiter, protect, async (req, res) => {
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

// ─── Get Bill Split Total ─────────────────
router.get("/bill-split-total", ModerateLimiter, protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({
        message: "dashboardId is required",
      });
    }

    const record = await DashboardBillSplit.findOne({ dashboardId });

    if (!record) {
      return res.status(404).json({
        message: "No bill split total found for this dashboard",
      });
    }

    res.status(200).json({
      dashboardId: record.dashboardId,
      totalAmount: record.totalAmount,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to fetch bill split total",
    });
  }
});

router.post("/users-by-emails", ModerateLimiter, protect, async (req, res) => {
  const { emails } = req.body;
  const users = await User.find({ email: { $in: emails } }, { email: 1, name: 1 });
  res.json(users);
});

router.post("/dashboard-entry", protect, async (req, res) => {
  try {
    const { dashboardId, userId, amount, verificationImage, assignmentId } = req.body;

    if (!dashboardId || !userId || !amount) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const encryptedImage = verificationImage ? encrypt(verificationImage) : null;

    const entry = new DashboardEntry({
      dashboardId,
      userId,
      amount,
      verificationImage: encryptedImage, // store encrypted
      assignmentId: assignmentId || null,
      status: "pending",
    });

    await entry.save();

    res.status(201).json({
      message: "Entry added successfully",
      entry,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

// module.exports = router;

router.get('/dashboard/:id', ModerateLimiter, protect, async (req, res) => {
  try {
    const dashboard = await Dashboard.findById(req.params.id);
    if (!dashboard) return res.status(404).json({ message: 'Dashboard not found' });
    res.json(dashboard);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/dashboard-entries", protect, async (req, res) => {
  try {
    let { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    // 1️⃣ Fetch entries
    const entries = await DashboardEntry.find({ dashboardId }).sort({
      createdAt: -1,
    });

    if (!entries.length) {
      return res.status(200).json([]);
    }

    // 2️⃣ Collect unique emails
    const emails = [...new Set(entries.map(e => e.userId))];

    // 3️⃣ Fetch users
    const users = await User.find(
      { email: { $in: emails } },
      { email: 1, name: 1 }
    );

    // 4️⃣ Create email → name map
    const userMap = {};
    users.forEach(u => {
      userMap[u.email] = u.name;
    });

    // 5️⃣ Attach username to each entry
    const enrichedEntries = entries.map(e => ({
      ...e.toObject(),
      userName: userMap[e.userId] || e.userId, // fallback
    }));

    res.status(200).json(enrichedEntries);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

router.post("/ledger-assignment", MediumLimiter,protect, async (req, res) => {
  try {
    const { dashboardId, memberId, totalAmount, dueDate } = req.body;

    if (!dashboardId || !memberId) {
      return res.status(400).json({ message: "dashboardId and memberId are required" });
    }

    // 1️⃣ Create ledger assignment
    const assignment = await LedgerAssignment.create({
      ...req.body,
      status: "active",
      penaltyApplied: false,
      lastInterestAppliedAt: null,
    });

    // 2️⃣ Upsert assigned member
    //    If member exists for this dashboard → update membersAssigned to true
    //    If not → create a new entry
    await AssignedMembers.findOneAndUpdate(
      { dashboardId, memberId },   // query
      { dashboardId, memberId, membersAssigned: true }, // update
      { upsert: true, new: true } // create if doesn't exist
    );

    await Notification.create({
      userId: memberId, // 🔥 notification receiver
      type: "Reminder",
      title: "Assignment Reminder",
      body: `You have to pay ${totalAmount} before ${new Date(dueDate)
        .toISOString()
        .split("T")[0]}`,
      dueDate: dueDate,
      relatedId: assignment._id,
    });

    const html = `
        <p>You got a new assignment,</p>
        <p>Amount to pay: <b>${totalAmount}</b></p>
        <p>Your payment is due on <b>${new Date(dueDate).toISOString().split("T")[0]}</b></p>
        
      `;
      await sendEmail(memberId, "FlowBank Reminder Notification", html);

    res.status(201).json({
      message: "Assignment created and member updated successfully",
      assignment,
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// ─── GET Unassigned Dashboard Members ─────────────────
router.get("/unassigned-members", ModerateLimiter,protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    // 1️⃣ Get assigned members for this dashboard
    const assigned = await AssignedMembers.find(
      { dashboardId },
      { memberId: 1 }
    );

    const assignedMemberIds = assigned.map(a => a.memberId);

    // 2️⃣ Get dashboard members who are NOT assigned
    const unassignedMembers = await DashboardMember.find({
      dashboardId,
      userId: { $nin: assignedMemberIds }, // 🔥 SET DIFFERENCE
    });

    if (!unassignedMembers.length) {
      return res.status(200).json([]);
    }

    // 3️⃣ Fetch user names
    const emails = unassignedMembers.map(m => m.userId);

    const users = await User.find(
      { email: { $in: emails } },
      { email: 1, name: 1 }
    );

    // 4️⃣ Map email → name
    const userMap = {};
    users.forEach(u => {
      userMap[u.email] = u.name;
    });

    // 5️⃣ Attach name to members
    const response = unassignedMembers.map(m => ({
      dashboardId: m.dashboardId,
      userId: m.userId,
      name: userMap[m.userId] || m.userId, // fallback
      role: m.role,
    }));

    res.status(200).json(response);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Failed to fetch unassigned members" });
  }
});

// ─── GET Ledger Summary (Total Lent + Assigned Members Count) ─────────────────
router.get("/ledger-summary", ModerateLimiter, protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    // 1️⃣ Total lent amount from LedgerAssignments
    const totalResult = await LedgerAssignment.aggregate([
      { $match: { dashboardId } },
      {
        $group: {
          _id: null,
          totalLent: { $sum: "$totalAmount" },
        },
      },
    ]);

    const totalLent =
      totalResult.length > 0 ? totalResult[0].totalLent : 0;

    // 2️⃣ Assigned members count
    const assignedMemberCount = await AssignedMembers.countDocuments({
      dashboardId,
      membersAssigned: true,
    });

    res.status(200).json({
      dashboardId,
      totalLent,
      assignedMemberCount,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to fetch ledger summary",
    });
  }
});

// ─── GET Assigned Members with Total Assigned Amount ─────────────────
router.get("/assigned-members-summary", ModerateLimiter,protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    const result = await LedgerAssignment.aggregate([
      // 1️⃣ Only this dashboard
      { $match: { dashboardId } },

      // 2️⃣ Group assignments per member
      {
        $group: {
          _id: "$memberId",
          totalAmount: { $sum: "$totalAmount" },
        },
      },

      // 3️⃣ Join USERS (for name)
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "email",
          as: "userInfo",
        },
      },
      { $unwind: "$userInfo" },

      // 4️⃣ Join ENTRIES (approved only)
      {
        $lookup: {
          from: "dashboardentries",
          let: { memberEmail: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$dashboardId", dashboardId] },
                    { $eq: ["$userId", "$$memberEmail"] },
                    { $eq: ["$status", "approved"] }, // ✅ ONLY approved
                  ],
                },
              },
            },
            {
              $group: {
                _id: null,
                paidAmount: { $sum: "$amount" },
              },
            },
          ],
          as: "paidInfo",
        },
      },

      // 5️⃣ Final shape
      {
        $project: {
          _id: 0,
          memberId: "$_id",
          name: "$userInfo.name",
          totalAmount: 1,
          paidAmount: {
            $ifNull: [{ $arrayElemAt: ["$paidInfo.paidAmount", 0] }, 0],
          },
        },
      },
    ]);

    res.status(200).json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to fetch assigned members summary",
    });
  }
});

// ─── GET Ledger Assignments for Member ─────────────────
router.get("/member-ledger", ModerateLimiter, protect, async (req, res) => {
  try {
    const { dashboardId, memberId } = req.query;

    if (!dashboardId || !memberId) {
      return res.status(400).json({
        message: "dashboardId and memberId are required",
      });
    }

    /* ─────────────────────────────────────────────
       1️⃣ Assignments + PAID AMOUNT (from entries)
    ───────────────────────────────────────────── */

    const assignments = await LedgerAssignment.aggregate([
      {
        $match: {
          dashboardId,
          memberId,
        },
      },
      {
        $lookup: {
          from: "dashboardentries",
          let: { assignmentId: "$_id" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$dashboardId", dashboardId] },
                    { $eq: ["$assignmentId", "$$assignmentId"] },
                    { $eq: ["$userId", memberId] },
                    { $eq: ["$status", "approved"] },
                  ],
                },
              },
            },
            {
              $group: {
                _id: null,
                paidAmount: { $sum: "$amount" },
              },
            },
          ],
          as: "paidInfo",
        },
      },
      {
        $addFields: {
          paidAmount: {
            $ifNull: [{ $arrayElemAt: ["$paidInfo.paidAmount", 0] }, 0],
          },
        },
      },
      {
        $project: {
          paidInfo: 0,
        },
      },
      { $sort: { createdAt: -1 } },
    ]);

    /* ─────────────────────────────────────────────
       2️⃣ MEMBER TOTAL PAID (ALL ENTRIES)
    ───────────────────────────────────────────── */

    const paidResult = await DashboardEntry.aggregate([
      {
        $match: {
          dashboardId,
          userId: memberId,
          status: "approved",
        },
      },
      {
        $group: {
          _id: null,
          totalPaid: { $sum: "$amount" },
        },
      },
    ]);

    const totalPaid =
      paidResult.length > 0 ? paidResult[0].totalPaid : 0;

    /* ─────────────────────────────────────────────
       3️⃣ TOTAL ASSIGNED AMOUNT
    ───────────────────────────────────────────── */

    const totalAmount = assignments.reduce(
      (sum, a) => sum + a.totalAmount,
      0
    );

    /* ─────────────────────────────────────────────
       4️⃣ MEMBER INFO
    ───────────────────────────────────────────── */

    const user = await User.findOne(
      { email: memberId },
      { name: 1 }
    );

    res.status(200).json({
      member: {
        name: user?.name || memberId,
        email: memberId,
      },
      summary: {
        totalAmount,
        paidAmount: totalPaid,
      },
      assignments,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Failed to fetch member ledger",
    });
  }
});



router.get("/dashboard-entry-image/:entryId", ModerateLimiter,async (req, res) => {
  try {
    const entry = await DashboardEntry.findById(req.params.entryId);

    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    res.status(200).json({
      verificationImage: entry.verificationImage,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});


router.get("/dashboard-entry/:entryId", ModerateLimiter, protect, async (req, res) => {
  try {
    const entry = await DashboardEntry.findById(req.params.entryId);

    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    // Decrypt verification image before sending
    const decryptedImage = entry.verificationImage
      ? decrypt(entry.verificationImage)
      : null;

    res.status(200).json({
      ...entry.toObject(),
      verificationImage: decryptedImage, // send decrypted image
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});


router.post("/verify-entry-ocr", ModerateLimiter, protect, async (req, res) => {
  try {
    const { entryId } = req.body;
    if (!entryId) return res.status(400).json({ message: "entryId is required" });

    const entry = await DashboardEntry.findById(entryId);
    if (!entry) return res.status(404).json({ message: "Entry not found" });

    const senderUser = await User.findOne({ email: entry.userId }, { name: 1 });
    const senderName = senderUser?.name || entry.userId;

    const dashboard = await Dashboard.findById(entry.dashboardId);
    if (!dashboard) return res.status(404).json({ message: "Dashboard not found" });

    const receiverUser = await User.findOne({ email: dashboard.ownerId }, { name: 1 });
    const receiverName = receiverUser?.name || dashboard.ownerId;

    const amountNumber = Number(entry.amount || 0);
    const imageUrl = entry.verificationImage ? decrypt(entry.verificationImage) : null; // decrypt here
    const dateStr = entry.createdAt ? entry.createdAt.toISOString().split("T")[0] : null;

    if (!imageUrl || !dateStr) {
      return res.status(400).json({ message: "Missing image or date for OCR" });
    }

    let ocrData;
    try {
      const ocrResponse = await axios.post("http://127.0.0.1:8000/ocr/verify", {
        image_url: imageUrl,
        sender_name: senderName,
        receiver_name: receiverName,
        amount: amountNumber,
        date: dateStr,
      });

      ocrData = ocrResponse.data;
    } catch (ocrError) {
      console.error("OCR server error:", ocrError.message);
      return res.status(500).json({ message: "OCR server failed", error: ocrError.message });
    }

    entry.ocrVerification = ocrData;
    entry.ocrVerified = Boolean(ocrData?.verified);
    await entry.save();

    res.status(200).json({
      verified: entry.ocrVerified,
      ocr: ocrData,
      meta: { senderName, receiverName, amount: amountNumber },
    });
  } catch (error) {
    console.error("OCR verification error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});


// ─── Update Entry Status (Verify / Reject) ─────────────────
router.post("/update-entry-status", MediumLimiter, protect, async (req, res) => {
  try {
    const { entryId, status } = req.body;

    if (!entryId || !status) {
      return res.status(400).json({
        message: "entryId and status are required",
      });
    }

    if (!["approved", "rejected"].includes(status)) {
      return res.status(400).json({
        message: "Invalid status value",
      });
    }

    const entry = await DashboardEntry.findById(entryId);
    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    entry.status = status;
    await entry.save();

    res.status(200).json({
      message: "Entry status updated",
      entryId,
      status,
    });
  } catch (error) {
    console.error("Update status error:", error);
    res.status(500).json({
      message: "Failed to update entry status",
    });
  }
});

// ─── GET Shared Expenses Total (Approved Entries Only) ─────────────────
router.get("/shared-expenses-total", ModerateLimiter, protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    const result = await DashboardEntry.aggregate([
      {
        $match: {
          dashboardId,
          status: "approved", // ✅ ONLY approved
        },
      },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: "$amount" },
        },
      },
    ]);

    const totalAmount =
      result.length > 0 ? result[0].totalAmount : 0;

    res.status(200).json({
      dashboardId,
      totalAmount,
    });
  } catch (error) {
    console.error("Shared expenses total error:", error);
    res.status(500).json({ message: "Failed to calculate shared expenses" });
  }
});

// GET dashboard owner by entryId
router.get("/entry-owner/:entryId", MediumLimiter, protect, async (req, res) => {
  try {
    const { entryId } = req.params;

    // 1️⃣ Find entry
    const entry = await DashboardEntry.findById(entryId);
    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    // 2️⃣ Find dashboard
    const dashboard = await Dashboard.findById(entry.dashboardId);
    if (!dashboard) {
      return res.status(404).json({ message: "Dashboard not found" });
    }

    // 3️⃣ Optional: fetch owner user info
    const owner = await User.findOne(
      { email: dashboard.ownerId },
      { email: 1, name: 1 }
    );

    res.status(200).json({
      entryId,
      dashboardId: entry.dashboardId,
      ownerId: dashboard.ownerId,
      ownerName: owner?.name || dashboard.ownerId,
    });
  } catch (error) {
    console.error("Entry owner fetch error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

const generateOTP = () => Math.floor(1000 + Math.random() * 9000).toString();
const otpStore = new Map();

router.post("/delete-group-otp", HighLimiter, async (req, res) => {
  try {
    const { email } = req.body; // get email and name from request body
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    // Generate OTP
    const otp = generateOTP();
    const expiry = Date.now() + 5 * 60 * 1000; // 5 minutes

    // Store OTP temporarily in memory
    otpStore.set(email, {
      otp,
      expiry, // ideally, hash OTP before storing for security
    });

    // Prepare email HTML
    const html = `
      <p>Hello,</p>
      <p>Your OTP for deleting a group is: <b>${otp}</b></p>
      <p>This code will expire in 5 minutes.</p>
    `;

    // Send email
    await sendEmail(email, "FlowBank Delete Group OTP", html);

    res.status(200).json({ message: "OTP sent to email. Please verify to delete the group." });
  } catch (err) {
    console.error("Delete group OTP error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

router.post("/verify-delete-otp", ModerateLimiter, protect, async (req, res) => {
  try {
    const { email, otp, dashboardId } = req.body;
    if (!email || !otp || !dashboardId) {
      return res.status(400).json({ message: "Email, OTP, and dashboardId are required" });
    }

    // Check OTP exists
    const record = otpStore.get(email);
    if (!record) {
      return res.status(400).json({ message: "No OTP found. Please request a new one." });
    }

    // Check OTP expiry
    if (Date.now() > record.expiry) {
      otpStore.delete(email);
      return res.status(400).json({ message: "OTP expired. Please request a new one." });
    }

    // Verify OTP
    if (record.otp !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    // OTP verified → delete OTP from store
    otpStore.delete(email);

    // Proceed to delete dashboard + related data
    const userId = req.user.email; // assuming email is stored in token
    const dashboard = await Dashboard.findById(dashboardId);
    if (!dashboard) return res.status(404).json({ message: "Dashboard not found" });
    if (dashboard.ownerId !== userId) return res.status(403).json({ message: "Not authorized" });

    await Promise.all([
      DashboardEntry.deleteMany({ dashboardId }),
      Invitation.deleteMany({ dashboardId }),
      LedgerAssignment.deleteMany({ dashboardId }),
      DashboardMember.deleteMany({ dashboardId }),
      DashboardBillSplit.deleteMany({ dashboardId }),
      AssignedMembers.deleteMany({ dashboardId }),
      Notification.deleteMany({ dashboardId }),
    ]);

    await Dashboard.findByIdAndDelete(dashboardId);

    res.status(200).json({ success: true, message: "Group and all related data deleted successfully" });

  } catch (err) {
    console.error("Verify Delete OTP error:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

router.post("/exit-group-request", MediumLimiter, protect, async (req, res) => {
  try {
    const { dashboardId, toUserId, fromUserId } = req.body;
     // logged-in user

    if (!dashboardId || !toUserId) {
      return res.status(400).json({ message: "dashboardId and toUserId are required" });
    }

    // Prevent duplicate pending requests
    const existing = await ExitRequest.findOne({
      dashboardId,
      fromUserId,
      status: "pending",
    });

    if (existing) {
      return res.status(400).json({ message: "Exit request already pending" });
    }

    // Fetch dashboard
    const dashboard = await Dashboard.findById(dashboardId, { name: 1 });
    if (!dashboard) {
      return res.status(404).json({ message: "Dashboard not found" });
    }

    // Fetch sender user
    const sender = await User.findOne(
      { email: fromUserId },
      { name: 1 }
    );

    const senderName = sender?.name || fromUserId;
    const dashboardName = dashboard.name || "a group";

    // Create exit request
    const exitRequest = await ExitRequest.create({
      dashboardId,
      toUserId,
      fromUserId,
      title: "Exit Group Request",
      body: `${senderName} has requested to exit the group "${dashboardName}".`,
      status: "pending",
    });

    // 🔔 Notification for owner
    await Notification.create({
      userId: toUserId,
      type: "Request",
      title: "Exit Group Request",
      body: `${senderName} wants to exit "${dashboardName}"`,
      relatedId: exitRequest._id,
    });

    // 📧 Email to owner
    const html = `
      <p><b>${senderName}</b> has requested to exit the group:</p>
      <p><b>${dashboardName}</b></p>
      <p>Please review this request in FlowBank.</p>
    `;

    await sendEmail(
      toUserId,
      "FlowBank Exit Group Request",
      html
    );

    res.status(201).json({
      message: "Exit request submitted successfully",
      exitRequest,
    });
  } catch (error) {
    console.error("Exit request error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// routes/collab.js
router.get("/exit-requests-by-dashboard", MediumLimiter, protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;
    const ownerEmail = req.user.email; // logged-in user

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    // Check pending exit requests for this dashboard & owner
    const requests = await ExitRequest.find({
      dashboardId,
      toUserId: ownerEmail,
      status: "pending",
    }).limit(1); // we only need to know IF EXISTS

    res.status(200).json({
      hasExitRequests: requests.length > 0,
    });
  } catch (err) {
    console.error("Fetch exit requests error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// routes/collab.js
router.get("/exit-requests-by-dashboard-data", MediumLimiter, protect, async (req, res) => {
  try {
    const { dashboardId } = req.query;
    const ownerEmail = req.user.email;

    if (!dashboardId) {
      return res.status(400).json({ message: "dashboardId is required" });
    }

    const requests = await ExitRequest.find({
      dashboardId,
      toUserId: ownerEmail,
      status: "pending",
    }).sort({ createdAt: -1 });

    res.status(200).json({
      exitRequests: requests, // ✅ send full list
    });
  } catch (err) {
    console.error("Fetch exit requests error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/approve-exit-request", MediumLimiter, protect, async (req, res) => {
  try {
    const { requestId } = req.body;

    if (!requestId) {
      return res.status(400).json({ message: "requestId is required" });
    }

    // 1️⃣ Find exit request
    const exitRequest = await ExitRequest.findById(requestId);

    if (!exitRequest) {
      return res.status(404).json({ message: "Exit request not found" });
    }

    if (exitRequest.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Exit request already processed" });
    }

    const { dashboardId, fromUserId } = exitRequest;

    // Fetch dashboard name
const dashboard = await Dashboard.findById(
  exitRequest.dashboardId,
  { name: 1 }
);

const dashboardName = dashboard?.name || "the group";


    // 2️⃣ Approve exit request
    exitRequest.status = "approved";
    await exitRequest.save();

    // 3️⃣ Remove from DashboardMember
    await DashboardMember.deleteMany({
      dashboardId,
      userId: fromUserId,
    });

    // 4️⃣ Remove ledger assignments
    await LedgerAssignment.deleteMany({
      dashboardId,
      memberId: fromUserId,
    });

    // 5️⃣ Remove assigned member record
    await AssignedMembers.deleteMany({
      dashboardId,
      memberId: fromUserId,
    });

    await Notification.create({
  userId: fromUserId,
  type: "Update",
  title: "Exit Request Approved",
  body: `Your request to exit "${dashboardName}" has been approved.`,
  relatedId: exitRequest._id,
});


    const html = `
  <p><b>Exit Request Approved</b></p>
  <p>Your request to exit <b>${dashboardName}</b> has been approved.</p>
  <p>You are no longer a member of this group.</p>
`;


    await sendEmail(
      fromUserId,
      "FlowBank Exit Group Request Approval",
      html
    );

    res.status(200).json({
      message: "Exit request approved and member removed successfully",
    });
  } catch (error) {
    console.error("Approve exit request error:", error);
    res.status(500).json({ message: "Server error" });
  }
});





module.exports = router;
