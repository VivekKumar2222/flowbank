import 'package:flutter/material.dart';

class AllGoalsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  const AllGoalsScreen({super.key, required this.goals});

  Color _colorFromTheme(String? theme) {
    switch (theme) {
      case 'purple': return const Color(0xFFB968F6);
      case 'blue':   return const Color(0xFF217BFF);
      default:       return const Color(0xFFC11574);
    }
  }

  IconData _iconFromCategory(String? cat) {
    switch ((cat ?? '').toLowerCase()) {
      case 'food':         return Icons.restaurant_rounded;
      case 'transport':    return Icons.directions_car_rounded;
      case 'subscription': return Icons.subscriptions_rounded;
      case 'bills':        return Icons.receipt_rounded;
      case 'shopping':     return Icons.shopping_bag_rounded;
      default:             return Icons.savings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF101828)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Goals',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF101828)),
        ),
      ),
      body: goals.isEmpty
          ? const Center(
              child: Text('No goals yet.', style: TextStyle(color: Color(0xFF667085))),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: goals.length,
              itemBuilder: (context, i) {
                final g = goals[i];
                final double amount = (g['amount'] as num).toDouble();
                final double spent = (g['currentSpend'] as num? ?? 0).toDouble();
                final double progress = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0;
                final color = _colorFromTheme(g['themeColor'] as String?);
                final icon = _iconFromCategory(g['category'] as String?);
                final String duration = g['resetDuration'] ?? 'monthly';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: Row(
                    children: [
                      // Icon circle
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      // Text + progress
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(g['goalName'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828))),
                                Text('\$${amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: Color(0xFF101828))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(duration,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: color.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('\$${spent.toStringAsFixed(0)} spent of \$${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}