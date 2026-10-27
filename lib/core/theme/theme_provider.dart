import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  static final ThemeProvider instance = ThemeProvider._();
  static const _key = 'theme_is_light';

  bool _isLight = false;

  bool get isLight => _isLight;

  Future<void> initFromPrefs(SharedPreferences prefs) async {
    _isLight = prefs.getBool(_key) ?? false;
  }

  Future<void> toggleTheme() async {
    _isLight = !_isLight;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isLight);
  }
}
