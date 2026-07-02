enum TodoPriority { high, medium, low }

extension TodoPriorityX on TodoPriority {
  String get name {
    switch (this) {
      case TodoPriority.high:
        return 'high';
      case TodoPriority.medium:
        return 'medium';
      case TodoPriority.low:
        return 'low';
    }
  }

  static TodoPriority fromString(String value) {
    switch (value) {
      case 'high':
        return TodoPriority.high;
      case 'low':
        return TodoPriority.low;
      default:
        return TodoPriority.medium;
    }
  }
}

class TodoModel {
  final String id;
  final String title;
  final String description;
  final TodoPriority priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const TodoModel({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TodoPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    TodoPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    bool clearDueDate = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: TodoPriorityX.fromString(map['priority'] as String? ?? 'medium'),
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
