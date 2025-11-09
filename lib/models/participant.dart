enum TransactionType { owed, owing }

class Participant {
  final String id;
  final String name;
  final String initials;
  final double amount;
  final TransactionType type;
  final String note;

  Participant({
    required this.id,
    required this.name,
    required this.initials,
    required this.amount,
    required this.type,
    required this.note,
  });

  Participant copyWith({
    String? id,
    String? name,
    String? initials,
    double? amount,
    TransactionType? type,
    String? note,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
