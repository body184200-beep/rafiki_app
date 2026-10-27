const List<String> kJuzArabicNames = [
  'الجزء الأول',
  'الجزء الثاني',
  'الجزء الثالث',
  'الجزء الرابع',
  'الجزء الخامس',
  'الجزء السادس',
  'الجزء السابع',
  'الجزء الثامن',
  'الجزء التاسع',
  'الجزء العاشر',
  'الجزء الحادي عشر',
  'الجزء الثاني عشر',
  'الجزء الثالث عشر',
  'الجزء الرابع عشر',
  'الجزء الخامس عشر',
  'الجزء السادس عشر',
  'الجزء السابع عشر',
  'الجزء الثامن عشر',
  'الجزء التاسع عشر',
  'الجزء العشرون',
  'الجزء الحادي والعشرون',
  'الجزء الثاني والعشرون',
  'الجزء الثالث والعشرون',
  'الجزء الرابع والعشرون',
  'الجزء الخامس والعشرون',
  'الجزء السادس والعشرون',
  'الجزء السابع والعشرون',
  'الجزء الثامن والعشرون',
  'الجزء التاسع والعشرون',
  'الجزء الثلاثون',
];

String toArabicDigits(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? digits[d] : c;
  }).join();
}

class MushafAyah {
  final int surahNumber;
  final String surahName;
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;
  final int hizbQuarter;
  final bool isFirstInSurah;
  final bool isHizbQuarterStart;
  final String surahRevelationType;
  final int surahTotalAyahs;

  const MushafAyah({
    required this.surahNumber,
    required this.surahName,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
    required this.hizbQuarter,
    required this.isFirstInSurah,
    required this.isHizbQuarterStart,
    required this.surahRevelationType,
    required this.surahTotalAyahs,
  });
}

class MushafPage {
  final int pageNumber;
  final int juzNumber;
  final String juzName;
  final String primarySurahName;
  final int primarySurahNumber;
  final String? hizbQuarterText;
  final List<MushafAyah> ayahs;

  const MushafPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.juzName,
    required this.primarySurahName,
    required this.primarySurahNumber,
    this.hizbQuarterText,
    required this.ayahs,
  });

  /// True if any ayah on this page is the beginning of a Surah
  bool get hasSurahBeginning => ayahs.any((a) => a.isFirstInSurah);
}
