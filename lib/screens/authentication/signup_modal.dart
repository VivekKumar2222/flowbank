import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home/homescreen.dart';
import '../authentication/otpscreen.dart';

Future<void> showSignUpBottomSheet(
  BuildContext context, {
  required Function(String) onMessage,
}) async {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isEmailValid = true;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[0-9!@#\$%\^&\*])(?=.{8,})');
    return passwordRegex.hasMatch(password);
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Sign Up',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation1, animation2) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFFCCD0D7),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(199, 204, 208, 215),
                            thickness: 1,
                            endIndent: 8,
                          ),
                        ),
                        const Text(
                          'or',
                          style: TextStyle(
                            color: Color.fromARGB(179, 105, 111, 121),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(199, 204, 208, 215),
                            thickness: 1,
                            indent: 8,
                          ),
                        ),
                      ],
                    ),
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

                    // Full name field
                    TextField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCD0D7),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email field
                    TextField(
                      controller: emailController,
                      onChanged: (value) {
                        isEmailValid = isValidEmail(value);
                      },
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCD0D7),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password field
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCD0D7),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          print("Validating inputs...");

                          final fullName = fullNameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          // Frontend validation
                          if (fullName.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            print("❌ Missing field(s)");
                            onMessage("All fields are required");
                            return;
                          }

                          if (!isValidEmail(email)) {
                            print("❌ Invalid email: $email");
                            onMessage(
                              "Please enter a valid email (e.g., name@gmail.com)",
                            );
                            return;
                          }

                          if (!isValidPassword(password)) {
                            print("❌ Weak password");
                            onMessage(
                              "Password must be at least 8 characters and include a number or special character",
                            );
                            return;
                          }

                          print("Sending data: $fullName, $email, $password");

                          final response = await http.post(
                            Uri.parse("http://localhost:5000/api/auth/signup"),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "name": fullName,
                              "email": email,
                              "password": password,
                            }),
                          );

                          print("Response status: ${response.statusCode}");
                          print("Response body: ${response.body}");

                          if (response.statusCode == 201) {
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            onMessage("User registered successfully");
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtpScreen(
                                  email: emailController.text.trim(),
                                ),
                              ),
                            );
                          } else {
                            final error = jsonDecode(response.body);
                            onMessage(
                              "Error: ${error['message'] ?? 'Unknown error'}",
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475467),
                            ),
                          ),
                          Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0179FE),
                            ),
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
    transitionBuilder: (context, animation1, animation2, child) {
      final curved = CurvedAnimation(
        parent: animation1,
        curve: Curves.easeInOut,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
