import '../entities/hadith.dart';

abstract class HadithRepository {
  Future<List<HadithBook>> getBooks();
  Future<List<Hadith>> getHadiths({
    required String bookId,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });
  Future<Hadith?> getHadithByNumber(String bookId, int number);
}
