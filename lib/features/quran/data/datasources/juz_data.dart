class QuranJuz {
  const QuranJuz({
    required this.number,
    required this.name,
    required this.surahNumber,
    required this.surahName,
    required this.startAyah,
  });

  final int number;
  final String name;
  final int surahNumber;
  final String surahName;
  final int startAyah;
}

const List<QuranJuz> kQuranAjza = [
  QuranJuz(number: 1, name: 'الجزء الأول', surahNumber: 1, surahName: 'الفاتحة', startAyah: 1),
  QuranJuz(number: 2, name: 'الجزء الثاني', surahNumber: 2, surahName: 'البقرة', startAyah: 142),
  QuranJuz(number: 3, name: 'الجزء الثالث', surahNumber: 2, surahName: 'البقرة', startAyah: 253),
  QuranJuz(number: 4, name: 'الجزء الرابع', surahNumber: 3, surahName: 'آل عمران', startAyah: 93),
  QuranJuz(number: 5, name: 'الجزء الخامس', surahNumber: 4, surahName: 'النساء', startAyah: 24),
  QuranJuz(number: 6, name: 'الجزء السادس', surahNumber: 4, surahName: 'النساء', startAyah: 148),
  QuranJuz(number: 7, name: 'الجزء السابع', surahNumber: 5, surahName: 'المائدة', startAyah: 82),
  QuranJuz(number: 8, name: 'الجزء الثامن', surahNumber: 6, surahName: 'الأنعام', startAyah: 111),
  QuranJuz(number: 9, name: 'الجزء التاسع', surahNumber: 7, surahName: 'الأعراف', startAyah: 88),
  QuranJuz(number: 10, name: 'الجزء العاشر', surahNumber: 8, surahName: 'الأنفال', startAyah: 41),
  QuranJuz(number: 11, name: 'الجزء الحادي عشر', surahNumber: 9, surahName: 'التوبة', startAyah: 93),
  QuranJuz(number: 12, name: 'الجزء الثاني عشر', surahNumber: 11, surahName: 'هود', startAyah: 6),
  QuranJuz(number: 13, name: 'الجزء الثالث عشر', surahNumber: 12, surahName: 'يوسف', startAyah: 53),
  QuranJuz(number: 14, name: 'الجزء الرابع عشر', surahNumber: 15, surahName: 'الحجر', startAyah: 1),
  QuranJuz(number: 15, name: 'الجزء الخامس عشر', surahNumber: 17, surahName: 'الإسراء', startAyah: 1),
  QuranJuz(number: 16, name: 'الجزء السادس عشر', surahNumber: 18, surahName: 'الكهف', startAyah: 75),
  QuranJuz(number: 17, name: 'الجزء السابع عشر', surahNumber: 21, surahName: 'الأنبياء', startAyah: 1),
  QuranJuz(number: 18, name: 'الجزء الثامن عشر', surahNumber: 23, surahName: 'المؤمنون', startAyah: 1),
  QuranJuz(number: 19, name: 'الجزء التاسع عشر', surahNumber: 25, surahName: 'الفرقان', startAyah: 21),
  QuranJuz(number: 20, name: 'الجزء العشرون', surahNumber: 27, surahName: 'النمل', startAyah: 56),
  QuranJuz(number: 21, name: 'الجزء الحادي والعشرون', surahNumber: 29, surahName: 'العنكبوت', startAyah: 46),
  QuranJuz(number: 22, name: 'الجزء الثاني والعشرون', surahNumber: 33, surahName: 'الأحزاب', startAyah: 31),
  QuranJuz(number: 23, name: 'الجزء الثالث والعشرون', surahNumber: 36, surahName: 'يس', startAyah: 28),
  QuranJuz(number: 24, name: 'الجزء الرابع والعشرون', surahNumber: 39, surahName: 'الزمر', startAyah: 32),
  QuranJuz(number: 25, name: 'الجزء الخامس والعشرون', surahNumber: 41, surahName: 'فصلت', startAyah: 47),
  QuranJuz(number: 26, name: 'الجزء السادس والعشرون', surahNumber: 46, surahName: 'الأحقاف', startAyah: 1),
  QuranJuz(number: 27, name: 'الجزء السابع والعشرون', surahNumber: 51, surahName: 'الذاريات', startAyah: 31),
  QuranJuz(number: 28, name: 'الجزء الثامن والعشرون', surahNumber: 58, surahName: 'المجادلة', startAyah: 1),
  QuranJuz(number: 29, name: 'الجزء التاسع والعشرون', surahNumber: 67, surahName: 'الملك', startAyah: 1),
  QuranJuz(number: 30, name: 'الجزء الثلاثون', surahNumber: 78, surahName: 'النبأ', startAyah: 1),
];
