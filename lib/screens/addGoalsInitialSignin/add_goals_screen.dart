import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import '../home/new_homescreen.dart';  // your home screen
import '../addGoalsInitialSignin/budget-goal-screen.dart';

class AddGoalsScreen extends StatefulWidget {
  const AddGoalsScreen({super.key});

  @override
  State<AddGoalsScreen> createState() => _AddGoalsScreenState();
}

class _AddGoalsScreenState extends State<AddGoalsScreen> {
  //bool _isLoading = true;
  bool   _isConnecting = false;
  String? _linkToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 12),
            // Image at the top
            SizedBox(
              height: 400,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/goals-card.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),

            // Dynamic gap
            const Spacer(),

            // Texts and buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Share Your",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        "Goals with us",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Set your savings goals. We’ll help you track them and reach them faster.",
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF424242),
                      height: 1.4,
                      letterSpacing: 0.25,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Loading/Error Handling ---
                  
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (){
                          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetGoalScreen()),
                        );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isConnecting
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text(
                                "Create Goals",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetGoalScreen()),
                        );
                      },
                      child: Text(
                        "Skip for now",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}