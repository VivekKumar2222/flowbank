import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/participant.dart';
import '../../widgets/settle_up/participant_card.dart';
import '../../widgets/settle_up/add_participant_modal.dart';
import '../../api/settlements_api.dart';
import '../home/homescreen.dart';

// Transaction type helper
String _typeToString(TransactionType t) =>
    t == TransactionType.owed ? 'owed' : 'owing';
TransactionType _typeFromString(String s) =>
    s == 'owed' ? TransactionType.owed : TransactionType.owing;

class SettleUpScreen extends StatefulWidget {
  const SettleUpScreen({Key? key}) : super(key: key);

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  // ===== CONFIG =====
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // <-- or 10.0.2.2 for Android
  String? currentUserId;
  // replace with your MongoDB user's _id

  // ===== STATE =====
  List<Participant> participants = [];
  String? settlementId;
  bool loading = true;
  String? error;

  // ===== API HELPERS =====
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-user-id': currentUserId ?? '',
  };

  Future<void> _loadData() async {
    try {
      setState(() => loading = true);
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('userId');

      if (currentUserId == null || currentUserId!.isEmpty) {
        error = 'User session not found. Please log in again.';
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/settlements'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final doc = data.first;
          settlementId = doc['_id'];
          final List parts = doc['participants'];
          participants = parts.map((e) {
            return Participant(
              id: e['id'],
              name: e['name'],
              initials: e['initials'],
              amount: (e['amount'] as num).toDouble(),
              type: _typeFromString(e['type']),
              note: e['note'],
            );
          }).toList();
        } else {
          participants = [];
        }
      } else {
        error = 'Failed to load (${res.statusCode})';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _persist() async {
    final body = jsonEncode({
      'title': 'Connected Settlements',
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

    if (settlementId == null) {
      final res = await http.post(
        Uri.parse('$baseUrl/settlements'),
        headers: _headers,
        body: body,
      );
      if (res.statusCode == 201) {
        settlementId = jsonDecode(res.body)['_id'];
      }
    } else {
      await http.put(
        Uri.parse('$baseUrl/settlements/$settlementId'),
        headers: _headers,
        body: body,
      );
    }
  }

  // ===== CRUD =====
  void _addParticipant(Participant participant) async {
    if (participant.amount <= 0 || participant.name.trim().isEmpty) {
      // prevent empty or invalid entries
      return;
    }

    // prevent duplicates
    bool alreadyExists = participants.any((p) => p.name == participant.name);
    if (alreadyExists) return;

    setState(() => participants.add(participant));
    await _persist();
  }

  void _updateParticipant(Participant updated) async {
    if (updated.amount <= 0 || updated.name.trim().isEmpty) return;

    setState(() {
      final index = participants.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        participants[index] = updated;
      }
    });

    await _persist();
    setState(() {}); // refresh totals
  }

  void _deleteParticipant(String id) async {
    setState(() => participants.removeWhere((p) => p.id == id));
    await _persist();
  }

  // ===== CALCULATIONS =====
  double _calculateTotalOwed() => participants
      .where((p) => p.type == TransactionType.owed)
      .fold(0.0, (sum, p) => sum + p.amount);

  double _calculateTotalOwing() => participants
      .where((p) => p.type == TransactionType.owing)
      .fold(0.0, (sum, p) => sum + p.amount);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final totalOwed = _calculateTotalOwed();
    final totalOwing = _calculateTotalOwing();

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error: $error')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settle-Up',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage settlements with friends',
                          style: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        showAddParticipantModal(
                          context,
                          onAdd: _addParticipant,
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // You Owe Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You Owe',
                              style: TextStyle(
                                color: const Color(0xFFE65100),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalOwing.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // You're Owed Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You\'re Owed',
                              style: TextStyle(
                                color: const Color(0xFF2E7D32),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalOwed.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Participants header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Connected Settlements',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Participants list
              if (participants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.handshake_outlined,
                          size: 56,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No settlements yet',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap the + button to add participants',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: participants.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < participants.length - 1 ? 12 : 0,
                        ),
                        child: ParticipantCard(
                          participant: participants[index],
                          onEdit: () {
                            showEditParticipantModal(
                              context,
                              participant: participants[index],
                              onUpdate: _updateParticipant,
                            );
                          },
                          onDelete: () =>
                              _deleteParticipant(participants[index].id),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: const Color(0xFFBDBDBD),
        currentIndex: 1, // highlight Settle-Up here
        onTap: (index) {
          if (index == 0) {
            // go back to Home
            Navigator.pop(context);
            // (or use pushReplacement to be explicit)
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Settle-Up',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
