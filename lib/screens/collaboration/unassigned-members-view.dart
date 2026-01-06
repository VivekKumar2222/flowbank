import 'package:flutter/material.dart';
import '../collaboration/unassigned-member-info-pill.dart';
import '../collaboration/ledger_tracking.dart';

class UnassignedMembersView extends StatelessWidget {
  final List<UnassignedMember> members;

  const UnassignedMembersView({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text("No unassigned members");
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1.2),
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
              child: UnassignedMemberInfoPill(
                name: member.name,    
                dashboardId: member.dashboardId,
                memberId: member.email,      // ✅ from backend
 // ✅ NOT _id
              ),
            );
          }),
        ),
      ),
    );
  }
}
