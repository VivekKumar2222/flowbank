import 'package:flutter/material.dart';


// ======================= MODELS =======================

class Bank {
  final String name;
  final String logoText;
  final List<TransactionItem> transactions;

  Bank({
    required this.name,
    required this.logoText,
    required this.transactions,
  });
}

class TransactionItem {
  final String title;
  final String subtitle;
  final String date; // NEW
  final double amount;
  final bool isPositive;
  final bool isCategorized; // NEW
  final VoidCallback? onCategorize; // optional action

  TransactionItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.isCategorized,
    this.onCategorize,
  });
}



// ======================= MAIN WIDGET =======================

class BankTransactionsWidget extends StatefulWidget {
  final List<Bank> banks;
  final int maxTransactionsPerBank;

  const BankTransactionsWidget({
    super.key,
    required this.banks,
    this.maxTransactionsPerBank = 5,
  });

  @override
  State<BankTransactionsWidget> createState() =>
      _BankTransactionsWidgetState();
}

class _BankTransactionsWidgetState extends State<BankTransactionsWidget> {
  int selectedBankIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.banks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BankTabs(
          banks: widget.banks,
          selectedIndex: selectedBankIndex,
          onSelected: (index) {
            setState(() {
              selectedBankIndex = index;
            });
          },
        ),
        const SizedBox(height: 2),
        _TransactionsList(
          bank: widget.banks[selectedBankIndex],
          maxItems: widget.maxTransactionsPerBank,
        ),
      ],
    );
  }
}


// ======================= BANK TABS =======================

class _BankTabs extends StatelessWidget {
  final List<Bank> banks;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BankTabs({
    required this.banks,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38, // tight height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: banks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final bool isActive = index == selectedIndex;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => onSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BANK NAME
                Text(
                  banks[index].name,
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 17,
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? const Color(0xFF217BFF)
                        : const Color(0xFF667085),
                  ),
                ),

                const SizedBox(height: 4),

                // INDICATOR
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 2.5,
                  width: isActive
                      ? _textWidth(banks[index].name)
                      : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF217BFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 Match underline width exactly to text
  double _textWidth(String text) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 17,
          fontFamily: "Manrope",
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return painter.width;
  }
}


// ======================= TRANSACTIONS LIST =======================

class _TransactionsList extends StatelessWidget {
  final Bank bank;
  final int maxItems;

  const _TransactionsList({
    required this.bank,
    required this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final items = bank.transactions.take(maxItems).toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "No transactions found",
          style: TextStyle(color: Color(0xFF667085)),
        ),
      );
    }

    return Column(
  children: items
      .map(
        (tx) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _TransactionTile(tx: tx),
        ),
      )
      .toList(),
);

  }
}


// ======================= SINGLE TRANSACTION TILE =======================

class _TransactionTile extends StatelessWidget {
  final TransactionItem tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tx.isPositive
                    ? const Color(0xFFF5FAFF)
                    : const Color(0xFFFFF5F5),

       border: Border.all(
        color: tx.isPositive
        ?const Color(0xFFD7E8FF)
        :const Color(0xFFFFD2D2),

        width: 1.2,
        
       ),
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
                color: tx.isPositive
                    ? const Color(0xFFD1E9FF)
                    : const Color(0xFFFFD1D1),
                    
              ),
              alignment: Alignment.center,
              child: Text(
                tx.title.substring(0, 2).toUpperCase(),
                style:  TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: "Manrope",
                  fontSize: 20,
                  color: tx.isPositive
                  ? const Color(0xFF217BFF)
                  : const Color(0xFFFF2121),
                ),
              ),
            ),
      
            const SizedBox(width: 20),
      
            // Name + subtitle
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
                      color: tx.isPositive
                      ? const Color(0xFF217BFF)
                  : const Color(0xFFFF2121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.date,
                        style:  TextStyle(
                          height: 0,
                          fontSize: 13,
                          color: tx.isPositive
                          ? const Color(0xFF4490FF)
                      : const Color(0xFFFF4646),
                      fontWeight: FontWeight.w500
                        ),
                      ),
                      Text(
                        tx.subtitle,
                        style:  TextStyle(
                          fontSize: 13,
                          color: tx.isPositive
                          ? const Color(0xFF4490FF)
                      : const Color(0xFFFF4646),
                      fontWeight: FontWeight.w500
                        ),
                      ),
                      
                    ],
                  ),
                ],
              ),
            ),
      
            // Amount
            Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '${tx.isPositive ? '+' : '-'}\$${tx.amount.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: tx.isPositive
              ? const Color(0xFF217BFF)
              : const Color(0xFFFF2121),
        ),
      ),
      const SizedBox(height: 6),

      /// CATEGORIZED / CATEGORIZE+
      tx.isCategorized
          ? Text(
              "Categorized",
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Manrope",
                fontWeight: FontWeight.w500,
                color: tx.isPositive
                    ? const Color(0xFF217BFF)
                    : const Color(0xFFFF2121),
              ),
            )
          : GestureDetector(
              onTap: tx.onCategorize,
              child: const Text(
                "Categorize +",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: "Manrope",
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
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
