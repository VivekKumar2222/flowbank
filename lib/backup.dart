import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  
  const OnboardingScreen({Key? key}) : super(key: key);


  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

    final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  int currentIndex = 0;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.15, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 80,
              right: -50,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: CurvePainter(),
              ),
            ),
            Positioned(
              bottom: 150,
              left: -80,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: WavePainter(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // ✅ Image (NO animation)
                  AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  transitionBuilder: (child, animation) {
    return FadeTransition(opacity: animation, child: child);
  },
  child: Image.asset(
    onboardingData[currentIndex]["image"]!,
    key: ValueKey<String>(onboardingData[currentIndex]["image"]!), // important
  ),
),


                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '◆',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FlowBank',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Text (NO animation)
                        Text(
                          onboardingData[currentIndex]["title1"]!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          onboardingData[currentIndex]["title2"]!,
                          style: TextStyle(
                            color: currentIndex == onboardingData.length - 1
                            ? const Color(0xFFB968F6) // Purple for last screen
                            : const Color(0xFF1E88E5), // Blue for others
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          onboardingData[currentIndex]["desc"]!,
                          style: const TextStyle(
                            color: Color(0xFF424242),
                            fontSize: 18.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            letterSpacing: 0.25,
                          ),
                        ),
                        const SizedBox(height: 18),

                       Row(
  children: List.generate(onboardingData.length, (index) {
    final bool isLastSlide = currentIndex == onboardingData.length - 1;

    final activeColor = isLastSlide
        ? const Color(0xFFB968F6)
        : const Color(0xFF1E88E5);

    final inactiveColor = isLastSlide
        ? const Color.fromARGB(255, 221, 186, 247)
        : const Color(0xFFBBDEFB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      width: currentIndex == index ? 36 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: currentIndex == index ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }),
),


                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
  if (currentIndex < onboardingData.length - 1) {
    setState(() {
      currentIndex++;
    });
  } else {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sign Up',
      barrierColor: Colors.black54, // dark overlay background
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
                      SizedBox(height: 4,),
                      Center(
                        child: Container(
                          width: 90,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(                     // 👇 Border added here
                               color: Color(0xFFCCD0D7),                // Blue border color
                               width: 1,                                // Border thickness
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
                           endIndent: 8, // space between line and "or"
                          ),
                         ),
                        const Text(
                         'or',
                         style: TextStyle(
                          color: Color.fromARGB(179, 105, 111, 121), // light grey text
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                         ),
                        ),
                       Expanded(
                        child: Divider(
                         color: const Color.fromARGB(199, 204, 208, 215),
                         thickness: 1,
                         indent: 8, // space between line and "or"
                        ),
                        ),
                        ],
                        ),

                     
                      const SizedBox(height: 16),

                      Text(
  'Please enter your details.',
  style: TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w400,
    color: Color(0xFF475467),
  ),
),

SizedBox(height: 8,),
                      // 👇 TextFields
                      TextField(
                        controller: fullNameController,
  decoration: InputDecoration(
    labelText: "Full Name",
    // prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E88E5)), // icon color
    filled: true, // enables background color
    fillColor: Color.fromARGB(255, 255, 255, 255), // light grey background

    // Adjust internal height
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16, // 👈 increases field height
      horizontal: 16,
    ),

    // Normal border
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFCCD0D7), // light grey border
        width: 1,
      ),
    ),

    // When focused
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF1E88E5), // blue when focused
        width: 2,
      ),
    ),
  ),
),

                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
  decoration: InputDecoration(
    labelText: "Email",
    // prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E88E5)), // icon color
    filled: true, // enables background color
    fillColor: Color.fromARGB(255, 255, 255, 255), // light grey background

    // Adjust internal height
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16, // 👈 increases field height
      horizontal: 16,
    ),

    // Normal border
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFCCD0D7), // light grey border
        width: 1,
      ),
    ),

    // When focused
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF1E88E5), // blue when focused
        width: 2,
      ),
    ),
  ),
),
                      const SizedBox(height: 12),

                      TextField(
                        controller: passwordController,
  decoration: InputDecoration(
    labelText: "Password",
    // prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E88E5)), // icon color
    filled: true, // enables background color
    fillColor: Color.fromARGB(255, 255, 255, 255), // light grey background

    // Adjust internal height
    contentPadding: const EdgeInsets.symmetric(
      vertical: 16, // 👈 increases field height
      horizontal: 16,
    ),

    // Normal border
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFCCD0D7), // light grey border
        width: 1,
      ),
    ),

    // When focused
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF1E88E5), // blue when focused
        width: 2,
      ),
    ),
  ),
),
                      const SizedBox(height: 36),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
  final fullName = fullNameController.text.trim();
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

print("Sending data: $fullName, $email, $password");

  final response = await http.post(
    Uri.parse("http://10.0.2.2:5000/api/auth/signup"), // use your IP on mobile
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
    // success popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User registered successfully")),
    );
  } else {
    // show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${response.body}")),
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
                      SizedBox(height: 14,),
                      Center(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center, // 👈 centers items in Row
    children: [
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
)

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
          curve: Curves.easeInOut, // smooth spring-like curve
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1), // starts from bottom
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
},

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  currentIndex == onboardingData.length - 1
                                      ? const Color(0xFFB968F6)
                                      : const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              currentIndex == onboardingData.length - 1
                                  ? "Get Started"
                                  : "Next",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
  onPressed: () {
    if (currentIndex == onboardingData.length - 1) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Login',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation1, animation2) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(42)),
              child: FractionallySizedBox(
                heightFactor: 0.48,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom + 16,
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
                              color: Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Please login to your account.",
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF475467),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 👇 Email Field
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Email",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(
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

                        // 👇 Password Field
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(
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

                        // 👇 Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 👇 Bottom Text
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Don’t have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475467),
                                ),
                              ),
                              Text(
                                "Sign Up",
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
    } else {
      setState(() {
        currentIndex = onboardingData.length - 1;
      });
    }
  },
  child: Text(
    currentIndex == onboardingData.length - 1
        ? "Already have an account?"
        : "Skip",
    style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
    ),
  ),
)


                      ],
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

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.3,
        size.width * 0.2, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvePainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7,
        size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}
