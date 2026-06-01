import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../api/api_service.dart';

class SpendingForecastScreen extends StatefulWidget {
  const SpendingForecastScreen({super.key});

  @override
  State<SpendingForecastScreen> createState() => _SpendingForecastScreenState();
}

class _SpendingForecastScreenState extends State<SpendingForecastScreen> {
  static const _dark = Color(0xFF0A0A0F);

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _minLoadDone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _minLoadDone = true);
    });
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; _minLoadDone = false; });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _minLoadDone = true);
    });
    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.get('/api/ai/spending-forecast', context);
      if (res.statusCode == 200 && mounted) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _error = jsonDecode(res.body)['message'] ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: Column(children: [
        _buildAppBar(),
        Expanded(
          child: (_loading || !_minLoadDone) ? _buildLoading()
              : _error != null ? _buildError()
              : _buildContent(),
        ),
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
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white70),
        ),
      ),
      const SizedBox(width: 14),
      Image.asset('assets/ai-iocn-3.png', width: 34, height: 34),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Spending Forecast', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope')),
        Text('Prophet AI Model', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _fetch,
        child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.4), size: 20),
      ),
    ]),
  );

  Widget _buildLoading() => Center(
    child: Lottie.asset('assets/ai-loading.json', width: 160, height: 160),
  );

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_off_rounded, color: Colors.white.withOpacity(0.3), size: 48),
      const SizedBox(height: 16),
      Text(_error ?? 'Something went wrong', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
      const SizedBox(height: 20),
      GestureDetector(onTap: _fetch, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      )),
    ]),
  ));

  Widget _buildContent() {
    final d = _data!;
    final summary = (d['summary'] as Map<String, dynamic>?) ?? {};
    final avgDaily = (summary['avgDailySpend'] as num?)?.toDouble() ?? 0;
    final avgMonthly = (summary['avgMonthlySpend'] as num?)?.toDouble() ?? 0;
    final peakDay = summary['peakSpendingDay']?.toString() ?? 'N/A';
    final forecastTotal = (summary['forecastedSpendNextDays'] as num?)?.toDouble() ?? 0;
    final forecastDays = (summary['forecastDays'] as num?)?.toInt() ?? 30;
    final weekly = (d['weeklyPattern'] as List?) ?? [];
    final categories = (d['categoryBreakdown'] as List?) ?? [];
    final predictions = (d['predictions'] as List?) ?? [];
    final wom = (d['weekOfMonthPattern'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Summary cards
        Row(children: [
          _statCard('Avg Daily Spend', '\$${avgDaily.toStringAsFixed(0)}', const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          _statCard('Avg Monthly', '\$${avgMonthly.toStringAsFixed(0)}', const Color(0xFF06B6D4)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('Peak Day', peakDay, const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          _statCard('Next $forecastDays Days', '\$${forecastTotal.toStringAsFixed(0)}', const Color(0xFF0179FE)),
        ]),

        // 30-day forecast chart
        if (predictions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('30-Day Spending Forecast'),
          const SizedBox(height: 10),
          _buildForecastChart(predictions),
        ],

        // Weekly pattern
        if (weekly.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Average Spend by Day'),
          const SizedBox(height: 10),
          _buildWeeklyChart(weekly),
        ],

        // Week of month
        if (wom.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Spend by Week of Month'),
          const SizedBox(height: 10),
          _buildWomChart(wom),
        ],

        // Category breakdown
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Category Breakdown'),
          const SizedBox(height: 10),
          ...categories.take(6).map((c) => _categoryRow(c)).toList(),
        ],
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Manrope'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _sectionLabel(String t) => Text(t,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.3));

  Widget _buildForecastChart(List predictions) {
    final values = predictions.map((p) => (p['predicted'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: [
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.map((v) {
              final h = maxVal > 0 ? (v / maxVal) * 80 + 6 : 6.0;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Day 1', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
          Text('Day 30', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
        ]),
      ]),
    );
  }

  Widget _buildWeeklyChart(List weekly) {
    final values = weekly.map((d) => (d['avgSpend'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final days = weekly.map((d) => (d['day']?.toString() ?? '').substring(0, 3)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: [
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((e) {
              final h = maxVal > 0 ? (e.value / maxVal) * 70 + 6 : 6.0;
              final isMax = e.value == maxVal;
              return Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isMax ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: days.map((d) => Expanded(child: Center(
            child: Text(d, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
          ))).toList(),
        ),
      ]),
    );
  }

  Widget _buildWomChart(List wom) {
    final values = wom.map((w) => (w['avgSpend'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final labels = wom.map((w) => w['week']?.toString() ?? '').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((e) {
          final h = maxVal > 0 ? (e.value / maxVal) * 80 + 10 : 10.0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('\$${e.value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 4),
              Container(
                height: h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[e.key].replaceAll('Week ', 'W'), style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4))),
            ]),
          ));
        }).toList(),
      ),
    );
  }

  Widget _categoryRow(dynamic c) {
    final name = c['category']?.toString() ?? 'Other';
    final pct = (c['percent'] as num?)?.toDouble() ?? 0;
    final total = (c['total'] as num?)?.toDouble() ?? 0;
    final color = _categoryColor(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500))),
          Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 8),
          Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ]),
    );
  }

  Color _categoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('restaurant')) return const Color(0xFF0179FE);
    if (n.contains('shop') || n.contains('retail')) return const Color(0xFF3B82F6);
    if (n.contains('transport') || n.contains('travel')) return const Color(0xFF06B6D4);
    if (n.contains('bill') || n.contains('util')) return const Color(0xFF2563EB);
    if (n.contains('health') || n.contains('medical')) return const Color(0xFF8B5CF6);
    if (n.contains('entertain')) return const Color(0xFF60A5FA);
    return const Color(0xFF64748B);
  }
}
