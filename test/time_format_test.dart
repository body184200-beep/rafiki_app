import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_app/core/utils/time_format.dart';

void main() {
  group('TimeFormat', () {
    test('pads single digits', () {
      expect(TimeFormat.two(5), '05');
      expect(TimeFormat.two(12), '12');
    });

    test('formats local clock time as HH:mm', () {
      final time = DateTime(2026, 1, 1, 9, 5);
      expect(TimeFormat.hhmm(time), '09:05');
    });

    test('formats countdown and clamps negatives', () {
      expect(
        TimeFormat.hhmmss(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
      expect(TimeFormat.hhmmss(const Duration(seconds: -1)), '00:00:00');
    });
  });
}
