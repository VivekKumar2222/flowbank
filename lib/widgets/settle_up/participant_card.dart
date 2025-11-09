import 'package:flutter/material.dart';
import '../../models/participant.dart';

class ParticipantCard extends StatelessWidget {
  final Participant participant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ParticipantCard({
    Key? key,
    required this.participant,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwed = participant.type == TransactionType.owed;
    final backgroundColor = isOwed
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final borderColor = isOwed
        ? const Color(0xFF81C784)
        : const Color(0xFFFFB74D);
    final amountColor = isOwed
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final amountSign = isOwed ? '+' : '-';

    final avatarMap = {
      'Sarah Johnson': 'assets/avatars/avatar-sarah.png',
      'Mike Chen': 'assets/avatars/avatar-mike.jpg',
      'Emma Davis': 'assets/avatars/avatar-emma.jpg',
      'Alex Martinez': 'assets/avatars/avatar-alex.png',
      'Jordan Lee': 'assets/avatars/avatar-jordan.jpg',
      'Casey Wilson': 'assets/avatars/avatar-casey.jpg',
    };

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: avatarMap.containsKey(participant.name)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            avatarMap[participant.name]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  participant.initials,
                                  style: TextStyle(
                                    color: amountColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            participant.initials,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        participant.note,
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountSign\$${participant.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwed ? 'You\'re owed' : 'You owe',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16, color: amountColor),
                            const SizedBox(width: 6),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF5350),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFFEF5350),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFFEF5350),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
