import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/hadith.dart';

class HadithLocalDataSource {
  List<HadithModel>? _localHadiths;

  Future<void> loadLocalHadiths() async {
    if (_localHadiths != null) return;
    try {
      final localJsonString = await rootBundle.loadString('assets/hadith.json');
      final decoded = jsonDecode(localJsonString);
      final hadithsList = decoded['data']['hadiths'] as List;
      _localHadiths = hadithsList.map<HadithModel>((e) => HadithModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading assets/hadith.json: $e');
      }
      _localHadiths = [];
    }
  }

  List<HadithModel>? get cachedLocalHadiths => _localHadiths;

  Future<List<HadithModel>?> getCachedHadiths(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as List;
        return decoded.map((e) => HadithModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing cached hadiths: $e');
        }
      }
    }
    return null;
  }

  Future<void> saveCachedHadiths(String cacheKey, List<HadithModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonToCache = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(cacheKey, jsonToCache);
  }
}
