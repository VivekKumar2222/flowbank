import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';

class CreateInvestmentScreen extends StatefulWidget {
  const CreateInvestmentScreen({super.key});

  @override
  State<CreateInvestmentScreen> createState() => _CreateInvestmentScreenState();
}

class _CreateInvestmentScreenState extends State<CreateInvestmentScreen> {
  static const _blue  = Color(0xFF217BFF);
  static const _textDark  = Color(0xFF1A1F36);
  static const _textLight = Color(0xFF98A2B3);
  static const _bgGrey    = Color(0xFFF5F7FA);
  static const _border    = Color(0xFFE2E8F0);

  final _pageCtrl = PageController();
  int _page = 0;

  // selections
  String? _selectedType;
  String? _selectedName;
  String? _selectedTicker;
  String? _selectedFrequency;
  final _targetCtrl    = TextEditingController();
  final _initialAmtCtrl = TextEditingController();
  final _initialPriceCtrl = TextEditingController();
  final _nameCtrl      = TextEditingController();

  // search
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;
  Timer? _debounce;

  bool _submitting = false;
  bool _fetchingPrice = false;
  bool _priceFetched = false;

  static const _types = [
    {'key': 'stock',       'label': 'Stock',       'icon': Icons.show_chart_rounded,         'color': Color(0xFF1E88E5)},
    {'key': 'crypto',      'label': 'Crypto',      'icon': Icons.currency_bitcoin_rounded,   'color': Color(0xFFF59E0B)},
    {'key': 'real_estate', 'label': 'Real Estate', 'icon': Icons.apartment_rounded,          'color': Color(0xFF10B981)},
    {'key': 'business',    'label': 'Business',    'icon': Icons.business_center_rounded,    'color': Color(0xFF7C3AED)},
    {'key': 'other',       'label': 'Other',       'icon': Icons.trending_up_rounded,        'color': Color(0xFF64748B)},
  ];

  static const _frequencies = [
    {'key': 'weekly',   'label': 'Weekly',   'sub': 'Resets every week'},
    {'key': 'monthly',  'label': 'Monthly',  'sub': 'Resets every month'},
    {'key': 'yearly',   'label': 'Yearly',   'sub': 'Resets every year'},
    {'key': 'one_time', 'label': 'One-Time', 'sub': 'Single investment'},
    {'key': 'whenever', 'label': 'Whenever', 'sub': 'No fixed schedule'},
  ];

  bool get _needsSearch => _selectedType == 'stock' || _selectedType == 'crypto';
  bool get _canProceed {
    switch (_page) {
      case 0: return _selectedType != null;
      case 1: return _selectedName != null && _selectedName!.isNotEmpty;
      case 2: return _selectedFrequency != null;
      case 3: return _targetCtrl.text.isNotEmpty && double.tryParse(_targetCtrl.text) != null;
      case 4: return !_fetchingPrice &&
                     _initialAmtCtrl.text.isNotEmpty && _initialPriceCtrl.text.isNotEmpty &&
                     double.tryParse(_initialAmtCtrl.text) != null && double.tryParse(_initialPriceCtrl.text) != null;
      default: return false;
    }
  }

  void _next() {
    if (_page < 4) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      setState(() => _page++);
      if (_page == 4 && _selectedTicker != null) _fetchInitialPrice();
    } else {
      _submit();
    }
  }

  Future<void> _fetchInitialPrice() async {
    setState(() { _fetchingPrice = true; _priceFetched = false; });
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/investments/price?ticker=$_selectedTicker', context);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final price = (data['price'] as num).toDouble();
        _initialPriceCtrl.text = price.toStringAsFixed(2);
        setState(() => _priceFetched = true);
      }
    } catch (_) {}
    if (mounted) setState(() => _fetchingPrice = false);
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      setState(() => _page--);
    } else {
      Navigator.pop(context);
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.isEmpty) { setState(() => _suggestions = []); return; }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final res = await ApiService.get('/api/investments/search?query=$q&type=$_selectedType', context);
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() => _suggestions = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final body = {
        'name':           _selectedName,
        'ticker':         _selectedTicker,
        'type':           _selectedType,
        'frequency':      _selectedFrequency,
        'targetAmount':   double.parse(_targetCtrl.text),
        'initialAmount':  double.tryParse(_initialAmtCtrl.text) ?? 0,
        'initialPrice':   double.tryParse(_initialPriceCtrl.text) ?? 0,
      };
      // ignore: use_build_context_synchronously
      final res = await ApiService.post('/api/investments', body, context);
      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create. Try again.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose(); _searchCtrl.dispose(); _targetCtrl.dispose();
    _initialAmtCtrl.dispose(); _initialPriceCtrl.dispose(); _nameCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildStepper(),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPage0(),
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
                _buildPage4(),
              ],
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: _back,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textDark),
          ),
        ),
        const SizedBox(width: 14),
        const Text('New Investment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, fontFamily: 'Manrope')),
      ]),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(5, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
            decoration: BoxDecoration(
              color: i <= _page ? _blue : _border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _canProceed && !_submitting ? _next : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            disabledBackgroundColor: _blue.withOpacity(0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_page < 4 ? 'Continue' : 'Create Investment',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  // ── Page 0: Type ────────────────────────────────────────────────────────────
  Widget _buildPage0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Investment Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
        const SizedBox(height: 4),
        const Text('What are you investing in?', style: TextStyle(fontSize: 14, color: _textLight)),
        const SizedBox(height: 24),
        ..._types.map((t) {
          final key = t['key'] as String;
          final color = t['color'] as Color;
          final sel = _selectedType == key;
          return GestureDetector(
            onTap: () => setState(() { _selectedType = key; _selectedName = null; _selectedTicker = null; _suggestions = []; _searchCtrl.clear(); }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.07) : _bgGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? color : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: sel ? color : color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(t['icon'] as IconData, color: sel ? Colors.white : color, size: 22),
                ),
                const SizedBox(width: 14),
                Text(t['label'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: sel ? color : _textDark)),
                const Spacer(),
                if (sel) Icon(Icons.check_circle_rounded, color: color, size: 20),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // ── Page 1: Name / Ticker ────────────────────────────────────────────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Name Your Investment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
        const SizedBox(height: 4),
        Text(
          _needsSearch ? 'Search by name or symbol' : 'Enter a name for this investment',
          style: const TextStyle(fontSize: 14, color: _textLight),
        ),
        const SizedBox(height: 24),
        if (_needsSearch) ...[
          TextField(
            controller: _searchCtrl,
            onChanged: (v) { _onSearchChanged(v); setState(() { _selectedName = null; _selectedTicker = null; }); },
            decoration: InputDecoration(
              hintText: _selectedType == 'stock' ? 'e.g. Apple, AAPL' : 'e.g. Bitcoin, BTC',
              hintStyle: const TextStyle(color: _textLight),
              filled: true, fillColor: _bgGrey,
              prefixIcon: _searching
                  ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _textLight)))
                  : const Icon(Icons.search_rounded, color: _textLight, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          if (_selectedName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _blue.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _blue, width: 1.5)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: _blue, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$_selectedName ${_selectedTicker != null ? "($_selectedTicker)" : ""}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _blue))),
                GestureDetector(
                  onTap: () => setState(() { _selectedName = null; _selectedTicker = null; }),
                  child: const Icon(Icons.close_rounded, size: 16, color: _blue),
                ),
              ]),
            ),
          ],
          if (_suggestions.isNotEmpty && _selectedName == null) ...[
            const SizedBox(height: 8),
            ..._suggestions.map((s) => GestureDetector(
              onTap: () => setState(() {
                _selectedName   = s['name'] as String?;
                _selectedTicker = s['ticker'] as String?;
                _searchCtrl.text = '${s['name']} (${s['ticker']})';
                _suggestions = [];
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                    Text('${s['ticker'] ?? ''}  ·  ${s['exchange'] ?? ''}', style: const TextStyle(fontSize: 12, color: _textLight)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _textLight),
                ]),
              ),
            )),
          ],
        ] else ...[
          TextField(
            controller: _nameCtrl,
            onChanged: (v) => setState(() => _selectedName = v.trim().isEmpty ? null : v.trim()),
            decoration: InputDecoration(
              hintText: 'e.g. Downtown Apartment, My Bakery',
              hintStyle: const TextStyle(color: _textLight),
              filled: true, fillColor: _bgGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Page 2: Frequency ────────────────────────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Investment Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
        const SizedBox(height: 4),
        const Text('How often do you plan to invest?', style: TextStyle(fontSize: 14, color: _textLight)),
        const SizedBox(height: 24),
        ..._frequencies.map((f) {
          final key = f['key'] as String;
          final sel = _selectedFrequency == key;
          return GestureDetector(
            onTap: () => setState(() => _selectedFrequency = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: sel ? _blue.withOpacity(0.07) : _bgGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? _blue : Colors.transparent, width: 1.5),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? _blue : _textDark)),
                  const SizedBox(height: 2),
                  Text(f['sub'] as String, style: const TextStyle(fontSize: 12, color: _textLight)),
                ])),
                if (sel) const Icon(Icons.check_circle_rounded, color: _blue, size: 20),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // ── Page 3: Target amount ────────────────────────────────────────────────────
  Widget _buildPage3() {
    final freqLabel = _frequencies.firstWhere(
      (f) => f['key'] == _selectedFrequency, orElse: () => {'label': 'period'},
    )['label'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Investment Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
        const SizedBox(height: 4),
        Text('How much do you plan to invest per ${freqLabel.toLowerCase()}?', style: const TextStyle(fontSize: 14, color: _textLight)),
        const SizedBox(height: 24),
        TextField(
          controller: _targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '\$ ',
            filled: true, fillColor: _bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
        ),
      ]),
    );
  }

  // ── Page 4: Initial buy ──────────────────────────────────────────────────────
  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('First Investment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark, fontFamily: 'Manrope')),
        const SizedBox(height: 4),
        const Text('Enter the details of your initial purchase', style: TextStyle(fontSize: 14, color: _textLight)),
        const SizedBox(height: 24),
        const Text('Amount Invested (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _initialAmtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0.00', prefixText: '\$ ',
            filled: true, fillColor: _bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Price Per Unit at Purchase (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
          const Spacer(),
          if (_fetchingPrice) ...[
            const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: _blue)),
            const SizedBox(width: 6),
            const Text('Fetching live price…', style: TextStyle(fontSize: 11, color: _blue)),
          ] else if (_priceFetched)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF10B981)),
                SizedBox(width: 3),
                Text('Live price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
              ]),
            ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _initialPriceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() { _priceFetched = false; }),
          decoration: InputDecoration(
            hintText: _fetchingPrice ? 'Fetching…' : '0.00',
            prefixText: '\$ ',
            filled: true, fillColor: _bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_initialAmtCtrl.text.isNotEmpty && _initialPriceCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _blue.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _blue.withOpacity(0.2))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Units acquired', style: TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w500)),
              Text(
                () {
                  final amt = double.tryParse(_initialAmtCtrl.text) ?? 0;
                  final price = double.tryParse(_initialPriceCtrl.text) ?? 0;
                  return price > 0 ? (amt / price).toStringAsFixed(6) : '—';
                }(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _blue),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
