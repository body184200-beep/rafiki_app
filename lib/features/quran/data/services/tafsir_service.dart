import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rafiki_app/core/logging/app_logger.dart';

class TafsirEdition {
  final String id;
  final String name;
  final int quranDotComId;
  final bool isOffline;

  const TafsirEdition({
    required this.id,
    required this.name,
    required this.quranDotComId,
    this.isOffline = true,
  });
}

const List<TafsirEdition> kTafsirEditions = [
  TafsirEdition(
    id: 'ar.muyassar',
    name: 'الميسر',
    quranDotComId: 16,
    isOffline: true,
  ),
  TafsirEdition(
    id: 'ar.saadi',
    name: 'السعدي',
    quranDotComId: 169,
    isOffline: true,
  ),
  TafsirEdition(
    id: 'ar.jalalayn',
    name: 'الجلالين',
    quranDotComId: 171,
    isOffline: true,
  ),
];

class TafsirService {
  TafsirService._();
  static final TafsirService instance = TafsirService._();

  static final Map<String, String> _cache = {};
  static final Map<String, Map<String, String>> _offlineData = {};
  static final Map<String, Future<void>> _loadingFutures = {};

  static const Map<String, String> _editionAssetMap = {
    'ar.muyassar': 'assets/tafsir_muyassar.json',
    'ar.saadi': 'assets/tafsir_saadi.json',
    'ar.jalalayn': 'assets/tafsir_jalalayn.json',
  };

  /// Preloads or lazy-loads the selected offline Tafsir dataset from assets
  Future<void> _loadEdition(String edition) async {
    if (_offlineData.containsKey(edition)) return;
    if (_loadingFutures.containsKey(edition)) return _loadingFutures[edition]!;

    final assetPath = _editionAssetMap[edition] ?? 'assets/tafsir_muyassar.json';

    final future = () async {
      try {
        final jsonStr = await rootBundle.loadString(assetPath);
        final dynamic decoded = jsonDecode(jsonStr);
        final Map<String, String> map = {};
        if (decoded is Map) {
          decoded.forEach((k, v) {
            map[k.toString()] = v.toString();
          });
        }
        _offlineData[edition] = map;
        AppLogger.info('Loaded offline Tafsir ($edition) with ${map.length} verses', tag: 'TafsirService');
      } catch (e) {
        AppLogger.warning('Failed to load local tafsir asset $assetPath: $e', tag: 'TafsirService');
      }
    }();

    _loadingFutures[edition] = future;
    return future;
  }

  /// Retrieves Ayah Tafsir with Instant Offline-First Architecture
  /// 1. Instant check from local bundled datasets (الميسر، السعدي، الجلالين - 100% بدون إنترنت).
  /// 2. If missing, fallbacks to Al-Muyassar offline dataset.
  /// 3. If still missing and online, queries AlQuran Cloud and Quran.com APIs.
  Future<String?> getAyahTafsir({
    required int surahNumber,
    required int ayahNumber,
    String edition = 'ar.muyassar',
  }) async {
    final key = '$surahNumber:$ayahNumber';
    final cacheKey = '$edition:$key';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 1. Offline-First check from bundled assets
    await _loadEdition(edition);
    final offlineMap = _offlineData[edition];
    if (offlineMap != null && offlineMap.containsKey(key)) {
      final text = _cleanText(offlineMap[key]!);
      if (text.isNotEmpty) {
        _cache[cacheKey] = text;
        return text;
      }
    }

    // 2. Fallback to offline Al-Muyassar if another edition was requested but missing this verse
    if (edition != 'ar.muyassar') {
      await _loadEdition('ar.muyassar');
      final fallbackMap = _offlineData['ar.muyassar'];
      if (fallbackMap != null && fallbackMap.containsKey(key)) {
        final text = _cleanText(fallbackMap[key]!);
        if (text.isNotEmpty) {
          _cache[cacheKey] = text;
          return text;
        }
      }
    }

    // 3. Online fallback: Try AlQuran Cloud API
    try {
      final url = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/$edition',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final text = _cleanText(data['data']['text'] as String? ?? '');
          if (text.isNotEmpty) {
            _cache[cacheKey] = text;
            return text;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('AlQuran Cloud Tafsir failed: $e', tag: 'TafsirService');
    }

    // 4. Online fallback: Quran.com API v4
    try {
      final qdcId = _getQdcId(edition);
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/$qdcId/by_ayah/$surahNumber:$ayahNumber',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tafsir'] != null && data['tafsir']['text'] != null) {
          final text = _cleanText(data['tafsir']['text'] as String);
          if (text.isNotEmpty) {
            _cache[cacheKey] = text;
            return text;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Quran.com Tafsir fallback failed: $e', tag: 'TafsirService');
    }

    return null;
  }

  int _getQdcId(String edition) {
    for (final e in kTafsirEditions) {
      if (e.id == edition) return e.quranDotComId;
    }
    return 16;
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
