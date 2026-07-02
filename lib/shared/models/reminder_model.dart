class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime reminderTime;
  final bool isRecurring;
  final String recurrenceType; // 'daily' | 'weekly' | 'monthly' | ''
  final bool isCompleted;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.reminderTime,
    this.isRecurring = false,
    this.recurrenceType = '',
    this.isCompleted = false,
    required this.createdAt,
  });

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderTime,
    bool? isRecurring,
    String? recurrenceType,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminder_time': reminderTime.millisecondsSinceEpoch,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_type': recurrenceType,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      reminderTime: DateTime.fromMillisecondsSinceEpoch(
          map['reminder_time'] as int? ?? 0),
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceType: map['recurrence_type'] as String? ?? '',
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? 0),
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return reminderTime.year == now.year &&
        reminderTime.month == now.month &&
        reminderTime.day == now.day;
  }

  bool get isUpcoming {
    return reminderTime.isAfter(DateTime.now()) && !isToday;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
