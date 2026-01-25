import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flowbank/api/api_service.dart';
import '../collaboration/collaboration_screen.dart';

class DeleteOtpScreen extends StatefulWidget {
  final String email;
  final String dashboardId;

  const DeleteOtpScreen({
    super.key,
    required this.email,
    required this.dashboardId,
  });

  @override
  State<DeleteOtpScreen> createState() => _DeleteOtpScreenState();
}

class _DeleteOtpScreenState extends State<DeleteOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      showMessage("Please enter the OTP");
      return;
    }

    setState(() { isLoading = true; });

    final response = await ApiService.post(
      "/api/collab/verify-delete-otp",
      {
        "email": widget.email,
        "otp": otp,
        "dashboardId": widget.dashboardId,
      },
      context,
    );

    setState(() { isLoading = false; });

    if (response.statusCode == 200) {
      showMessage("Group deleted successfully");
      Navigator.push(context, MaterialPageRoute(builder: (context) => CollaborationScreen()));
    } else {
      final error = jsonDecode(response.body);
      showMessage(error['message'] ?? "OTP verification failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter the OTP sent to your email to delete this group.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify & Delete Group"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
