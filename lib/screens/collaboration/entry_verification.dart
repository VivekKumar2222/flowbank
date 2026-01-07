import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/* ============================================================
   ENTRY VERIFICATION PAGE (FETCH BY ENTRY ID)
============================================================ */

class EntryVerificationPage extends StatefulWidget {
  final String entryId;

  const EntryVerificationPage({
    super.key,
    required this.entryId,
  });

  @override
  State<EntryVerificationPage> createState() => _EntryVerificationPageState();
}

class _EntryVerificationPageState extends State<EntryVerificationPage> {
  bool isLoading = true;

  String title = "";
  String subtitle = "";
  String date = "";
  double amount = 0;
  String verificationImage = "";

  @override
  void initState() {
    super.initState();
    _fetchEntry();
  }

  Future<void> _fetchEntry() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2:5000/api/collab/dashboard-entry/${widget.entryId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          title = data["userId"] ?? "Unknown";
          subtitle = data["status"] ?? "";
          date = data["createdAt"] ?? "";
          amount = (data["amount"] ?? 0).toDouble();
          verificationImage = data["verificationImage"] ?? "";
          isLoading = false;
        });

        debugPrint("✅ ENTRY FETCHED: ${widget.entryId}");
      } else {
        debugPrint("❌ Entry fetch failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  VerificationImage(
                    imageData: verificationImage,
                  ),
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
   HEADER (UNCHANGED)
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
            style: TextStyle(fontSize: 14, color: Colors.white70),
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
   IMAGE (BASE64 FROM MONGODB)
============================================================ */

class VerificationImage extends StatelessWidget {
  final String imageData;

  const VerificationImage({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    if (imageData.isEmpty) {
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
        base64Decode(imageData),
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
