import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../collaboration/groups_outlook.dart';
import '../collaboration/request-widgets.dart';
import '../collaboration/create_group.dart';

import '../home/section_header.dart';
import '../home/status_card.dart';
import '../home/status_card_box.dart';
import '../home/user-total-balance-view.dart';
import '../home/bank_transactions.dart';

import '../onboarding/OnboardingScreen.dart';

import '..//home/new_homescreen.dart';

/// --------------------
/// Get Saved Balance
/// --------------------
Future<double> getSavedTotalBalance() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('totalBalance') ?? 0.0;
}

/// --------------------
/// Collaboration Screen
/// --------------------
class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  final int _selectedIndex = 1;

    void _onBottomNavTap(int index) {
    if (index == 0) {
      // ✅ HOME
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      // Already on Collaboration
      return;
    }
  }

  String? userEmail;
  String? userName;

  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

  List<GroupData> userGroups = [];
  List<GroupData> invitedUserGroups = [];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _loadUserName();
  }

  /// --------------------
  /// Load User Email
  /// --------------------
  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'user';
    });

    

    if (userEmail != null) {
      await _fetchUserGroups(userEmail!);
      await _fetchInvitedGroups(userEmail!);
    }
  }

    Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('userName') ?? 'user';
    });

    

  }

  /// --------------------
  /// Fetch User Groups
  /// --------------------
  ///

Future<void> _fetchInvitedGroups(String email) async {
  try {
    final response = await http.get(
      Uri.parse(
        'http://10.0.2.2:5000/api/collab/invited-dashboards?userId=$email',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load invited dashboards");
    }

    final List<dynamic> data = jsonDecode(response.body);

    List<GroupData> invitedGroups = data.map((dash) {
      return GroupData(
        dashboardId: dash['_id'],
        invitationId: dash['invitationId'],
        groupName: dash['name'],
        groupType: dash['type'],
        ownerName: dash['ownerName'], // email or map later
        createdDate: DateTime.parse(dash['createdAt']),
        members: List<String>.from(dash['members']), // ✅ REAL MEMBERS
      );
    }).toList();

    setState(() {
      invitedUserGroups = invitedGroups;
      debugPrint("Invited groups count: ${invitedGroups.length}");

    });
  } catch (e) {
    debugPrint("Error fetching invited groups: $e");
  }

  
}


  Future<void> _fetchUserGroups(String email) async {
  try {
    // 1️⃣ dashboards user belongs to
    final membersResponse = await http.get(
      Uri.parse(
        'http://10.0.2.2:5000/api/collab/dashboard-members?userId=$email',
      ),
    );

    final List<dynamic> membersData = jsonDecode(membersResponse.body);
    final dashboardIds =
        membersData.map((m) => m['dashboardId'].toString()).toList();

    if (dashboardIds.isEmpty) return;

    // 2️⃣ fetch dashboards
    final dashboardsResponse = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/collab/dashboards-by-ids'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ids': dashboardIds}),
    );

    final List<dynamic> dashboardsData =
        jsonDecode(dashboardsResponse.body);

    // 3️⃣ fetch members for EACH dashboard
    List<GroupData> groups = [];

    for (final dash in dashboardsData) {
      final membersRes = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/collab/dashboard-members-by-dashboard?dashboardId=${dash['_id']}',
        ),
      );

      final membersList = (jsonDecode(membersRes.body) as List)
          .map((m) => m['userId'].toString())
          .toList();

      groups.add(
        GroupData(
          dashboardId: dash['_id'],
          invitationId: dash['invitationId'],
          groupName: dash['name'],
          groupType: dash['type'],
          ownerName: dash['ownerName'],
          createdDate: DateTime.parse(dash['createdAt']),
          members: membersList, // ✅ ALL MEMBERS
        ),
      );
    }

    setState(() {
      userGroups = groups;
    });
  } catch (e) {
    debugPrint("Error: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,

        /// --------------------
        /// Floating Button
        /// --------------------
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 80 + bottomInset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF217BFF).withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF217BFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

        /// --------------------
        /// App Bar
        /// --------------------
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            flexibleSpace: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 26, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "CollaBorations",
                          style: TextStyle(
                            color: Color(0xFF0179FE),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/150?img=3",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// --------------------
        /// Body
        /// --------------------
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                /// Requests
                SectionHeader(
                  title: "All Requests",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

        invitedUserGroups.isEmpty
            ? Container(
        width: double.infinity,
        height: 118,
        decoration: BoxDecoration(
          color: const Color(0xFFD6D6D6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB0B0B0),
            width: 1.2,
          ),
        ),
        child: const Center(
          child: Text(
            "No Request",
            style: TextStyle(
              color: Color(0xFF5E5E5E),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      )
            : RequestsRow(
                requests: invitedUserGroups.map((group) {
                  return RequestData(
                    dashboardID: group.dashboardId,
                    invitationID: group.invitationId,
                    groupName: group.groupName,
                    groupType: group.groupType,
                    ownerName: group.ownerName,
                    createdDate: group.createdDate,
                    members: group.members,
                  );
                }).toList(),
              ),

                const SizedBox(height: 12),

                /// Groups
                SectionHeader(
                  title: "All Groups",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

                userGroups.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Center(
                          child: Text(
                            "No groups yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    : GroupsRow(
                        groups: userGroups.map((group) {
                          final ownerName = group.ownerName == userName
                              ? "You"
                              : group.ownerName;

                          return GroupData(
                            dashboardId: group.dashboardId,
                            invitationId: group.invitationId,
                            groupName: group.groupName,
                            groupType: group.groupType,
                            members: group.members,
                            ownerName: ownerName,
                            createdDate: group.createdDate,
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),

        /// --------------------
        /// Bottom Navigation
        /// --------------------
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
                onTap: _onBottomNavTap,
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
                    icon: Icon(Icons.insert_chart_rounded),
                    label: "Report",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
