import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flowbank/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


/* ============================================================
   ENTRY VERIFICATION PAGE (FETCH BY ENTRY ID)
============================================================ */

class EntryVerificationPage extends StatefulWidget {
  final String entryId;
  final String name;

  const EntryVerificationPage({
    super.key,
    required this.entryId,
    required this.name,
  });

  @override
  State<EntryVerificationPage> createState() => _EntryVerificationPageState();
}

class _EntryVerificationPageState extends State<EntryVerificationPage> {
  bool isLoading = true;
  bool? ocrVerified;
  int? ocrScore;
  String title = "";
  String subtitle = "";
  String date = "";
  double amount = 0;
  String verificationImage = "";
  String ownerEmail = "";
  String userEmail = "";
  bool isOwner = false;


  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
  await _loadUserEmail();
  await _fetchOwner(widget.entryId);

  setState(() {
    isOwner = ownerEmail.trim() == userEmail.trim();
  });

  debugPrint("👑 OWNER EMAIL: $ownerEmail");
  debugPrint("🙋 USER EMAIL: $userEmail");
  debugPrint("✅ IS OWNER: $isOwner");

  await _fetchEntry();
}


  Future<void> _fetchOwner(String entryId) async {
  final response = await ApiService.get(
    "/api/collab/entry-owner/$entryId",
    context
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    ownerEmail = data['ownerId'] ?? "";
    print(ownerEmail);
    
  }
}

Future<void> _loadUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  userEmail = prefs.getString('userEmail') ?? '';
}



  Future<void> _fetchEntry() async {
    try {
      final response = await ApiService.get(
        "/api/collab/dashboard-entry/${widget.entryId}",
        context
        
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

          final ocrResponse = await ApiService.post(
  "/api/collab/verify-entry-ocr",
  {"entryId": widget.entryId},
  context
);

if (ocrResponse.statusCode == 200) {
  final ocrData = jsonDecode(ocrResponse.body);

  setState(() {
    ocrVerified = ocrData["verified"];
    ocrScore = ocrData["ocr"]?["totalScore"];
  });
}



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
            "Loading content",
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
    if (isLoading) {
      return _loadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _VerificationHeader(
            title: widget.name,
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
                  if (ocrVerified != null)
  _OcrStatusBox(
    verified: ocrVerified!,
    score: ocrScore!,
  ),
  const SizedBox(height: 16),

                   _ActionButtons(
                    entryId: widget.entryId,
                    isOwner: isOwner,),
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) =>
                _FullImageViewer(imageUrl: imageData),
          ),
        );
      },
      child: Hero(
        tag: imageData,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageData,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) {
              return const SizedBox(
                height: 280,
                child: Center(child: Text("Failed to load image")),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FullImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}



/* ============================================================
   ACTION BUTTONS (UNCHANGED)
============================================================ */

class _ActionButtons extends StatelessWidget {

  final String entryId;
  final bool isOwner;
  const _ActionButtons({
    
    required this.entryId,
    required this.isOwner,
    }
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
  child: Opacity(
    opacity: isOwner ? 1 : 0.4,
    child: ElevatedButton(
      onPressed: isOwner
          ? () async {
              await ApiService.post(
                "/api/collab/update-entry-status",
                {
                  "entryId": entryId,
                  "status": "rejected",
                },
                context
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Entry rejected")),
              );
            }
          : null,
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
),

        const SizedBox(width: 16),
        Expanded(
  child: Opacity(
    opacity: isOwner ? 1 : 0.4,
    child: ElevatedButton(
      onPressed: isOwner
          ? () async {
              await ApiService.post(
                "/api/collab/update-entry-status",
                {
                  "entryId": entryId,
                  "status": "approved",
                },
                context
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Entry approved")),
              );
            }
          : null,
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
),

      ],
    );
  }
}

class _OcrStatusBox extends StatefulWidget {
  final bool verified;
  final int score;

  const _OcrStatusBox({
    required this.verified,
    required this.score,
  });

  @override
  State<_OcrStatusBox> createState() => _OcrStatusBoxState();
}

class _OcrStatusBoxState extends State<_OcrStatusBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _glow = Tween(begin: 0.1, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.verified ? const Color(0xFF1B8E4B) : const Color(0xFFC62828);
    final bgColor =
        widget.verified ? const Color(0xFFE7F6EC) : const Color(0xFFFDECEC);

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(2), // Border thickness
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(_glow.value),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: baseColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.verified ? "Verified by AI" : "Not Matching",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: baseColor,
                  ),
                ),
                Text(
                  "Score: ${widget.score}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: baseColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


