import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settingsBox';
  static const String _keyTheme = 'isDarkMode';

  bool _isDarkMode = true; // Default to dark

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  // Factory constructor to create an instance and load the theme preference
  static Future<ThemeProvider> create() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    // Default to true (dark mode) if no preference is saved
    final isDarkMode = box.get(_keyTheme, defaultValue: true);
    return ThemeProvider(isDarkMode);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final box = Hive.box(_boxName);
    await box.put(_keyTheme, _isDarkMode);
    notifyListeners();
  }
}
