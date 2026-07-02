import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? const Color(0xFF7C6EF8);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .animate(delay: 450.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
