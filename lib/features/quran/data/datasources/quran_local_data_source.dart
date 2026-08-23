import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';

class QuranLocalDataSource {
  static List<Map<String, dynamic>>? _cachedSurahs;

  Future<List<Map<String, dynamic>>> getSurahs() async {
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/quran.json');
      final parsed = await compute(_parseQuran, jsonString);
      _cachedSurahs = parsed;
      return parsed;
    } catch (e) {
      AppLogger.warning('Failed to load Quran data', tag: 'QuranLocal', error: e);
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseQuran(String jsonString) {
    final decoded = jsonDecode(jsonString);
    final data = decoded['data']['surahs'] as List;
    return data.map<Map<String, dynamic>>((s) {
      final ayahsList = s['ayahs'] as List;
      return {
        'number': s['number'] as int,
        'name': s['name'] as String,
        'englishName': s['englishName'] as String,
        'revelationType': s['revelationType'] as String? ?? '',
        'numberOfAyahs': s['numberOfAyahs'] as int? ?? ayahsList.length,
        'ayahs': s['ayahs'],
      };
    }).toList();
  }
}
