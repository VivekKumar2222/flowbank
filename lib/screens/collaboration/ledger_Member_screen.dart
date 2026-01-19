import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import '../collaboration/add_Entries.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../collaboration/add_Entries.dart';
import 'package:flowbank/api/api_service.dart';

/* ============================================================
   MODELS
============================================================ */

class Member {
  final String name;
  final String initials;
  final String group;
  final double paid;
  final double total;

  Member({
    required this.name,
    required this.initials,
    required this.group,
    required this.paid,
    required this.total,
  });
}

class LedgerAssignment {
  final String id;
  final String title;
  final String description;
  final double totalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final double interestRate;
  final String? interestCycle;
  final double penaltyAmount;
  final String? penaltyType;
  final String? verificationSource;

  LedgerAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueDate,
    required this.interestRate,
    this.interestCycle,
    required this.penaltyAmount,
    this.penaltyType,
    this.verificationSource,
  });

  factory LedgerAssignment.fromJson(Map<String, dynamic> json) {
    return LedgerAssignment(
      id: json["_id"],
      title: json["title"],
      description: json["description"] ?? "",
      totalAmount: (json["totalAmount"] as num).toDouble(),
      paidAmount: (json["paidAmount"] as num).toDouble(),
      dueDate: DateTime.parse(json["dueDate"]),
      interestRate: (json["interestRate"] as num).toDouble(),
      interestCycle: json["interestCycle"],
      penaltyAmount: (json["penaltyAmount"] as num).toDouble(),
      penaltyType: json["penaltyType"],
      verificationSource: json["verificationSource"],
    );
  }
}

/* ============================================================
   IMAGE DECRYPTION
============================================================ */

Uint8List decryptImage(String encryptedBase64) {
  try {
    final key = encrypt.Key.fromUtf8(
      '0123456789abcdef0123456789abcdef',
    );
    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encryptedBytes = base64Decode(encryptedBase64);
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );

    return Uint8List.fromList(decrypted);
  } catch (_) {
    return Uint8List(0);
  }
}

/* ============================================================
   SCREEN
============================================================ */

class LedgerMemberScreen extends StatefulWidget {
  final String dashboardId;
  final String memberId;

  const LedgerMemberScreen({
    super.key,
    required this.dashboardId,
    required this.memberId,
  });

  @override
  State<LedgerMemberScreen> createState() => _LedgerMemberScreenState();
}

class _LedgerMemberScreenState extends State<LedgerMemberScreen> {
  int _selectedIndex = 0;

  final Color activeColor = const Color(0xFF2F80ED);
  final Color inactiveColor = const Color(0xFF9AA4B2);

  Member? member;
  List<LedgerAssignment> assignments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLedger();
  }

  Future<void> fetchLedger() async {
  

    final res = await ApiService.get(
  "/api/collab/member-ledger"
  "?dashboardId=${widget.dashboardId}&memberId=${widget.memberId}",
);


    final data = jsonDecode(res.body);

    setState(() {
      member = Member(
        name: data["member"]["name"],
        initials: data["member"]["name"]
            .split(" ")
            .map((e) => e[0])
            .take(2)
            .join(),
        group: "Member of Ledger Tracking Group",
        paid: (data["summary"]["paidAmount"] as num).toDouble(),
        total: (data["summary"]["totalAmount"] as num).toDouble(),
      );

      assignments = (data["assignments"] as List)
          .map((e) => LedgerAssignment.fromJson(e))
          .toList();

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (member == null) {
      return const Scaffold(
        body: Center(child: Text("No data found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
          child: Column(
            children: [
              _Header(member: member!),
              const SizedBox(height: 16),
              _Assignments(assignments: assignments,dashboardId: widget.dashboardId,),
              const SizedBox(height: 120),
            ],
          ),
        ),
      

      floatingActionButton: FloatingActionButton(
        backgroundColor: activeColor,
        onPressed: (){},
        child: const Icon(Icons.add, size: 28, color: Colors.white,),
      ),

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70 + bottomInset.clamp(0, 40),
            color: Colors.white.withOpacity(0.6),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: activeColor,
              unselectedItemColor: inactiveColor,
              onTap: (index) {
                setState(() => _selectedIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_rounded),
                  label: "Groups",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: "Wallet",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   HEADER
============================================================ */

class _Header extends StatelessWidget {
  final Member member;

  const _Header({required this.member});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
final double progress =
    member.total == 0 ? 0.0 : (member.paid / member.total).clamp(0.0, 1.0);


    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF4893FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              member.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.group,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Entry was made of",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text( // for GPT: here in the member.paid we will show every approved entry by the member for this particular dashboard
            "${member.paid.toInt()}/${member.total.toInt()}",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   ASSIGNMENTS
============================================================ */

class _Assignments extends StatelessWidget {
  final List<LedgerAssignment> assignments;
    final String dashboardId;

  const _Assignments({required this.assignments, required this.dashboardId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Assignments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...assignments.map(
  (a) => _AssignmentCard(
    assignment: a,
    dashboardId: dashboardId,
  ),
),

        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget { // for GPT: this will show the paid amount for each assignment. So from entry we will fetch all the approved entries for this particular assignment and show it here as total
  final LedgerAssignment assignment;
  final String dashboardId;

const _AssignmentCard({
  required this.assignment,
  required this.dashboardId,
});


  @override
  Widget build(BuildContext context) {
    return InkWell(
  borderRadius: BorderRadius.circular(20),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntriesPage(
          dashboardId: dashboardId,
          assignmentId: assignment.id,
        ),
      ),
    );
  },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD7E8FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F80ED),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4490FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Due: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}\n"
                        "${assignment.interestRate}% Interest\n"
                        "${assignment.penaltyAmount}% Penalty",
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4490FF),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            "\$${assignment.paidAmount.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F80ED),
                        ),
                      ),
                      TextSpan(
                        text: "/${assignment.totalAmount.toInt()}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181818),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (assignment.verificationSource != null &&
              assignment.verificationSource!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                decryptImage(assignment.verificationSource!),
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    ),
    );
  }
}
