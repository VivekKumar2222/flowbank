import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../collaboration/groups_outlook.dart';
import '../home/section_header.dart';
import '../onboarding/OnboardingScreen.dart';
import '../home/status_card.dart';
import '../home/status_card_box.dart';
import '../home/user-total-balance-view.dart';
import '../home/bank_transactions.dart';
import '../collaboration/request-widgets.dart';

Future<double> getSavedTotalBalance() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('totalBalance') ?? 0.0;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: 80 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF217BFF).withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 0.7,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                // TODO: open create group / request modal
              },
              backgroundColor: const Color(0xFF217BFF),
              elevation: 0, // IMPORTANT: disable default shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

        backgroundColor: Colors.white,
        extendBody: true,

        // ---------------------- APP BAR ----------------------
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0, // disable default shadow
            backgroundColor: const Color.fromARGB(
              0,
              255,
              255,
              255,
            ).withOpacity(0.0),
            surfaceTintColor: Colors.transparent, // IMPORTANT
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "space", //black space
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w700,
                                    height: -0.5,
                                    color: Color.fromARGB(0, 255, 255, 255),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "CollaBorations",
                                  style: TextStyle(
                                    color: Color(0xFF0179FE),
                                    fontSize: 28,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(
                                  "https://i.pravatar.cc/150?img=3",
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

        // ---------------------- BODY (SCROLLABLE) ----------------------
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // -------- TOP SECTION --------
              Padding(
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

                    RequestsRow(
                      requests: [
                        RequestData(
                          groupName: "Office Expenses",
                          groupType: "Shared Expenses",
                          ownerName: "Katty Phillips",
                          createdDate: DateTime(2025, 1, 17),
                          members: [
                            "Vivek Kumar",
                            "John Doe",
                            "Sarah Smith",
                            "Ali Khan",
                            "Zara Noor",
                            "Michael",
                          ],
                        ),
                        RequestData(
                          groupName: "Trip Budgeting and planning",
                          groupType: "Bill Split",
                          ownerName: "John Doe",
                          createdDate: DateTime(2025, 2, 2),
                          members: ["Vivek Kumar", "Sarah Smith"],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SectionHeader(
                      title: "All Groups",
                      showButton: true,
                      destination: OnboardingScreen(),
                    ),

                    const SizedBox(height: 16),

                    GroupsRow(
                      groups: [
                        GroupData(
                          groupName: "Office Expenses",
                          groupType: "Shared Expenses",
                          ownerName: "Katty Phillips",
                          createdDate: DateTime(2025, 1, 17),
                          members: [
                            "Vivek Kumar",
                            "John Doe",
                            "Sarah Smith",
                            "Ali Khan",
                            "Zara Noor",
                            "Michael",
                          ],
                        ),
                        GroupData(
                          groupName: "Trip Plan 2025",
                          groupType: "Bill Splitting",
                          ownerName: "John Doe",
                          createdDate: DateTime(2025, 2, 2),
                          members: ["Vivek Kumar", "Sarah Smith"],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ---------------------- BOTTOM NAV ----------------------
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 70 + bottomInset.clamp(0, 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedItemColor: activeColor,
                  unselectedItemColor: inactiveColor,
                  currentIndex: _selectedIndex,
                  showUnselectedLabels: true,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
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
                      icon: Icon(Icons.insert_chart_rounded),
                      label: "Report",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
