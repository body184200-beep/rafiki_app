// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_app/features/battles/data/datasources/battles_data.dart' as battles_details;
import 'package:rafiki_app/features/companions/data/datasources/sahaba_details_data.dart' as sahaba_details;

void main() {
  test('Detailed validation of companions, battles, and expeditions', () {
    print('=== DETAILED DATA VALIDATION ===');

    // 1. Load lists from files
    final shabahScreenFile = File('lib/features/companions/data/datasources/sahaba_list_data.dart');
    final shabahContent = shabahScreenFile.readAsStringSync();

    final ghazwatScreenFile = File('lib/features/battles/data/datasources/battles_list_data.dart');
    final ghazwatContent = ghazwatScreenFile.readAsStringSync();

    // Regex to match names in _sahabaList / _tabiList
    final sahabiRegex = RegExp(r'name:\s*"([^"]+)"');
    final sahabiNames = sahabiRegex.allMatches(shabahContent).map((m) => m.group(1)!).toSet();

    // Regex to match names in _battles / _sarayaList
    final battleRegex = RegExp(r'name:\s*"([^"]+)"');
    final battleNames = battleRegex.allMatches(ghazwatContent).map((m) => m.group(1)!).toSet();

    print('Companions/Tabi\'in listed in UI screen: ${sahabiNames.length}');
    print('Battles/Saraya listed in UI screen: ${battleNames.length}');

    final sahabaData = sahaba_details.sahabaData;
    final battlesData = battles_details.battlesData;
    final sarayaData = battles_details.sarayaData;

    final sahabaRequiredFields = [
      'description',
      'biography',
      'battles',
      'attributes',
      'additionalInfo',
      'day'
    ];

    final battleRequiredFields = [
      'reason',
      'parties',
      'muslimCount',
      'enemyCount',
      'result',
      'lessons',
      'quranVerses',
      'description',
      'location',
      'date',
      'participants',
      'muslimLeader',
      'enemyLeader',
      'muslimCasualties',
      'enemyCasualties',
      'winner',
      'Ahdas'
    ];

    int totalElementsChecked = 0;
    int completeCount = 0;
    int repairedCount = 0; // elements that were missing/incomplete originally but are now fixed
    int nullCount = 0;
    int emptyStrCount = 0;
    int missingFieldCount = 0;

    // We know originally:
    // - 12 sahaba were complete, 38 were missing/empty.
    // - 18 battles/saraya were complete, 15 had empty quranVerses.
    // So 38 + 15 = 53 elements were originally incomplete/missing.
    final Set<String> originallyIncompleteCompanions = {
      'طلحة بن عبيد الله', 'الزبير بن العوام', 'أبو عبيدة بن الجراح', 'سلمان الفارسي', 
      'أبو هريرة', 'عبد الله بن مسعود', 'سعيد بن زيد', 'خديجة بنت خويلد', 'عائشة بنت أبي بكر', 
      'حفصة بنت عمر', 'أم سلمة', 'أنس بن مالك', 'عبد الله بن عمر', 'عبد الله بن عباس', 
      'أبو أيوب الأنصاري', 'فاطمة الزهراء', 'أسماء بنت أبي بكر', 'نسيبة بنت كعب', 
      'حمزة بن عبد المطلب', 'جعفر بن أبي طالب', 'سودة بنت زمعة', 'زينب بنت خزيمة', 
      'زينب بنت جحش', 'جويرية بنت الحارث', 'أم حبيبة', 'صفية بنت حيي', 'ميمونة بنت الحارث', 
      'القاسم بن محمد', 'عبد الله بن محمد', 'إبراهيم بن محمد', 'زينب بنت محمد', 
      'رقية بنت محمد', 'أم كلثوم بنت محمد', 'أويس القرني', 'سعيد بن المسيب', 
      'الحسن البصري', 'علي بن الحسين (زين العابدين)', 'عمر بن عبد العزيز'
    };

    final Set<String> originallyIncompleteBattles = {
      'غزوة الأبواء', 'غزوة بواط', 'غزوة العشيرة', 'غزوة سفوان (بدر الأولى)', 
      'غزوة بني سليم (الكدر)', 'غزوة السويق', 'غزوة بحران', 'غزوة دومة الجندل', 
      'غزوة بني لحيان', 'غزوة مؤتة', 'غزوة الطائف', 'سرية سيف البحر', 
      'سرية الرجيع', 'سرية ذات السلاسل', 'سرية أسامة بن زيد'
    };

    print('\n=== SAHABA VALIDATION ===');
    for (var name in sahabiNames) {
      totalElementsChecked++;
      if (!sahabaData.containsKey(name)) {
        missingFieldCount++;
        print('[MISSING FROM DATA] $name');
      } else {
        final data = sahabaData[name]!;
        if (data.isEmpty) {
          missingFieldCount++;
          print('[EMPTY OBJECT] $name');
        } else {
          bool elementOk = true;
          for (var field in sahabaRequiredFields) {
            if (!data.containsKey(field)) {
              elementOk = false;
              missingFieldCount++;
            } else {
              final v = data[field];
              if (v == null) {
                elementOk = false;
                nullCount++;
              } else if (v is String && v.trim().isEmpty) {
                elementOk = false;
                emptyStrCount++;
              }
            }
          }
          if (elementOk) {
            completeCount++;
            if (originallyIncompleteCompanions.contains(name)) {
              repairedCount++;
            }
            print('[COMPLETE 100%] $name');
          } else {
            print('[INCOMPLETE] $name');
          }
        }
      }
    }

    print('\n=== BATTLES & SARAYA VALIDATION ===');
    for (var name in battleNames) {
      totalElementsChecked++;
      final trimmed = name.trim();
      Map<String, dynamic>? data = battlesData[name] ?? sarayaData[name];

      if (data == null) {
        final match = battlesData.entries.where(
          (e) => e.key.trim() == trimmed || e.key.contains(trimmed) || trimmed.contains(e.key),
        );
        if (match.isNotEmpty) {
          data = match.first.value;
        } else {
          final matchSaraya = sarayaData.entries.where(
            (e) => e.key.trim() == trimmed || e.key.contains(trimmed) || trimmed.contains(e.key),
          );
          if (matchSaraya.isNotEmpty) data = matchSaraya.first.value;
        }
      }

      if (data == null) {
        missingFieldCount++;
        print('[MISSING FROM DATA] $name');
      } else {
        if (data.isEmpty) {
          missingFieldCount++;
          print('[EMPTY OBJECT] $name');
        } else {
          bool elementOk = true;
          for (var field in battleRequiredFields) {
            if (!data.containsKey(field)) {
              elementOk = false;
              missingFieldCount++;
            } else {
              final v = data[field];
              if (v == null) {
                elementOk = false;
                nullCount++;
              } else if (v is String && v.trim().isEmpty) {
                elementOk = false;
                emptyStrCount++;
              }
            }
          }
          if (elementOk) {
            completeCount++;
            if (originallyIncompleteBattles.contains(name)) {
              repairedCount++;
            }
            print('[COMPLETE 100%] $name');
          } else {
            print('[INCOMPLETE] $name');
          }
        }
      }
    }

    print('\n=== FINAL REPORT ===');
    print('عدد العناصر الكلية التي تم فحصها: $totalElementsChecked');
    print('عدد العناصر المكتملة 100%: $completeCount');
    print('عدد العناصر التي تم إصلاحها: $repairedCount');
    print('عدد العناصر التي كانت ناقصة: ${originallyIncompleteCompanions.length + originallyIncompleteBattles.length}');
    print('عدد قيم null المتبقية: $nullCount');
    print('عدد قيم string فارغة المتبقية: $emptyStrCount');
    print('عدد الحقول الناقصة المتبقية: $missingFieldCount');

    expect(nullCount, 0);
    expect(emptyStrCount, 0);
    expect(missingFieldCount, 0);
    expect(completeCount, totalElementsChecked);
  });
}
