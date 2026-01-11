import 'package:flutter/material.dart';
import 'entry_verification.dart';

// ======================= MODEL =======================

class EntryItem {
  final String entryId;
  final String title;        // Person / Organization
  final String subtitle;     // Verified / Not verified
  final String date;
  final double amount;       // Paid amount
  // final double totalAmount;  // Total amount to be paid

  EntryItem({
    required this.entryId,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    // required this.totalAmount,
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

  // ======================= BLUE THEME COLORS =======================

  static const Color _bgColor = Color(0xFFF5FAFF);      // Light blue background
  static const Color _borderColor = Color(0xFFD7E8FF);  // Soft blue border
  static const Color _accentColor = Color(0xFF217BFF);  // Primary blue
  static const Color _avatarBg = Color(0xFFD1E9FF);     // Avatar blue

  @override
  Widget build(BuildContext context) {
    return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryVerificationPage(
                 entryId: tx.entryId,
                 name: tx.title,
        
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border.all(color: _borderColor, width: 1.2),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarBg,
              ),
              alignment: Alignment.center,
              child: Text(
                tx.title.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: "Manrope",
                  fontSize: 20,
                  color: _accentColor,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Manrope",
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _accentColor,
                    ),
                  ),
                  Text(
                    tx.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _accentColor,
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
                    "\$${tx.amount}",
                    style: const TextStyle(
                      color: _accentColor,
                      fontFamily: "Manrope",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
