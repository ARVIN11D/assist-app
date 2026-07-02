import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/widgets/empty_state.dart';

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<ReminderModel>>(
        (ref) => RemindersNotifier());

class RemindersNotifier extends StateNotifier<List<ReminderModel>> {
  RemindersNotifier() : super([]) {
    _load();
  }

  final _db = DatabaseService();

  Future<void> _load() async {
    final all = await _db.getAllReminders();
    state = all;
  }

  Future<void> refresh() => _load();

  Future<void> complete(String id) async {
    await _db.completeReminder(id);
    state = state
        .map((r) =>
            r.id == id ? r.copyWith(isCompleted: true) : r)
        .toList();
  }

  Future<void> delete(String id) async {
    final reminder =
        state.firstWhere((r) => r.id == id, orElse: () => state.first);
    await _db.deleteReminder(id);
    await NotificationService.cancelNotification(id.hashCode);
    state = state.where((r) => r.id != id).toList();
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF);

    final now = DateTime.now();
    final todayReminders = reminders
        .where((r) =>
            !r.isCompleted &&
            r.reminderTime.year == now.year &&
            r.reminderTime.month == now.month &&
            r.reminderTime.day == now.day)
        .toList();

    final upcomingReminders = reminders
        .where((r) => !r.isCompleted && r.reminderTime.isAfter(now) && !r.isToday)
        .toList();

    final completedReminders =
        reminders.where((r) => r.isCompleted).toList();

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
            title: Text(
              'Reminders',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (reminders.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.alarm_outlined,
                title: 'No Reminders',
                subtitle:
                    'Set reminders and never miss\nimportant events again.',
                actionLabel: 'Add Reminder',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (todayReminders.isNotEmpty) ...[
                    _SectionHeader(
                        title: 'TODAY',
                        isDark: isDark,
                        color: const Color(0xFFFF6B6B)),
                    const SizedBox(height: 8),
                    ...todayReminders.asMap().entries.map(
                          (e) => _ReminderCard(
                            reminder: e.value,
                            isDark: isDark,
                            onComplete: () => ref
                                .read(remindersProvider.notifier)
                                .complete(e.value.id),
                            onDelete: () => ref
                                .read(remindersProvider.notifier)
                                .delete(e.value.id),
                          )
                              .animate(
                                  delay:
                                      Duration(milliseconds: e.key * 50))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: -0.05, end: 0),
                        ),
                    const SizedBox(height: 16),
                  ],
                  if (upcomingReminders.isNotEmpty) ...[
                    _SectionHeader(
                        title: 'UPCOMING',
                        isDark: isDark,
                        color: const Color(0xFF7C6EF8)),
                    const SizedBox(height: 8),
                    ...upcomingReminders.asMap().entries.map(
                          (e) => _ReminderCard(
                            reminder: e.value,
                            isDark: isDark,
                            onComplete: () => ref
                                .read(remindersProvider.notifier)
                                .complete(e.value.id),
                            onDelete: () => ref
                                .read(remindersProvider.notifier)
                                .delete(e.value.id),
                          )
                              .animate(
                                  delay:
                                      Duration(milliseconds: e.key * 50))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: -0.05, end: 0),
                        ),
                    const SizedBox(height: 16),
                  ],
                  if (completedReminders.isNotEmpty)
                    _CompletedSection(
                      reminders: completedReminders,
                      isDark: isDark,
                      onDelete: (id) => ref
                          .read(remindersProvider.notifier)
                          .delete(id),
                    ),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/reminder/add');
          ref.read(remindersProvider.notifier).refresh();
        },
        backgroundColor: const Color(0xFF7C6EF8),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Reminder',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isDark;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = reminder.isToday;
    final accentColor = isToday
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF7C6EF8);

    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_rounded,
            color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onDelete();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E36) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                reminder.isRecurring
                    ? Icons.repeat_rounded
                    : Icons.alarm_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color:
                          isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (reminder.description.isNotEmpty)
                    Text(
                      reminder.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a, d MMM')
                            .format(reminder.reminderTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reminder.isRecurring) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6EF8)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reminder.recurrenceType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF7C6EF8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF4ADE80)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSection extends StatefulWidget {
  final List<ReminderModel> reminders;
  final bool isDark;
  final Function(String) onDelete;

  const _CompletedSection({
    required this.reminders,
    required this.isDark,
    required this.onDelete,
  });

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF1E1E36)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFF4ADE80)),
                const SizedBox(width: 8),
                Text(
                  'Completed (${widget.reminders.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.reminders.map(
            (r) => Dismissible(
              key: Key(r.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => widget.onDelete(r.id),
              background: Container(
                margin: const EdgeInsets.only(top: 8),
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
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.title,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
