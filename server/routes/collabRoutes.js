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

// ─── Get Bill Split Total ─────────────────
router.get("/bill-split-total", async (req, res) => {
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

router.post("/users-by-emails", async (req, res) => {
  const { emails } = req.body;
  const users = await User.find({ email: { $in: emails } }, { email: 1, name: 1 });
  res.json(users);
});

router.post("/dashboard-entry", async (req, res) => {
  try {
    const {
      dashboardId,
      userId,
      amount,
      verificationImage,
      assignmentId,
    } = req.body;

    if (!dashboardId || !userId || !amount) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const entry = new DashboardEntry({
      dashboardId,
      userId,
      amount,
      verificationImage, // 🔐 encrypted string
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

router.get('/dashboard/:id', async (req, res) => {
  try {
    const dashboard = await Dashboard.findById(req.params.id);
    if (!dashboard) return res.status(404).json({ message: 'Dashboard not found' });
    res.json(dashboard);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/dashboard-entries", async (req, res) => {
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

router.post("/ledger-assignment", async (req, res) => {
  try {
    const { dashboardId, memberId } = req.body;

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

    res.status(201).json({
      message: "Assignment created and member updated successfully",
      assignment,
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// ─── GET Unassigned Dashboard Members ─────────────────
router.get("/unassigned-members", async (req, res) => {
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
router.get("/ledger-summary", async (req, res) => {
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
router.get("/assigned-members-summary", async (req, res) => {
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
router.get("/member-ledger", async (req, res) => {
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



router.get("/dashboard-entry-image/:entryId", async (req, res) => {
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


router.get("/dashboard-entry/:entryId", async (req, res) => {
  try {
    const entry = await DashboardEntry.findById(req.params.entryId);

    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    res.status(200).json(entry);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

router.post("/verify-entry-ocr", async (req, res) => {
  try {
    const { entryId } = req.body;

    if (!entryId) {
      return res.status(400).json({ message: "entryId is required" });
    }

    const entry = await DashboardEntry.findById(entryId);
    if (!entry) {
      return res.status(404).json({ message: "Entry not found" });
    }

    const senderUser = await User.findOne({ email: entry.userId }, { name: 1 });
    const senderName = senderUser?.name || entry.userId;

    const dashboard = await Dashboard.findById(entry.dashboardId);
    if (!dashboard) {
      return res.status(404).json({ message: "Dashboard not found" });
    }

    const receiverUser = await User.findOne({ email: dashboard.ownerId }, { name: 1 });
    const receiverName = receiverUser?.name || dashboard.ownerId;

    const amountNumber = Number(entry.amount || 0);
    const imageUrl = entry.verificationImage;
    const dateStr = entry.createdAt ? entry.createdAt.toISOString().split("T")[0] : null;

    // ❌ Validate before OCR
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
      return res.status(500).json({
        message: "OCR server failed",
        error: ocrError.message,
      });
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
router.post("/update-entry-status", async (req, res) => {
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



module.exports = router;
