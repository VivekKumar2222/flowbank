// import 'package:flowbank/screens/settlle_up/settle_up_screen.dart';
import 'package:flowbank/screens/collaboration/collaboration_screen.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding/OnboardingScreen.dart';
// import 'screens/home/homescreen.dart';
import 'screens/home/detail_collector.dart';
import 'screens/home/profile.dart';
import 'screens/home/new_homescreen.dart';
import 'screens/collaboration/create_group.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/collaboration/add_members_page.dart';
import 'screens/collaboration/bill_splitting.dart';
import 'screens/collaboration/bill_splitting_amount_page.dart';
import 'screens/collaboration/add_Entries.dart';
import 'screens/collaboration/ledger_tracking.dart';
import 'screens/collaboration/create-assignment.dart';
import 'screens/collaboration/ledger_Member_screen.dart';
import 'screens/collaboration/entry_verification.dart';
import 'screens/authentication/email-for-password-reset.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 this is required
  runApp(
        DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
      )
      // const MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowBank',
      theme: ThemeData(fontFamily: 'Manrope', useMaterial3: true),
            locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      // home: const LedgerMemberScreen(dashboardId: "6957abe8ab9bb45065050376", memberId: "bsse2280166@szabist.pk",),
      home: const OnboardingScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}
