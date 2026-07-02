import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/models/reminder_model.dart';
import '../../shared/widgets/gradient_button.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extras;

  const AddReminderScreen({super.key, this.extras});

  @override
  ConsumerState<AddReminderScreen> createState() =>
      _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();
  final _db = DatabaseService();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  String _recurrenceType = 'daily';
  bool _isSaving = false;

  static const _recurrenceOptions = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    final extras = widget.extras;
    if (extras != null) {
      if (extras['title'] != null) {
        _titleController.text = extras['title'].toString();
      }
      if (extras['datetime'] != null) {
        try {
          _selectedDateTime =
              DateTime.parse(extras['datetime'].toString());
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reminder title'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder time must be in the future'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final reminder = ReminderModel(
      id: _uuid.v4(),
      title: title,
      description: _descController.text.trim(),
      reminderTime: _selectedDateTime,
      isRecurring: _isRecurring,
      recurrenceType: _isRecurring ? _recurrenceType : '',
      createdAt: DateTime.now(),
    );

    await _db.insertReminder(reminder);

    // Schedule notification
    await NotificationService.scheduleReminder(
      id: reminder.id.hashCode,
      title: '⏰ $title',
      body: _descController.text.trim().isEmpty
          ? 'Time for your reminder!'
          : _descController.text.trim(),
      scheduledTime: _selectedDateTime,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text('New Reminder'),
        backgroundColor:
            isDark ? const Color(0xFF12122A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildLabel('Reminder Title', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'What do you want to remember?',
              icon: Icons.alarm_rounded,
              isDark: isDark,
              fontSize: 18,
            ),
            const SizedBox(height: 20),
            // Description
            _buildLabel('Note (optional)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descController,
              hint: 'Add a note...',
              icon: Icons.notes_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            // Date & Time
            _buildLabel('When?', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _InfoTile(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat('EEE, d MMM')
                          .format(_selectedDateTime),
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _InfoTile(
                      icon: Icons.access_time_rounded,
                      label: DateFormat('hh:mm a')
                          .format(_selectedDateTime),
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recurring toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E36) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isRecurring
                      ? const Color(0xFF7C6EF8).withValues(alpha: 0.5)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded,
                          color: Color(0xFF7C6EF8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring Reminder',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              'Repeat this reminder',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) =>
                            setState(() => _isRecurring = v),
                        activeColor: const Color(0xFF7C6EF8),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Row(
                      children:
                          _recurrenceOptions.map((opt) {
                        final isSelected = _recurrenceType == opt;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _recurrenceType = opt),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C6EF8)
                                    : isDark
                                        ? const Color(0xFF12122A)
                                        : Colors.grey.shade100,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                opt[0].toUpperCase() +
                                    opt.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.7)
                                          : Colors.black
                                              .withValues(alpha: 0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),
            GradientButton(
              label: 'Set Reminder',
              isLoading: _isSaving,
              onPressed: _save,
              icon: const Icon(Icons.alarm_add_rounded,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.2,
        color: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    double fontSize = 15,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: fontSize,
          fontWeight:
              fontSize > 15 ? FontWeight.w600 : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.35),
            fontSize: fontSize,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF7C6EF8)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoTile(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C6EF8).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7C6EF8)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
