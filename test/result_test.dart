import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_app/core/utils/result.dart';

void main() {
  group('Result', () {
    test('fold routes success and failure', () {
      expect(const Ok<int>(2).fold((v) => v + 1, (_) => 0), 3);
      expect(Result<int>.err('x').fold((v) => v, (_) => -1), -1);
    });

    test('valueOrNull is null on error', () {
      expect(const Ok('ok').valueOrNull, 'ok');
      expect(Result<String>.err(Exception()).valueOrNull, isNull);
    });
  });
}
