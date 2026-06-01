import 'package:flutter/material.dart';
import 'financial_chat_screen.dart';
import 'financial_health_screen_ai.dart';
import 'spending_forecast_screen.dart';

class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _dark = Color(0xFF0A0A0F);
  static const _modules = [
    {
      'title': 'Financial Chat',
      'subtitle': 'Ask Finara anything about your money',
      'image': 'assets/ai-iocn-1.png',
    },
    {
      'title': 'Financial Health',
      'subtitle': 'AI predictions on your financial runway',
      'image': 'assets/ai-iocn-2.png',
    },
    {
      'title': 'Spending Forecast',
      'subtitle': 'Understand your spending patterns',
      'image': 'assets/ai-iocn-3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openModule(int index) {
    Widget screen;
    switch (index) {
      case 0: screen = const FinancialChatScreen(); break;
      case 1: screen = const FinancialHealthScreenAI(); break;
      default: screen = const SpendingForecastScreen();
    }
    Navigator.push(context, _darkRoute(screen));
  }

  Route _darkRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image — anchored to bottom, natural height, width overflows freely
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: FadeTransition(
          //     opacity: _fadeAnim,
          //     child: SlideTransition(
          //       position: _slideAnim,
          //       child: Image.asset('assets/background-gradient.png'),
          //     ),
          //   ),
          // ),

          // Content
          SafeArea(
            child: Column(children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const Spacer(),
              _buildModules(),
              const SizedBox(height: 16),
              _buildFooter(),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        const SizedBox(height: 12),
        const Text(
          'Talk With Finara. \nYour Financial \nAI Assistant',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope', height: 1.05),
        ),
        const SizedBox(height: 8),
        Text(
          'An AI-powered system that provides near-accurate predictions of your financial stability and future outlook',
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w400, height: 1.2),
        ),
      ]),
    );
  }

  Widget _buildModules() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_modules.length, (i) {
          final m = _modules[i];
          return GestureDetector(
            onTap: () => _openModule(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.5),
              padding: const EdgeInsets.only(left: 14, right: 16, top: 18, bottom: 18),
              decoration: BoxDecoration(
                color: Color(0xFF16161B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                SizedBox(
                  width: 48, height: 48,
                  child: Image.asset(
                    m['image'] as String,
                    width: 48, height: 48,
                    errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome_rounded, color: Colors.white54, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['title'] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope')),
                  const SizedBox(height: 3),
                  Text(m['subtitle'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Icon(Icons.lock_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
        const SizedBox(width: 6),
        Text('Your data never leaves FlowBank servers',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
      ]),
    );
  }
}
