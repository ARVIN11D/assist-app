import 'package:flutter/material.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? gradientColors;
  final double? width;
  final double height;
  final Widget? icon;
  final double borderRadius;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradientColors,
    this.width,
    this.height = 54,
    this.icon,
    this.borderRadius = 16,
    this.textStyle,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.forward();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        [
          const Color(0xFF7C6EF8),
          const Color(0xFF9B8DFF),
          const Color(0xFF5B4EE0),
        ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : _onTapDown,
        onTapUp: widget.isLoading ? null : _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLoading
                  ? [Colors.grey.shade600, Colors.grey.shade700]
                  : colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: widget.textStyle ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
