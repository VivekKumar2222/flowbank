import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/participant.dart';

// Convert TransactionType ↔ String
String _typeToString(TransactionType t) =>
    t == TransactionType.owed ? 'owed' : 'owing';
TransactionType _typeFromString(String s) =>
    s == 'owed' ? TransactionType.owed : TransactionType.owing;

class SettlementsApi {
  // ✅ Choose ONE URL based on your setup:
  // For Flutter web (Chrome)
  static const String baseUrl = 'http://localhost:5000/api';

  final String userId; // MongoDB user _id
  SettlementsApi({required this.userId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-user-id': userId,
  };

  /// Fetch all settlements
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final r = await http.get(
      Uri.parse('$baseUrl/settlements'),
      headers: _headers,
    );
    if (r.statusCode != 200) {
      throw Exception('Fetch failed: ${r.statusCode} ${r.body}');
    }
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  /// Create settlement
  Future<Map<String, dynamic>> create({
    String title = 'Connected Settlements',
    required List<Participant> participants,
  }) async {
    final body = jsonEncode({
      'title': title,
      'participants': participants
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'initials': p.initials,
              'amount': p.amount,
              'type': _typeToString(p.type),
              'note': p.note,
            },
          )
          .toList(),
    });

    final r = await http.post(
      Uri.parse('$baseUrl/settlements'),
      headers: _headers,
      body: body,
    );
    if (r.statusCode != 201) {
      throw Exception('Create failed: ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Update settlement
  Future<Map<String, dynamic>> update({
    required String id,
    String? title,
    List<Participant>? participants,
  }) async {
    final body = jsonEncode({
      if (title != null) 'title': title,
      if (participants != null)
        'participants': participants
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'initials': p.initials,
                'amount': p.amount,
                'type': _typeToString(p.type),
                'note': p.note,
              },
            )
            .toList(),
    });

    final r = await http.put(
      Uri.parse('$baseUrl/settlements/$id'),
      headers: _headers,
      body: body,
    );
    if (r.statusCode != 200) {
      throw Exception('Update failed: ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Delete settlement
  Future<void> delete(String id) async {
    final r = await http.delete(
      Uri.parse('$baseUrl/settlements/$id'),
      headers: _headers,
    );
    if (r.statusCode != 204) {
      throw Exception('Delete failed: ${r.statusCode} ${r.body}');
    }
  }
}
