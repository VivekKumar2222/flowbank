import 'package:flowbank/screens/collaboration/create_group.dart';
import 'package:flutter/material.dart';
import '../collaboration/member-info-pill.dart';

class MembersViewRow extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String? groupType;

  const MembersViewRow({
    super.key,
    required this.members,
    this.groupType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E8FF), width: 1.2),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(members.length, (index) {
            final member = members[index];

            return Padding(
              padding: EdgeInsets.only(
                right: index == members.length - 1 ? 0 : 16,
              ),
              child: SimpleScreen(
                dashboardId: member['dashboardId'],
                memberId: member['memberId'],
                name: member['name'],
                paidAmount: member['paidAmount'],
                totalAmount: member['totalAmount'],
                groupType: groupType,
              ),
            );
          }),
        ),
      ),
    );
  }
}
