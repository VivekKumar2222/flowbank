import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';

import '../notification/notification-outlook.dart';
import '../home/profile.dart';

// 👇 Add these (adjust paths if needed)
import '../home/new_homescreen.dart';
import '../collaboration/collaboration_screen.dart'; // <-- change to your actual file path
// If your collaborations screen file name differs, import the correct one.

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? userEmail;

  List notifications = [];
  bool _pageLoading = false;

  // 👇 current tab index for Notifications
  final int _selectedIndex = 2;

  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      userEmail = prefs.getString('userEmail');
      _pageLoading = true;
    });

    if (userEmail != null) {
      await fetchNotifications(userEmail!);
    }

    if (!mounted) return;

    setState(() {
      _pageLoading = false;
    });
  }

  Future<void> fetchNotifications(String userEmail) async {
    try {
      final response = await ApiService.get(
        "/api/notifications/$userEmail",
        context,
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
        });
      } else {
        // ignore: avoid_print
        print("Failed to fetch notifications: ${response.body}");
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching notifications: $e");
    }
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

  // ✅ Premium route transition (fade + subtle slide)
  void _premiumReplace(Widget target) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(curved);

          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
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

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: const Color.fromARGB(
              0,
              255,
              255,
              255,
            ).withOpacity(0.0),
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      right: 26,
                      bottom: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Notifications",
                              style: TextStyle(
                                color: Color(0xFF0179FE),
                                fontSize: 28,
                                fontFamily: "Manrope",
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(),
                                    ),
                                  );
                                },
                                child: const CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    "https://i.pravatar.cc/150?img=3",
                                  ),
                                ),
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
          ),
        ),

        body: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 12.0,
            // keep content above bottom bar
            bottom: 90 + bottomInset,
          ),
          child: notifications.isEmpty
              ? Center(
                  child: Text(
                    "You will see your notifications here",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return NotificationOutlook(
                      titleText: n['title'] ?? 'No Title',
                      badgeText: n['type'] ?? '',
                      bodyText: n['body'] ?? '',
                    );
                  },
                ),
        ),

        // ✅ Same premium bottom navigation bar
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
              onTap: (index) {
                if (index == _selectedIndex) return;

                switch (index) {
                  case 0:
                    _premiumReplace(const HomeScreen());
                    break;
                  case 1:
                    _premiumReplace(const CollaborationScreen());
                    break;
                  case 2:
                    // already here
                    break;
                }
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
}
