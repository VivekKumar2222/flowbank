import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

/* ============================================================
   ENTRY VERIFICATION PAGE
============================================================ */

class EntryVerificationPage extends StatelessWidget {
  final String entryId;
  final String title;
  final String subtitle;
  final String date;
  final double amount;

  const EntryVerificationPage({
    super.key,
    required this.entryId,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _VerificationHeader(
            title: title,
            amount: amount,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  VerificationImage(entryId: entryId),
                  const SizedBox(height: 24),
                  const _ActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   HEADER
============================================================ */

class _VerificationHeader extends StatelessWidget {
  final String title;
  final double amount;

  const _VerificationHeader({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    final initials = title
        .split(" ")
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF4893FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFD1E9FF),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4893FF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Amount to Verify",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   IMAGE FETCH + DECRYPT
============================================================ */

class VerificationImage extends StatefulWidget {
  final String entryId;

  const VerificationImage({
    super.key,
    required this.entryId,
  });

  @override
  State<VerificationImage> createState() => _VerificationImageState();
}

class _VerificationImageState extends State<VerificationImage> {
  Uint8List? imageBytes;
  bool loading = true;

  // 🔐 SAME KEY & IV AS ENTRY CREATION
  final encrypt.Key _key =
      encrypt.Key.fromUtf8('0123456789abcdef0123456789abcdef');
  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

Future<void> _loadImage() async {
  try {
    debugPrint("STEP 1: API call start");

    final response = await http.get(
      Uri.parse(
        "http://10.0.2.2:5000/api/collab/dashboard-entry-image/${widget.entryId}",
      ),
    );

    debugPrint("STEP 2: API response received");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      debugPrint("STEP 3: JSON decoded");

      final encryptedString = decoded['verificationImage'];
      debugPrint(
        "STEP 4: encryptedString length = ${encryptedString?.length}",
      );

      if (encryptedString == null || encryptedString.isEmpty) {
        debugPrint("STEP 4A: encryptedString is NULL or EMPTY");

        setState(() {
          loading = false;
        });
        return;
      }

      debugPrint("STEP 5: compute() start");

final decryptedBytes = await compute(
  decryptImageInBackground,
  {
    "data": encryptedString,
    "key": _key.base64,
    "iv": _iv.base64,
  },
);

if (decryptedBytes.isEmpty) {
  debugPrint("Decryption returned empty bytes");

  setState(() {
    loading = false;
  });
  return;
}



      debugPrint(
        "STEP 6: compute() finished, bytes = ${decryptedBytes.length}",
      );

      if (!mounted) return;

      setState(() {
        imageBytes = decryptedBytes;
        loading = false;
      });

      debugPrint("STEP 7: setState done");
    } else {
      debugPrint("STEP X: API failed ${response.statusCode}");
      setState(() {
        loading = false;
      });
    }
  } catch (e, stack) {
    debugPrint("EXCEPTION: $e");
    debugPrint("$stack");

    setState(() {
      loading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (imageBytes == null) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: const Text(
          "No image for verification",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        imageBytes!,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

/* ============================================================
   ACTION BUTTONS (UNCHANGED)
============================================================ */

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2D2D2),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Reject",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF737373),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4893FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Verify",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Uint8List decryptImageInBackground(Map<String, dynamic> params) {
  try {
    final key = encrypt.Key.fromBase64(params['key']);
    final iv = encrypt.IV.fromBase64(params['iv']);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc,padding: 'PKCS7'),
    );

    final decryptedBytes = encrypter.decryptBytes(
      encrypt.Encrypted(base64Decode(params['data'])),
      iv: iv,
    );

    return Uint8List.fromList(decryptedBytes);
  } catch (e) {
    debugPrint("ISOLATE DECRYPT ERROR: $e");
    return Uint8List(0);
  }
}
