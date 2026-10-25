import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/features/quran/data/models/mushaf_page_model.dart';

class QuranLocalDataSource {
  static List<Map<String, dynamic>>? _cachedSurahs;
  static List<MushafPage>? _cachedMushafPages;
  static Future<void>? _loadingFuture;

  static Future<void> _ensureLoaded() async {
    if (_cachedSurahs != null && _cachedMushafPages != null) return;
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = () async {
      try {
        final jsonString = await rootBundle.loadString('assets/quran.json');
        final result = await compute(_parseAllData, jsonString);
        _cachedSurahs = result.$1;
        _cachedMushafPages = result.$2;
      } catch (e) {
        AppLogger.warning('Failed to load Quran data', tag: 'QuranLocal', error: e);
      } finally {
        _loadingFuture = null;
      }
    }();

    return _loadingFuture!;
  }

  Future<List<Map<String, dynamic>>> getSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    await _ensureLoaded();
    return _cachedSurahs ?? [];
  }

  Future<List<MushafPage>> getMushafPages() async {
    if (_cachedMushafPages != null) return _cachedMushafPages!;
    await _ensureLoaded();
    return _cachedMushafPages ?? [];
  }

  static (List<Map<String, dynamic>>, List<MushafPage>) _parseAllData(String jsonString) {
    final decoded = jsonDecode(jsonString);
    final surahs = decoded['data']['surahs'] as List;

    final List<Map<String, dynamic>> surahList = [];
    final Map<int, List<MushafAyah>> pageAyahsMap = {};
    for (int p = 1; p <= 604; p++) {
      pageAyahsMap[p] = [];
    }

    int prevHq = 0;

    for (final s in surahs) {
      final sNum = s['number'] as int;
      final sName = s['name'] as String;
      final engName = s['englishName'] as String? ?? '';
      final sRev = s['revelationType'] as String? ?? 'Meccan';
      final ayahs = s['ayahs'] as List;
      final totalAyahs = ayahs.length;

      surahList.add({
        'number': sNum,
        'name': sName,
        'englishName': engName,
        'revelationType': sRev,
        'numberOfAyahs': s['numberOfAyahs'] as int? ?? totalAyahs,
        'ayahs': ayahs,
      });

      for (final a in ayahs) {
        final p = (a['page'] as int?) ?? 1;
        final numInSurah = (a['numberInSurah'] as int?) ?? 1;
        final hq = (a['hizbQuarter'] as int?) ?? 1;
        final juz = (a['juz'] as int?) ?? 1;
        final text = (a['text'] as String?) ?? '';

        final isHizbStart = prevHq != 0 && hq != prevHq;
        prevHq = hq;

        final ayahModel = MushafAyah(
          surahNumber: sNum,
          surahName: sName,
          numberInSurah: numInSurah,
          text: text,
          juz: juz,
          page: p,
          hizbQuarter: hq,
          isFirstInSurah: numInSurah == 1,
          isHizbQuarterStart: isHizbStart,
          surahRevelationType: sRev,
          surahTotalAyahs: totalAyahs,
        );

        if (pageAyahsMap.containsKey(p)) {
          pageAyahsMap[p]!.add(ayahModel);
        } else {
          pageAyahsMap[p] = [ayahModel];
        }
      }
    }

    final List<MushafPage> pages = [];
    for (int p = 1; p <= 604; p++) {
      final items = pageAyahsMap[p] ?? [];
      final juzNum = items.isNotEmpty ? items.first.juz : 1;
      final juzName = (juzNum >= 1 && juzNum <= kJuzArabicNames.length)
          ? kJuzArabicNames[juzNum - 1]
          : 'الجزء $juzNum';

      final primarySurah = items.isNotEmpty ? items.first.surahName : '';
      final primarySurahNum = items.isNotEmpty ? items.first.surahNumber : 1;

      String? hqText;
      final hizbAyah = items.where((a) => a.isHizbQuarterStart).firstOrNull;
      if (hizbAyah != null) {
        final hq = hizbAyah.hizbQuarter;
        final hizbNum = ((hq - 1) ~/ 4) + 1;
        final rem = hq % 4;
        if (rem == 1) {
          hqText = 'الحزب ${toArabicDigits(hizbNum)}';
        } else if (rem == 2) {
          hqText = 'ربع الحزب ${toArabicDigits(hizbNum)}';
        } else if (rem == 3) {
          hqText = 'نصف الحزب ${toArabicDigits(hizbNum)}';
        } else {
          hqText = 'ثلاثة أرباع الحزب ${toArabicDigits(hizbNum)}';
        }
      }

      pages.add(
        MushafPage(
          pageNumber: p,
          juzNumber: juzNum,
          juzName: juzName,
          primarySurahName: primarySurah,
          primarySurahNumber: primarySurahNum,
          hizbQuarterText: hqText,
          ayahs: items,
        ),
      );
    }

    return (surahList, pages);
  }
}
