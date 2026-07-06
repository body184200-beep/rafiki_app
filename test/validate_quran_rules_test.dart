import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quran Metadata & Basmala Rule Tests', () {
    late Map<String, dynamic> quranData;
    late List<dynamic> surahs;

    setUpAll(() {
      final file = File('assets/quran.json');
      final jsonString = file.readAsStringSync();
      quranData = jsonDecode(jsonString);
      surahs = quranData['data']['surahs'] as List;
    });

    test('All 114 Surahs must be present, ordered, and have non-zero ayah counts', () {
      expect(surahs.length, equals(114));

      for (int i = 0; i < 114; i++) {
        final surah = surahs[i] as Map<String, dynamic>;
        expect(surah['number'], equals(i + 1));
        expect(surah['name'], isNotEmpty);
        expect(surah['englishName'], isNotEmpty);

        final ayahs = surah['ayahs'] as List;
        expect(ayahs, isNotEmpty);
        expect(ayahs.length, greaterThan(0));
      }
    });

    test('Surah Al-Fatihah (1) Ayah count and Basmala integrity', () {
      final fatihah = surahs[0] as Map<String, dynamic>;
      final ayahs = fatihah['ayahs'] as List;
      
      // Fatihah has 7 verses
      expect(ayahs.length, equals(7));

      // First verse of Al-Fatihah must be the Basmala itself
      final firstAyahText = ayahs[0]['text'] as String;
      expect(firstAyahText.contains('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), isTrue);
    });

    test('Surah Al-Tawbah (9) Ayah count and NO Basmala integrity', () {
      final tawbah = surahs[8] as Map<String, dynamic>;
      final ayahs = tawbah['ayahs'] as List;

      // Tawbah has 129 verses
      expect(ayahs.length, equals(129));

      // First verse of Tawbah must NOT contain Basmala
      final firstAyahText = ayahs[0]['text'] as String;
      expect(firstAyahText.contains('بِسْمِ'), isFalse);
    });

    test('Regex clean check for Basmala in other Surahs', () {
      final regex = RegExp(
        r'^ب[\u064B-\u065F]*سْمِ\s+[\u0600-\u06FF\s]+?(?:ٱلرَّحِيمِ|الرَّحِيمِ|الرَّحِيْمِ|الرحيم)\s*',
      );

      // Surah 2 (Al-Baqarah)
      final baqarah = surahs[1] as Map<String, dynamic>;
      final baqarahFirst = baqarah['ayahs'][0]['text'] as String;
      expect(regex.hasMatch(baqarahFirst), isTrue);

      final baqarahCleaned = baqarahFirst.replaceFirst(regex, '').trim();
      // Should result in "الٓمٓ"
      expect(baqarahCleaned, equals('الٓمٓ'));

      // Surah 114 (An-Nas)
      final nas = surahs[113] as Map<String, dynamic>;
      final nasFirst = nas['ayahs'][0]['text'] as String;
      expect(regex.hasMatch(nasFirst), isTrue);

      final nasCleaned = nasFirst.replaceFirst(regex, '').trim();
      expect(nasCleaned, equals('قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ'));
    });
  });
}
