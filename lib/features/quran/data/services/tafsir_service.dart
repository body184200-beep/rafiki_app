import 'dart:convert';

import 'package:http/http.dart' as http;

class TafsirEdition {
  const TafsirEdition({
    required this.id,
    required this.name,
    required this.isOffline,
  });

  final String id;
  final String name;
  final bool isOffline;
}

const List<TafsirEdition> kTafsirEditions = [
  TafsirEdition(id: 'ar.muyassar', name: 'التفسير الميسر', isOffline: false),
  TafsirEdition(id: 'ar.jalalayn', name: 'تفسير الجلالين', isOffline: false),
];

class TafsirService {
  TafsirService._();

  static final TafsirService instance = TafsirService._();
  final Map<String, String> _cache = {};

  Future<String?> getAyahTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String edition,
  }) async {
    final key = '$edition:$surahNumber:$ayahNumber';
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.parse(
      'https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/$edition',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map || body['data'] is! Map) return null;
    final text = (body['data'] as Map)['text'];
    if (text is! String || text.trim().isEmpty) return null;
    _cache[key] = text.trim();
    return _cache[key];
  }
}
