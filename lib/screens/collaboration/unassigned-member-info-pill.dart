import 'package:flutter/material.dart';
import '../collaboration/create-assignment.dart';

class UnassignedMemberInfoPill extends StatelessWidget {
  final String name;
  final String dashboardId;
  final String memberId;



  const UnassignedMemberInfoPill({
    super.key,
    required this.name,
    required this.dashboardId,
    required this.memberId,

    
  });

  

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // 🔹 Fixed grey shades
  static const Color _bgColor = Color(0xFFE0E0E0);
  static const Color _textColor = Color(0xFF4A4A4A);
  static const Color _borderColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return InkWell(
    borderRadius: BorderRadius.circular(100),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAssignmentPage(
            dashboardId: dashboardId,
            membersId: memberId,
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: _textColor,
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
                style: const TextStyle(
                  color: _textColor,
                  fontFamily: "Manrope",
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    "Not Assigned",
                    style: const TextStyle(
                      color: _textColor,
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
    )
    );
  }
}
