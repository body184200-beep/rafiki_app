import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/settings/presentation/pages/profile_page.dart';
import 'package:rafiki_app/features/prayer/presentation/pages/qibla_page.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'username': 'Abdulrahman Ashraf',
      'highest_azkar_streak': 150,
      'highest_prayer_streak': 200,
      'total_tasbihat_count': 500,
    });
  });

  testWidgets('ProfilePage renders correctly with stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الملف الشخصي'), findsOneWidget);
    expect(find.text('Abdulrahman Ashraf'), findsOneWidget);
    expect(find.text('ستريك أذكار'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('ستريك الصلاة'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('الإنجازات'), findsOneWidget);
    expect(find.text('إجمالي النقاط'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('QiblaPage renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QiblaPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('القبلة الشريفة'), findsOneWidget);
  });
}
