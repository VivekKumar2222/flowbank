import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authentication/otpscreen.dart';
import 'package:flowbank/api/api_service.dart';
import 'package:flowbank/services/google_auth_service.dart';
// REPLACE NewHomeScreen with your actual home screen class name and import:
import 'package:flowbank/screens/home/new_homescreen.dart';
import '../connectBank/connect_bank_screen.dart';

Future<void> showSignUpBottomSheet(
  BuildContext context, {
  required Function(String) onMessage,
}) async {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[0-9!@#\$%\^&\*])(?=.{8,})');
    return passwordRegex.hasMatch(password);
  }

  String getInitials(String name) {
  if (name.trim().isEmpty) return "";

  final parts = name.trim().split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts[0][0].toUpperCase();
  }

  return (parts[0][0] + parts[1][0]).toUpperCase();
}

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Sign Up',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation1, animation2) {
      bool isGoogleLoading = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(42)),
              child: FractionallySizedBox(
                heightFactor: 0.6175,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 90,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Google Button ──────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: isGoogleLoading
                                ? null
                                : () async {
                                    setState(() => isGoogleLoading = true);
                                    try {
                                      final data = await GoogleAuthService
                                          .signInWithGoogle(context);
                                      if (data == null) return;

                                      debugPrint('Google response keys: ${data.keys.toList()}');
                                      debugPrint('token value: ${data['token']}');
                                      debugPrint('user: ${data['user']}');

                                      // ✅ AFTER (fixed)
final prefs = await SharedPreferences.getInstance();
final String userName = data['user']?['name'] ?? '';
await prefs.setString('accessToken', data['token'] ?? ''); // ← moved out, correct key
await prefs.setString('userName', userName);
await prefs.setString('userEmail', data['user']?['email'] ?? '');
await prefs.setString('userId', data['user']?['id'] ?? '');
await prefs.setString('userInitials', getInitials(userName));

                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          // ⚠️ Replace with your actual home screen class:
                                          builder: (_) => const ConnectBankScreen(isAddingNew: false),
                                        ),
                                      );
                                    } catch (e) {
                                      onMessage(e.toString());
                                    } finally {
                                      setState(() => isGoogleLoading = false);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFCCD0D7), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isGoogleLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://developers.google.com/identity/images/g-logo.png',
                                        height: 20,
                                        width: 20,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.login, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Sign up with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475467),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Divider ────────────────────────────────────
                        Row(children: [
                          const Expanded(
                              child: Divider(
                                  color: Color(0xFFCCD0D7),
                                  thickness: 1,
                                  endIndent: 8)),
                          const Text('or',
                              style: TextStyle(
                                  color: Color(0xFF98A2B3), fontSize: 14)),
                          const Expanded(
                              child: Divider(
                                  color: Color(0xFFCCD0D7),
                                  thickness: 1,
                                  indent: 8)),
                        ]),
                        const SizedBox(height: 16),

                        const Text(
                          'Please enter your details.',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF475467),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Full Name ──────────────────────────────────
                        TextField(
                          controller: fullNameController,
                          decoration: _inputDecoration('Full Name'),
                        ),
                        const SizedBox(height: 12),

                        // ── Email ──────────────────────────────────────
                        TextField(
                          controller: emailController,
                          decoration: _inputDecoration('Email'),
                        ),
                        const SizedBox(height: 12),

                        // ── Password ───────────────────────────────────
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: _inputDecoration('Password'),
                        ),
                        const SizedBox(height: 36),

                        // ── Sign Up Button ─────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final fullName = fullNameController.text.trim();
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();

                              if (fullName.isEmpty ||
                                  email.isEmpty ||
                                  password.isEmpty) {
                                onMessage('All fields are required');
                                return;
                              }
                              if (!isValidEmail(email)) {
                                onMessage(
                                    'Please enter a valid email (e.g., name@gmail.com)');
                                return;
                              }
                              if (!isValidPassword(password)) {
                                onMessage(
                                    'Password must be at least 8 characters and include a number or special character');
                                return;
                              }

                              try {
                                final response = await ApiService.post(
                                  '/api/auth/signup',
                                  {
                                    'name': fullName,
                                    'email': email,
                                    'password': password,
                                  },
                                  context,
                                );

                                if (response.statusCode == 200 ||
                                    response.statusCode == 201) {
                                  onMessage('User registered successfully');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtpScreen(email: email),
                                    ),
                                  );
                                } else {
                                  final error = jsonDecode(response.body);
                                  onMessage(
                                      'Error: ${error['message'] ?? 'Unknown error'}');
                                }
                              } catch (e) {
                                onMessage('Failed to connect to the server');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475467)),
                              ),
                              Text(
                                'Login',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0179FE)),
                              ),
                            ],
                          ),
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
    },
    transitionBuilder: (context, animation1, animation2, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation1, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCCD0D7), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
    ),
  );
}