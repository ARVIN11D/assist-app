import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/gemini_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();

  bool _obscureGemini = true;
  bool _obscureSupabase = true;
  bool _isSaving = false;
  String _version = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString(AppConstants.userNamePref) ?? '';
      _nameController.text = _userName;
      _geminiKeyController.text =
          prefs.getString(AppConstants.geminiApiKeyPref) ?? '';
      _supabaseUrlController.text =
          prefs.getString(AppConstants.supabaseUrlPref) ?? '';
      _supabaseKeyController.text =
          prefs.getString(AppConstants.supabaseKeyPref) ?? '';
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(
          () => _version = 'v${info.version} (${info.buildNumber})');
    } catch (_) {
      _version = 'v1.0.0';
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        AppConstants.userNamePref, _nameController.text.trim());
    await prefs.setString(AppConstants.geminiApiKeyPref,
        _geminiKeyController.text.trim());
    await prefs.setString(AppConstants.supabaseUrlPref,
        _supabaseUrlController.text.trim());
    await prefs.setString(AppConstants.supabaseKeyPref,
        _supabaseKeyController.text.trim());

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _userName = _nameController.text.trim();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _geminiKeyController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor:
            isDark ? const Color(0xFF12122A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildSectionCard(
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C6EF8), Color(0xFF5B4EE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName.isEmpty ? 'User' : _userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'ASSIST AI Secretary',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.05, end: 0),
            const SizedBox(height: 20),

            // Name
            _buildSectionLabel('PROFILE', isDark),
            _buildSectionCard(
              isDark: isDark,
              child: _buildTextField(
                controller: _nameController,
                label: 'Your Name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // Appearance
            _buildSectionLabel('APPEARANCE', isDark),
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  _ThemeTile(
                    label: 'Dark Mode',
                    icon: Icons.dark_mode_rounded,
                    isSelected: themeMode == ThemeMode.dark,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark),
                  ),
                  Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.07)),
                  _ThemeTile(
                    label: 'Light Mode',
                    icon: Icons.light_mode_rounded,
                    isSelected: themeMode == ThemeMode.light,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light),
                  ),
                  Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.07)),
                  _ThemeTile(
                    label: 'System Default',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: themeMode == ThemeMode.system,
                    isDark: isDark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // API Settings
            _buildSectionLabel('API SETTINGS', isDark),
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _geminiKeyController,
                    label: 'Gemini API Key',
                    icon: Icons.psychology_rounded,
                    isDark: isDark,
                    obscure: _obscureGemini,
                    onToggleObscure: () =>
                        setState(() => _obscureGemini = !_obscureGemini),
                    hint: 'AIza...',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _supabaseUrlController,
                    label: 'Supabase URL',
                    icon: Icons.link_rounded,
                    isDark: isDark,
                    hint: 'https://xxx.supabase.co',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _supabaseKeyController,
                    label: 'Supabase Anon Key',
                    icon: Icons.vpn_key_rounded,
                    isDark: isDark,
                    obscure: _obscureSupabase,
                    onToggleObscure: () => setState(
                        () => _obscureSupabase = !_obscureSupabase),
                    hint: 'eyJhbGciOi...',
                  ),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded,
                        color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Settings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6EF8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // About
            _buildSectionLabel('ABOUT', isDark),
            _buildSectionCard(
              isDark: isDark,
              child: Column(
                children: [
                  _AboutTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    value: _version,
                    isDark: isDark,
                  ),
                  Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.07)),
                  _AboutTile(
                    icon: Icons.code_rounded,
                    label: 'Developer',
                    value: 'ASSIST Team',
                    isDark: isDark,
                  ),
                  Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.07)),
                  _AboutTile(
                    icon: Icons.psychology_rounded,
                    label: 'AI Engine',
                    value: 'Gemini 1.5 Pro',
                    isDark: isDark,
                  ),
                  Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.07)),
                  _AboutTile(
                    icon: Icons.storage_rounded,
                    label: 'Backend',
                    value: 'Supabase + SQLite',
                    isDark: isDark,
                  ),
                ],
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E36) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF12122A)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon,
                  color: const Color(0xFF7C6EF8), size: 20),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C6EF8).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF7C6EF8)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7)),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF7C6EF8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _AboutTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              color: const Color(0xFF7C6EF8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
