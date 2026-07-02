import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/gemini_service.dart';
import '../../shared/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  bool _isSaving = false;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      title: 'Your AI Secretary',
      subtitle:
          'ASSIST uses powerful Gemini AI to understand you, manage your tasks, and help you stay organized — all in one place.',
      icon: Icons.psychology_rounded,
      gradient: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
      accent: Color(0xFF9B8DFF),
    ),
    _OnboardPage(
      title: 'Track Everything',
      subtitle:
          'Notes, expenses, udhari, reminders and todos — ASSIST keeps your entire life organized with beautiful charts and smart summaries.',
      icon: Icons.auto_graph_rounded,
      gradient: [Color(0xFF00BFA6), Color(0xFF008B75)],
      accent: Color(0xFF4DD0C4),
    ),
    _OnboardPage(
      title: 'Get Started',
      subtitle:
          "Tell ASSIST your name and let's begin your journey to a more organized life.",
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFFFF6B6B), Color(0xFFE040FB)],
      accent: Color(0xFFFFB3B3),
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name to continue'),
          backgroundColor: Color(0xFF7C6EF8),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userNamePref, name);
    await prefs.setBool(AppConstants.onboardedPref, true);

    if (!mounted) return;
    context.go('/home/chat');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pages[_currentPage].gradient.first.withValues(alpha: 0.15),
              const Color(0xFF0D0D1A),
              const Color(0xFF0D0D1A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < _pages.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 56),
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _OnboardPageView(
                    page: _pages[i],
                    nameController: i == _pages.length - 1
                        ? _nameController
                        : null,
                  ),
                ),
              ),
              // Indicator
              SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: _pages[_currentPage].accent,
                  dotColor: Colors.white.withValues(alpha: 0.3),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),
              const SizedBox(height: 40),
              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _currentPage == _pages.length - 1
                    ? GradientButton(
                        label: 'Get Started',
                        isLoading: _isSaving,
                        onPressed: _onGetStarted,
                        gradientColors: _pages[_currentPage].gradient,
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                      )
                    : GradientButton(
                        label: 'Next',
                        onPressed: _nextPage,
                        gradientColors: _pages[_currentPage].gradient,
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                      ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final bool isLast;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accent,
    this.isLast = false,
  });
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final TextEditingController? nameController;

  const _OnboardPageView({required this.page, this.nameController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in gradient circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.first.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(
                duration: 700.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
              )
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.2, end: 0),
          if (nameController != null) ...[
            const SizedBox(height: 40),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your name...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: page.accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: page.accent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 20),
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ],
      ),
    );
  }
}
