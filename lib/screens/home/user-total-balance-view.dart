import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTotalBalance(double total) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('totalBalance', total);
}

class BankAccount {
  final String bankName;
  final String cardHolder;
  final double amount;
  final String dateConnected;
  final List<Color> gradientColors;

  BankAccount({
    required this.bankName,
    required this.cardHolder,
    required this.amount,
    required this.dateConnected,
    required this.gradientColors,
  });
}

class UserTotal extends StatelessWidget {
  final List<BankAccount> accounts;

  const UserTotal({Key? key, required this.accounts}) : super(key: key);

  double get totalBalance {
    double total = 0;
    for (var account in accounts) {
      total += account.amount;
    }
    
    return total;
  }

  Future<void> persistTotal() async {
    final prefs = await SharedPreferences.getInstance();
  final savedTotal = prefs.getDouble('totalBalance') ?? -1;

  if (savedTotal != totalBalance) {
    await prefs.setDouble('totalBalance', totalBalance);
  }
}


  @override
  Widget build(BuildContext context) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
    persistTotal();
  });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ TOP ROW WITH 18px PADDING
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Current Balance",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      color: Color(0xFF667085),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "\$${totalBalance.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      color: Color(0xFF217BFF),
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  "+ Add Bank",
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ✅ CARDS WITH ONLY LEFT PADDING
        SizedBox(
          height: 202,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(left: 18), // 👈 ONLY LEFT
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 328,
                  decoration: BoxDecoration(
                    color: Color(0xFF344054),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          12,
                          11,
                          27,
                        ).withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.bankName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "Manrope",
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "\$${account.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Manrope",
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        account.cardHolder,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Manrope",
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        account.dateConnected,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Manrope",
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Gradient side
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            colors: account.gradientColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.wifi, color: Colors.white),
                              SvgPicture.asset('assets/visa.svg'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
