import 'dart:convert';
import 'dart:ui';
import 'package:flowbank/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../collaboration/groups_outlook.dart';
import '../collaboration/request-widgets.dart';
import '../collaboration/create_group.dart';

import '../home/section_header.dart';
import '../onboarding/OnboardingScreen.dart';

/// --------------------
/// Collaboration Screen
/// --------------------
class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  bool _pageLoading = true;

  final int _selectedIndex = 1;

  String? userEmail;
  String? userName;
  String? userInitials;

  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

  List<GroupData> userGroups = [];
  List<GroupData> invitedUserGroups = [];

  bool _loadingGroups = false;
  bool _loadingInvites = false;

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
    if (!mounted) return;

    final email = prefs.getString('userEmail') ?? 'user';

    setState(() {
      userEmail = email;
      _pageLoading = true;
    });

    await Future.wait([
    _fetchUserGroups(email),
    _fetchInvitedGroups(email),
  ]);

  if (!mounted) return;

  setState(() {
    _pageLoading = false;
  }); 
  
  }

  /// --------------------
  /// Load User Name
  /// --------------------
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      userName = prefs.getString('userName') ?? 'user';
      userInitials = prefs.getString('userInitials') ?? 'U';
    });
  }

  /// --------------------
  /// Fetch Invited Groups
  /// --------------------
  Future<void> _fetchInvitedGroups(String email) async {
    if (_loadingInvites) return;
    _loadingInvites = true;

    try {
      final response = await ApiService.get(
  "/api/collab/invited-dashboards?userId=$email",
  context
);


      if (response.statusCode != 200) {
        throw Exception("Failed to load invited dashboards");
      }

      final List<dynamic> data = jsonDecode(response.body);

      final invitedGroups = data.map((dash) {
        return GroupData(
          dashboardId: dash['_id'],
          invitationId: dash['invitationId'],
          groupName: dash['name'],
          groupType: dash['type'],
          ownerName: dash['ownerName'],
          createdDate: DateTime.parse(dash['createdAt']),
          members: List<String>.from(dash['members']),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        invitedUserGroups = invitedGroups;
      });
    } catch (e) {
      debugPrint("Error fetching invited groups: $e");
    } finally {
      _loadingInvites = false;
    }
  }

  /// --------------------
  /// Fetch User Groups
  /// --------------------
  Future<void> _fetchUserGroups(String email) async {
    if (_loadingGroups) return;
    _loadingGroups = true;

    try {
      final membersResponse = await ApiService.get(
  "/api/collab/dashboard-members?userId=$email",
  context
);


      final List<dynamic> membersData = jsonDecode(membersResponse.body);
      final dashboardIds =
          membersData.map((m) => m['dashboardId'].toString()).toList();

      if (dashboardIds.isEmpty) return;

      final dashboardsResponse = await ApiService.post(
  "/api/collab/dashboards-by-ids",
  {"ids": dashboardIds},
  context
);


      final List<dynamic> dashboardsData =
          jsonDecode(dashboardsResponse.body);

      final futures = dashboardsData.map((dash) async {
        final membersRes = await ApiService.get(
  "/api/collab/dashboard-members-by-dashboard?dashboardId=${dash['_id']}",
  context
);


        final membersList = (jsonDecode(membersRes.body) as List)
            .map((m) => m['userId'].toString())
            .toList();

        return GroupData(
          dashboardId: dash['_id'],
          invitationId: dash['invitationId'],
          groupName: dash['name'],
          groupType: dash['type'],
          ownerName: dash['ownerName'],
          createdDate: DateTime.parse(dash['createdAt']),
          members: membersList,
        );
      });

      final groups = await Future.wait(futures);
      if (!mounted) return;

      setState(() {
        userGroups = groups;
      });
    } catch (e) {
      debugPrint("Error fetching groups: $e");
    } finally {
      _loadingGroups = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _loadingScreen() {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF217BFF)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Loading content",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF217BFF),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    if (_pageLoading) {
    return _loadingScreen();
  }
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,

        /// Floating Button
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 80 + bottomInset),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF217BFF),
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

        /// App Bar
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
                padding: const EdgeInsets.only(
                      left: 18,
                      right: 26,
                      bottom: 16,
                    ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:  [
                        Text(
                          "CollaBorations",
                          style: TextStyle(
                            color: Color(0xFF0179FE),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5FAFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userInitials ?? 'U',
                                      style: TextStyle(
                                        color: Color(0xFF0179FE), 
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Body
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                SectionHeader(
                  title: "All Requests",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

                invitedUserGroups.isEmpty
                    ? _emptyBox("No Request")
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

                SectionHeader(
                  title: "All Groups",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

                userGroups.isEmpty
                    ? _emptyText("No groups yet")
                    : GroupsRow(
                        groups: userGroups.map((group) {
                          final owner =
                              group.ownerName == userName ? "You" : group.ownerName;
                          return group.copyWith(ownerName: owner);
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),

        /// Bottom Navigation
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: Colors.white.withOpacity(0.6),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: activeColor,
              unselectedItemColor: inactiveColor,
              onTap: (_) {},
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
                  icon: Icon(Icons.notification_add),
                  label: "Notifications",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFFD6D6D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB0B0B0), width: 1.2),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF5E5E5E),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
