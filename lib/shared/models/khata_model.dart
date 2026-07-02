enum KhataType { income, expense, udhari }

extension KhataTypeX on KhataType {
  String get name {
    switch (this) {
      case KhataType.income:
        return 'income';
      case KhataType.expense:
        return 'expense';
      case KhataType.udhari:
        return 'udhari';
    }
  }

  static KhataType fromString(String value) {
    switch (value) {
      case 'income':
        return KhataType.income;
      case 'expense':
        return KhataType.expense;
      case 'udhari':
        return KhataType.udhari;
      default:
        return KhataType.expense;
    }
  }
}

class KhataEntry {
  final String id;
  final KhataType type;
  final double amount;
  final String category;
  final String description;
  final String personName; // used for udhari
  final DateTime date;
  final bool isSettled; // for udhari
  final DateTime createdAt;

  const KhataEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description = '',
    this.personName = '',
    required this.date,
    this.isSettled = false,
    required this.createdAt,
  });

  KhataEntry copyWith({
    String? id,
    KhataType? type,
    double? amount,
    String? category,
    String? description,
    String? personName,
    DateTime? date,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return KhataEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      personName: personName ?? this.personName,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'category': category,
      'description': description,
      'person_name': personName,
      'date': date.millisecondsSinceEpoch,
      'is_settled': isSettled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory KhataEntry.fromMap(Map<String, dynamic> map) {
    return KhataEntry(
      id: map['id'] as String,
      type: KhataTypeX.fromString(map['type'] as String? ?? 'expense'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      personName: map['person_name'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int? ?? 0),
      isSettled: (map['is_settled'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
