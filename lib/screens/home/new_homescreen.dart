import 'dart:ui';
import 'package:flutter/material.dart';
import '../home/profile.dart';
import '../home/section_header.dart';
import '../onboarding/OnboardingScreen.dart';
import '../home/status_card.dart';
import '../home/status_card_box.dart';
import '../home/user-total-balance-view.dart';
import '../home/bank_transactions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../collaboration/collaboration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
    @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
    });
  }
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
                              children: [
                                Text(
                                  "Welcome,",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w700,
                                    height: -0.5,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  userName ?? 'User',
                                  style: TextStyle(
                                    color: Color(0xFF0179FE),
                                    fontSize: 28,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                      title: "Top Picks",
                      showButton: true,
                      destination: OnboardingScreen(),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Column(
                          children: [
                            InfoCard(
                              title: 'Subscription',
                              currentValue: 600,
                              maxValue: 1400,
                              themeColor: "red",
                            ),
                            SizedBox(height: 8),
                            InfoCard(
                              title: 'Food',
                              currentValue: 756,
                              maxValue: 1200,
                              themeColor: "purple",
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InfoCard_Box(
                            title: "Home Bills",
                            currentValue: 200,
                            maxValue: 1500,
                            themeColor: "blue",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // -------- USER TOTAL CARDS --------
              UserTotal(
                accounts: [
                  BankAccount(
                    bankName: "JS Mastery Pro",
                    cardHolder: "Adrian Hajdin",
                    amount: 1000.12,
                    dateConnected: "06/24",
                    gradientColors: [Color(0xFFB28DFF), Color(0xFFF3B0FF)],
                  ),
                  BankAccount(
                    bankName: "Sky Bank",
                    cardHolder: "John Doe",
                    amount: 1600.00,
                    dateConnected: "07/23",
                    gradientColors: [Color(0xFF2193FF), Color(0xFF6DD5ED)],
                  ),
                ],
              ),

              // -------- TRANSACTIONS --------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 26),

                    SectionHeader(
                      title: "Recent Transactions",
                      showButton: true,
                      destination: OnboardingScreen(),
                    ),

                    const SizedBox(height: 16),

                    BankTransactionsWidget(
                      banks: [
                        Bank(
                          name: 'Chase Bank',
                          logoText: 'CB',
                          transactions: [
                            TransactionItem(
                              title: 'Chris David',
                              subtitle: 'Request Received',
                              amount: 35.0,
                              isPositive: true,
                              date: "12 Jan",
                              isCategorized: true,
                            ),
                            TransactionItem(
                              title: 'James Richardson',
                              subtitle: 'Payment Sent',
                              amount: 104.0,
                              date: "12 Jan",
                              isPositive: false,
                              isCategorized: false,
                              onCategorize: () {
                                print("Categorize clicked");
                              },
                            ),
                          ],
                        ),
                        Bank(
                          name: 'Bank of America',
                          logoText: 'BA',
                          transactions: [
                            TransactionItem(
                              title: 'Dale Harry',
                              subtitle: 'Payment Sent',
                              amount: 85.0,
                              date: "12 Jan",
                              isCategorized: false,
                              isPositive: false,
                            ),
                            TransactionItem(
                              title: 'Dale Harry',
                              subtitle: 'Request Received',
                              amount: 15.0,
                              isCategorized: true,
                              date: "12 Jan",
                              isPositive: true,
                            ),
                          ],
                        ),
                        Bank(
                          name: 'National Bank',
                          logoText: 'BA',
                          transactions: [
                            TransactionItem(
                              title: 'Dale Harry',
                              subtitle: 'Payment Sent',
                              amount: 85.0,
                              date: "12 Jan",
                              isCategorized: false,
                              isPositive: false,
                            ),
                            TransactionItem(
                              title: 'Dale Harry',
                              subtitle: 'Request Received',
                              amount: 15.0,
                              isCategorized: true,
                              date: "12 Jan",
                              isPositive: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // -------- SPACE FOR BOTTOM NAV --------
              const SizedBox(height: 120),
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
                    if (index == 1) {
                      // Navigate to Groups page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CollaborationScreen(),
                        ),
                      );
                    } else {
                      setState(() {
                        _selectedIndex = index;
                      });
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
