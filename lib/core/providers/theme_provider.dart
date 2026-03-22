import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { light, dark, system }

class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeNotifier() : super(ThemeModeOption.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // Default to system
    state = ThemeModeOption.values[themeIndex];
  }

  Future<void> setTheme(ThemeModeOption theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', theme.index);
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>((ref) {
  return ThemeNotifier();
});
