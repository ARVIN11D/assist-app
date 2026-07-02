import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/gemini_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool(AppConstants.onboardedPref) ?? false;
    if (!mounted) return;
    if (isOnboarded) {
      context.go('/home/chat');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF1A1035),
              Color(0xFF0D0D1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background orbs
            Positioned(
              top: -100,
              right: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C6EF8)
                            .withValues(alpha: 0.3 + 0.15 * _pulseController.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF5B4EE0)
                            .withValues(alpha: 0.25 + 0.1 * _pulseController.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotateController.value * 6.28,
                      child: child,
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFF7C6EF8),
                            Color(0xFF9B8DFF),
                            Color(0xFF5B4EE0),
                            Color(0xFF7C6EF8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C6EF8).withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                      ),
                  const SizedBox(height: 12),
                  // Inner icon overlay
                  Transform.translate(
                    offset: const Offset(0, -86),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D0D1A),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 44,
                        color: Color(0xFF9B8DFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    'ASSIST',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF9B8DFF), Color(0xFF7C6EF8)],
                        ).createShader(
                            const Rect.fromLTWH(0, 0, 200, 50)),
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'AI Personal Secretary',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms),
                  const SizedBox(height: 60),
                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C6EF8).withValues(alpha: 0.8),
                        ),
                      )
                          .animate(
                            delay: Duration(milliseconds: 700 + i * 150),
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scaleXY(
                            begin: 0.5,
                            end: 1.2,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          )
                          .fadeIn(duration: 400.ms);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
