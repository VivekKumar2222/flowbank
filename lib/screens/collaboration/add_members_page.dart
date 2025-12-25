import 'package:flutter/material.dart';
import '../collaboration/members-search-list.dart';

class AddMembersPage extends StatefulWidget {
  final String dashboardId;
  const AddMembersPage({
    Key? key,
    required this.dashboardId,
  }) : super(key: key);

  @override
  State<AddMembersPage> createState() => _AddMembersPageState();
}

class _AddMembersPageState extends State<AddMembersPage> {
  String searchQuery = ""; // Live search input
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 650;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                const SizedBox(height: 9),

                /// IMAGE
                Image.asset(
                  'assets/members-image.png',
                  height: isSmallScreen ? 140 : null,
                ),

                const SizedBox(height: 9),

                /// TITLE
                Text(
                  "Add Members",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF101828),
                    fontFamily: "Manrope",
                    fontSize: isSmallScreen ? 22 : 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                /// DESCRIPTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    "You've created a new Group! Invite colleagues to collaborate in this group",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF565758),
                      fontFamily: "Manrope",
                      fontSize: isSmallScreen ? 13 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 46),

                /// SEARCH + LIST + BUTTON SECTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      /// SEARCH BAR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD7E8FF),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Color(0xFF8FC7FF),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value; // update live
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: "Search Members",
                                  hintStyle: TextStyle(
                                    color: Color(0xFF8FC7FF),
                                    fontSize: 17,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// MEMBERS LIST (Live Search)
                      MembersSearchList(
                        searchName: searchQuery,
                        dashboardID: widget.dashboardId,
                      ),

                      const SizedBox(height: 24),

                      /// CONFIRM BUTTON
                      Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF217BFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// FOOTER TEXT
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                          "Find your members and share a single dashboard to optimize financing",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475467),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
