class HadithBook {
  final String id;
  final String name;
  final int available;

  const HadithBook({
    required this.id,
    required this.name,
    required this.available,
  });

  factory HadithBook.fromJson(Map<String, dynamic> j) => HadithBook(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        available: j['available'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'available': available,
      };
}

class Hadith {
  final int number;
  final String arab;
  final String id; // Indonesian translation from API
  final String english; // English translation (from local database if matched)
  final String narrator;
  final String source;
  final String grade;
  final String category;
  final String book;
  final String chapter;
  final List<String> keywords;

  const Hadith({
    required this.number,
    required this.arab,
    required this.id,
    required this.english,
    required this.narrator,
    required this.source,
    required this.grade,
    required this.category,
    required this.book,
    required this.chapter,
    required this.keywords,
  });

  factory Hadith.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] as String? ?? '';
    final rawEnglish = j['english'] as String? ?? '';
    return Hadith(
      number: j['number'] as int? ?? 0,
      arab: j['arab'] as String? ?? '',
      id: rawId,
      english: rawEnglish,
      narrator: j['narrator'] as String? ?? '',
      source: j['source'] as String? ?? '',
      grade: j['grade'] as String? ?? '',
      category: j['category'] as String? ?? '',
      book: j['book'] as String? ?? '',
      chapter: j['chapter'] as String? ?? '',
      keywords: (j['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'arab': arab,
        'id': id,
        'english': english,
        'narrator': narrator,
        'source': source,
        'grade': grade,
        'category': category,
        'book': book,
        'chapter': chapter,
        'keywords': keywords,
      };
}

typedef HadithBookModel = HadithBook;
typedef HadithModel = Hadith;
