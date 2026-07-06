import 'package:flutter/foundation.dart';
import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/hadith_local_data_source.dart';
import '../datasources/hadith_remote_data_source.dart';

class HadithRepositoryImpl implements HadithRepository {
  final HadithRemoteDataSource _remoteDataSource;
  final HadithLocalDataSource _localDataSource;

  static List<HadithBookModel>? _cachedBooks;

  // Fallback list of books if API is unreachable
  static const List<HadithBookModel> _fallbackBooks = [
    HadithBookModel(id: 'bukhari', name: 'صحيح البخاري', available: 6638),
    HadithBookModel(id: 'muslim', name: 'صحيح مسلم', available: 4930),
    HadithBookModel(id: 'tirmidzi', name: 'سنن الترمذي', available: 3625),
    HadithBookModel(id: 'nasai', name: 'سنن النسائي', available: 5364),
    HadithBookModel(id: 'abu-daud', name: 'سنن أبي داود', available: 4419),
    HadithBookModel(id: 'ibnu-majah', name: 'سنن ابن ماجه', available: 4285),
    HadithBookModel(id: 'ahmad', name: 'مسند أحمد', available: 4305),
    HadithBookModel(id: 'darimi', name: 'سنن الدارمي', available: 2949),
    HadithBookModel(id: 'malik', name: 'موطأ مالك', available: 1587),
  ];

  HadithRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<HadithBook>> getBooks() async {
    if (_cachedBooks != null) {
      return _cachedBooks!;
    }

    try {
      final remoteBooks = await _remoteDataSource.getBooks();
      _cachedBooks = remoteBooks;
      return remoteBooks;
    } catch (e) {
      if (kDebugMode) {
        print('Error calling API /books: $e. Falling back to local book list.');
      }
    }

    return _fallbackBooks;
  }

  @override
  Future<List<Hadith>> getHadiths({
    required String bookId,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    await _localDataSource.loadLocalHadiths();

    final cacheKey = 'hadith_cache_${bookId}_${page}_$limit';

    // Load from cache if not forced refresh
    if (!forceRefresh) {
      final cachedList = await _localDataSource.getCachedHadiths(cacheKey);
      if (cachedList != null) {
        return cachedList;
      }
    }

    // Try fetching from network API
    final start = (page - 1) * limit + 1;
    final end = page * limit;

    try {
      final rawList = await _remoteDataSource.getHadithsRange(bookId, start, end);

      // Deduplicate and Enrich
      final List<HadithModel> enrichedList = [];
      final Set<int> numbers = {};

      for (var h in rawList) {
        if (!numbers.contains(h.number)) {
          numbers.add(h.number);
          enrichedList.add(_enrichHadith(h, bookId));
        }
      }

      // Save to cache
      await _localDataSource.saveCachedHadiths(cacheKey, enrichedList);

      return enrichedList;
    } catch (e) {
      if (kDebugMode) {
        print('Network error fetching hadiths from API: $e. Falling back to local.');
      }
    }

    // Fallback: Parse from local assets/hadith.json file
    try {
      final localList = _localDataSource.cachedLocalHadiths;
      if (localList != null) {
        // Filter by bookId matching source
        final filtered = localList.where((h) => _sourceMatchesBook(h.source, bookId)).toList();

        final startIndex = (page - 1) * limit;
        if (startIndex >= filtered.length) {
          return [];
        }
        final endIndex = startIndex + limit > filtered.length ? filtered.length : startIndex + limit;
        return filtered.sublist(startIndex, endIndex);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Final fallback error: $e');
      }
    }
    return [];
  }

  @override
  Future<Hadith?> getHadithByNumber(String bookId, int number) async {
    await _localDataSource.loadLocalHadiths();
    try {
      final raw = await _remoteDataSource.getHadithByNumber(bookId, number);
      return _enrichHadith(raw, bookId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting single hadith: $e. Fetching from local fallback.');
      }
      final localList = _localDataSource.cachedLocalHadiths;
      if (localList != null) {
        final matched = localList.firstWhere(
          (element) => element.number == number && _sourceMatchesBook(element.source, bookId),
          orElse: () => const HadithModel(
            number: 0, arab: '', id: '', english: '', narrator: '', source: '', grade: '', category: '', book: '', chapter: '', keywords: []
          ),
        );
        if (matched.number != 0) return matched;
      }
    }
    return null;
  }

  // Helper to enrich API-fetched hadiths with rich local data if available
  HadithModel _enrichHadith(HadithModel h, String bookId) {
    final localList = _localDataSource.cachedLocalHadiths;
    if (localList == null || localList.isEmpty) return h;

    // Look for matching local hadith
    final local = localList.firstWhere(
      (element) => element.number == h.number && 
                   (element.book == bookId || _sourceMatchesBook(element.source, bookId)),
      orElse: () => const HadithModel(
        number: 0, arab: '', id: '', english: '', narrator: '', source: '', grade: '', category: '', book: '', chapter: '', keywords: []
      ),
    );

    if (local.number != 0) {
      return HadithModel(
        number: h.number,
        arab: h.arab,
        id: h.id, // Keep the API translation (Indonesian)
        english: local.english, // Rich English
        narrator: local.narrator, // Rich Narrator
        source: local.source.isNotEmpty ? local.source : h.source,
        grade: local.grade,
        category: local.category,
        book: bookId,
        chapter: local.chapter,
        keywords: local.keywords,
      );
    }

    // Fallback: extract narrator and use default grade
    final narrator = _extractNarrator(h.arab);
    return HadithModel(
      number: h.number,
      arab: h.arab,
      id: h.id,
      english: '',
      narrator: narrator,
      source: h.source,
      grade: _getDefaultGrade(bookId),
      category: 'عام',
      book: bookId,
      chapter: '',
      keywords: const [],
    );
  }

  bool _sourceMatchesBook(String source, String bookId) {
    final s = source.toLowerCase();
    if (bookId == 'bukhari' && s.contains('البخاري')) return true;
    if (bookId == 'muslim' && s.contains('مسلم')) return true;
    if (bookId == 'tirmidzi' && s.contains('الترمذي')) return true;
    if (bookId == 'nasai' && s.contains('النسائي')) return true;
    if (bookId == 'abu-daud' && s.contains('داود')) return true;
    if (bookId == 'ibnu-majah' && s.contains('ماجه')) return true;
    return false;
  }

  String _extractNarrator(String arabText) {
    // Match "عَنْ [اسم] رَضِيَ اللَّهُ عَنْهُ"
    final regex = RegExp(r'عَنْ\s+([\u0600-\u06FF\s]+?)(?:\s+قَالَ|\s+قَالَتْ|\s+عَنِ|\s+أَنَّ|\s+رَضِيَ)');
    final match = regex.firstMatch(arabText);
    if (match != null && match.groupCount >= 1) {
      final name = match.group(1)!.trim();
      if (name.length < 30) {
        return name;
      }
    }
    return '';
  }

  String _getDefaultGrade(String bookId) {
    if (bookId == 'bukhari' || bookId == 'muslim') {
      return 'صحيح';
    }
    return 'مقبول';
  }
}
