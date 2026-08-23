/// Canonical Arabic book names ↔ API ids for the Hadith feature.
abstract final class HadithCatalog {
  static const sources = <String>[
    'البخاري',
    'مسلم',
    'الترمذي',
    'النسائي',
    'أبو داود',
    'ابن ماجه',
    'أحمد',
    'الدارمي',
    'مالك',
  ];

  static const categories = <String>[
    'الكل',
    'العقيدة',
    'الصلاة',
    'الصيام',
    'الزكاة',
    'الحج',
    'الأخلاق',
    'بر الوالدين',
    'الدعاء',
    'الذكر',
    'المعاملات',
    'طلب العلم',
    'التوبة',
    'الصبر',
  ];

  static const Map<String, String> _ids = {
    'البخاري': 'bukhari',
    'مسلم': 'muslim',
    'الترمذي': 'tirmidzi',
    'النسائي': 'nasai',
    'أبو داود': 'abu-daud',
    'ابن ماجه': 'ibnu-majah',
    'أحمد': 'ahmad',
    'الدارمي': 'darimi',
    'مالك': 'malik',
  };

  static String idOf(String source) => _ids[source] ?? 'bukhari';

  static String nameOf(String id) {
    for (final entry in _ids.entries) {
      if (entry.value == id) return entry.key;
    }
    return 'كتاب الحديث';
  }
}
