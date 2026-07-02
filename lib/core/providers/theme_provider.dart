import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_kThemeModeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_kThemeModeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_kThemeModeKey, 'system');
        break;
    }
  }

  Future<void> toggleTheme() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
