import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/database_service.dart';
import '../../shared/models/khata_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';

final khataProvider =
    StateNotifierProvider<KhataNotifier, List<KhataEntry>>((ref) {
  return KhataNotifier();
});

class KhataNotifier extends StateNotifier<List<KhataEntry>> {
  KhataNotifier() : super([]) {
    _load();
  }

  final _db = DatabaseService();

  Future<void> _load() async {
    final entries = await _db.getAllKhataEntries();
    state = entries;
  }

  Future<void> refresh() => _load();

  Future<void> delete(String id) async {
    await _db.deleteKhataEntry(id);
    state = state.where((e) => e.id != id).toList();
  }
}

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<KhataEntry> _filterEntries(
      List<KhataEntry> all, String? type) {
    var filtered = all.where((e) {
      return e.date.month == _selectedMonth &&
          e.date.year == _selectedYear;
    }).toList();
    if (type != null) {
      filtered = filtered.where((e) => e.type.name == type).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(khataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF);

    // Compute summary
    double totalIncome = 0;
    double totalExpense = 0;
    double totalUdhari = 0;
    final monthEntries = _filterEntries(all, null);
    for (final e in monthEntries) {
      if (e.type == KhataType.income) totalIncome += e.amount;
      if (e.type == KhataType.expense) totalExpense += e.amount;
      if (e.type == KhataType.udhari && !e.isSettled)
        totalUdhari += e.amount;
    }
    final net = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF12122A)
                : Colors.white.withValues(alpha: 0.95),
            expandedHeight: 0,
            flexibleSpace: const FlexibleSpaceBar(),
            title: Text(
              'Khata Book',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: _showMonthPicker,
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Summary cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Income',
                          amount: totalIncome,
                          color: const Color(0xFF4ADE80),
                          icon: Icons.arrow_downward_rounded,
                          isDark: isDark,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Expense',
                          amount: totalExpense,
                          color: const Color(0xFFFF6B6B),
                          icon: Icons.arrow_upward_rounded,
                          isDark: isDark,
                        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: -0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Net Balance',
                          amount: net,
                          color: const Color(0xFF7C6EF8),
                          icon: Icons.account_balance_rounded,
                          isDark: isDark,
                        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: -0.1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Udhari',
                          amount: totalUdhari,
                          color: const Color(0xFFFBBF24),
                          icon: Icons.people_rounded,
                          isDark: isDark,
                        ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: -0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mini bar chart
                  if (monthEntries.isNotEmpty)
                    _WeeklyBarChart(
                        entries: monthEntries, isDark: isDark),
                ],
              ),
            ),
          ),
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF7C6EF8),
                unselectedLabelColor: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                indicatorColor: const Color(0xFF7C6EF8),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Income'),
                  Tab(text: 'Expense'),
                  Tab(text: 'Udhari'),
                ],
              ),
              isDark: isDark,
            ),
          ),
          // List
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KhataList(
                    entries: _filterEntries(all, null),
                    isDark: isDark,
                    onDelete: (id) =>
                        ref.read(khataProvider.notifier).delete(id)),
                _KhataList(
                    entries: _filterEntries(all, 'income'),
                    isDark: isDark,
                    onDelete: (id) =>
                        ref.read(khataProvider.notifier).delete(id)),
                _KhataList(
                    entries: _filterEntries(all, 'expense'),
                    isDark: isDark,
                    onDelete: (id) =>
                        ref.read(khataProvider.notifier).delete(id)),
                _KhataList(
                    entries: _filterEntries(all, 'udhari'),
                    isDark: isDark,
                    onDelete: (id) =>
                        ref.read(khataProvider.notifier).delete(id)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/khata/add');
          ref.read(khataProvider.notifier).refresh();
        },
        backgroundColor: const Color(0xFF7C6EF8),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Entry',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showMonthPicker() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => _selectedMonth = i + 1);
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedMonth == i + 1
                    ? const Color(0xFF7C6EF8)
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(months[i],
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_fmt(amount)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<KhataEntry> entries;
  final bool isDark;

  const _WeeklyBarChart(
      {required this.entries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Last 7 days data
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayEntries = entries.where((e) {
        return e.date.day == day.day && e.date.month == day.month;
      }).toList();
      final income = dayEntries
          .where((e) => e.type == KhataType.income)
          .fold(0.0, (s, e) => s + e.amount);
      final expense = dayEntries
          .where((e) => e.type == KhataType.expense)
          .fold(0.0, (s, e) => s + e.amount);
      return (income, expense, day);
    });

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final day = days[v.toInt()].$3;
                        final labels = [
                          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                        ];
                        return Text(
                          labels[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: days[i].$1,
                        color: const Color(0xFF4ADE80),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: days[i].$2,
                        color: const Color(0xFFFF6B6B),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KhataList extends StatelessWidget {
  final List<KhataEntry> entries;
  final bool isDark;
  final Function(String) onDelete;

  const _KhataList({
    required this.entries,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Entries',
        subtitle: 'Add income, expense or udhari entries\nto track your finances.',
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(entry.id),
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E36) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _typeColor(entry.type).withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor(entry.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon(entry.category),
                    color: _typeColor(entry.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.category.isEmpty
                            ? entry.type.name
                            : entry.category,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (entry.description.isNotEmpty)
                        Text(
                          entry.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (entry.personName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12,
                                color: Color(0xFFFBBF24)),
                            const SizedBox(width: 3),
                            Text(
                              entry.personName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.type == KhataType.expense ? '-' : '+'}₹${entry.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _typeColor(entry.type),
                      ),
                    ),
                    Text(
                      '${entry.date.day}/${entry.date.month}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    if (entry.type == KhataType.udhari &&
                        entry.isSettled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Settled',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: i * 30))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, end: 0),
        );
      },
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'salary':
        return Icons.work_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'utilities':
        return Icons.electrical_services_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
