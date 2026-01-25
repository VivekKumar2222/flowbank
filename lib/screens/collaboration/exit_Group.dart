import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import '../collaboration/delete-OTP-screen.dart';


class GroupExitScreen extends StatefulWidget {
  final String? dashboardId;
  final String? ownerId;

  const GroupExitScreen({
    super.key,
    required this.dashboardId,
    required this.ownerId,
  });

  @override
  State<GroupExitScreen> createState() => _GroupExitScreenState();
}

class _GroupExitScreenState extends State<GroupExitScreen> {
  late String userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'user';
    });
  }

  Future<void> submitExitRequest() async {
  try {
    final response = await ApiService.post(
      "/api/collab/exit-group-request",
      {
        "dashboardId": widget.dashboardId,
        "toUserId": widget.ownerId,
        "fromUserId": userEmail,
      },
      context,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Exit request submitted successfully"),
        ),
      );

      
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit exit request: ${response.body}"),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to submit exit request"),
      ),
    );
  }
}

  

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E88E5);
    final exitColor = const Color(0xFF424242); // dark grey

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
                  // Exit Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: exitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: exitColor,
                      size: 34,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Exit Group?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "You are about to request an exit from this group.\n\n"
                    "Once approved, you will no longer have access to this group’s data.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Submit Exit Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitExitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: exitColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Exit Request",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
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
