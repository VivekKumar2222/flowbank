import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../collaboration/bill_splitting.dart';
import '../collaboration/ledger_tracking.dart';
/// ─────────────────────────────────────────
/// REQUEST DATA MODEL
/// ─────────────────────────────────────────
class GroupData {
  final String dashboardId;
  final String? invitationId;
  final String groupName;
  final String groupType;
  final List<String> members;
  final String ownerName;
  final DateTime createdDate;

  GroupData({
    required this.dashboardId,
    this.invitationId,
    required this.groupName,
    required this.groupType,
    required this.members,
    required this.ownerName,
    required this.createdDate,
  });

    GroupData copyWith({
    String? dashboardId,
    String? invitationId,
    String? groupName,
    String? groupType,
    String? ownerName,
    DateTime? createdDate,
    List<String>? members,
  }) {
    return GroupData(
      dashboardId: dashboardId ?? this.dashboardId,
      invitationId: invitationId ?? this.invitationId,
      groupName: groupName ?? this.groupName,
      groupType: groupType ?? this.groupType,
      ownerName: ownerName ?? this.ownerName,
      createdDate: createdDate ?? this.createdDate,
      members: members ?? this.members,
    );
  }
}

/// ─────────────────────────────────────────
/// REQUESTS LIST (SAFE INSIDE ANY LAYOUT)
/// ─────────────────────────────────────────
class GroupsRow extends StatelessWidget {
  final List<GroupData> groups;

  const GroupsRow({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true, // ✅ prevents unbounded height
      physics: const NeverScrollableScrollPhysics(), // ✅ safe inside scroll
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Group(
          dashboardID: group.dashboardId,
          groupName: group.groupName,
          groupType: group.groupType,
          members: group.members,
          ownerName: group.ownerName,
          createdDate: group.createdDate,
        );
      },
    );
  }
}

/// ─────────────────────────────────────────
/// SINGLE GROUP CARD
/// ─────────────────────────────────────────
class Group extends StatelessWidget {
  final String dashboardID;
  final String groupName;
  final String groupType;
  final List<String> members;
  final String ownerName;
  final DateTime createdDate;

  const Group({
    super.key,
    required this.dashboardID,
    required this.groupName,
    required this.groupType,
    required this.members,
    required this.ownerName,
    required this.createdDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
  borderRadius: BorderRadius.circular(20),
onTap: () {
  if (groupType == "Bill Splitting") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillSplitting(
          dashboardId: dashboardID,
        ),
      ),
    );
  } else if (groupType == "Ledger Tracking") {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LedgerTracking(
          dashboardId: dashboardID,
        ),
      ),
    );
  }
},

    
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD7E8FF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ───────── TOP ROW ─────────
          Row(
            children: [
              _AvatarsRow(members: members),
              const Spacer(),
              Row(
                children: [
                  // const _RejectButton(),
                  // const SizedBox(width: 5),
                  // const _JoinButton(),
                  // const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: Color(0xFF2C82FF),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ───────── TITLE + TAG ─────────
Row(
  children: [
    Flexible(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const maxFontSize = 20.0;
          const minFontSize = 14.0;

          double fontSize = maxFontSize;

          final textPainter = TextPainter(
            text: TextSpan(
              text: groupName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: maxFontSize,
              ),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout(maxWidth: constraints.maxWidth);

          if (textPainter.didExceedMaxLines) {
            fontSize = minFontSize;
          }

          return Text(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C82FF),
            ),
          );
        },
      ),
    ),
    const SizedBox(width: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E9FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        groupType,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C82FF),
        ),
      ),
    ),
  ],
),


          const SizedBox(height: 4),

          Text(
            "Created ${_formatDate(createdDate)}. Owner: $ownerName",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2C82FF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    );
  }

  static String _formatDate(DateTime date) {
    return "${_months[date.month - 1]} ${date.day}, ${date.year}";
  }
}

/// ─────────────────────────────────────────
/// AVATARS ROW
/// ─────────────────────────────────────────
class _AvatarsRow extends StatelessWidget {
  final List<String> members;

  const _AvatarsRow({required this.members});

  static const int maxVisible = 4;
  static const double radius = 13;
  static const double overlap = 20;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(maxVisible).toList();
    final extraCount = members.length - visibleMembers.length;

    final diameter = radius * 2;
    final width = diameter + (visibleMembers.length - 1) * overlap;

    return Row(
      children: [
        SizedBox(
          width: width,
          height: diameter,
          child: Stack(
            children: List.generate(visibleMembers.length, (index) {
              return Positioned(
                left: index * overlap,
                child: CircleAvatar(
                  radius: radius,
                  backgroundColor: _colors[index % _colors.length],
                  child: Text(
                    _getInitials(visibleMembers[index]),
                    style: TextStyle(
                      fontSize: radius * 0.75,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C82FF),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (extraCount > 0) ...[
          const SizedBox(width: 6),
          Text(
            "+$extraCount",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C82FF),
            ),
          ),
        ],
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

/// ─────────────────────────────────────────
/// BUTTONS
/// ─────────────────────────────────────────
class _RejectButton extends StatelessWidget {
  const _RejectButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2F73FF), width: 1.5),
      ),
      child: const Text(
        "Reject",
        style: TextStyle(
          color: Color(0xFF2F73FF),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2ECC71), width: 1.5),
      ),
      child: const Text(
        "Join",
        style: TextStyle(
          color: Color(0xFF2ECC71),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// HELPERS
/// ─────────────────────────────────────────
const _colors = [
  Color(0xFFD6E4FF),
  Color(0xFFEBD7FF),
  Color(0xFFFFD6E7),
  Color(0xFFDFF7E3),
];

const _months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];
