import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';

/// ─────────────────────────────────────────
/// REQUEST DATA MODEL
/// ─────────────────────────────────────────
class RequestData {
  final String dashboardID;
  final String? invitationID;
  final String groupName;
  final String groupType;
  final List<String> members;
  final String ownerName;
  final DateTime createdDate;

  RequestData({
    required this.dashboardID,
    this.invitationID,
    required this.groupName,
    required this.groupType,
    required this.members,
    required this.ownerName,
    required this.createdDate,
  });
}

/// ─────────────────────────────────────────
/// REQUESTS ROW (Scrollable cards with animation)
/// ─────────────────────────────────────────
class RequestsRow extends StatefulWidget {
  final List<RequestData> requests;

  const RequestsRow({super.key, required this.requests});

  @override
  State<RequestsRow> createState() => _RequestsRowState();
}

class _RequestsRowState extends State<RequestsRow> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<RequestData> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List.from(widget.requests);
  }

  @override
  void didUpdateWidget(covariant RequestsRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.requests.length != widget.requests.length) {
      _requests = List.from(widget.requests);
      setState(() {});
    }
  }

  void _removeRequest(int index) {
    final removedItem = _requests[index];
    _requests.removeAt(index);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        child: Request(
          request: removedItem,
          onActionCompleted: () {},
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: AnimatedList(
        key: _listKey,
        scrollDirection: Axis.horizontal,
        initialItemCount: _requests.length,
        itemBuilder: (context, index, animation) {
          return SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Request(
                request: _requests[index],
                onActionCompleted: () => _removeRequest(index),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// SINGLE REQUEST CARD
/// ─────────────────────────────────────────
class Request extends StatelessWidget {
  final RequestData request;
  final VoidCallback onActionCompleted;

  const Request({super.key, required this.request, required this.onActionCompleted});

  Future<String?> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail'); // store logged in user email
  }

  Future<void> _join(BuildContext context) async {
    final userEmail = await _getLoggedInUser();
    if (userEmail == null) return;
    if (request.invitationID == null) return;

    final response = await ApiService.post(
      "/api/collab/accept-invitation",
      {
        "invitationId": request.invitationID,
        "dashboardId": request.dashboardID,
        "userId": userEmail,
      },
      context
    );

    if (response.statusCode == 200) {
      onActionCompleted();
    }
  }

  Future<void> _reject(BuildContext context) async {

    if (request.invitationID == null) return;
    
    final response = await ApiService.post(
      "/api/collab/reject-invitation",
      {"invitationId": request.invitationID},
      context
    );

    if (response.statusCode == 200) {
      onActionCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IntrinsicWidth(
          child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AvatarsRow(members: request.members),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _reject(context),
                          child: const _RejectButton(),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => _join(context),
                          child: const _JoinButton(),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// ───────── TITLE + TAG ─────────
                Row(
                  children: [
                    Text(
                      request.groupName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C82FF),
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
                        request.groupType,
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
                  "Created ${_formatDate(request.createdDate)}. Owner: ${request.ownerName}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C82FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        border: Border.all(
          color: const Color(0xFF2F73FF),
          width: 1.5,
        ),
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
        border: Border.all(
          color: const Color(0xFF2ECC71),
          width: 1.5,
        ),
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
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
];
