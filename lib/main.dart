import 'package:flutter/material.dart';
import 'screens/onboarding/OnboardingScreen.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/collaboration/delete_Group.dart';
import 'screens/connectBank/connect_bank_screen.dart';
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

      home: const OnboardingScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}
