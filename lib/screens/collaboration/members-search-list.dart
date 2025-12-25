import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// --------------------
/// MEMBER MODEL
/// --------------------
class Member {
  final String name;
  final String email;
  final String id; // added to send as toUser

  Member({
    required this.name,
    required this.email,
    required this.id,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      name: json['name'],
      email: json['email'],
      id: json['_id'] ?? "", // assuming backend sends _id for the user
    );
  }
}

/// --------------------
/// MEMBERS SEARCH LIST
/// --------------------
class MembersSearchList extends StatefulWidget {
  final String searchName;
  final String dashboardID;

  const MembersSearchList({
    super.key,
    required this.searchName,
    required this.dashboardID,
  });

  @override
  State<MembersSearchList> createState() => _MembersSearchListState();
}

class _MembersSearchListState extends State<MembersSearchList> {
  static const String baseUrl = "http://10.0.2.2:5000";

  String? userEmail; // Logged-in user email
  String? fromUserId; // fromUser ID from backend
  Map<String, bool> invitedUsers = {}; // Track sent invitations by member.id

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'user';
    });

    // You may need to fetch the fromUserId from backend using userEmail
    // For now, assume userEmail is sufficient to send in API
    fromUserId = userEmail;
  }

  Future<List<Member>> fetchMembers() async {
    if (widget.searchName.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      "$baseUrl/api/search/search?name=${widget.searchName}",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Member.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch members");
    }
  }

  Future<void> sendInvitation(Member member) async {
    if (fromUserId == null) return;

    final uri = Uri.parse("$baseUrl/api/collab/invite");

    final body = {
      "dashboardId": widget.dashboardID,
      "fromUser": fromUserId,
      "toUser": member.email,
      "status": "pending",
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      // success
      setState(() {
        invitedUsers[member.id] = true;
      });
    } else {
      // handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send invitation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 312,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7E8FF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Suggestions",
            style: TextStyle(
              color: Color(0xFF565758),
              fontFamily: "Manrope",
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Member>>(
              future: fetchMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Something went wrong",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      "No members found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MemberTile(
                        member: members[index],
                        onAdd: () => sendInvitation(members[index]),
                        isInvited: invitedUsers[members[index].id] ?? false,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// MEMBER TILE
/// --------------------
class MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onAdd;
  final bool isInvited;

  const MemberTile({
    super.key,
    required this.member,
    required this.onAdd,
    required this.isInvited,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInvited ? null : onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isInvited ? const Color(0xFFB1E0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD7E8FF),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            /// AVATAR
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD1E9FF),
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitials(member.name),
                style: const TextStyle(
                  fontFamily: "Manrope",
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF217BFF),
                ),
              ),
            ),
            const SizedBox(width: 20),

            /// NAME + EMAIL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Manrope",
                      color: Color(0xFF217BFF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4490FF),
                    ),
                  ),
                ],
              ),
            ),

            /// ADD BUTTON
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                isInvited ? "Sent" : "+ Add",
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isInvited ? Colors.white : const Color(0xFF217BFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r"\s+"))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return "";
  }
}
