import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../collaboration/bill_splitting.dart';
import '../collaboration/ledger_tracking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../collaboration/ledger_Member_screen.dart';
import '../collaboration/shared_Expenses.dart';
import 'package:flowbank/api/api_service.dart';

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
/// REQUESTS LIST
/// ─────────────────────────────────────────
class GroupsRow extends StatelessWidget {
  final List<GroupData> groups;

  const GroupsRow({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
class Group extends StatefulWidget {
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
  State<Group> createState() => _GroupState();
}

class _GroupState extends State<Group> {
  String? userEmail;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _loadOwnerId();
    
  }

Future<void> _loadOwnerId() async {
  final response = await ApiService.get(
    "/api/collab/dashboard/${widget.dashboardID}"
  );

  print("🟥 FULL DASHBOARD RESPONSE: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // ✅ TRY NESTED STRUCTURE
    final fetchedOwnerId =
        data["ownerId"] ??
        data["dashboard"]?["ownerId"] ??
        data["data"]?["ownerId"] ??
        data["owner"] ??
        data["ownerEmail"];

    print("🟢 RESOLVED OWNER ID: $fetchedOwnerId");

    if (!mounted) return;
    setState(() {
      ownerId = fetchedOwnerId;
    });
  }
}



  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
      final email = prefs.getString('userEmail');

  print("🟢 USER EMAIL FROM PREFS: $email");
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        print("🔍 USER EMAIL: $userEmail");
print("🔍 OWNER ID: $ownerId");
print("🔍 EQUAL? ${userEmail == ownerId}");

        if (widget.groupType == "Bill Splitting") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BillSplitting(
                dashboardId: widget.dashboardID,
              ),
            ),
          );
        } else if (widget.groupType == "Ledger Tracking") {
          if (userEmail != null && userEmail == ownerId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LedgerTracking(
                  dashboardId: widget.dashboardID,
                ),
              ),
            );
          } else {
                       Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LedgerMemberScreen(
                  dashboardId: widget.dashboardID,
                  memberId: userEmail ?? '',
                ),
              ),
            );
          }
        }
        else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SharedExpenses(dashboardId: widget.dashboardID)
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
            Row(
              children: [
                _AvatarsRow(members: widget.members),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: Color(0xFF2C82FF),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                          text: widget.groupName,
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
                        widget.groupName,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E9FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    widget.groupType,
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
              "Created ${_formatDate(widget.createdDate)}. Owner: ${widget.ownerName}",
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
