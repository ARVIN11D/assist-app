import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
        label: 'Chat',
        route: '/home/chat'),
    _NavItem(
        icon: Icons.note_outlined,
        activeIcon: Icons.note_rounded,
        label: 'Notes',
        route: '/home/notes'),
    _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Khata',
        route: '/home/khata'),
    _NavItem(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: 'Todos',
        route: '/home/todo'),
    _NavItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Reminders',
        route: '/home/reminders'),
  ];

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    // Sync selected index from current route
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        if (_selectedIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedIndex = i),
          );
        }
        break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12122A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: isSelected
                          ? BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C6EF8),
                                  Color(0xFF5B4EE0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C6EF8)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? Colors.white
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
