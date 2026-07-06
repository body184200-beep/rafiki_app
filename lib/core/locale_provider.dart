import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the selected app locale, persisting it with SharedPreferences.
///
/// The [isLoaded] flag prevents UI flash: the app waits until the locale is
/// resolved before rendering, avoiding a jarring language switch on startup.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale = const Locale('ar');
  bool _isLoaded = false;

  LocaleProvider();

  /// The currently active locale (always Arabic).
  Locale? get locale => _locale;

  /// True once the persisted preference has been read from disk.
  bool get isLoaded => _isLoaded;

  /// Supported locale codes (only Arabic).
  static const List<String> supportedCodes = ['ar'];

  /// Load the persisted locale. Always uses Arabic.
  void initFromPrefs(SharedPreferences prefs) {
    _locale = const Locale('ar');
    _isLoaded = true;
  }

  /// Change the locale (disabled, does nothing to prevent changing from Arabic).
  Future<void> setLocale(Locale locale) async {
    // Only Arabic is supported
    if (locale.languageCode != 'ar') return;
    _locale = const Locale('ar');
    notifyListeners();
  }

  /// Clear any persisted preference.
  Future<void> clearLocale() async {
    _locale = const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('language_code');
    notifyListeners();
  }
}
