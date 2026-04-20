import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flowbank/api/api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use your Web Client ID here (same one as in AndroidManifest)
    serverClientId: '712252945401-hqi28ea7p66rc33hdnltt9ctavtg9rin.apps.googleusercontent.com',
  );

  /// Call this from Login or Signup modal.
  /// Returns the user map on success, null on failure/cancel.
  static Future<Map<String, dynamic>?> signInWithGoogle(
    BuildContext context,
  ) async {
    try {
      // Sign out first to always show account picker
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google idToken is null');
      }

      // Send idToken to your backend
      final response = await ApiService.post(
        '/api/auth/google',
        {'idToken': idToken},
        context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // { token, user: { name, email, ... } }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Google login failed');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }
}