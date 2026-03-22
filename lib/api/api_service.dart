import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/session_expired.dart';

class ApiService {
  // ✅ Use different URLs for web vs mobile/emulator
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
      //"https://dagmar-bioelectric-varietally.ngrok-free.dev";//"http://localhost:5000"; // web browser can access
    } else {
      return "http://10.0.2.2:5000"; // Android emulator
    }
  }

  // ================= HEADERS =================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Widget _loadingScreen() {
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

  static Future<void> _handleUnauthorized(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _loadingScreen()),
    );

    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SessionExpiredScreen()),
      (route) => false,
    );
  }

  // ================= GET =================
  static Future<http.Response> get(
    String endpoint,
    BuildContext context,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }

  // ================= POST =================
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
    BuildContext context,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }

  // ================= PUT =================
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
    BuildContext context,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }

  // ================= DELETE =================
  static Future<http.Response> delete(
    String endpoint,
    BuildContext context,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }
}
