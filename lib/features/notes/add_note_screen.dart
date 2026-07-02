import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../../shared/models/note_model.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final NoteModel? existingNote;
  final Map<String, dynamic>? extras;

  const AddNoteScreen({
    super.key,
    this.noteId,
    this.existingNote,
    this.extras,
  });

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _db = DatabaseService();
  final _uuid = const Uuid();

  String _selectedColor = '#1E1E36';
  bool _isPinned = false;
  NoteModel? _existing;
  bool _hasChanges = false;

  static const _colorOptions = [
    Color(0xFF1E1E36),
    Color(0xFF1A3A2A),
    Color(0xFF2A1A3A),
    Color(0xFF3A2A1A),
    Color(0xFF1A2A3A),
    Color(0xFF3A1A2A),
  ];

  static const _colorHexes = [
    '#1E1E36',
    '#1A3A2A',
    '#2A1A3A',
    '#3A2A1A',
    '#1A2A3A',
    '#3A1A2A',
  ];

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note = await _db.getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _existing = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _selectedColor = note.color;
          _isPinned = note.isPinned;
        });
      }
    } else if (widget.extras != null) {
      final extras = widget.extras!;
      if (extras['title'] != null) {
        _titleController.text = extras['title'].toString();
      }
      if (extras['content'] != null) {
        _contentController.text = extras['content'].toString();
      }
    }

    _titleController.addListener(() => _hasChanges = true);
    _contentController.addListener(() => _hasChanges = true);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    final now = DateTime.now();
    if (_existing != null) {
      final updated = _existing!.copyWith(
        title: title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        updatedAt: now,
      );
      await _db.updateNote(updated);
    } else {
      final newNote = NoteModel(
        id: _uuid.v4(),
        title: title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertNote(newNote);
    }
    _hasChanges = false;
  }

  Future<bool> _onWillPop() async {
    await _save();
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _hexToColor(_selectedColor);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? bgColor : bgColor.withValues(alpha: 0.9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white),
            onPressed: () async {
              await _save();
              if (mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            _existing != null ? 'Edit Note' : 'New Note',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: _isPinned
                    ? const Color(0xFF7C6EF8)
                    : Colors.white.withValues(alpha: 0.7),
              ),
              onPressed: () => setState(() => _isPinned = !_isPinned),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              onPressed: () async {
                await _save();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    TextField(
                      controller: _contentController,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.6,
                      ),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom toolbar
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                border: const Border(
                  top: BorderSide(color: Colors.white24),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Color: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(_colorOptions.length, (i) {
                      final isSelected =
                          _selectedColor == _colorHexes[i];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedColor = _colorHexes[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          width: isSelected ? 30 : 26,
                          height: isSelected ? 30 : 26,
                          decoration: BoxDecoration(
                            color: _colorOptions[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _colorOptions[i]
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF1E1E36);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
