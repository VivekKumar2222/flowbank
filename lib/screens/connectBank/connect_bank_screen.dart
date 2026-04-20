import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowbank/api/api_service.dart';
import '../home/new_homescreen.dart';  // your home screen
import '../addGoalsInitialSignin/budget-goal-screen.dart'; // your budget goals screen
import '../addGoalsInitialSignin/add_goals_screen.dart';

class ConnectBankScreen extends StatefulWidget {
  const ConnectBankScreen({super.key});

  @override
  State<ConnectBankScreen> createState() => _ConnectBankScreenState();
}

class _ConnectBankScreenState extends State<ConnectBankScreen> {
  bool _isLoading = true;
  bool   _isConnecting = false;
  String? _linkToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLinkToken();
  }

  Future<void> _fetchLinkToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        setState(() {
          _errorMessage = 'User not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.post(
        '/api/plaid/create-link-token',
        {'userId': userId},
        context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _linkToken = data['link_token'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to initialize. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openPlaidLink() async {
    if (_linkToken == null) return;

    setState(() => _isConnecting = true);

    final configuration = LinkTokenConfiguration(token: _linkToken!);

    PlaidLink.onSuccess.listen((LinkSuccess event) async {
      final publicToken = event.publicToken;
      await _exchangeToken(publicToken);
    });

    PlaidLink.onExit.listen((LinkExit event) {
      setState(() => _isConnecting = false);
      if (event.error != null) {
        print('Plaid exit error: ${event.error?.message}');
        print('Plaid exit error code: ${event.error?.code}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${event.error?.message ?? "Unknown"}')),
        );
      } else {
        print('User exited Plaid Link without error');
      }
    });

    PlaidLink.onEvent.listen((LinkEvent event) {
      print('Plaid event: ${event.name}');
    });

    await PlaidLink.open(configuration: configuration);
  }

  Future<void> _exchangeToken(String publicToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await ApiService.post(
        '/api/plaid/exchange-token',
        {'public_token': publicToken, 'userId': userId},
        context,
      );

      if (response.statusCode == 200) {
        await prefs.setBool('bankConnected', true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddGoalsScreen()),
        );
      } else {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect bank. Try again.')),
        );
      }
    } catch (e) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
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
                  "assets/bank-card.png",
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
                        "Connect ",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        "Your Bank",
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
                    "Securely link your bank accounts to FlowBank. Track every transaction in one place.",
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
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isLoading = true;
                              });
                              _fetchLinkToken();
                            },
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : _openPlaidLink,
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
                                "Connect Account",
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
                          MaterialPageRoute(builder: (_) => const AddGoalsScreen()),
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