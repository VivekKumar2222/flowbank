import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';

class InvestmentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> investment;
  final VoidCallback onRefresh;

  const InvestmentDetailSheet({super.key, required this.investment, required this.onRefresh});

  @override
  State<InvestmentDetailSheet> createState() => _InvestmentDetailSheetState();
}

class _InvestmentDetailSheetState extends State<InvestmentDetailSheet> {
  static const _blue      = Color(0xFF217BFF);
  static const _green     = Color(0xFF10B981);
  static const _red       = Color(0xFFE53935);
  static const _textDark  = Color(0xFF1A1F36);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);
  static const _border    = Color(0xFFE2E8F0);

  Map<String, dynamic>? _roi;
  bool _loadingRoi = false;
  bool _requiresManualPrice = false;

  @override
  void initState() {
    super.initState();
    _requiresManualPrice = widget.investment['requiresManualPrice'] == true;
  }

  Color get _typeColor {
    switch (widget.investment['type']) {
      case 'stock':       return const Color(0xFF1E88E5);
      case 'crypto':      return const Color(0xFFF59E0B);
      case 'real_estate': return const Color(0xFF10B981);
      case 'business':    return const Color(0xFF7C3AED);
      default:            return const Color(0xFF64748B);
    }
  }

  double get _totalInvested {
    final buys = (widget.investment['buyEntries'] as List?) ?? [];
    return buys.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0));
  }

  double get _totalUnits {
    final buys = (widget.investment['buyEntries'] as List?) ?? [];
    final w = (widget.investment['withdrawalEntries'] as List?) ?? [];
    return buys.fold(0.0, (s, e) => s + ((e['unitsAcquired'] as num?)?.toDouble() ?? 0.0))
      - w.fold(0.0, (s, e) => s + ((e['unitsWithdrawn'] as num?)?.toDouble() ?? 0.0));
  }

  Future<void> _fetchRoi(double price) async {
    setState(() => _loadingRoi = true);
    try {
      final id = widget.investment['_id'];
      final res = await ApiService.post('/api/investments/$id/roi', {'currentPrice': price}, context);
      if (res.statusCode == 200 && mounted) {
        setState(() => _roi = jsonDecode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoi = false);
  }

  Future<void> _autoFetchRoi() async {
    final ticker = widget.investment['ticker'];
    if (ticker == null || ticker.toString().isEmpty || _requiresManualPrice) {
      _showManualPriceDialog(onPrice: _fetchRoi);
      return;
    }
    setState(() => _loadingRoi = true);
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/investments/price?ticker=$ticker', context);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        await _fetchRoi((data['price'] as num).toDouble());
      } else {
        if (mounted) _showManualPriceDialog(onPrice: _fetchRoi);
      }
    } catch (_) {
      if (mounted) _showManualPriceDialog(onPrice: _fetchRoi);
    }
    if (mounted) setState(() => _loadingRoi = false);
  }

  void _showManualPriceDialog({required void Function(double) onPrice}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Current Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) { Navigator.pop(context); onPrice(val); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            child: const Text('Calculate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<double?> _fetchLivePrice() async {
    final ticker = widget.investment['ticker'];
    if (ticker == null || ticker.toString().isEmpty || _requiresManualPrice) return null;
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/investments/price?ticker=$ticker', context);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['price'] as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  Widget _livePriceBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF10B981)),
      SizedBox(width: 3),
      Text('Live price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
    ]),
  );

  Future<void> _showBuySheet() async {
    final autoPrice = await _fetchLivePrice();
    if (!mounted) return;

    final amtCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: autoPrice != null ? autoPrice.toStringAsFixed(2) : '');
    bool submitting = false;

    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              const Text('Add Investment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
              const SizedBox(height: 16),
              const Text('Amount (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
              const SizedBox(height: 8),
              TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Price Per Unit (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                const Spacer(),
                if (autoPrice != null) _livePriceBadge(),
              ]),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: amtCtrl.text.isEmpty || priceCtrl.text.isEmpty || submitting ? null : () async {
                    setSt(() => submitting = true);
                    final id = widget.investment['_id'];
                    // ignore: use_build_context_synchronously
                    final res = await ApiService.post('/api/investments/$id/buy', {
                      'amount': double.parse(amtCtrl.text),
                      'priceAtPurchase': double.parse(priceCtrl.text),
                    }, ctx);
                    if (res.statusCode == 200) {
                      widget.onRefresh();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                    if (ctx.mounted) setSt(() => submitting = false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _blue, disabledBackgroundColor: _blue.withOpacity(0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Buy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showWithdrawSheet() async {
    final autoPrice = await _fetchLivePrice();
    if (!mounted) return;

    final unitsCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: autoPrice != null ? autoPrice.toStringAsFixed(2) : '');
    bool submitting = false;

    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              const Text('Withdraw', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
              const SizedBox(height: 4),
              Text('You hold ${_totalUnits.toStringAsFixed(6)} units', style: const TextStyle(fontSize: 13, color: _textLight)),
              const SizedBox(height: 16),
              const Text('Units to Withdraw', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
              const SizedBox(height: 8),
              TextField(controller: unitsCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(hintText: '0.000000', filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Current Price Per Unit (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                const Spacer(),
                if (autoPrice != null) _livePriceBadge(),
              ]),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: unitsCtrl.text.isEmpty || priceCtrl.text.isEmpty || submitting ? null : () async {
                    setSt(() => submitting = true);
                    final id = widget.investment['_id'];
                    // ignore: use_build_context_synchronously
                    final res = await ApiService.post('/api/investments/$id/withdraw', {
                      'unitsWithdrawn': double.parse(unitsCtrl.text),
                      'priceAtWithdrawal': double.parse(priceCtrl.text),
                    }, ctx);
                    if (res.statusCode == 200) {
                      widget.onRefresh();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                    if (ctx.mounted) setSt(() => submitting = false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), disabledBackgroundColor: _red.withOpacity(0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Withdrawal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showCloseDialog() async {
    final autoPrice = await _fetchLivePrice();
    if (!mounted) return;

    final priceCtrl = TextEditingController(text: autoPrice != null ? autoPrice.toStringAsFixed(2) : '');
    bool submitting = false;

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Close Investment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Enter the closing price per unit to calculate your final P&L.', style: TextStyle(fontSize: 13, color: _textLight)),
            const SizedBox(height: 14),
            if (autoPrice != null) ...[
              _livePriceBadge(),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Closing price per unit'),
              autofocus: autoPrice == null,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: priceCtrl.text.isEmpty || submitting ? null : () async {
                setSt(() => submitting = true);
                final id = widget.investment['_id'];
                // ignore: use_build_context_synchronously
                final res = await ApiService.post('/api/investments/$id/close', {
                  'closingPrice': double.parse(priceCtrl.text),
                }, ctx);
                if (res.statusCode == 200 && ctx.mounted) {
                  final data = jsonDecode(res.body);
                  final pl = (data['summary']?['unrealisedPL'] as num?)?.toDouble() ?? 0.0;
                  Navigator.pop(ctx);
                  widget.onRefresh();
                  if (mounted) Navigator.pop(context);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Investment closed. Total P&L: ${pl >= 0 ? '+' : ''}\$${pl.toStringAsFixed(2)}'),
                    backgroundColor: pl >= 0 ? _green : _red,
                  ));
                }
                if (ctx.mounted) setSt(() => submitting = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _red),
              child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Close Investment', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final pl = _roi != null ? (_roi!['unrealisedPL'] as num?)?.toDouble() : null;
    final roi = _roi != null ? (_roi!['unrealisedROI'] as num?)?.toDouble() : null;
    final thisPeriod = _roi != null ? (_roi!['thisperiodInvested'] as num?)?.toDouble() : null;
    final lastPeriod = _roi != null ? (_roi!['lastPeriodInvested'] as num?)?.toDouble() : null;
    final totalROI = _roi != null ? (_roi!['totalROI'] as num?)?.toDouble() : null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(_typeIconFor(widget.investment['type']), color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.investment['name'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark, fontFamily: 'Manrope')),
              if (widget.investment['ticker'] != null)
                Text(widget.investment['ticker'], style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            ])),
          ]),

          const SizedBox(height: 20),

          // Stats row
          Row(children: [
            _statBox('Total Invested', '\$${_totalInvested.toStringAsFixed(2)}', _textDark),
            const SizedBox(width: 10),
            _statBox('Units Held', _totalUnits.toStringAsFixed(4), color),
          ]),

          const SizedBox(height: 10),

          // ROI section
          GestureDetector(
            onTap: _loadingRoi ? null : _autoFetchRoi,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _roi == null ? _bgGrey : (pl != null && pl >= 0 ? _green.withOpacity(0.07) : _red.withOpacity(0.07)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _roi == null ? _border : (pl != null && pl >= 0 ? _green : _red), width: 1.2),
              ),
              child: _loadingRoi
                  ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)))
                  : _roi == null
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.analytics_rounded, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text('Check ROI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Unrealised P&L', style: TextStyle(fontSize: 12, color: pl != null && pl >= 0 ? _green : _red, fontWeight: FontWeight.w600)),
                            GestureDetector(onTap: _autoFetchRoi, child: const Icon(Icons.refresh_rounded, size: 16, color: _textLight)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text(
                              pl != null ? '${pl >= 0 ? '+' : ''}\$${pl.toStringAsFixed(2)}' : '—',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: pl != null && pl >= 0 ? _green : _red),
                            ),
                            const SizedBox(width: 10),
                            if (roi != null) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: (roi >= 0 ? _green : _red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roi >= 0 ? _green : _red)),
                            ),
                          ]),
                          if (thisPeriod != null || lastPeriod != null || totalROI != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(children: [
                              if (thisPeriod != null) _miniStat('This Period', '\$${thisPeriod.toStringAsFixed(2)}', _textDark),
                              if (lastPeriod != null) _miniStat('Last Period', '\$${lastPeriod.toStringAsFixed(2)}', _textDark),
                              if (totalROI != null) _miniStat('Total ROI', '${totalROI >= 0 ? '+' : ''}${totalROI.toStringAsFixed(2)}%', totalROI >= 0 ? _green : _red),
                            ]),
                          ],
                        ]),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(children: [
            Expanded(child: _actionBtn('Buy More', Icons.add_rounded, _blue, _showBuySheet)),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Withdraw', Icons.remove_rounded, const Color(0xFFE53935), _showWithdrawSheet)),
          ]),
          const SizedBox(height: 10),
          _actionBtn('Close Investment', Icons.lock_outline_rounded, const Color(0xFF64748B), _showCloseDialog, full: true),
        ]),
      ),
    );
  }

  IconData _typeIconFor(String? type) {
    switch (type) {
      case 'stock':       return Icons.show_chart_rounded;
      case 'crypto':      return Icons.currency_bitcoin_rounded;
      case 'real_estate': return Icons.apartment_rounded;
      case 'business':    return Icons.business_center_rounded;
      default:            return Icons.trending_up_rounded;
    }
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: _textLight)),
    ]),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool full = false}) {
    final w = GestureDetector(
      onTap: onTap,
      child: Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
    return full ? w : w;
  }
}
