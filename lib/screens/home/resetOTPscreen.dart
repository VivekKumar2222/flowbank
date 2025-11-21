import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home/newPasswordscreen.dart';

class ResetOtpScreen extends StatefulWidget {
  final String email;

  const ResetOtpScreen({required this.email, Key? key}) : super(key: key);

  @override
  _ResetOtpScreenState createState() => _ResetOtpScreenState();
}

class _ResetOtpScreenState extends State<ResetOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyResetOTP() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://10.0.2.2:5000/api/auth/verify-reset-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email, "otp": otpController.text}),
    );

    setState(() => isLoading = false);

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data["message"])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E88E5);
    final accentColor = const Color(0xFFB968F6);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon (same as normal OTP screen)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      color: primaryColor,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Heading
                  const Text(
                    "Reset Password OTP",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "We’ve sent a 6-digit OTP to",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),

                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 15,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP Input UI
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText: "Enter OTP",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Verify Button (same UI)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : verifyResetOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "Verify OTP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Note
                  Text(
                    "Didn’t receive the OTP? Try again after 60s.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
