import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark mode state, persisted across launches.
///
/// `main.dart` listens to [mode] and rebuilds the [MaterialApp];
/// any screen can read or toggle it without a context lookup.
class ThemeController {
  ThemeController._();

  static const _key = 'dark_mode';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value =
        (prefs.getBool(_key) ?? false)
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static Future<void> toggle() async {
    final dark = mode.value != ThemeMode.dark;
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dark);
  }
}
