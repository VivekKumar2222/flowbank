import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  static const _bg      = Color(0xFFF5F7FA);
  static const _surface = Colors.white;
  static const _blue    = Color(0xFF0179FE);
  static const _green   = Color(0xFF10B981);
  static const _red     = Color(0xFFEF4444);

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/networth', context);
      if (res.statusCode == 200 && mounted) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _error = jsonDecode(res.body)['message'] ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ─── Liability dialogs ────────────────────────────────────────────────────

  Future<void> _showAddLiabilityDialog({Map? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing['amount'].toString() : '');
    String type = existing?['type'] ?? 'other';
    const types = ['credit_card', 'loan', 'mortgage', 'other'];
    const typeLabels = {'credit_card': 'Credit Card', 'loan': 'Loan', 'mortgage': 'Mortgage', 'other': 'Other'};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(existing != null ? 'Edit Liability' : 'Add Liability',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: _inputDecoration('Name (e.g. Car Loan)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Amount (\$)'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: types.map((t) => ChoiceChip(
                label: Text(typeLabels[t]!),
                selected: type == t,
                selectedColor: _blue.withOpacity(0.12),
                onSelected: (_) => setModal(() => type = t),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (name.isEmpty || amount == null || amount <= 0) return;
                  Navigator.pop(ctx);
                  if (existing != null) {
                    await ApiService.put('/api/networth/liability/${existing['_id']}',
                        {'name': name, 'type': type, 'amount': amount}, context);
                  } else {
                    await ApiService.post('/api/networth/liability',
                        {'name': name, 'type': type, 'amount': amount}, context);
                  }
                  _fetch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(existing != null ? 'Save Changes' : 'Add Liability'),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Future<void> _deleteLiability(String id) async {
    await ApiService.delete('/api/networth/liability/$id', context);
    _fetch();
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: Column(children: [
        _buildAppBar(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
            : _error != null ? _buildError()
            : _buildContent()),
      ])),
    );
  }

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.black87),
        ),
      ),
      const SizedBox(width: 14),
      const Text('Net Worth', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
      const Spacer(),
      GestureDetector(
        onTap: _fetch,
        child: Icon(Icons.refresh_rounded, color: Colors.grey.shade400, size: 22),
      ),
    ]),
  );

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.cloud_off_rounded, color: Colors.grey.shade300, size: 48),
    const SizedBox(height: 16),
    Text(_error ?? 'Something went wrong', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
    const SizedBox(height: 20),
    GestureDetector(onTap: _fetch, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12)),
      child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    )),
  ]));

  Widget _buildContent() {
    final current = _data!['current'] as Map<String, dynamic>;
    final liabilities = (_data!['liabilities'] as List?) ?? [];
    final history = (_data!['history'] as List?) ?? [];

    final netWorth = (current['netWorth'] as num).toDouble();
    final totalAssets = (current['totalAssets'] as num).toDouble();
    final totalLiab = (current['totalLiabilities'] as num).toDouble();
    final bankBal = (current['bankBalance'] as num).toDouble();
    final invVal = (current['investmentValue'] as num).toDouble();
    final goalSav = (current['goalSavings'] as num).toDouble();
    final isPositive = netWorth >= 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      color: _blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Net Worth Hero ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPositive
                    ? [const Color(0xFF0179FE), const Color(0xFF06B6D4)]
                    : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Net Worth', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 8),
              Text(
                '${isPositive ? '' : '-'}\$${netWorth.abs().toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Manrope'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _heroStat('Assets', '\$${totalAssets.toStringAsFixed(0)}'),
                Container(width: 1, height: 32, color: Colors.white.withOpacity(0.25), margin: const EdgeInsets.symmetric(horizontal: 20)),
                _heroStat('Liabilities', '\$${totalLiab.toStringAsFixed(0)}'),
              ]),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Asset Breakdown ───────────────────────────────────────────────
          _sectionLabel('Asset Breakdown'),
          const SizedBox(height: 10),
          _assetRow(Icons.account_balance_rounded, 'Bank Balance', bankBal, totalAssets),
          _assetRow(Icons.trending_up_rounded, 'Investments', invVal, totalAssets),
          _assetRow(Icons.savings_rounded, 'Goal Savings', goalSav, totalAssets),

          const SizedBox(height: 24),

          // ── Liabilities ───────────────────────────────────────────────────
          Row(children: [
            _sectionLabel('Liabilities'),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddLiabilityDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (liabilities.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: _green, size: 20),
                const SizedBox(width: 12),
                const Text('No liabilities added', style: TextStyle(fontSize: 14, color: Colors.black54)),
              ]),
            )
          else
            ...liabilities.map((l) => _liabilityTile(l)).toList(),

          // ── History Chart ─────────────────────────────────────────────────
          if (history.length >= 2) ...[
            const SizedBox(height: 24),
            _sectionLabel('Net Worth Over Time'),
            const SizedBox(height: 10),
            _buildHistoryChart(history),
          ],
        ]),
      ),
    );
  }

  Widget _heroStat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
  ]);

  Widget _sectionLabel(String label) => Text(label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.3));

  Widget _assetRow(IconData icon, String label, double value, double total) {
    final pct = total > 0 ? value / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _blue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(_blue),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
      ]),
    );
  }

  Widget _liabilityTile(dynamic l) {
    const typeIcons = {
      'credit_card': Icons.credit_card_rounded,
      'loan': Icons.account_balance_rounded,
      'mortgage': Icons.home_rounded,
      'other': Icons.receipt_long_rounded,
    };
    const typeLabels = {
      'credit_card': 'Credit Card', 'loan': 'Loan',
      'mortgage': 'Mortgage', 'other': 'Other',
    };
    final icon = typeIcons[l['type']] ?? Icons.receipt_long_rounded;
    final typeLabel = typeLabels[l['type']] ?? 'Other';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _red, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(typeLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ])),
        Text('\$${(l['amount'] as num).toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _red)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showAddLiabilityDialog(existing: l),
          child: Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _deleteLiability(l['_id'].toString()),
          child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey.shade400),
        ),
      ]),
    );
  }

  Widget _buildHistoryChart(List history) {
    final values = history.map((h) => (h['netWorth'] as num).toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${history.length} snapshots', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const Spacer(),
          Text('\$${values.last.toStringAsFixed(0)} now',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: values.last >= values.first ? _green : _red)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((e) {
              final h = range > 0 ? ((e.value - minVal) / range) * 65 + 10 : 40.0;
              final isLast = e.key == values.length - 1;
              final isPositive = e.value >= 0;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: isPositive
                        ? _blue.withOpacity(isLast ? 1.0 : 0.4)
                        : _red.withOpacity(isLast ? 1.0 : 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Oldest', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          Text('Today', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ]),
      ]),
    );
  }
}
