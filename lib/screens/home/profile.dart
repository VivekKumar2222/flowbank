import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../home/resetOTPscreen.dart';
import 'package:flowbank/api/api_service.dart';
import 'package:flowbank/screens/home/section_header.dart';
import 'package:flowbank/screens/home/user-total-balance-view.dart';
import '../onboarding/OnboardingScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "";
  String userEmail = "";
  double? _monthlyIncome;
  bool _incomeConfirmed = false;

  String _getInitials(String name) {
  List<String> names = name.split(" ");
  String initials = "";
  for (var part in names) {
    if (part.isNotEmpty) {
      initials += part[0].toUpperCase();
    }
  }
  return initials;
}


  // Color Palette
  final Color primaryBlue = const Color(0xFF1A73E8);
  final Color cloudBlue = const Color(0xFFF0F7FF);
  final Color secondaryPurple = const Color(0xFF6C63FF);

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
    _fetchIncome();
  }

  Future<void> _fetchIncome() async {
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/auth/income', context);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _monthlyIncome = (data['monthlyIncome'] as num?)?.toDouble();
          _incomeConfirmed = data['incomeConfirmed'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveIncome(double amount) async {
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.patch(
        '/api/auth/income',
        {'monthlyIncome': amount, 'incomeConfirmed': true},
        context,
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _monthlyIncome = (data['monthlyIncome'] as num?)?.toDouble();
          _incomeConfirmed = true;
        });
      }
    } catch (_) {}
  }

  void _showEditIncomeDialog() {
    final ctrl = TextEditingController(
        text: _monthlyIncome != null && _monthlyIncome! > 0 ? _monthlyIncome!.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Monthly Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) { Navigator.pop(context); _saveIncome(val); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {

     Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _loadingScreen()),
  );

  // ⏳ Wait 2.5 seconds
  await Future.delayed(const Duration(seconds: 2));

  final prefs = await SharedPreferences.getInstance();

  // 🔥 Clear auth + user data
  await prefs.remove('accessToken');
  await prefs.remove('userName');
  await prefs.remove('userEmail');

  // (Optional but safe)
  // await prefs.clear();

  // 🚀 Navigate to onboarding / login
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    (route) => false,
  );
}


  Future<void> sendResetOTP(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");

    final response = await ApiService.post(
      "/api/auth/request-password-reset",
      {"email": email},
      context
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResetOtpScreen(email: email!)),
      );
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["message"])));
    }
  }

  Widget _loadingScreen() {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF217BFF)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Logging out",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF217BFF),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.settings_outlined, color: primaryBlue),
          //   onPressed: () {},
          // )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cloudBlue, width: 5),
                    ),
                    child: Center(
  child: Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cloudBlue, width: 5),
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFD1E9FF), // custom background color
          child: Text(
            _getInitials(userName),
            style: const TextStyle(
              color: Color(0xFF217BFF), // custom text color
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(4),
          // decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
          // child: const Icon(Icons.edit, color: Colors.white, size: 18),
        ),
      ),
    ],
  ),
),

                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      // decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                      // child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  "Reset Password", 
                  primaryBlue, 
                  Icons.lock_reset, 
                  () => sendResetOTP(context)
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  "Delete", 
                  Colors.redAccent, 
                  Icons.delete_outline, 
                  () => logout(context)
                ),

                
              ],
            ),

            SizedBox(height: 12,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: _buildActionButton(
                "Log Out", 
                const Color.fromARGB(255, 38, 38, 38), 
                Icons.logout, 
                () => logout(context),
                ),
            ),

            const SizedBox(height: 24),

            // ── Income Card ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBDD7FF), width: 1.2),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1A73E8), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('Monthly Income', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475467))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _incomeConfirmed ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _incomeConfirmed ? 'Confirmed' : 'Estimated',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _incomeConfirmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      _monthlyIncome != null ? '\$${_monthlyIncome!.toStringAsFixed(0)}/month' : 'Not set',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36), fontFamily: 'Manrope'),
                    ),
                  ])),
                  GestureDetector(
                    onTap: _showEditIncomeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBDD7FF)),
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
                    ),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            // Bank Section Header
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 24),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       const Text("My Banks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //       TextButton.icon(
            //         onPressed: () {},
            //         icon: Icon(Icons.add, size: 18, color: secondaryPurple),
            //         label: Text("Add bank", style: TextStyle(color: secondaryPurple)),
            //       )
            //     ],
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(
                        title: "Connected Accounts",
                        showButton: true,
                        
                      ),
            ),

            const SizedBox(height: 12),

            // Modernized Bank Card
            // SizedBox(
            //   height: 190,
            //   child: ListView(
            //     padding: const EdgeInsets.only(left: 24),
            //     scrollDirection: Axis.horizontal,
            //     children: [
            //       // _buildModernBankCard(
            //       //   "JS Mastery Pro.",
            //       //   "\$1,000.12",
            //       //   userName.toUpperCase(),
            //       //   "06/24",
            //       // ),
            //     ],
            //   ),
            // ),

            UserTotal(
                accounts: [
                  BankAccount(
                    bankName: "JS Mastery Pro",
                    //cardHolder: "Adrian Hajdin",
                    amount: 1000.12,
                    dateConnected: "06/24",
                    gradientColors: [Color(0xFFB28DFF), Color(0xFFF3B0FF)],
                  ),
                  BankAccount(
                    bankName: "Sky Bank",
                    //cardHolder: "John Doe",
                    amount: 1600.00,
                    dateConnected: "07/23",
                    gradientColors: [Color(0xFF2193FF), Color(0xFF6DD5ED)],
                  ),
                ],
              ),


          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Widget _buildModernBankCard(String title, String amount, String holder, String expiry) {
  //   return Container(
  //     width: 300,
  //     margin: const EdgeInsets.only(right: 16),
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [primaryBlue, secondaryPurple],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: primaryBlue.withOpacity(0.3),
  //           blurRadius: 20,
  //           offset: const Offset(0, 10),
  //         )
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
  //             const Icon(Icons.contactless, color: Colors.white54),
  //           ],
  //         ),
  //         const Spacer(),
  //         Text(amount, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
  //         const Spacer(),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             // _cardInfoLabel("CARD HOLDER", holder),
  //             // _cardInfoLabel("EXPIRY", expiry),
  //           ],
  //         )
  //       ],
  //     ),
  //   );
  // }

  // Widget _cardInfoLabel(String label, String value) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
  //       const SizedBox(height: 4),
  //       Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  //     ],
  //   );
  // }
}