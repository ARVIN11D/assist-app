import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/database_service.dart';
import '../../shared/models/note_model.dart';
import '../../shared/widgets/empty_state.dart';

final notesProvider =
    StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier() : super([]) {
    _load();
  }

  final _db = DatabaseService();

  Future<void> _load() async {
    final notes = await _db.getAllNotes();
    state = notes;
  }

  Future<void> refresh() => _load();

  Future<void> delete(String id) async {
    await _db.deleteNote(id);
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    await _db.togglePinNote(id, !note.isPinned);
    state = state
        .map((n) =>
            n.id == id ? n.copyWith(isPinned: !n.isPinned) : n)
        .toList();
  }

  void search(String query) async {
    if (query.isEmpty) {
      await _load();
      return;
    }
    final results = await _db.searchNotes(query);
    state = results;
  }
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _isGrid = true;
  final _searchController = TextEditingController();

  static const _noteColors = [
    Color(0xFF1E1E36),
    Color(0xFF1A3A2A),
    Color(0xFF2A1A3A),
    Color(0xFF3A2A1A),
    Color(0xFF1A2A3A),
    Color(0xFF3A1A2A),
  ];

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _noteColors.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF);

    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark
                ? const Color(0xFF12122A)
                : Colors.white.withValues(alpha: 0.95),
            expandedHeight: 60,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isGrid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded),
                onPressed: () =>
                    setState(() => _isGrid = !_isGrid),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: _NoteSearchDelegate(ref),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (notes.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.note_outlined,
                title: 'No Notes Yet',
                subtitle:
                    'Tap the + button to create your first note.\nYour thoughts, organized.',
                actionLabel: 'Create Note',
              ),
            )
          else ...[
            if (pinned.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin_rounded,
                          size: 14, color: Color(0xFF7C6EF8)),
                      const SizedBox(width: 6),
                      Text(
                        'PINNED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildNoteGrid(pinned, isDark),
              ),
            ],
            if (unpinned.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    pinned.isEmpty ? '' : 'OTHERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: _buildNoteGrid(unpinned, isDark),
              ),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/note/add');
          ref.read(notesProvider.notifier).refresh();
        },
        backgroundColor: const Color(0xFF7C6EF8),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Note',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNoteGrid(List<NoteModel> notes, bool isDark) {
    if (_isGrid) {
      return SliverMasonryGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childCount: notes.length,
        itemBuilder: (_, i) =>
            _buildNoteCard(notes[i], isDark)
                .animate(delay: Duration(milliseconds: i * 40))
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildNoteCard(notes[i], isDark)
              .animate(delay: Duration(milliseconds: i * 40))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0),
        ),
        childCount: notes.length,
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note, bool isDark) {
    final cardColor = _hexToColor(note.color);

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(notesProvider.notifier).delete(note.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () =>
                    ref.read(notesProvider.notifier).refresh(),
              ),
              backgroundColor: const Color(0xFF7C6EF8),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () async {
          await context.push('/note/${note.id}');
          ref.read(notesProvider.notifier).refresh();
        },
        onLongPress: () async {
          await ref
              .read(notesProvider.notifier)
              .togglePin(note.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? cardColor : cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isPinned)
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.push_pin_rounded,
                      size: 14, color: Color(0xFF7C6EF8)),
                ),
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                  maxLines: _isGrid ? 6 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: note.tags
                      .take(3)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NoteSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  _NoteSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear), onPressed: () => query = '')
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    ref.read(notesProvider.notifier).search(query);
    return _buildResultList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    ref.read(notesProvider.notifier).search(query);
    return _buildResultList(context);
  }

  Widget _buildResultList(BuildContext context) {
    final notes = ref.watch(notesProvider);
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(
            note.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, note.id);
            context.push('/note/${note.id}');
          },
        );
      },
    );
  }
}
