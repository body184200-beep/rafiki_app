import 'package:flutter/material.dart';

class DuaCategory {
  final String label;
  final IconData icon;
  const DuaCategory({required this.label, required this.icon});
}

class DuaData {
  final String category;
  final String title;
  final String dua;
  final String fadl;
  final String source;
  final String when;
  final int repeat;
  final IconData icon;
  final Color accentA;
  final Color accentB;
  final bool isFeatured;

  const DuaData({
    required this.category,
    required this.title,
    required this.dua,
    required this.fadl,
    required this.source,
    required this.when,
    required this.repeat,
    required this.icon,
    required this.accentA,
    required this.accentB,
    this.isFeatured = false,
  });
}
