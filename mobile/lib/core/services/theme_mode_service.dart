import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeService extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.light;
    await prefs.setString(_key, 'light');
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, enabled ? 'dark' : 'light');
  }
}
