enum MessageRole { user, ai }

extension MessageRoleX on MessageRole {
  String get name {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.ai:
        return 'ai';
    }
  }

  static MessageRole fromString(String value) {
    if (value == 'user') return MessageRole.user;
    return MessageRole.ai;
  }
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String sessionId;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.sessionId,
    required this.timestamp,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAi => role == MessageRole.ai;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'session_id': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: MessageRoleX.fromString(map['role'] as String? ?? 'ai'),
      content: map['content'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int? ?? 0),
    );
  }

  /// Converts to a format suitable for Gemini history
  Map<String, String> toGeminiHistory() {
    return {
      'role': isUser ? 'user' : 'model',
      'content': content,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
