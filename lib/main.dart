// import 'package:flowbank/screens/settlle_up/settle_up_screen.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding/OnboardingScreen.dart';
// import 'screens/home/homescreen.dart';
import 'screens/home/detail_collector.dart';
import 'screens/home/profile.dart';
import 'screens/home/new_homescreen.dart';
import 'screens/collaboration/create_group.dart';
// import 'package:device_preview/device_preview.dart';
import 'screens/collaboration/add_members_page.dart';
import 'screens/collaboration/bill_splitting.dart';
import 'screens/collaboration/bill_splitting_amount_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 this is required
  runApp(
      //   DevicePreview(
      // enabled: true,
      // builder: (context) => const MyApp(),
      // )
      const MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowBank',
      theme: ThemeData(fontFamily: 'Manrope', useMaterial3: true),
      //       locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,

      home: const OnboardingScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}
