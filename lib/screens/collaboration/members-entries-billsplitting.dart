import 'package:flutter/material.dart';

// ======================= MODEL =======================

class EntryItem {
  final String title;        // Person / Organization
  final String subtitle;     // Verified / Not verified
  final String date;
  final double amount;       // Paid amount
  final double totalAmount;  // Total amount to be paid

  EntryItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.totalAmount,
  });
}

// ======================= MAIN WIDGET =======================

class EntriesEntryList extends StatelessWidget {
  final List<EntryItem> entries;

  const EntriesEntryList({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "No entries found",
          style: TextStyle(color: Color(0xFF667085)),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (tx) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _EntryTile(tx: tx),
            ),
          )
          .toList(),
    );
  }
}

// ======================= SINGLE ENTRY TILE =======================

class _EntryTile extends StatelessWidget {
  final EntryItem tx;

  const _EntryTile({required this.tx});

  // ======================= STATUS HELPERS =======================

  bool get isZero => tx.amount == 0;
  bool get isPartial => tx.amount > 0 && tx.amount < tx.totalAmount;
  bool get isComplete => tx.amount == tx.totalAmount;
  bool get isOverpaid => tx.amount > tx.totalAmount;

  Color get bgColor {
    if (isOverpaid) return const Color(0xFFFFF5F5);
    if (isComplete) return const Color(0xFFF5FFF7);
    if (isZero) return const Color(0xFFF9F9F9);
    return const Color(0xFFF5FAFF);
  }

  Color get borderColor {
    if (isOverpaid) return const Color.fromARGB(148, 255, 33, 33);
    if (isComplete) return const Color.fromARGB(148, 0, 103, 0);
    if (isZero) return const Color.fromARGB(148, 98, 98, 98);
    return const Color(0xFFD7E8FF);
  }

  Color get accentColor {
    if (isOverpaid) return const Color(0xFFFF2121);
    if (isComplete) return const Color(0xFF006700);
    if (isZero) return const Color(0xFF626262);
    return const Color(0xFF217BFF);
  }

  Color get avatarBg {
    if (isOverpaid) return const Color(0xFFFFD1D1);
    if (isComplete) return const Color(0xFFD1FFD2);
    if (isZero) return const Color(0xFFC9C9C9);
    return const Color(0xFFD1E9FF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarBg,
              ),
              alignment: Alignment.center,
              child: Text(
                tx.title.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: "Manrope",
                  fontSize: 20,
                  color: accentColor,
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Name + date + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Manrope",
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.date,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    tx.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Paid / Total Amount
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    "\$${tx.amount.toString()}",
                    style: TextStyle(
                      color: accentColor,
                      fontFamily: "Manrope",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "/${tx.totalAmount.toString()}",
                    style: const TextStyle(
                      color: Color(0xFF2A2A2A),
                      fontFamily: "Manrope",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
