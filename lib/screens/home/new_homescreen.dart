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
import '../notification/notification-page.dart';
import '../home/financial_health_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? userInitials;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      userInitials = prefs.getString('userInitials') ?? 'U';
    });
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
                                const Text(
                                  "Welcome,",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w700,
                                    height: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  userName ?? 'User',
                                  style: const TextStyle(
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
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5FAFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userInitials ?? 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF0179FE),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                            const SizedBox(height: 8),
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
                                // ignore: avoid_print
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

                    // -------- AI ANALYSIS (NEW) --------
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: "AI Analysis",
                      showButton: false,
                      destination: OnboardingScreen(),
                    ),
                    const SizedBox(height: 12),
                    AIGlowAnalysisCard(
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
                    } else if (index == 2) {
                      // Navigate to Notifications page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
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

class AIGlowAnalysisCard extends StatefulWidget {
  final VoidCallback onTap;
  const AIGlowAnalysisCard({super.key, required this.onTap});

  @override
  State<AIGlowAnalysisCard> createState() => _AIGlowAnalysisCardState();
}

class _AIGlowAnalysisCardState extends State<AIGlowAnalysisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF217BFF);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.22),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.22),
                  blurRadius: 22,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _GlowBorderPainter(progress: _c.value),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: blue.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              blue.withOpacity(0.90),
                              const Color(0xFF6DD5ED).withOpacity(0.90),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: blue.withOpacity(0.22),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Analysis",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF101828),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Predict spending, savings feasibility, and smart cut suggestions.",
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: blue.withOpacity(0.10),
                          border: Border.all(color: blue.withOpacity(0.15)),
                        ),
                        child: const Text(
                          "View",
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: blue,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;
  _GlowBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const blue = Color(0xFF217BFF);

    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(
      rect.deflate(0.8),
      const Radius.circular(20),
    );

    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: 6.283185307179586,
      transform: GradientRotation(6.283185307179586 * progress),
      colors: [
        blue.withOpacity(0.0),
        blue.withOpacity(0.20),
        Colors.white.withOpacity(0.95),
        blue.withOpacity(0.30),
        blue.withOpacity(0.0),
      ],
      stops: const [0.0, 0.40, 0.50, 0.60, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = sweep.createShader(rect);

    final innerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = blue.withOpacity(0.15);

    canvas.drawRRect(r, innerGlow);
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
