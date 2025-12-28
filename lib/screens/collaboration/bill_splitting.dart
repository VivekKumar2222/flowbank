import 'dart:ui';
import 'package:flutter/material.dart';
import '../collaboration/create_group.dart';
import '../home/section_header.dart';
import '../onboarding/OnboardingScreen.dart';
import '../collaboration/members-view-row.dart';
import '../collaboration/members-entries-billsplitting.dart';

/// --------------------
/// Collaboration Screen
/// --------------------
class BillSplitting extends StatefulWidget {
  const BillSplitting({super.key});

  @override
  State<BillSplitting> createState() => _BillSplittingState();
}

class _BillSplittingState extends State<BillSplitting> {
  int _selectedIndex = 0;

  final List<EntryItem> demoEntries = [
  EntryItem(
    title: "John Doe",
    subtitle: "Verified",
    date: "12 Dec 2025",
    amount: 30,
    totalAmount: 50,
  ),
  EntryItem(
    title: "Amazon",
    subtitle: "Pending",
    date: "10 Dec 2025",
    amount: 50,
    totalAmount: 50,
  ),
  EntryItem(
    title: "Alice",
    subtitle: "Not Verified",
    date: "09 Dec 2025",
    amount: 0,
    totalAmount: 100,
  ),
  EntryItem(
    title: "Bob",
    subtitle: "Verified",
    date: "08 Dec 2025",
    amount: 120,
    totalAmount: 100,
  ),
];


  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bill Splitting",
                              style: TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Manrope",
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "CollaBorations",
                              style: TextStyle(
                                color: Color(0xFF0179FE),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

                Container(
                  width: double.infinity,
                  height: 187,
                  decoration: BoxDecoration(
                    color: Color(0xFF4893FF),
                    borderRadius: BorderRadius.circular(27),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Total Amount to Split",
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontFamily: "Manrope",
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "\$" "3549.62",
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontFamily: "Manrope",
                          fontSize: 37,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "Split between 8 group members",
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontFamily: "Manrope",
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 27),

                /// Requests
                SectionHeader(
                  title: "Group Members",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

                MembersViewRow(
                  members: [
                    {
                      "name": "Chris David",
                      "paidAmount": 35.0,
                      "totalAmount": 750.0,
                    },
                    {
                      "name": "Alex John",
                      "paidAmount": 751.0,
                      "totalAmount": 750.0,
                    },
                  ],
                ),

                SizedBox(height: 24),

                /// Requests
                SectionHeader(
                  title: "All Entries",
                  showButton: true,
                  destination: OnboardingScreen(),
                ),
                const SizedBox(height: 16),

                EntriesEntryList(
          entries: demoEntries,)
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
    );
  }
}
