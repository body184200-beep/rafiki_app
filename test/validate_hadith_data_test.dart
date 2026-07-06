// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Validate Hadith JSON Database Integrity', () {
    print('=== HADITH DATABASE VALIDATION ===');
    final file = File('assets/hadith.json');
    expect(file.existsSync(), true);

    final jsonString = file.readAsStringSync();
    final decoded = jsonDecode(jsonString);
    expect(decoded, isNotNull);

    final hadiths = decoded['data']['hadiths'] as List;
    expect(hadiths, isNotEmpty);
    print('Total Hadiths in Database: ${hadiths.length}');

    final requiredFields = [
      'number',
      'arab',
      'english',
      'narrator',
      'source',
      'grade',
      'category',
      'keywords'
    ];

    for (var item in hadiths) {
      final map = item as Map<String, dynamic>;
      final num = map['number'];
      print('Validating Hadith #$num...');

      for (var field in requiredFields) {
        expect(map.containsKey(field), true, reason: 'Hadith #$num is missing field "$field"');
        final val = map[field];
        expect(val, isNotNull, reason: 'Hadith #$num field "$field" is null');

        if (val is String) {
          expect(val.trim().isNotEmpty, true, reason: 'Hadith #$num field "$field" is empty string');
        } else if (val is List) {
          expect(val.isNotEmpty, true, reason: 'Hadith #$num field "$field" is an empty list');
          for (var keyword in val) {
            expect(keyword is String, true);
            expect((keyword as String).trim().isNotEmpty, true);
          }
        }
      }
    }

    print('=== VALIDATION SUCCESSFUL ===');
  });
}
