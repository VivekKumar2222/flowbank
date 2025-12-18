import 'package:flutter/material.dart';

enum GroupType { billSplitting, sharedExpenses, ledgerTracking }

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  GroupType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Create Group',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// GROUP NAME
              _SectionTitle(title: 'Group Name'),
              const SizedBox(height: 8),
              _CardContainer(
                child: TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Office Expenses, Goa Trip',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// GROUP TYPE
              _SectionTitle(title: 'Group Type'),
              const SizedBox(height: 12),

              _GroupTypeCard(
                title: 'Bill Splitting',
                subtitle: 'Split bills equally or custom',
                icon: Icons.receipt_long_rounded,
                isSelected: _selectedType == GroupType.billSplitting,
                onTap: () {
                  setState(() {
                    _selectedType = GroupType.billSplitting;
                  });
                },
              ),

              _GroupTypeCard(
                title: 'Shared Expenses',
                subtitle: 'Track group spending together',
                icon: Icons.groups_rounded,
                isSelected: _selectedType == GroupType.sharedExpenses,
                onTap: () {
                  setState(() {
                    _selectedType = GroupType.sharedExpenses;
                  });
                },
              ),

              _GroupTypeCard(
                title: 'Ledger Tracking',
                subtitle: 'Track who owes whom',
                icon: Icons.book_rounded,
                isSelected: _selectedType == GroupType.ledgerTracking,
                onTap: () {
                  setState(() {
                    _selectedType = GroupType.ledgerTracking;
                  });
                },
              ),

              const SizedBox(height: 24),

              /// FILLER / EMPTY STATE GRAPHIC
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Color(0xFFB6C5E3),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'You can change group settings later',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// CREATE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedType == null ||
                          _groupNameController.text.isEmpty
                      ? null
                      : () {
                          // Handle create group
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8DF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Create Group',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// REUSABLE WIDGETS

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GroupTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F8DF7)
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4F8DF7),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4F8DF7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
