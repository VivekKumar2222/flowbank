import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../home/profile.dart';
import '../home/section_header.dart';
import '../onboarding/OnboardingScreen.dart';
import '../home/status_card.dart';
import '../home/status_card_box.dart';
import '../home/user-total-balance-view.dart';
import '../home/bank_transactions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../collaboration/collaboration_screen.dart';
import '../notification/notification-page.dart';
import 'financial_health_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flowbank/api/api_service.dart';
import '../home/home_skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? userInitials;
  String? email;
  double? totalBalance;
  List<BankAccount> plaidAccounts = [];
  List<Map<String, dynamic>> recentTransactions = [];
  bool isLoadingData = true;
  
    @override
  void initState() {
    super.initState();
    _loadUserData();
    //_loadUserEmail();
    //_fetchTotalBalance();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      userInitials = prefs.getString('userInitials') ?? 'U';
      email = prefs.getString('userEmail') ?? '';
      
    });
    if (email != null && email!.isNotEmpty) {
    _fetchTotalBalance();  // ✅ Now email is guaranteed
  }
  }

  // Future<void> _loadUserEmail() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     email = prefs.getString('userEmail') ?? '';
  //   });
  //   if (email != null && email!.isNotEmpty) {
  //   await _fetchTotalBalance();  // ✅ Now email is guaranteed
  // }
  // }

  // Add this inside _HomeScreenState


// Predefined gradient pairs for cards
final List<List<Color>> _cardGradients = [
  [Color(0xFFB28DFF), Color(0xFFF3B0FF)],
  [Color(0xFF2193FF), Color(0xFF6DD5ED)],
  [Color(0xFF11998e), Color(0xFF38ef7d)],
  [Color(0xFFf7971e), Color(0xFFffd200)],
  [Color(0xFFc94b4b), Color(0xFF4b134f)],
];

Future<void> _fetchTotalBalance() async {
  final stopwatch = Stopwatch()..start();
  try {
    final response = await ApiService.get("/api/bank/all-data/$email", context);

    print("⏱ API call took: ${stopwatch.elapsedMilliseconds} ms");

    if (response.statusCode == 200) {
      final parseWatch = Stopwatch()..start();
      final data = jsonDecode(response.body);

      print("⏱ JSON decode took: ${parseWatch.elapsedMilliseconds} ms");

      // Parse accounts
      final List accountsRaw = data['accounts'] ?? [];
final List<BankAccount> parsedAccounts = [];

for (int i = 0; i < accountsRaw.length; i++) {
  final acc = accountsRaw[i];

  String dateConnected = '';
  try {
    final dt = DateTime.parse(acc['dateConnected']);
    dateConnected =
        '${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
  } catch (_) {
    dateConnected = '';
  }

  // Parse sub-accounts
  final List subRaw = acc['subAccounts'] ?? [];
  final List<Map<String, dynamic>> subAccounts = subRaw
      .map((s) => Map<String, dynamic>.from(s))
      .toList();

  parsedAccounts.add(BankAccount(
    bankName: acc['institutionName'] ?? 'Bank',
    amount: (acc['totalBalance'] as num?)?.toDouble() ?? 0.0,
    dateConnected: dateConnected,
    gradientColors: _cardGradients[i % _cardGradients.length],
    subAccounts: subAccounts,
  ));
}
      // Parse recent transactions (last 5 from historical)
      final List historicalRaw = data['historical'] ?? [];
      final List<Map<String, dynamic>> parsedTransactions = historicalRaw
          .take(5)
          .map((t) => Map<String, dynamic>.from(t))
          .toList();

      setState(() {
        totalBalance = (data['totalBalance'] as num?)?.toDouble() ?? 0.0;
        plaidAccounts = parsedAccounts;
        recentTransactions = parsedTransactions;
        isLoadingData = false;
        print('✅ Total Balance: $totalBalance');
        print('✅ Accounts: ${plaidAccounts.length}');
        print('✅ Transactions: ${recentTransactions.length}');
      });
    } else {
      print('Failed to fetch data: ${response.body}');
      setState(() => isLoadingData = false);
    }
  } catch (e) {
    print('Error fetching data: $e');
    setState(() => isLoadingData = false);
  }
}
  int _selectedIndex = 0;

  final Color activeColor = const Color(0xFF217BFF);
  final Color inactiveColor = const Color(0xFF667085);

  Route _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => page,
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
    );
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
                                child:  Container(
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
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
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
              // -------- USER TOTAL CARDS --------
isLoadingData
    ? const HomeSkeletonLoader()
    : plaidAccounts.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Text(
              "No bank accounts connected.",
              style: TextStyle(color: Color(0xFF667085), fontSize: 14),
            ),
          )
        : UserTotal(accounts: plaidAccounts),

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

              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  children: [
                    SectionHeader(
                        title: "AI Analysis",
                        showButton: false,
                        destination: OnboardingScreen(),
                      ),
                      const SizedBox(height: 12),
                      AIFinancialHeroCard(
  onTap: () {
    Navigator.push(
      context,
      _premiumRoute(const FinancialHealthScreen()),
    );
  },
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
                    } 
                    else if (index == 2) {
    // Navigate to Notifications page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),);} 
      else {
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
                      icon: Icon(Icons.notification_add),
                      label: "Notifications",
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


class AIFinancialHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const AIFinancialHeroCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // 🔵 BACKGROUND (Replace this with your SVG)
              Positioned.fill(
  child: Image.asset(
    "assets/financial-prediction-background.png",
    fit: BoxFit.cover,
  ),
),



              // Optional curve overlay (subtle design detail)
              // Positioned(
              //   right: -40,
              //   top: -40,
              //   child: Container(
              //     width: 200,
              //     height: 200,
              //     decoration: BoxDecoration(
              //       border: Border.all(
              //         color: Colors.white.withOpacity(0.3),
              //         width: 1,
              //       ),
              //       shape: BoxShape.circle,
              //     ),
              //   ),
              // ),

              // CONTENT
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 41,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),

                    const Spacer(),

                    // 🧠 Title
                    Text(
                      "Financial\nPrediction System\nPowered by AI",
                      style: TextStyle(
                        fontSize: width < 360 ? 28 : 29,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.12,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 📄 Description
                    Text(
                      "An AI-powered system that provides near-accurate predictions of your financial stability and future outlook",
                      style: TextStyle(
                        fontSize: width < 360 ? 11 : 12.5,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // 🔘 Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Try It",
                        style: TextStyle(
                          color: Color(0xFF217BFF),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}