import 'package:flutter/material.dart';
import '../../models/participant.dart';

// Dummy friends list for prototyping
final List<Map<String, dynamic>> dummyFriends = [
  {'name': 'Alex Martinez', 'initials': 'AM', 'userId': 'user_alex_123'},
  {'name': 'Jordan Lee', 'initials': 'JL', 'userId': 'user_jordan_456'},
  {'name': 'Casey Wilson', 'initials': 'CW', 'userId': 'user_casey_789'},
  {'name': 'Taylor Brown', 'initials': 'TB', 'userId': 'user_taylor_012'},
  {'name': 'Morgan Davis', 'initials': 'MD', 'userId': 'user_morgan_345'},
];

Future<void> showAddParticipantModal(
  BuildContext context, {
  required Function(Participant) onAdd,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Participant',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation1, animation2) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
          child: FractionallySizedBox(
            heightFactor: 0.65,
            child: AddParticipantModalContent(onAdd: onAdd),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation1, animation2, child) {
      final curved = CurvedAnimation(
        parent: animation1,
        curve: Curves.easeInOut,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class AddParticipantModalContent extends StatefulWidget {
  final Function(Participant) onAdd;

  const AddParticipantModalContent({Key? key, required this.onAdd})
    : super(key: key);

  @override
  State<AddParticipantModalContent> createState() =>
      _AddParticipantModalContentState();
}

class _AddParticipantModalContentState extends State<AddParticipantModalContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController userIdController = TextEditingController();
  String selectedFriendId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 90,
                height: 6,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add Participant",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Select from friends or enter a User ID",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E88E5),
              unselectedLabelColor: const Color(0xFF999999),
              indicatorColor: const Color(0xFF1E88E5),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Friends List'),
                Tab(text: 'User ID'),
              ],
            ),
            const SizedBox(height: 16),
            // Tab content
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Friends list tab
                  ListView.builder(
                    itemCount: dummyFriends.length,
                    itemBuilder: (context, index) {
                      final friend = dummyFriends[index];
                      final isSelected = selectedFriendId == friend['userId'];

                      final friendAvatars = {
                        'Sarah Johnson': 'assets/avatars/avatar-sarah.png',
                        'Mike Chen': 'assets/avatars/avatar-mike.jpg',
                        'Emma Davis': 'assets/avatars/avatar-emma.jpg',
                        'Alex Martinez': 'assets/avatars/avatar-alex.png',
                        'Jordan Lee': 'assets/avatars/avatar-jordan.jpg',
                        'Casey Wilson': 'assets/avatars/avatar-casey.jpg',
                      };

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFriendId = friend['userId'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1E88E5)
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      friendAvatars.containsKey(friend['name'])
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.asset(
                                            friendAvatars[friend['name']]!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      friend['initials'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            friend['initials'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend['name'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        friend['userId'],
                                        style: const TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF1E88E5),
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // User ID tab
                  Column(
                    children: [
                      TextField(
                        controller: userIdController,
                        decoration: InputDecoration(
                          labelText: "Enter User ID",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFCCD0D7),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E88E5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter a valid User ID to add someone not in your friends list',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  String selectedName = '';
                  String selectedInitials = '';

                  if (selectedFriendId.isNotEmpty) {
                    final friend = dummyFriends.firstWhere(
                      (f) => f['userId'] == selectedFriendId,
                      orElse: () => null as Map<String, dynamic>,
                    );
                    if (friend != null) {
                      selectedName = friend['name'];
                      selectedInitials = friend['initials'];
                    }
                  } else if (userIdController.text.isNotEmpty) {
                    selectedName = 'User - ${userIdController.text}';
                    selectedInitials = 'U';
                  }

                  if (selectedName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a participant'),
                      ),
                    );
                    return;
                  }

                  final newParticipant = Participant(
                    id: DateTime.now().toString(),
                    name: selectedName,
                    initials: selectedInitials,
                    amount: 0,
                    type: TransactionType.owed,
                    note: '',
                  );

                  widget.onAdd(newParticipant);
                  Navigator.pop(context);

                  // Show edit modal immediately
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showEditParticipantModal(
                      context,
                      participant: newParticipant,
                      onUpdate: (updated) {
                        widget.onAdd(updated); // 🔥 triggers parent refresh
                      },
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showEditParticipantModal(
  BuildContext context, {
  required Participant participant,
  required Function(Participant) onUpdate,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit Participant',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation1, animation2) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: EditParticipantModalContent(
              participant: participant,
              onUpdate: onUpdate,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation1, animation2, child) {
      final curved = CurvedAnimation(
        parent: animation1,
        curve: Curves.easeInOut,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class EditParticipantModalContent extends StatefulWidget {
  final Participant participant;
  final Function(Participant) onUpdate;

  const EditParticipantModalContent({
    Key? key,
    required this.participant,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditParticipantModalContent> createState() =>
      _EditParticipantModalContentState();
}

class _EditParticipantModalContentState
    extends State<EditParticipantModalContent> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  late TransactionType selectedType;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.participant.amount.toString(),
    );
    noteController = TextEditingController(text: widget.participant.note);
    selectedType = widget.participant.type;
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 90,
                height: 6,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Edit Settlement",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adjust details for ${widget.participant.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),

            // Transaction type selector
            const Text(
              'Transaction Type',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = TransactionType.owed;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedType == TransactionType.owed
                            ? const Color(0xFFE8F5E9)
                            : Colors.white,
                        border: Border.all(
                          color: selectedType == TransactionType.owed
                              ? const Color(0xFF81C784)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: selectedType == TransactionType.owed
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF999999),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re Owed',
                            style: TextStyle(
                              color: selectedType == TransactionType.owed
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF666666),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = TransactionType.owing;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedType == TransactionType.owing
                            ? const Color(0xFFFFF3E0)
                            : Colors.white,
                        border: Border.all(
                          color: selectedType == TransactionType.owing
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: selectedType == TransactionType.owing
                                ? const Color(0xFFE65100)
                                : const Color(0xFF999999),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You Owe',
                            style: TextStyle(
                              color: selectedType == TransactionType.owing
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF666666),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount field
            const Text(
              'Amount',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\$ ',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFCCD0D7),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E88E5),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Dinner at BBQ Tonight',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFCCD0D7),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E88E5),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  final note = noteController.text.trim();

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }

                  final updatedParticipant = widget.participant.copyWith(
                    amount: amount,
                    type: selectedType,
                    note: note,
                  );

                  widget.onUpdate(updatedParticipant);
                  Navigator.pop(context);

                  // ⬇️ Force the totals to refresh right after modal closes
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      setState(() {}); // rebuild modal
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
