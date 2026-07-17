import 'package:flutter/material.dart';

class LifeEvent {
  final String year;
  final String event;
  final String icon;
  const LifeEvent({required this.year, required this.event, required this.icon});
}

@immutable
class Reciter {
  final String name;
  final String country;
  final String era;
  final String emoji;
  final String birth;
  final String specialty;
  final String story;
  final List<String> highlights;
  final List<LifeEvent> timeline;
  final String quranRelation;
  final String famousQuote;
  final String teachingStyle;
  final List<String> students;
  final int yearsWithQuran;

  const Reciter({
    required this.name,
    required this.country,
    required this.era,
    required this.emoji,
    required this.birth,
    required this.specialty,
    required this.story,
    required this.highlights,
    required this.timeline,
    required this.quranRelation,
    required this.famousQuote,
    required this.teachingStyle,
    required this.students,
    required this.yearsWithQuran,
  });

  String get stableKey => name;
}
