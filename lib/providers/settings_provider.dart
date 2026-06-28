import 'package:flutter/material.dart';
import '../db/database.dart';

class SettingsProvider extends ChangeNotifier {
  Map<String, String> _settings = {};
  String _language = 'ar';
  ThemeMode _themeMode = ThemeMode.light;
  Color _primaryColor = const Color(0xFF1565C0);

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Map<String, String> get settings => _settings;

  String get(String key, {String defaultValue = ''}) =>
      _settings[key] ?? defaultValue;

  Future<void> init() async {
    _settings = await AppDatabase.instance.getAllSettings();
    _language = _settings['language'] ?? 'ar';

    final theme = _settings['theme'] ?? 'light';
    _themeMode = theme == 'dark'
        ? ThemeMode.dark
        : theme == 'system'
            ? ThemeMode.system
            : ThemeMode.light;

    final colorStr = _settings['primary_color'];
    if (colorStr != null) {
      try {
        _primaryColor = Color(int.parse(colorStr));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setSetting(String key, String value) async {
    await AppDatabase.instance.setSetting(key, value);
    _settings[key] = value;

    if (key == 'language') _language = value;
    if (key == 'theme') {
      _themeMode = value == 'dark'
          ? ThemeMode.dark
          : value == 'system'
              ? ThemeMode.system
              : ThemeMode.light;
    }
    if (key == 'primary_color') {
      try {
        _primaryColor = Color(int.parse(value));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> updateSettings(Map<String, String> updates) async {
    for (final e in updates.entries) {
      await AppDatabase.instance.setSetting(e.key, e.value);
      _settings[e.key] = e.value;
    }
    await init();
  }
}
