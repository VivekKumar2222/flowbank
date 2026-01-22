import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flowbank/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flowbank/api/api_service.dart';

class AddEntriesPage extends StatefulWidget {
  final String dashboardId;
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

  File? _verificationImage;            // UI preview only
  Uint8List? _verificationImageBytes;  // actual data sent
  final ImagePicker _picker = ImagePicker();

  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<String?> _uploadToCloudinary(Uint8List bytes) async {
  final uri = Uri.parse(
    "https://api.cloudinary.com/v1_1/dzuc4aors/image/upload",
  );

  final request = http.MultipartRequest("POST", uri)
    ..fields["upload_preset"] = "verification_unsigned"
    ..files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: "verification.jpg",
      ),
    );

  final response = await request.send();

  if (response.statusCode == 200) {
    final resStr = await response.stream.bytesToString();
    final data = jsonDecode(resStr);
    return data["secure_url"];
  }

  return null;
}


  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'user';
    });
  }

  /// ✔ Allow only JPEG / PNG
  bool _isSupportedImage(Uint8List bytes) {
    // JPEG
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }

    // PNG
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    return false;
  }

  void _showInvalidImageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Invalid Image"),
        content: const Text(
          "Only JPEG and PNG images are allowed.\nPlease select a valid image.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final Uint8List bytes = await pickedFile.readAsBytes();

    if (!_isSupportedImage(bytes)) {
      _showInvalidImageDialog();
      return;
    }

    setState(() {
      _verificationImageBytes = bytes;
      _verificationImage = File(pickedFile.path);
    });
  }

  Future<void> _submitEntry() async {
  if (_verificationImageBytes == null) return;

  final amount = double.tryParse(_amountController.text);
  if (amount == null || amount <= 0) return;

  final imageUrl = await _uploadToCloudinary(_verificationImageBytes!);
  if (imageUrl == null) {
    debugPrint("Cloudinary upload failed");
    return;
  }

  final Map<String, dynamic> body = {
    "dashboardId": widget.dashboardId,
    "userId": userEmail,
    "amount": amount,
    "verificationImage": imageUrl, // ✅ URL now
  };

  if (widget.assignmentId != null) {
    body["assignmentId"] = widget.assignmentId;
  }

  final response = await ApiService.post(
  "/api/collab/dashboard-entry",
  body,
  context
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 24),

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
                            Icon(Icons.upload_file,
                                size: 40, color: Color(0xFF217BFF)),
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
