import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/azkar/presentation/pages/azkar_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AzkarPage loads successfully and displays tabs', (WidgetTester tester) async {
    // Build the widget tree with AzkarPage
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AzkarPage(),
      ),
    ));

    // Pump a frame to let the widget initialize
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the Morning ("الصباح") and Evening ("المساء") tabs are displayed
    expect(find.text('الصباح'), findsOneWidget);
    expect(find.text('المساء'), findsOneWidget);
  });
}
