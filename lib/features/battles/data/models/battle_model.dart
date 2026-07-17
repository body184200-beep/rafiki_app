import 'package:flutter/material.dart';

class Battle {
  final String name;
  final String year;   // Hijri year
  final String emoji;
  final Color accent;

  const Battle({
    required this.name,
    required this.year,
    required this.emoji,
    required this.accent,
  });
}
