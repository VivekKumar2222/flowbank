import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../screens/onboarding/OnboardingScreen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/session_expired.dart';

class ApiService {
  static final String baseUrl = kIsWeb
      ? "http://localhost:5000"
      : "http://10.0.2.2:5000";

  static http.Client _client() {
    if (kIsWeb) return http.Client();
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 5);
    httpClient.autoUncompress = true;
    return IOClient(httpClient);
  }

  // ================= HEADERS =================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Connection": "close", // 🔥 THIS FIXES NGROK
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

  // ⏳ Wait 2.5 seconds
  await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // remove token + user info

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SessionExpiredScreen()),
      (route) => false,
    );
  }

  // ================= GET =================
  static Future<http.Response> get(String endpoint, BuildContext context) async {
    final client = _client();
    final response = await client.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
    );
    client.close();
    if (response.statusCode == 401) {
      // session expired
      _handleUnauthorized(context);
    }
    return response;
  }

  // ================= POST =================
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, BuildContext context
  ) async {
    final client = _client();
    final response = await client.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    client.close();
    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }
    return response;
  }

  // ================= PUT =================
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, BuildContext context
  ) async {
    final client = _client();
    final response = await client.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    client.close();

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }

  // ================= PATCH =================
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, BuildContext context
  ) async {
    final client = _client();
    final response = await client.patch(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    client.close();
    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }
    return response;
  }

  // ================= DELETE =================
  static Future<http.Response> delete(String endpoint, BuildContext context) async {
    final client = _client();
    final response = await client.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: await _headers(),
    );
    client.close();

    if (response.statusCode == 401) {
      _handleUnauthorized(context);
    }

    return response;
  }
}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class ApiService {
//   // static const String baseUrl = "http://10.0.2.2:5000";
//   static const String baseUrl =
//       "https://dagmar-bioelectric-varietally.ngrok-free.dev";

//   // ================= GET =================
//   static Future<http.Response> get(String endpoint) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     return http.get(
//       Uri.parse("$baseUrl$endpoint"),
//       headers: {
//         "Content-Type": "application/json",
//         if (token != null) "Authorization": "Bearer $token",
//       },
//     );
//   }

//   // ================= POST =================
//   static Future<http.Response> post(
//     String endpoint,
//     Map<String, dynamic> body,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     return http.post(
//       Uri.parse("$baseUrl$endpoint"),
//       headers: {
//         "Content-Type": "application/json",
//         if (token != null) "Authorization": "Bearer $token",
//       },
//       body: jsonEncode(body),
//     );
//   }

//   // ================= PUT =================
//   static Future<http.Response> put(
//     String endpoint,
//     Map<String, dynamic> body,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     return http.put(
//       Uri.parse("$baseUrl$endpoint"),
//       headers: {
//         "Content-Type": "application/json",
//         if (token != null) "Authorization": "Bearer $token",
//       },
//       body: jsonEncode(body),
//     );
//   }

//   // ================= DELETE =================
//   static Future<http.Response> delete(String endpoint) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     return http.delete(
//       Uri.parse("$baseUrl$endpoint"),
//       headers: {
//         "Content-Type": "application/json",
//         if (token != null) "Authorization": "Bearer $token",
//       },
//     );
//   }
// }
