import 'package:flutter/material.dart';

/// Shared visual language for Rafiki.
///
/// Feature screens may still use a local accent, but chrome (shell, nav,
/// dialogs, snackbars) should read from these tokens so the app feels one piece.
abstract final class AppColors {
  static const Color bg = Color(0xFF080C12);
  static const Color bgDeep = Color(0xFF05080C);
  static const Color bgMid = Color(0xFF0C1520);
  static const Color surface = Color(0xFF111620);
  static const Color surfaceHi = Color(0xFF161D2A);

  static const Color border = Color(0xFF1E2738);
  static const Color borderHi = Color(0xFF2A3548);

  static const Color accent = Color(0xFF4ECCA3);
  static const Color accentDim = Color(0xFF1D9E75);
  static const Color accentDark = Color(0xFF0E6B4E);

  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFF0C870);
  static const Color goldDim = Color(0xFF8A6E2A);

  static const Color textPrimary = Color(0xFFEEF0F4);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textOnGold = Color(0xFF1A1408);

  static const Color error = Color(0xFFE05252);
  static const Color warning = Color(0xFFE8A030);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF05211B), Color(0xFF080C12)],
  );
}
