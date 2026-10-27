import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._();
  ThemeProvider._();
  factory ThemeProvider() => instance;

  bool _isLight = false;
  bool get isLight => _isLight;

  Future<void> initFromPrefs(SharedPreferences prefs) async {
    _isLight = prefs.getBool('is_light_theme') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isLight = !_isLight;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_light_theme', _isLight);
  }

  Future<void> setLightMode(bool value) async {
    if (_isLight == value) return;
    _isLight = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_light_theme', _isLight);
  }
}
