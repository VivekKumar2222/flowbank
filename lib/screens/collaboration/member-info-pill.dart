import 'package:flutter/material.dart';
import '../collaboration/create-assignment.dart';

class SimpleScreen extends StatelessWidget {
  final String? dashboardId;
  final String? memberId;
  final String name;
  final double paidAmount;
  final double totalAmount;
  final String? groupType;

  const SimpleScreen({
    super.key,
    this.dashboardId,
    this.memberId,
    required this.name,
    required this.paidAmount,
    required this.totalAmount,
    this.groupType,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Determine colors based on payment status
  Color get bgColor {
    if (paidAmount == 0) return const Color(0xFFC9C9C9);
    if (paidAmount < totalAmount) return const Color(0xFFD1E9FF);
    if (paidAmount == totalAmount) return const Color(0xFFD1FFD2);
    return const Color(0xFFFFD1D1);
  }

  Color get textColor {
    if (paidAmount == 0) return const Color(0xFF626262);
    if (paidAmount < totalAmount) return const Color(0xFF217BFF);
    if (paidAmount == totalAmount) return const Color(0xFF006700);
    return const Color(0xFFFF2121);
  }

  Color get borderColor {
    if (paidAmount == 0) return const Color.fromARGB(78, 98, 98, 98);
    if (paidAmount < totalAmount) return const Color(0xFFD7E8FF);
    if (paidAmount == totalAmount) return const Color.fromARGB(148, 0, 103, 0);
    return const Color.fromARGB(148, 255, 33, 33);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return InkWell(
  borderRadius: BorderRadius.circular(100),
  onTap: () {
    if (groupType == "Ledger Tracking") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateAssignmentPage(dashboardId: dashboardId ?? '', membersId: memberId ?? ''),
        ),
      );
    }
  },
    child: Container(
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              // border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: textColor,
                  fontFamily: "Manrope",
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontFamily: "Manrope",
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    "+\$${paidAmount.toString()}",
                    style: TextStyle(
                      color: textColor,
                      fontFamily: "Manrope",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "/${totalAmount.toString()}",
                    style: const TextStyle(
                      color: Color(0xFF2A2A2A),
                      fontFamily: "Manrope",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    ),
    );
  }
}
