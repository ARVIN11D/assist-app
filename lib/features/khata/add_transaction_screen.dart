import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/services/database_service.dart';
import '../../shared/models/khata_model.dart';
import '../../shared/widgets/gradient_button.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extras;

  const AddTransactionScreen({super.key, this.extras});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _personController = TextEditingController();
  final _uuid = const Uuid();
  final _db = DatabaseService();

  KhataType _selectedType = KhataType.expense;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _udhariGive = true; // true = giving money, false = receiving

  static const _incomeCategories = [
    'Salary', 'Freelance', 'Business', 'Investment', 'Gift', 'Other'
  ];
  static const _expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Health', 'Rent', 'Utilities',
    'Entertainment', 'Education', 'Other'
  ];
  static const _udhariCategories = ['Personal', 'Business', 'Other'];

  List<String> get _categories {
    switch (_selectedType) {
      case KhataType.income:
        return _incomeCategories;
      case KhataType.expense:
        return _expenseCategories;
      case KhataType.udhari:
        return _udhariCategories;
    }
  }

  @override
  void initState() {
    super.initState();
    final extras = widget.extras;
    if (extras != null) {
      if (extras['type'] == 'expense') _selectedType = KhataType.expense;
      if (extras['type'] == 'income') _selectedType = KhataType.income;
      if (extras['amount'] != null) {
        _amountController.text = extras['amount'].toString();
      }
      if (extras['category'] != null) {
        _selectedCategory = extras['category'].toString();
      }
      if (extras['description'] != null) {
        _descController.text = extras['description'].toString();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    if (_selectedType == KhataType.udhari &&
        _personController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter person name for Udhari'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final entry = KhataEntry(
      id: _uuid.v4(),
      type: _selectedType,
      amount: amount,
      category: _selectedCategory,
      description: _descController.text.trim(),
      personName: _personController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await _db.insertKhataEntry(entry);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text('Add Entry'),
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
            // Type selector
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E36) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _TypeButton(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF4ADE80),
                    isSelected: _selectedType == KhataType.income,
                    onTap: () => setState(() {
                      _selectedType = KhataType.income;
                      _selectedCategory = _incomeCategories.first;
                    }),
                  ),
                  _TypeButton(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFFFF6B6B),
                    isSelected: _selectedType == KhataType.expense,
                    onTap: () => setState(() {
                      _selectedType = KhataType.expense;
                      _selectedCategory = _expenseCategories.first;
                    }),
                  ),
                  _TypeButton(
                    label: 'Udhari',
                    icon: Icons.people_rounded,
                    color: const Color(0xFFFBBF24),
                    isSelected: _selectedType == KhataType.udhari,
                    onTap: () => setState(() {
                      _selectedType = KhataType.udhari;
                      _selectedCategory = _udhariCategories.first;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Amount field
            Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E36) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _typeColor(_selectedType).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _typeColor(_selectedType),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Category
            _buildLabel('Category', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _typeColor(_selectedType)
                          : isDark
                              ? const Color(0xFF1E1E36)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _typeColor(_selectedType)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.black.withValues(alpha: 0.8),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Udhari direction toggle
            if (_selectedType == KhataType.udhari) ...[
              _buildLabel('Direction', isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _udhariGive = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: _udhariGive
                              ? const Color(0xFFFF6B6B)
                              : isDark
                                  ? const Color(0xFF1E1E36)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 16,
                                color: _udhariGive
                                    ? Colors.white
                                    : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'I gave',
                              style: TextStyle(
                                color: _udhariGive
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _udhariGive = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: !_udhariGive
                              ? const Color(0xFF4ADE80)
                              : isDark
                                  ? const Color(0xFF1E1E36)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded,
                                size: 16,
                                color: !_udhariGive
                                    ? Colors.white
                                    : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'I received',
                              style: TextStyle(
                                color: !_udhariGive
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Person Name', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _personController,
                hint: 'Enter person\'s name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],
            // Description
            _buildLabel('Description (optional)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descController,
              hint: 'Add a note...',
              icon: Icons.notes_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            // Date
            _buildLabel('Date', isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF1E1E36) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Color(0xFF7C6EF8)),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM y')
                          .format(_selectedDate),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            GradientButton(
              label: 'Save Entry',
              isLoading: _isSaving,
              onPressed: _save,
              gradientColors: [
                _typeColor(_selectedType),
                _typeColor(_selectedType).withValues(alpha: 0.7),
              ],
              icon: const Icon(Icons.check_rounded, color: Colors.white),
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
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.35),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF7C6EF8)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Color _typeColor(KhataType type) {
    switch (type) {
      case KhataType.income:
        return const Color(0xFF4ADE80);
      case KhataType.expense:
        return const Color(0xFFFF6B6B);
      case KhataType.udhari:
        return const Color(0xFFFBBF24);
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
