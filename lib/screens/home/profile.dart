import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home/resetOTPscreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString("userName") ?? "User";
      userEmail = prefs.getString("userEmail") ?? "No email";
    });
  }

  Future<void> sendResetOTP(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString("userEmail");

  final response = await http.post(
    Uri.parse("http://10.0.2.2:5000/api/auth/request-password-reset"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResetOtpScreen(email: email!)),
    );
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data["message"])));
  }
}


  Widget _buildBankCard({
  required String title,
  required String amount,
  required String holder,
  required String expiry,
  required Color cardColor,
  required Color accentColor,
}) {
  return Container(
    width: 260,
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CARD HOLDER",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                Text(
                  holder,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "EXPIRY",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                Text(
                  expiry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with avatar and buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-4QvDEYBhfqhVp1tgHRD4nqHqAHo06K.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE91E63),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.transparent,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
GestureDetector(
  onTap: () => sendResetOTP(context),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFF1E88E5), width: 1.5),
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
    ),
    child: const Text(
      'Reset Password',
      style: TextStyle(
        color: Color(0xFF1E88E5),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
)

                      ],
                    ),
                  ],
                ),
              ),

              // User info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // My Banks header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Banks',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: Color(0xFF9CA3AF),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add bank',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bank cards carousel
              SizedBox(
                height: 160,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBankCard(
                      title: 'JS Mastery Pro.',
                      amount: '\$1000.12',
                      holder: userName.toUpperCase(),
                      expiry: '06/24',
                      cardColor: const Color(0xFF2C3E50),
                      accentColor: const Color(0xFFE91E63),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ... rest of your code ...
            ],
          ),
        ),
      ),
    );
  }

  // keep your existing _buildBankCard and _buildBudgetItem
}
