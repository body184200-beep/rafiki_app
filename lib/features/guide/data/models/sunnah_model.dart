import 'package:flutter/material.dart';

class SunnahCategory {
  const SunnahCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class SunnahItem {
  const SunnahItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.hadith,
    required this.fadl,
    required this.practicalTip,
    required this.source,
    required this.icon,
    this.badge = '',
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String hadith;
  final String fadl;
  final String practicalTip;
  final String source;
  final String badge;
  final IconData icon;
}
