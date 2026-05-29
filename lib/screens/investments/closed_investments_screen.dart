import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';

class ClosedInvestmentsScreen extends StatefulWidget {
  const ClosedInvestmentsScreen({super.key});

  @override
  State<ClosedInvestmentsScreen> createState() => _ClosedInvestmentsScreenState();
}

class _ClosedInvestmentsScreenState extends State<ClosedInvestmentsScreen> {
  static const _blue      = Color(0xFF1E88E5);
  static const _textDark  = Color(0xFF1A1F36);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);

  List<Map<String, dynamic>> _investments = [];
  bool _loading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchClosed();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userName = prefs.getString('userName') ?? 'User');
  }

  Future<void> _fetchClosed() async {
    try {
      final res = await ApiService.get('/api/investments/closed', context);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue))
          : _investments.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchClosed,
                  color: _blue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: _investments.length,
                    itemBuilder: (_, i) => _ClosedTile(investment: _investments[i]),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textDark),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Closed Investments',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
                  Text(_userName, style: const TextStyle(fontSize: 14, color: _blue, fontWeight: FontWeight.w500)),
                ]),
              ],
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
          child: const Icon(Icons.history_rounded, color: _textLight, size: 34)),
      const SizedBox(height: 16),
      const Text('No closed investments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
      const SizedBox(height: 6),
      const Text('Closed investments will appear here', style: TextStyle(fontSize: 13, color: _textLight)),
    ]));
  }
}

// ─── Closed Investment Tile ───────────────────────────────────────────────────

class _ClosedTile extends StatelessWidget {
  final Map<String, dynamic> investment;
  const _ClosedTile({required this.investment});

  static const _textDark  = Color(0xFF1A1F36);
  static const _textMid   = Color(0xFF475467);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);
  static const _green     = Color(0xFF10B981);
  static const _red       = Color(0xFFE53935);


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

  String _fmtDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final pl = (investment['totalProfitLoss'] as num?)?.toDouble() ?? 0.0;
    final isProfit = pl >= 0;
    final plColor = isProfit ? _green : _red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(investment['name'] ?? '',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: _textDark, fontFamily: 'Manrope'),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_typeLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Closed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMid)),
              ),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isProfit ? '+' : ''}\$${pl.abs().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: plColor),
            ),
            const SizedBox(height: 2),
            Text(isProfit ? 'profit' : 'loss',
                style: TextStyle(fontSize: 11, color: plColor.withOpacity(0.7))),
          ]),
        ]),
        const SizedBox(height: 10),
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Invested', style: TextStyle(fontSize: 11, color: _textLight)),
            const SizedBox(height: 2),
            Text('\$${_totalInvested.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
          ]),
          if (investment['closingPrice'] != null)
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text('Closing Price', style: TextStyle(fontSize: 11, color: _textLight)),
              const SizedBox(height: 2),
              Text('\$${(investment['closingPrice'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Closed On', style: TextStyle(fontSize: 11, color: _textLight)),
            const SizedBox(height: 2),
            Text(_fmtDate(investment['closedAt']?.toString()),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
          ]),
        ]),
      ]),
    );
  }
}
