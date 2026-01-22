import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'package:flowbank/api/api_service.dart';


class CreateAssignmentPage extends StatefulWidget {
   final String dashboardId;
   final String membersId; // assigned to
   

  const CreateAssignmentPage({
    super.key,
    required this.dashboardId,
    required this.membersId,
    
  });

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _penaltyRateController = TextEditingController();

  bool interestEnabled = false;
  bool penaltyEnabled = false;
  String? userEmail;  // assigner, owner, assigned by

  // 🔐 Encryption setup
final encrypt.Key _key =
    encrypt.Key.fromUtf8('0123456789abcdef0123456789abcdef'); // 32 chars
final encrypt.IV _iv = encrypt.IV.fromLength(16);


  String _interestCycle = "monthly";
  String _penaltyType = "fixed";
  String? currency;
  DateTime? _dueDate;

  File? _verificationImage;
  final ImagePicker _picker = ImagePicker();

   @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _fetchDashboardCurrency();
  }

  Future<void> _fetchDashboardCurrency() async {
  try {
    final response = await ApiService.post(
      "/api/collab/dashboards-by-ids",
      {"ids": [widget.dashboardId],},
      context
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List;

      if (decoded.isNotEmpty) {
        setState(() {
          currency = decoded[0]["currency"] ?? "USD";
        });
      }
    }
  } catch (e) {
    debugPrint("Failed to fetch dashboard currency: $e");
  }
}


  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'user';
    });
  }

  Future<String?> _encryptImage(File? imageFile) async {
  if (imageFile == null) return null;

  final bytes = await imageFile.readAsBytes();
  final encrypter = encrypt.Encrypter(
    encrypt.AES(_key, mode: encrypt.AESMode.cbc),
  );

  final encrypted = encrypter.encryptBytes(bytes, iv: _iv);
  return base64Encode(encrypted.bytes);
}

Future<void> _createAssignment() async {
  if (_dueDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select due date")),
    );
    return;
  }

  final encryptedImage = await _encryptImage(_verificationImage);

final body = {
  "dashboardId": widget.dashboardId,
  "memberId": widget.membersId,
  "assignedBy": userEmail,

  "title": _titleController.text.trim(),
  "description": _descriptionController.text.trim(),

  "totalAmount": double.parse(_amountController.text),
  "paidAmount": 0,

  "interestRate": interestEnabled
      ? double.parse(_interestRateController.text)
      : 0,

  "penaltyAmount": penaltyEnabled
      ? double.parse(_penaltyRateController.text)
      : 0,

  "dueDate": _dueDate!.toIso8601String(),
};

// 👇 conditionally add fields
if (interestEnabled) {
  body["interestCycle"] = _interestCycle;
}

if (penaltyEnabled) {
  body["penaltyType"] = _penaltyType;
}

if (encryptedImage != null) {
  body["verificationSource"] = encryptedImage;
}


  try {
    final response = await ApiService.post(
      "/api/collab/ledger-assignment",
      body,
      context
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assignment created successfully")),
      );
      Navigator.pop(context);
    } else {
      debugPrint(response.body);
      throw Exception("Failed to create assignment");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}



  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _verificationImage = File(picked.path);
      });
    }
  }

  // ---------------- DATE PICKER ----------------
  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // ---------------- REUSABLE INPUT ----------------
Widget _inputBox({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  String? prefixText,
  TextInputType keyboard = TextInputType.text,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color.fromARGB(154, 33, 122, 255),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,

        // 👇 ICON OR TEXT PREFIX
prefixIcon: prefixText != null
    ? SizedBox(
        width: 56, // same width as icon
        child: Center(
          child: Text(
            prefixText,
            style: const TextStyle(
              color: Color(0xFF217BFF),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      )
    : (icon != null
        ? Icon(icon, color: const Color(0xFF217BFF))
        : null),


        prefixIconConstraints:
            const BoxConstraints(minWidth: 50, minHeight: 0),

        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Center(
          child: Text(
            'Create Assignment',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF217BFF),
              fontSize: 26,
            ),
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 14),
                const Text("Title",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _inputBox(
                  controller: _titleController,
                  hint: "Assignment title",
                  icon: Icons.title,
                ),

                const SizedBox(height: 16),
                const Text("Description",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _inputBox(
                  controller: _descriptionController,
                  hint: "Optional description",
                  icon: Icons.description,
                ),

                const SizedBox(height: 16),
                const Text("Amount",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
               _inputBox(
  controller: _amountController,
  hint: "Enter amount",
  keyboard: TextInputType.number,

  // ONLY replace the icon
  icon: currency == "USD"
      ? Icons.attach_money_rounded
      : null,

  prefixText: currency == "PKR"
      ? "PKR"
      : null,
),



                const SizedBox(height: 20),

                // ---------------- INTEREST ----------------
                SwitchListTile(
                  title: const Text(
                    "Interest",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  value: interestEnabled,
                  activeColor: const Color(0xFF217BFF),
                  onChanged: (val) =>
                      setState(() => interestEnabled = val),
                ),

                if (interestEnabled) ...[
                  const SizedBox(height: 12),
                  _inputBox(
                    controller: _interestRateController,
                    hint: "Interest Rate (%)",
                    icon: Icons.percent,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _interestCycle,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "weekly", child: Text("Weekly")),
                      DropdownMenuItem(
                          value: "monthly", child: Text("Monthly")),
                      DropdownMenuItem(
                          value: "yearly", child: Text("Yearly")),
                    ],
                    onChanged: (val) =>
                        setState(() => _interestCycle = val!),
                  ),
                ],

                const SizedBox(height: 20),

                // ---------------- DUE DATE ----------------
                const Text("Due Date",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(154, 33, 122, 255),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _dueDate == null
                          ? "Select due date"
                          : _dueDate!.toLocal().toString().split(" ")[0],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------- PENALTY ----------------
                SwitchListTile(
                  title: const Text(
                    "Penalty",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  value: penaltyEnabled,
                  activeColor: const Color(0xFF217BFF),
                  onChanged: (val) =>
                      setState(() => penaltyEnabled = val),
                ),

                if (penaltyEnabled) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _penaltyType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "fixed", child: Text("Fixed")),
                      DropdownMenuItem(
                          value: "percentage", child: Text("Percentage")),
                    ],
                    onChanged: (val) =>
                        setState(() => _penaltyType = val!),
                  ),

                  const SizedBox(height: 12),
                  _inputBox(
                    controller: _penaltyRateController,
                    hint: "Penalty rate",
                    icon: Icons.warning,
                    keyboard: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 20),

                // ---------------- VERIFICATION IMAGE ----------------
                const Text(
                  "Source of Verification",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(154, 33, 122, 255),
                        width: 1.5,
                      ),
                      color: const Color(0xFFF5FAFF),
                    ),
                    child: _verificationImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.upload_file,
                                  size: 40,
                                  color: Color(0xFF217BFF)),
                              SizedBox(height: 8),
                              Text(
                                "Upload Verification Image",
                                style: TextStyle(
                                  color: Color(0xFF217BFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _verificationImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // ---------------- BUTTON ----------------
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _createAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF217BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Create Assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
