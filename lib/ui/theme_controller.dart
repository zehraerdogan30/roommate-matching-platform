import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode'; // 'system' | 'light' | 'dark'

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key) ?? 'system';
    _mode = _fromString(v);
    notifyListeners();
  }

  Future<void> toggleDark(bool on) async {
    _mode = on ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, _toString(_mode));
  }

  ThemeMode _fromString(String v) {
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
