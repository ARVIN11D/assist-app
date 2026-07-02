import 'dart:convert';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final String color; // hex string e.g. '#7C6EF8'
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.color = '#1E1E2E',
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? color,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'tags': jsonEncode(tags),
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && (map['tags'] as String).isNotEmpty) {
      final decoded = jsonDecode(map['tags'] as String);
      if (decoded is List) {
        parsedTags = decoded.cast<String>();
      }
    }
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      color: map['color'] as String? ?? '#1E1E2E',
      tags: parsedTags,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updated_at'] as int? ?? 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, isPinned: $isPinned)';
  }
}
