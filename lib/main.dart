import 'package:flowbank/screens/settlle_up/settle_up_screen.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding/OnboardingScreen.dart';
import 'screens/home/homescreen.dart';
import 'screens/home/detail_collector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 this is required
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowBank',
      theme: ThemeData(useMaterial3: true),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
