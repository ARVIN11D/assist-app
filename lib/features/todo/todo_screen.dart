import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/database_service.dart';
import '../../shared/models/todo_model.dart';
import '../../shared/widgets/empty_state.dart';

final todosProvider =
    StateNotifierProvider<TodosNotifier, List<TodoModel>>(
        (ref) => TodosNotifier());

class TodosNotifier extends StateNotifier<List<TodoModel>> {
  TodosNotifier() : super([]) {
    _load();
  }

  final _db = DatabaseService();

  Future<void> _load() async {
    final all = await _db.getAllTodos();
    state = all;
  }

  Future<void> refresh() => _load();

  Future<void> toggle(String id) async {
    final todo = state.firstWhere((t) => t.id == id);
    await _db.toggleTodo(id, !todo.isCompleted);
    state = state
        .map((t) => t.id == id
            ? t.copyWith(isCompleted: !t.isCompleted)
            : t)
        .toList();
  }

  Future<void> delete(String id) async {
    await _db.deleteTodo(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> add(TodoModel todo) async {
    await _db.insertTodo(todo);
    state = [todo, ...state];
  }
}

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF);

    final total = todos.length;
    final done = todos.where((t) => t.isCompleted).length;
    final progress = total == 0 ? 0.0 : done / total;

    final highTodos =
        todos.where((t) => t.priority == TodoPriority.high).toList();
    final medTodos = todos
        .where((t) => t.priority == TodoPriority.medium)
        .toList();
    final lowTodos =
        todos.where((t) => t.priority == TodoPriority.low).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF12122A)
                : Colors.white.withValues(alpha: 0.95),
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Todos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            valueColor:
                                const AlwaysStoppedAnimation(
                                    Color(0xFF7C6EF8)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$done/$total',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (todos.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.checklist_rounded,
                title: 'No Todos Yet',
                subtitle:
                    'Add your first task and start\nbeing productive!',
                actionLabel: 'Add Todo',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (highTodos.isNotEmpty)
                    _PrioritySection(
                      title: 'HIGH PRIORITY',
                      color: const Color(0xFFFF6B6B),
                      todos: highTodos,
                      isDark: isDark,
                      onToggle: (id) =>
                          ref.read(todosProvider.notifier).toggle(id),
                      onDelete: (id) =>
                          ref.read(todosProvider.notifier).delete(id),
                    ),
                  if (medTodos.isNotEmpty)
                    _PrioritySection(
                      title: 'MEDIUM PRIORITY',
                      color: const Color(0xFFFBBF24),
                      todos: medTodos,
                      isDark: isDark,
                      onToggle: (id) =>
                          ref.read(todosProvider.notifier).toggle(id),
                      onDelete: (id) =>
                          ref.read(todosProvider.notifier).delete(id),
                    ),
                  if (lowTodos.isNotEmpty)
                    _PrioritySection(
                      title: 'LOW PRIORITY',
                      color: const Color(0xFF4ADE80),
                      todos: lowTodos,
                      isDark: isDark,
                      onToggle: (id) =>
                          ref.read(todosProvider.notifier).toggle(id),
                      onDelete: (id) =>
                          ref.read(todosProvider.notifier).delete(id),
                    ),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoSheet(context, ref, isDark),
        backgroundColor: const Color(0xFF7C6EF8),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Todo',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showAddTodoSheet(
      BuildContext context, WidgetRef ref, bool isDark) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TodoPriority priority = TodoPriority.medium;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E36) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Todo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF7C6EF8), width: 2),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF12122A)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              // Priority
              Row(
                children: [
                  Text('Priority: ',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7))),
                  const SizedBox(width: 8),
                  ...[TodoPriority.high, TodoPriority.medium, TodoPriority.low]
                      .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () =>
                            setSheet(() => priority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: priority == p
                                ? _priorityColor(p)
                                : _priorityColor(p).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.name[0].toUpperCase() +
                                p.name.substring(1),
                            style: TextStyle(
                              color: priority == p
                                  ? Colors.white
                                  : _priorityColor(p),
                              fontSize: 12,
                              fontWeight: priority == p
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final todo = TodoModel(
                      id: const Uuid().v4(),
                      title: title,
                      priority: priority,
                      dueDate: dueDate,
                      createdAt: DateTime.now(),
                    );
                    ref.read(todosProvider.notifier).add(todo);
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6EF8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add Todo',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return const Color(0xFFFF6B6B);
      case TodoPriority.medium:
        return const Color(0xFFFBBF24);
      case TodoPriority.low:
        return const Color(0xFF4ADE80);
    }
  }
}

class _PrioritySection extends StatelessWidget {
  final String title;
  final Color color;
  final List<TodoModel> todos;
  final bool isDark;
  final Function(String) onToggle;
  final Function(String) onDelete;

  const _PrioritySection({
    required this.title,
    required this.color,
    required this.todos,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        ...todos.asMap().entries.map(
              (e) => _TodoItem(
                todo: e.value,
                color: color,
                isDark: isDark,
                onToggle: () => onToggle(e.value.id),
                onDelete: () => onDelete(e.value.id),
              )
                  .animate(
                      delay: Duration(milliseconds: e.key * 40))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.04, end: 0),
            ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  final TodoModel todo;
  final Color color;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItem({
    required this.todo,
    required this.color,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E36) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: todo.isCompleted ? 0.1 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.isCompleted
                      ? color
                      : Colors.transparent,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: todo.isCompleted
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.35))
                          : (isDark ? Colors.white : Colors.black),
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (todo.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 11,
                              color: _isDueSoon(todo.dueDate!)
                                  ? const Color(0xFFFF6B6B)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('d MMM').format(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: _isDueSoon(todo.dueDate!)
                                  ? const Color(0xFFFF6B6B)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: todo.isCompleted
                    ? color.withValues(alpha: 0.3)
                    : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDueSoon(DateTime due) {
    return due.isBefore(DateTime.now().add(const Duration(days: 1)));
  }
}
