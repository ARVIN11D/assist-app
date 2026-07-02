import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blurSigma;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.opacity = 0.15,
    this.blurSigma = 12.0,
    this.borderColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity + 0.3));
    final effectiveBorder =
        borderColor ?? Colors.white.withValues(alpha: isDark ? 0.2 : 0.5);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(20);

    Widget card = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: effectiveBorder,
              width: 1.2,
            ),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
