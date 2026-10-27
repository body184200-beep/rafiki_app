import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/deeds/presentation/pages/deeds_page.dart';
import 'package:rafiki_app/features/deeds/presentation/widgets/deeds_widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Misbaha (DeedsPage) loads and increments counter on tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeedsPage(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    // Verify header title and subtitle
    expect(find.text('المِسْبَحَةُ الإِلِكْتُرُونِيَّة'), findsOneWidget);
    expect(find.text('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'), findsOneWidget);

    // Verify initial dhikr
    expect(find.text('سُبْحَانَ اللَّهِ'), findsWidgets);

    // Verify count begins at 0
    expect(find.text('0'), findsWidgets);

    // Tap on the counter to increment
    await tester.tap(find.text('انقر للتسبيح'));
    await tester.pump(const Duration(milliseconds: 100));

    // Count should now be 1
    expect(find.text('1'), findsWidgets);

    // Tap Undo
    await tester.tap(find.text('تراجع -١'));
    await tester.pump(const Duration(milliseconds: 100));

    // Count returns to 0
    expect(find.text('0'), findsWidgets);

    // Allow spark timers to settle
    await tester.pump(const Duration(seconds: 1));
  });

  test('MisbahaTheme provides all 5 luxury gemstone styles', () {
    expect(MisbahaTheme.all.length, 5);
    final themeIds = MisbahaTheme.all.map((t) => t.id).toList();
    expect(themeIds.contains('emerald'), true);
    expect(themeIds.contains('amber'), true);
    expect(themeIds.contains('turquoise'), true);
    expect(themeIds.contains('pearl'), true);
    expect(themeIds.contains('obsidian'), true);
  });
}
