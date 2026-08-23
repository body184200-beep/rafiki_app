import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_app/features/hadith/domain/hadith_catalog.dart';

void main() {
  group('HadithCatalog', () {
    test('maps Arabic source names to API ids', () {
      expect(HadithCatalog.idOf('البخاري'), 'bukhari');
      expect(HadithCatalog.idOf('الترمذي'), 'tirmidzi');
      expect(HadithCatalog.idOf('أبو داود'), 'abu-daud');
      expect(HadithCatalog.idOf('unknown'), 'bukhari');
    });

    test('maps API ids back to Arabic names', () {
      expect(HadithCatalog.nameOf('muslim'), 'مسلم');
      expect(HadithCatalog.nameOf('ibnu-majah'), 'ابن ماجه');
      expect(HadithCatalog.nameOf('missing'), 'كتاب الحديث');
    });

    test('exposes sources and categories', () {
      expect(HadithCatalog.sources, contains('البخاري'));
      expect(HadithCatalog.categories.first, 'الكل');
    });
  });
}
