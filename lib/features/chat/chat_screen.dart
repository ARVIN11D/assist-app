import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/chat_message_model.dart';
import '../../shared/widgets/glass_card.dart';

final _geminiServiceProvider = Provider<GeminiService?>((ref) {
  // Will be initialized lazily from prefs
  return null;
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _userName = 'there';
  String _sessionId = '';
  GeminiService? _gemini;

  static const _quickActions = [
    ('Add expense', Icons.receipt_long_rounded, '/khata/add'),
    ('Set reminder', Icons.alarm_rounded, '/reminder/add'),
    ('New note', Icons.note_add_rounded, '/note/add'),
    ('My todos', Icons.checklist_rounded, '/home/todo'),
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(AppConstants.userNamePref) ?? 'there';
    _sessionId = prefs.getString(AppConstants.chatSessionIdPref) ??
        _uuid.v4();
    await prefs.setString(AppConstants.chatSessionIdPref, _sessionId);

    final apiKey =
        prefs.getString(AppConstants.geminiApiKeyPref) ?? '';
    if (apiKey.isNotEmpty) {
      _gemini = GeminiService(apiKey: apiKey);
    }

    // Load messages from DB
    final saved = await _db.getChatMessages(_sessionId);
    if (!mounted) return;

    setState(() {
      _messages = saved;
      if (_messages.isEmpty) {
        // Add greeting
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          role: MessageRole.ai,
          content:
              'Hello $_userName! 👋 I\'m ASSIST, your AI Personal Secretary.\n\nHow can I help you today? You can ask me anything, or use the quick actions below.',
          sessionId: _sessionId,
          timestamp: DateTime.now(),
        ));
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _msgController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _msgController.clear();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    // Persist user message
    await _db.insertChatMessage(userMsg);

    String aiResponse =
        'I\'d love to help, but my AI is not configured yet.\n\nPlease add your **Gemini API key** in Settings → API Settings.';

    if (_gemini != null) {
      // Build history (last 20 messages excluding current)
      final history = _messages
          .sublist(max(0, _messages.length - 20), _messages.length - 1)
          .map((m) => m.toGeminiHistory())
          .toList();

      aiResponse = await _gemini!.sendMessage(text, history: history);

      // Try intent parsing for action cards
      final intent = await _gemini!.parseIntent(text);
      if (intent != null && intent['intent'] != 'general') {
        _handleIntent(intent);
      }
    }

    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.ai,
      content: aiResponse,
      sessionId: _sessionId,
      timestamp: DateTime.now(),
    );

    await _db.insertChatMessage(aiMsg);

    if (!mounted) return;
    setState(() {
      _messages.add(aiMsg);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _handleIntent(Map<String, dynamic> intent) {
    final type = intent['intent'] as String;
    Map<String, dynamic>? extra;

    switch (type) {
      case 'add_expense':
        extra = {
          'type': 'expense',
          'amount': intent['amount'],
          'category': intent['category'],
          'description': intent['description'],
        };
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.push('/khata/add', extra: extra);
        });
        break;
      case 'add_reminder':
        extra = {
          'title': intent['title'],
          'datetime': intent['datetime'],
        };
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.push('/reminder/add', extra: extra);
        });
        break;
      case 'add_note':
        extra = {
          'title': intent['title'],
          'content': intent['content'],
        };
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.push('/note/add', extra: extra);
        });
        break;
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0D0D1A),
                    const Color(0xFF12122A),
                  ]
                : [
                    const Color(0xFFF5F5FF),
                    const Color(0xFFEEECFF),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: _messages.isEmpty && !_isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C6EF8),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount:
                          _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length && _isLoading) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(
                            _messages[i], isDark)
                            .animate(delay: Duration(milliseconds: i < 10 ? i * 30 : 0))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
            ),
            // Quick actions
            if (_messages.length <= 2) _buildQuickActions(isDark),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12122A)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
              ),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ASSIST AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings_outlined,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
                ),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : isDark
                        ? const Color(0xFF1E1E36)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                      Radius.circular(isUser ? 20 : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? const Color(0xFF7C6EF8)
                            : Colors.black)
                        .withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : isDark
                          ? Colors.white.withValues(alpha: 0.92)
                          : Colors.black.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
              ),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E36),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C6EF8),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                      delay: Duration(milliseconds: i * 200),
                    )
                    .scaleXY(
                      begin: 0.6,
                      end: 1.0,
                      duration: 500.ms,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(action.$2,
                    size: 16, color: const Color(0xFF7C6EF8)),
                label: Text(action.$1),
                onPressed: () {
                  if (action.$3.startsWith('/home')) {
                    context.go(action.$3);
                  } else {
                    context.push(action.$3);
                  }
                },
                backgroundColor: isDark
                    ? const Color(0xFF1E1E36)
                    : Colors.white,
                side: BorderSide(
                  color: const Color(0xFF7C6EF8).withValues(alpha: 0.3),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.black.withValues(alpha: 0.85),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12122A)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E36)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _msgController,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textInputAction: TextInputAction.send,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Message ASSIST...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? const LinearGradient(
                        colors: [Colors.grey, Colors.grey])
                    : const LinearGradient(
                        colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
                      ),
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF7C6EF8)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
