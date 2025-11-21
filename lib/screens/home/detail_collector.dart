import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../home/homescreen.dart';
import '../home/country_dropdown.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class DetailCollector extends StatefulWidget {
  final String email;
  const DetailCollector({Key? key, required this.email}) : super(key: key);

  @override
  State<DetailCollector> createState() => _DetailCollectorState();
}

class _DetailCollectorState extends State<DetailCollector> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  bool isLoading = false;

  Future<void> submitDetails() async {
    final phone = phoneController.text.trim();
    final city = cityController.text.trim();
    final country = selectedCountry ?? '';
    final postalCode = postalCodeController.text.trim();

    if (phone.isEmpty || city.isEmpty || country.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://localhost:5000/api/auth/complete-profile"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": widget.email,
        "phone": phone,
        "city": city,
        "postalCode": postalCode,
        "country": country,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile completed successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${error['message'] ?? 'Unknown error'}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
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
            stops: [0.0, 0.15, 0.35, 0.65, 1.0],
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
                  // ✅ Image with NO padding
                  Image.asset('assets/my_image8.png'),

                  // ✅ Scrollable form with padding
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please enter your details.',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Country
                          // Country Dropdown
DropdownButtonFormField2<String>(
          value: selectedCountry,
          isExpanded: true, // makes text fill horizontally
          decoration: InputDecoration(
            labelText: "Country",
            labelStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFF667085),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(210, 204, 208, 215),
                width: 1.8,
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

          // 👇 Selected text style (in the input box)
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF475467),
            fontWeight: FontWeight.w400,
          ),

          // 👇 Dropdown popup style customization
          dropdownStyleData: DropdownStyleData(
            maxHeight: 300, // maximum height of popup list
            width: MediaQuery.of(context).size.width - 32, // full width
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // background of dropdown popup
              borderRadius: BorderRadius.circular(14), // rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15), // soft shadow
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFD0D5DD), // border around dropdown
                width: 1.2,
              ),
            ),
            elevation: 2, // controls the depth/shadow intensity
            offset: const Offset(0, 8), // space between input and popup
          ),

          // 👇 Custom padding/spacing inside each item
          menuItemStyleData: const MenuItemStyleData(
            height: 48, // item height
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),

          // 👇 The dropdown items
          items: countries.map((country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(
                country,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }).toList(),

          // 👇 Called when user selects something
          onChanged: (value) {
            setState(() {
              selectedCountry = value;
            });
          },

          // 👇 Optional: change how the dropdown icon looks
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 26,
            iconEnabledColor: Color(0xFF475467),
          ),
        ),

                          const SizedBox(height: 16),

                          // City
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: cityController,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: "City",

                                    labelStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF667085),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(
                                          210,
                                          204,
                                          208,
                                          215,
                                        ),
                                        width: 1.8,
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
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: postalCodeController,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    labelText: "Postal Code",
                                    labelStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF667085),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(
                                          210,
                                          204,
                                          208,
                                          215,
                                        ),
                                        width: 1.8,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Phone",
                              labelStyle: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF667085),
                              ),

                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(210, 204, 208, 215),
                                  width: 1.8,
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
                          const SizedBox(height: 34),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : submitDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              "We collect this info just to improve your experience",
                              style: TextStyle(
                                fontSize: 12.6,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(212, 71, 84, 103),
                              ),
                            ),
                          ),
                          SizedBox(height: 2),
                          Center(
                            child: Text(
                              "it stays private.",
                              style: TextStyle(
                                fontSize: 12.6,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF308AFF),
                              ),
                            ),
                          ),
                        ],
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

// Decorative Painters (unchanged)
class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.2,
      size.height,
    );
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
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}
