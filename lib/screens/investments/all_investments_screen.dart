import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import 'create_investment_screen.dart';
import 'closed_investments_screen.dart';
import 'investment_detail_sheet.dart';

class AllInvestmentsScreen extends StatefulWidget {
  const AllInvestmentsScreen({super.key});

  @override
  State<AllInvestmentsScreen> createState() => _AllInvestmentsScreenState();
}

class _AllInvestmentsScreenState extends State<AllInvestmentsScreen> {
  static const _blue   = Color(0xFF1E88E5);
  static const _textDark  = Color(0xFF1A1F36);
  static const _textMid   = Color(0xFF475467);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);
  static const _border    = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> _investments = [];
  bool _loading = true;
  String _userName = 'User';
  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchInvestments();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userInitials = prefs.getString('userInitials') ?? 'U';
    });
  }

  Future<void> _fetchInvestments() async {
    try {
      final res = await ApiService.get('/api/investments/active', context);
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _investments = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreateInvestmentScreen()),
        ).then((_) => _fetchInvestments()),
        backgroundColor: _blue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Investment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Manrope')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
          : _investments.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchInvestments,
                  color: _blue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _investments.length,
                    itemBuilder: (_, i) => _InvestmentTile(
                      investment: _investments[i],
                      onRefresh: _fetchInvestments,
                    ),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.0),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 26, bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Investments',
                              style: TextStyle(
                                fontSize: 28,
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                                height: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Color(0xFF0179FE),
                                fontSize: 28,
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ClosedInvestmentsScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.history_rounded, size: 15, color: Color(0xFF475467)),
                                SizedBox(width: 5),
                                Text('Closed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475467), fontFamily: 'Manrope')),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.trending_up_rounded, color: _textLight, size: 34)),
      const SizedBox(height: 16),
      const Text('No investments yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
      const SizedBox(height: 6),
      const Text('Tap "Add Investment" to start tracking', style: TextStyle(fontSize: 13, color: _textLight)),
    ]));
  }
}

// ─── Investment Tile ──────────────────────────────────────────────────────────

class _InvestmentTile extends StatelessWidget {
  final Map<String, dynamic> investment;
  final VoidCallback onRefresh;

  const _InvestmentTile({required this.investment, required this.onRefresh});

  static const _textDark  = Color(0xFF1A1F36);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);

  Color get _typeColor {
    switch (investment['type']) {
      case 'stock':       return const Color(0xFF1E88E5);
      case 'crypto':      return const Color(0xFFF59E0B);
      case 'real_estate': return const Color(0xFF10B981);
      case 'business':    return const Color(0xFF7C3AED);
      default:            return const Color(0xFF64748B);
    }
  }

  IconData get _typeIcon {
    switch (investment['type']) {
      case 'stock':       return Icons.show_chart_rounded;
      case 'crypto':      return Icons.currency_bitcoin_rounded;
      case 'real_estate': return Icons.apartment_rounded;
      case 'business':    return Icons.business_center_rounded;
      default:            return Icons.trending_up_rounded;
    }
  }

  String get _typeLabel {
    switch (investment['type']) {
      case 'stock':       return 'Stock';
      case 'crypto':      return 'Crypto';
      case 'real_estate': return 'Real Estate';
      case 'business':    return 'Business';
      default:            return 'Other';
    }
  }

  double get _totalInvested {
    final buys = (investment['buyEntries'] as List?) ?? [];
    return buys.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0));
  }

  double get _totalUnits {
    final buys = (investment['buyEntries'] as List?) ?? [];
    final withdrawals = (investment['withdrawalEntries'] as List?) ?? [];
    final bought = buys.fold(0.0, (s, e) => s + ((e['unitsAcquired'] as num?)?.toDouble() ?? 0.0));
    final withdrawn = withdrawals.fold(0.0, (s, e) => s + ((e['unitsWithdrawn'] as num?)?.toDouble() ?? 0.0));
    return bought - withdrawn;
  }

  String _fmtFreq(String f) {
    switch (f) {
      case 'weekly':   return 'Weekly';
      case 'monthly':  return 'Monthly';
      case 'yearly':   return 'Yearly';
      case 'one_time': return 'One-Time';
      default:         return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InvestmentDetailSheet(
          investment: investment,
          onRefresh: onRefresh,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(_typeIcon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(investment['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark, fontFamily: 'Manrope'), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(_typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
                const SizedBox(width: 6),
                Text(_fmtFreq(investment['frequency'] ?? ''), style: const TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w500)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${_totalInvested.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text('invested', style: const TextStyle(fontSize: 11, color: _textLight)),
            ]),
          ]),
          if (_totalUnits > 0) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: color.withOpacity(0.1)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_totalUnits.toStringAsFixed(4)} units held',
                style: const TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w500)),
              Text('Target: \$${((investment['targetAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}/period',
                style: const TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w500)),
            ]),
          ],
        ]),
      ),
    );
  }
}
