import 'package:flutter/material.dart';

class SunnahCategory {
  final String id;
  final String label;
  final IconData icon;

  const SunnahCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class SunnahItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final String hadith;
  final String fadl;
  final String source;
  final String practicalTip;
  final String badge;
  final IconData icon;
  final Color accentA;
  final Color accentB;
  final bool isFeatured;

  const SunnahItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.hadith,
    required this.fadl,
    required this.source,
    required this.practicalTip,
    required this.badge,
    required this.icon,
    required this.accentA,
    required this.accentB,
    this.isFeatured = false,
  });
}
