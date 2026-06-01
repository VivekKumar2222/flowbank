import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../api/api_service.dart';

class FinancialHealthScreenAI extends StatefulWidget {
  const FinancialHealthScreenAI({super.key});

  @override
  State<FinancialHealthScreenAI> createState() => _FinancialHealthScreenAIState();
}

class _FinancialHealthScreenAIState extends State<FinancialHealthScreenAI> {
  static const _dark    = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _border  = Color(0xFF1E1E2E);

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
      final res = await ApiService.get('/api/ai/financial-health', context);
      if (res.statusCode == 200 && mounted) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _error = jsonDecode(res.body)['message'] ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color get _scoreColor {
    final score = (_data?['healthScore'] as num?)?.toInt() ?? 0;
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _scoreLabel {
    final score = (_data?['healthScore'] as num?)?.toInt() ?? 0;
    if (score >= 75) return 'Strong';
    if (score >= 50) return 'Moderate';
    return 'Needs Attention';
  }

  // ─── Detail bottom sheet ──────────────────────────────────────────────────

  void _showDetailSheet({
    required String title,
    required String value,
    required Color color,
    required String statusLabel,
    required IconData icon,
    required List<String> insights,
    required List<String> suggestions,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Drag handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, fontFamily: 'Manrope')),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 16),

          // Insights
          Row(children: [
            Icon(Icons.analytics_rounded, size: 14, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 6),
            Text('Insights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          ...insights.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 5, height: 5,
                decoration: BoxDecoration(color: color.withOpacity(0.7), shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.5))),
            ]),
          )),

          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 16),

          // Suggestions
          Row(children: [
            Icon(Icons.lightbulb_rounded, size: 14, color: const Color(0xFFF59E0B).withOpacity(0.8)),
            const SizedBox(width: 6),
            Text('Suggestions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.5))),
            ]),
          )),
        ]),
      ),
    );
  }

  void _showScoreDetail(int score) => _showDetailSheet(
    title: 'Health Score',
    value: '$score / 100',
    color: _scoreColor,
    statusLabel: _scoreLabel,
    icon: Icons.favorite_rounded,
    insights: [
      score >= 75
          ? 'Your financial health is strong. You are saving consistently and have a solid runway.'
          : score >= 50
              ? 'Your finances are in moderate shape. There is room to improve savings and runway.'
              : 'Your financial health needs attention. Focus on reducing spend or increasing income.',
      'Score is calculated from savings rate, income vs spend balance, and runway length.',
      score >= 75
          ? 'Maintaining 20%+ savings rate and 6+ months of runway keeps you in the strong zone.'
          : 'Improving your savings rate by even 5% would noticeably boost your score.',
    ],
    suggestions: [
      score < 75 ? 'Set a monthly budget cap to bring your savings rate above 20%.' : 'Keep your current savings discipline — consider investing the surplus.',
      score < 50 ? 'Review recurring subscriptions and non-essential spending to free up cash.' : 'Aim to build your emergency fund to cover 6+ months of expenses.',
    ],
  );

  void _showIncomeDetail(double income) => _showDetailSheet(
    title: 'Monthly Income',
    value: '\$${income.toStringAsFixed(0)}',
    color: const Color(0xFF10B981),
    statusLabel: income > 0 ? 'Detected' : 'Not Set',
    icon: Icons.account_balance_wallet_rounded,
    insights: [
      'This is estimated from your average credit transactions over the last 3 months.',
      income > 3000 ? 'Your income level gives you strong capacity to save and invest.' : income > 1500 ? 'Your income is moderate — careful budgeting will help maximise savings.' : 'With this income level, keeping expenses lean is key to building savings.',
      'Confirming your income in Profile settings will make all predictions more accurate.',
    ],
    suggestions: [
      'Confirm your monthly income in Profile → Edit Income for better forecast accuracy.',
      'Consider diversifying income streams (freelance, investments) to improve stability.',
    ],
  );

  void _showSpendDetail(double spend, double income) {
    final ratio = income > 0 ? (spend / income * 100) : 0.0;
    final status = ratio < 50 ? 'Healthy' : ratio < 80 ? 'Moderate' : 'High';
    final color = ratio < 50 ? const Color(0xFF10B981) : ratio < 80 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    _showDetailSheet(
      title: 'Monthly Spend',
      value: '\$${spend.toStringAsFixed(0)}',
      color: color,
      statusLabel: status,
      icon: Icons.shopping_cart_rounded,
      insights: [
        'You are spending ${ratio.toStringAsFixed(0)}% of your monthly income.',
        ratio < 50 ? 'Spending below 50% of income is excellent — you have significant savings capacity.' : ratio < 80 ? 'The 50/30/20 rule recommends keeping needs under 50% and wants under 30%.' : 'Spending above 80% of income leaves very little room for savings or emergencies.',
        'Review your top spending categories in Spending Forecast for a detailed breakdown.',
      ],
      suggestions: [
        ratio >= 60 ? 'Identify your top 2 spending categories and set a monthly cap for each.' : 'Your spending is well controlled — direct the surplus toward investments or goals.',
        'Use the Spending Forecast screen to see which day of the week you spend the most.',
      ],
    );
  }

  void _showSavingsDetail(double savings, double income) {
    final isPositive = savings >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    _showDetailSheet(
      title: 'Monthly Savings',
      value: '${isPositive ? '+' : ''}\$${savings.toStringAsFixed(0)}',
      color: color,
      statusLabel: isPositive ? 'Positive' : 'Deficit',
      icon: Icons.savings_rounded,
      insights: [
        isPositive ? 'You are saving \$${savings.toStringAsFixed(0)} per month after all expenses.' : 'You are spending more than you earn by \$${savings.abs().toStringAsFixed(0)} per month.',
        isPositive ? 'At this rate you will save \$${(savings * 12).toStringAsFixed(0)} over the next year.' : 'A spending deficit will erode your balance over time — action is needed.',
        'Financial experts recommend saving at least 20% of monthly income consistently.',
      ],
      suggestions: [
        isPositive ? 'Automate your savings — set up a recurring transfer on payday.' : 'List your fixed monthly expenses and identify at least one to reduce or eliminate.',
        isPositive ? 'Consider putting a portion into an index fund or high-yield savings account.' : 'Track daily spending for 2 weeks to find where money is silently leaking.',
      ],
    );
  }

  void _showSavingsRateDetail(double rate) {
    final color = rate >= 20 ? const Color(0xFF10B981) : rate >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final status = rate >= 20 ? 'Excellent' : rate >= 10 ? 'Fair' : rate >= 0 ? 'Low' : 'Negative';
    _showDetailSheet(
      title: 'Savings Rate',
      value: '${rate.toStringAsFixed(1)}%',
      color: color,
      statusLabel: status,
      icon: Icons.percent_rounded,
      insights: [
        'The 20% rule: saving 20% or more of income is the widely accepted financial benchmark.',
        rate >= 20 ? 'You are meeting or exceeding the 20% savings benchmark — excellent discipline.' : rate >= 10 ? 'You are saving but below the 20% benchmark. A 10% improvement makes a big difference.' : 'A savings rate below 10% leaves you vulnerable to unexpected expenses.',
        'Even a 1% increase in savings rate compounded over years has a significant impact on wealth.',
      ],
      suggestions: [
        rate < 20 ? 'Try increasing savings by 2% each month until you reach the 20% target.' : 'With a strong savings rate, explore tax-advantaged accounts to grow wealth faster.',
        'Pay yourself first — allocate savings at the start of the month before spending.',
      ],
    );
  }

  void _showRunwayDetail(double runway) {
    final color = runway >= 6 ? const Color(0xFF10B981) : runway >= 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final status = runway >= 6 ? 'Safe' : runway >= 3 ? 'Moderate' : 'Critical';
    _showDetailSheet(
      title: 'Income Runway',
      value: '${runway.toStringAsFixed(1)} months',
      color: color,
      statusLabel: status,
      icon: Icons.hourglass_empty_rounded,
      insights: [
        'Runway = current balance ÷ average monthly spend. It shows how long you can survive with zero income.',
        runway >= 6 ? 'You have a healthy emergency fund equivalent — 6+ months is the gold standard.' : runway >= 3 ? '3–6 months of runway is acceptable but building toward 6 is recommended.' : 'Less than 3 months of runway is financially dangerous. Building an emergency fund is urgent.',
        'This does not account for income — it is purely a worst-case survival estimate.',
      ],
      suggestions: [
        runway < 6 ? 'Set a goal to build your emergency fund to cover 6 months of expenses.' : 'Your emergency fund is solid — any surplus beyond 6 months can be invested.',
        'Keep your emergency fund in a liquid, accessible account separate from daily spending.',
      ],
    );
  }

  void _showGoalDetail(dynamic g) {
    final months = (g['monthsToAchieve'] as num?)?.toDouble();
    final name = g['name']?.toString() ?? 'Goal';
    final remaining = (g['remaining'] as num?)?.toDouble() ?? 0;
    final color = months == null ? Colors.white54 : months <= 3 ? const Color(0xFF10B981) : months <= 12 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
    _showDetailSheet(
      title: name,
      value: months != null ? '~${months.toStringAsFixed(0)} months' : 'Unknown',
      color: color,
      statusLabel: months == null ? 'No Data' : months <= 3 ? 'Almost There' : months <= 12 ? 'On Track' : 'Long Term',
      icon: Icons.flag_rounded,
      insights: [
        '\$${remaining.toStringAsFixed(0)} remaining to reach this goal.',
        months != null ? 'At your current savings rate, you will achieve this goal in approximately ${months.toStringAsFixed(0)} months.' : 'Confirm your monthly income in Profile to get a timeline estimate for this goal.',
        months != null && months > 12 ? 'Goals over 12 months benefit from dedicated savings automation.' : months != null ? 'You are close — a small spending reduction could shorten this timeline.' : 'More transaction data will improve the accuracy of goal timelines.',
      ],
      suggestions: [
        months != null && months > 6 ? 'Create a dedicated sub-savings account just for this goal.' : 'You are nearly there — avoid large discretionary purchases until this goal is hit.',
        'Review this goal monthly and adjust your budget if the timeline drifts.',
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
      Image.asset('assets/ai-iocn-2.png', width: 34, height: 34),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Financial Health', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope')),
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
          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      )),
    ]),
  ));

  Widget _buildContent() {
    final d = _data!;
    final score = (d['healthScore'] as num?)?.toInt() ?? 0;
    final savings = (d['savingsRate'] as num?)?.toDouble() ?? 0;
    final runway = (d['runwayMonths'] as num?)?.toDouble() ?? 0;
    final monthlyIncome = (d['monthlyIncome'] as num?)?.toDouble() ?? 0;
    final monthlySpend = (d['avgMonthlySpend'] as num?)?.toDouble() ?? 0;
    final monthlySavings = (d['monthlySavings'] as num?)?.toDouble() ?? 0;
    final forecast = (d['balanceForecast'] as List?) ?? [];
    final goals = (d['goalEstimates'] as List?) ?? [];
    final costCuts = (d['costCuttingSuggestions'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Health Score Ring
        GestureDetector(
          onTap: () => _showScoreDetail(score),
          child: Center(child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 140, height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(children: [
                Text('$score', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: _scoreColor, fontFamily: 'Manrope')),
                Text(_scoreLabel, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Health Score', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 13, color: Colors.white.withOpacity(0.25)),
            ]),
          ])),
        ),

        const SizedBox(height: 28),

        // Key Stats
        Row(children: [
          _statCard('Monthly Income', '\$${monthlyIncome.toStringAsFixed(0)}', const Color(0xFF10B981), () => _showIncomeDetail(monthlyIncome)),
          const SizedBox(width: 10),
          _statCard('Monthly Spend', '\$${monthlySpend.toStringAsFixed(0)}', const Color(0xFFEF4444), () => _showSpendDetail(monthlySpend, monthlyIncome)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard('Monthly Savings', '${monthlySavings >= 0 ? '+' : ''}\$${monthlySavings.toStringAsFixed(0)}',
              monthlySavings >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              () => _showSavingsDetail(monthlySavings, monthlyIncome)),
          const SizedBox(width: 10),
          _statCard('Savings Rate', '${savings.toStringAsFixed(1)}%',
              savings >= 20 ? const Color(0xFF10B981) : savings >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
              () => _showSavingsRateDetail(savings)),
        ]),

        const SizedBox(height: 24),

        // Runway
        _sectionLabel('Income Runway'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showRunwayDetail(runway),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: (runway >= 6 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.hourglass_empty_rounded,
                    color: runway >= 6 ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${runway.toStringAsFixed(1)} months',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: runway >= 6 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontFamily: 'Manrope'),
                ),
                const SizedBox(height: 4),
                Text('Balance would last this long if income stopped',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45), height: 1.4)),
              ])),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
            ]),
          ),
        ),

        if (forecast.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('12-Month Balance Forecast'),
          const SizedBox(height: 10),
          _buildMiniChart(forecast),
        ],

        if (goals.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Goal Timelines'),
          const SizedBox(height: 10),
          ...goals.map((g) => _goalTile(g)).toList(),
        ],

        if (costCuts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Cost Cutting Suggestions'),
          const SizedBox(height: 4),
          Text('Based on repetitive spending patterns', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 10),
          ...costCuts.map((c) => _costCutTile(c)).toList(),
        ],
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)))),
            Icon(Icons.info_outline_rounded, size: 12, color: Colors.white.withOpacity(0.2)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Manrope')),
        ]),
      ),
    ),
  );

  Widget _sectionLabel(String label) => Text(label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.3));

  Widget _buildMiniChart(List forecast) {
    final balances = forecast.map((f) => (f['projectedBalance'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = balances.reduce((a, b) => a > b ? a : b);
    final minVal = balances.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

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
            children: balances.asMap().entries.map((e) {
              final h = range > 0 ? ((e.value - minVal) / range) * 70 + 10 : 40.0;
              final isLast = e.key == balances.length - 1;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        (e.value >= balances.first ? const Color(0xFF06B6D4) : const Color(0xFFEF4444)).withOpacity(isLast ? 1.0 : 0.6),
                        (e.value >= balances.first ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Now', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
          Text('12 months', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
        ]),
      ]),
    );
  }

  void _showCostCutDetail(dynamic c) {
    final merchant = c['merchant']?.toString() ?? 'Merchant';
    final visits = (c['visits'] as num?)?.toInt() ?? 0;
    final total = (c['totalSpent'] as num?)?.toDouble() ?? 0;
    final avg = (c['avgPerVisit'] as num?)?.toDouble() ?? 0;
    _showDetailSheet(
      title: merchant,
      value: '\$${total.toStringAsFixed(0)} spent',
      color: const Color(0xFFF59E0B),
      statusLabel: 'Repetitive',
      icon: Icons.store_rounded,
      insights: [
        'You visited $merchant $visits times, spending \$${total.toStringAsFixed(0)} in total.',
        'Your average spend per visit is \$${avg.toStringAsFixed(0)}.',
        visits >= 8
            ? 'This is a very frequent pattern — even cutting half the visits could save \$${(total / 2).toStringAsFixed(0)}.'
            : 'Reducing visits by 2–3 per month could save \$${(avg * 2.5).toStringAsFixed(0)}/month.',
      ],
      suggestions: [
        'Ask yourself: is every visit to $merchant necessary, or is it a habit?',
        'Set a monthly budget cap for $merchant and track it in your Goals.',
      ],
    );
  }

  Widget _costCutTile(dynamic c) {
    final merchant = c['merchant']?.toString() ?? 'Merchant';
    final visits = (c['visits'] as num?)?.toInt() ?? 0;
    final total = (c['totalSpent'] as num?)?.toDouble() ?? 0;
    final avg = (c['avgPerVisit'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () => _showCostCutDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.store_rounded, color: Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(merchant, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 3),
            Text('$visits visits · \$${avg.toStringAsFixed(0)} avg per visit',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
            Text('total', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
          ]),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 18),
        ]),
      ),
    );
  }

  Widget _goalTile(dynamic g) {
    final months = (g['monthsToAchieve'] as num?)?.toDouble();
    final name = g['name']?.toString() ?? 'Goal';
    final remaining = (g['remaining'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () => _showGoalDetail(g),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_rounded, color: Color(0xFF3B82F6), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 3),
            Text('\$${remaining.toStringAsFixed(0)} remaining',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
          ])),
          months != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('~${months.toStringAsFixed(0)} mo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4))),
                  Text('to achieve', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
                ])
              : Text('Set income\nto estimate', textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35))),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 18),
        ]),
      ),
    );
  }
}
