import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showButton;
  final Widget? destination;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.showButton = false,
    this.destination,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // left & right gap
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A2A2A),
            ),
          ),

          // Show or hide button based on boolean
          if (showButton)
GestureDetector(
  onTap: () {
    if (onViewAll != null) {
      onViewAll!();
    } else if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination!),
      );
    }
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color(0xFFD0D5DD),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      "View All",
      style: TextStyle(
        fontSize: 13,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w600,
        color: Color(0xFF667085),
      ),
    ),
  ),
)

        ],
      ),
    );
  }
}
