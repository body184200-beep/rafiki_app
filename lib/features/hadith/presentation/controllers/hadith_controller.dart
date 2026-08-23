import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/core/utils/debouncer.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/domain/hadith_catalog.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';

class HadithController extends ChangeNotifier {
  HadithController(this._repository);

  static const _favIdsKey = 'hadith_fav';
  static const _favJsonKey = 'hadith_fav_objects';
  static const _lastNumberKey = 'last_read_hadith_number';
  static const _lastBookKey = 'last_read_book_id';
  static const _pageSize = 20;

  final HadithRepository _repository;
  final Debouncer _searchDebounce = Debouncer();

  List<HadithBookModel> books = const [];
  List<HadithModel> all = [];
  List<HadithModel> filtered = [];
  List<HadithModel> favList = [];
  Set<int> favNums = {};
  final Set<int> _loadedNumbers = {};

  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  String query = '';
  int tab = 0;
  int page = 1;
  String selectedCategory = 'الكل';
  String selectedSource = 'البخاري';

  int? lastReadNumber;
  String? lastReadBookId;
  String? lastReadBookName;

  Future<void> init() async {
    try {
      books = await _repository.getBooks();
    } catch (e, st) {
      AppLogger.warning('Failed to load hadith books', tag: 'Hadith', error: e, stackTrace: st);
    }
    await _loadLastRead();
    await load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    super.dispose();
  }

  void setTab(int index) {
    if (tab == index) return;
    tab = index;
    notifyListeners();
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  Future<void> setSource(String source) async {
    if (selectedSource == source) return;
    selectedSource = source;
    notifyListeners();
    await load(reset: true);
  }

  void search(String q) {
    _searchDebounce.run(() {
      query = q;
      _applyFilter();
      notifyListeners();
    });
  }

  Future<HadithModel?> fetchLastRead() async {
    if (lastReadBookId == null || lastReadNumber == null) return null;
    try {
      return await _repository.getHadithByNumber(lastReadBookId!, lastReadNumber!);
    } catch (e, st) {
      AppLogger.warning('Failed to resume hadith', tag: 'Hadith', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> saveLastRead(HadithModel h) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastNumberKey, h.number);
    await prefs.setString(_lastBookKey, h.book);
    lastReadNumber = h.number;
    lastReadBookId = h.book;
    lastReadBookName = HadithCatalog.nameOf(h.book);
    notifyListeners();
  }

  int availableOf(String source) {
    final id = HadithCatalog.idOf(source);
    for (final book in books) {
      if (book.id == id) return book.available;
    }
    if (id == 'bukhari') return 6638;
    if (id == 'muslim') return 4930;
    return 0;
  }

  Future<void> load({bool reset = false}) async {
    if (loadingMore && !reset) return;

    if (reset) {
      page = 1;
      hasMore = true;
      loading = true;
      error = null;
      all = [];
      filtered = [];
      _loadedNumbers.clear();
      notifyListeners();
    } else {
      loadingMore = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      favNums = (prefs.getStringList(_favIdsKey) ?? []).map(int.parse).toSet();
      final favJson = prefs.getStringList(_favJsonKey) ?? [];
      favList = favJson
          .map((e) => HadithModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();

      final data = await _repository.getHadiths(
        bookId: HadithCatalog.idOf(selectedSource),
        page: page,
        limit: _pageSize,
        forceRefresh: reset,
      );

      if (data.isNotEmpty) {
        final unique = data.where((h) => !_loadedNumbers.contains(h.number)).toList();
        for (final h in unique) {
          _loadedNumbers.add(h.number);
        }
        all = [...all, ...unique];
        page++;
        if (data.length < _pageSize) hasMore = false;
        error = null;
        _applyFilter();
      } else {
        hasMore = false;
        if (reset) error = 'لا توجد أحاديث حالية لهذا الكتاب.';
      }
    } catch (e, st) {
      AppLogger.warning('Failed to load hadiths', tag: 'Hadith', error: e, stackTrace: st);
      if (reset) {
        error = 'فشل الاتصال بالخادم. يرجى التحقق من الإنترنت وإعادة المحاولة.';
      }
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleFav(int number) async {
    HadithModel? model = _findByNumber(all, number) ?? _findByNumber(favList, number);
    if (model == null) return;

    if (favNums.contains(number)) {
      favNums = {...favNums}..remove(number);
      favList = favList.where((e) => e.number != number).toList();
    } else {
      favNums = {...favNums, number};
      favList = [...favList, model];
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favIdsKey, favNums.map((e) => e.toString()).toList());
    await prefs.setStringList(
      _favJsonKey,
      favList.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final number = prefs.getInt(_lastNumberKey);
    final bookId = prefs.getString(_lastBookKey);
    if (number == null || bookId == null) return;
    lastReadNumber = number;
    lastReadBookId = bookId;
    lastReadBookName = HadithCatalog.nameOf(bookId);
  }

  void _applyFilter() {
    filtered = all.where((h) {
      if (selectedCategory != 'الكل' && h.category != selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return h.arab.contains(q) ||
          h.id.toLowerCase().contains(q) ||
          h.english.toLowerCase().contains(q) ||
          h.narrator.contains(q) ||
          h.source.contains(q) ||
          h.category.contains(q) ||
          h.number.toString().contains(q) ||
          h.keywords.any((k) => k.contains(q));
    }).toList();
  }

  HadithModel? _findByNumber(List<HadithModel> list, int number) {
    for (final h in list) {
      if (h.number == number) return h;
    }
    return null;
  }
}
