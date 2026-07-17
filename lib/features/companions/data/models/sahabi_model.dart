import 'package:flutter/material.dart';

class Sahabi {
  final String name;
  final String title;
  final String initial;
  final Color accent;
  final List<String> categories;

  const Sahabi({
    required this.name,
    required this.title,
    required this.initial,
    required this.accent,
    required this.categories,
  });
}
