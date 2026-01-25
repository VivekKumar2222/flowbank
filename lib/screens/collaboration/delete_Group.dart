import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import '../collaboration/delete-OTP-screen.dart';

class GroupDeleteScreen extends StatefulWidget {
  final String? dashboardId;
  

  const GroupDeleteScreen({
    super.key,
    required this.dashboardId,
    
  });

  @override
  State<GroupDeleteScreen> createState() => _GroupDeleteScreenState();
}

class _GroupDeleteScreenState extends State<GroupDeleteScreen> {
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

  Future<void> deleteGroup() async {
    try {
        final response = await ApiService.post(
                      "/api/collab/delete-group-otp",
                    {
                                "email": userEmail,
                              },
                              context
                            );    
                            
                            print("Response status: ${response.statusCode}");
                            print("Response body: ${response.body}");
                     
                        if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                                  Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeleteOtpScreen(email: userEmail, dashboardId: widget.dashboardId ?? '',),
                                ),
                              );
                                }

                            } catch (e) {
      // Handle errors here
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E88E5);
    final dangerColor = const Color(0xFFE53935);

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
                  // Warning Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: dangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: dangerColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Delete Group?",
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
                    "Are you sure you want to delete this group?\n\n"
                    "This action is permanent and cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: deleteGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Delete Group",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
