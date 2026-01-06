import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;


class AddEntriesPage extends StatefulWidget {
  final String dashboardId; // ✅ constructor input
  final String? assignmentId;

  const AddEntriesPage({
    super.key,
    required this.dashboardId,
    this.assignmentId,
  });

  @override
  State<AddEntriesPage> createState() => _AddEntriesPageState();
}

class _AddEntriesPageState extends State<AddEntriesPage> {
  final TextEditingController _amountController = TextEditingController();
  File? _verificationImage;

  final ImagePicker _picker = ImagePicker();

  String? userEmail;

  // 🔐 Encryption setup
final encrypt.Key _key = encrypt.Key.fromUtf8('0123456789abcdef0123456789abcdef'); // 32 chars
final encrypt.IV _iv = encrypt.IV.fromLength(16); // 16 bytes IV


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

  /// 🔐 Encrypt image bytes
Future<String> _encryptImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final encrypter = encrypt.Encrypter(
    encrypt.AES(_key, mode: encrypt.AESMode.cbc,padding: 'PKCS7'),
  );

  final encrypted = encrypter.encryptBytes(bytes, iv: _iv);
  return encrypted.base64; // ✅ send base64 from the encrypt package
}



  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _verificationImage = File(pickedFile.path);
      });
    }
  }

//   Future<void> _submitEntry() async {
//   final encryptedImage = await _encryptImage(_verificationImage!);

//   final response = await http.post(
//     Uri.parse("http://10.0.2.2:5000/api/collab/dashboard-entry"),
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: jsonEncode({
//       "dashboardId": widget.dashboardId,
//       "userId": userEmail,
//       "amount": double.parse(_amountController.text),
//       "verificationImage": encryptedImage, // 🔐 encrypted
//     }),

    
//   );

//   if (response.statusCode == 201) {
//     Navigator.pop(context); // ✅ go back after success
//   } else {
//     debugPrint("Failed: ${response.body}");
//   }
// }

Future<void> _submitEntry() async {
  if (_verificationImage == null) return;

  final amount = double.tryParse(_amountController.text);
  if (amount == null || amount <= 0) return;

  final encryptedImage = await _encryptImage(_verificationImage!);

  final Map<String, dynamic> body = {
    "dashboardId": widget.dashboardId,
    "userId": userEmail,
    "amount": amount,
    "verificationImage": encryptedImage,
  };

  // ✅ only attach if coming from ledger
  if (widget.assignmentId != null) {
    body["assignmentId"] = widget.assignmentId;
  }

  final response = await http.post(
    Uri.parse("http://10.0.2.2:5000/api/collab/dashboard-entry"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    Navigator.pop(context);
  } else {
    debugPrint("Failed: ${response.body}");
  }
}



  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled =
        _amountController.text.isNotEmpty && _verificationImage != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Center(
          child: Text(
            'Add Entries',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF217BFF),
              fontSize: 26,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// Entry Amount
              const Text(
                "Entry Amount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(154, 33, 122, 255),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter amount',
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.attach_money, color: Color(0xFF217BFF)),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 24),

              /// Source of Verification
              const Text(
                "Source of Verification",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: Color(0xFF217BFF),
                            ),
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
            ],
          ),
        ),
      ),

      /// Submit Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isButtonEnabled ? _submitEntry : null,

            style: ElevatedButton.styleFrom(
              backgroundColor: isButtonEnabled
                  ? const Color(0xFF217BFF)
                  : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Add Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isButtonEnabled
                    ? Colors.white
                    : const Color(0xFF217BFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
