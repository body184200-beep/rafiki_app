import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:rafiki_app/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_local_data_source.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_remote_data_source.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF070D1A);
const _kCard    = Color(0xFF131F33);
const _kGold    = Color(0xFFD4A853);
const _kGoldDim = Color(0xFF8A6A2A);
const _kTeal    = Color(0xFF1A7F7A);
const _kText    = Color(0xFFEEE8D8);
const _kMuted   = Color(0xFF8A9BB0);
const _kSurface = Color(0xFF0F1929);

// ─────────────────────────────────────────────────────────────
//  HADITH SCREEN
// ─────────────────────────────────────────────────────────────
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  List<HadithBookModel> _books = [];
  List<HadithModel> _all      = [];
  List<HadithModel> _filtered = [];
  List<HadithModel> _favList  = [];
  Set<int>          _favNums  = {};
  Set<int>          _loadedNumbers = {}; // To prevent duplicates
  bool              _loading  = true;
  bool              _loadingMore = false;
  bool              _hasMore  = true;
  String?           _error;
  String            _query    = '';
  int               _tab      = 0;
  int               _page     = 1;
  String            _selectedCategory = 'الكل';
  String            _selectedSource   = 'البخاري'; // Default source name

  // Resume last read hadith fields
  int? _lastReadNumber;
  String? _lastReadBookId;
  String? _lastReadBookName;

  final ScrollController _scrollController = ScrollController();
  final HadithRepository _hadithRepository = HadithRepositoryImpl(HadithRemoteDataSource(), HadithLocalDataSource());

  final List<String> _categories = [
    "الكل",
    "العقيدة",
    "الصلاة",
    "الصيام",
    "الزكاة",
    "الحج",
    "الأخلاق",
    "بر الوالدين",
    "الدعاء",
    "الذكر",
    "المعاملات",
    "طلب العلم",
    "التوبة",
    "الصبر"
  ];

  final List<String> _sources = [
    "البخاري",
    "مسلم",
    "الترمذي",
    "النسائي",
    "أبو داود",
    "ابن ماجه",
    "أحمد",
    "الدارمي",
    "مالك"
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _hasMore) {
        _load(reset: false);
      }
    }
  }

  String _getBookId(String source) {
    switch (source) {
      case 'البخاري': return 'bukhari';
      case 'مسلم': return 'muslim';
      case 'الترمذي': return 'tirmidzi';
      case 'النسائي': return 'nasai';
      case 'أبو داود': return 'abu-daud';
      case 'ابن ماجه': return 'ibnu-majah';
      case 'أحمد': return 'ahmad';
      case 'الدارمي': return 'darimi';
      case 'مالك': return 'malik';
      default: return 'bukhari';
    }
  }

  Future<void> _initData() async {
    try {
      final list = await _hadithRepository.getBooks();
      if (mounted) {
        setState(() {
          _books = list;
        });
      }
    } catch (_) {}
    await _loadLastRead();
    await _load(reset: true);
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final num = prefs.getInt('last_read_hadith_number');
    final bId = prefs.getString('last_read_book_id');
    if (num != null && bId != null) {
      final bName = _sources.firstWhere(
        (b) => _getBookId(b) == bId,
        orElse: () => 'كتاب الحديث',
      );
      if (mounted) {
        setState(() {
          _lastReadNumber = num;
          _lastReadBookId = bId;
          _lastReadBookName = bName;
        });
      }
    }
  }

  Future<void> _saveLastRead(HadithModel h) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_hadith_number', h.number);
    await prefs.setString('last_read_book_id', h.book);
    
    final bName = _sources.firstWhere(
      (b) => _getBookId(b) == h.book,
      orElse: () => 'كتاب الحديث',
    );
    if (mounted) {
      setState(() {
        _lastReadNumber = h.number;
        _lastReadBookId = h.book;
        _lastReadBookName = bName;
      });
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;

    if (reset) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _loading = true;
        _error = null;
        _all = [];
        _filtered = [];
        _loadedNumbers.clear();
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _favNums = (prefs.getStringList('hadith_fav') ?? []).map(int.parse).toSet();

      // Load fav objects
      final favListJson = prefs.getStringList('hadith_fav_objects') ?? [];
      _favList = favListJson.map((e) => HadithModel.fromJson(jsonDecode(e))).toList();

      final bookId = _getBookId(_selectedSource);
      final data = await _hadithRepository.getHadiths(
        bookId: bookId,
        page: _page,
        limit: 20,
        forceRefresh: reset,
      );

      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            // Deduplicate incoming data
            final uniqueData = data.where((h) => !_loadedNumbers.contains(h.number)).toList();
            for (var h in uniqueData) {
              _loadedNumbers.add(h.number);
            }
            
            _all.addAll(uniqueData);
            _page++;
            if (data.length < 20) {
              _hasMore = false;
            }
            _filterAndSearch();
            _error = null;
          } else {
            _hasMore = false;
            if (reset) {
              _error = 'لا توجد أحاديث حالية لهذا الكتاب.';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (reset) {
            _error = 'فشل الاتصال بالخادم. يرجى التحقق من الإنترنت وإعادة المحاولة.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleFav(int number) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Find model in _all
    final index = _all.indexWhere((element) => element.number == number);
    HadithModel? model;
    if (index != -1) {
      model = _all[index];
    } else {
      // Find in _favList if not in current book page
      final favIndex = _favList.indexWhere((element) => element.number == number);
      if (favIndex != -1) model = _favList[favIndex];
    }

    if (model == null) return;

    setState(() {
      if (_favNums.contains(number)) {
        _favNums.remove(number);
        _favList.removeWhere((element) => element.number == number);
      } else {
        _favNums.add(number);
        _favList.add(model!);
      }
    });

    await prefs.setStringList(
      'hadith_fav', _favNums.map((e) => e.toString()).toList(),
    );

    final favListJson = _favList.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('hadith_fav_objects', favListJson);
  }

  void _search(String q) {
    _query = q;
    _filterAndSearch();
  }

  void _filterAndSearch() {
    setState(() {
      _filtered = _all.where((h) {
        // Category Filter
        if (_selectedCategory != 'الكل' && h.category != _selectedCategory) {
          return false;
        }
        // Search Query
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          final matchText = h.arab.contains(q) ||
              h.id.toLowerCase().contains(q) ||
              h.english.toLowerCase().contains(q) ||
              h.narrator.contains(q) ||
              h.source.contains(q) ||
              h.category.contains(q) ||
              h.number.toString().contains(q) ||
              h.keywords.any((k) => k.contains(q));
          if (!matchText) return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _resumeReading() async {
    if (_lastReadBookId == null || _lastReadNumber == null) return;
    
    // Show spinner modal while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _kGold),
      ),
    );

    try {
      final h = await _hadithRepository.getHadithByNumber(_lastReadBookId!, _lastReadNumber!);
      if (mounted) {
        Navigator.pop(context); // Dismiss spinner
      }
      
      if (h != null && mounted) {
        Navigator.push(context, _slideRoute(
          _DetailScreen(
            list: [h],
            index: 0,
            favNums: _favNums,
            onToggle: _toggleFav,
            onSaveLastRead: _saveLastRead,
          ),
        ));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحميل الحديث. يرجى التحقق من الشبكة.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل الحديث.')),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _tab,
        children: [_hadithTab(), _favTab()],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: Color(0xFF1E2D45), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor:   _kGold,
        unselectedItemColor: _kMuted,
        items: [
          const BottomNavigationBarItem(
            icon:  Icon(Icons.menu_book_rounded),
            label: 'الأحاديث',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _favNums.isNotEmpty,
              backgroundColor: _kGold,
              textColor: _kBg,
              label: Text('${_favNums.length}'),
              child: const Icon(Icons.bookmark_rounded),
            ),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Hadith list ───────────────────────────────────────
  Widget _hadithTab() {
    return RefreshIndicator(
      color: _kGold,
      backgroundColor: _kCard,
      onRefresh: () => _load(reset: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildResumeBanner(),
                _buildSearch(),
                _buildFilterChips(),
              ],
            ),
          ),
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const _ShimmerCard(),
                childCount: 8,
              ),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HadithCard(
                    hadith:   _filtered[i],
                    isFav:    _favNums.contains(_filtered[i].number),
                    onToggle: _toggleFav,
                    onTap: () {
                      _saveLastRead(_filtered[i]);
                      Navigator.push(ctx, _slideRoute(
                        _DetailScreen(
                          list:     _filtered,
                          index:    i,
                          favNums:  _favNums,
                          onToggle: _toggleFav,
                          onSaveLastRead: _saveLastRead,
                        ),
                      ));
                    },
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _kGold,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 1: Favorites ─────────────────────────────────────────
  Widget _favTab() {
    final list = _favList;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        automaticallyImplyLeading: false,
        title: Text(
          list.isEmpty ? 'المفضلة' : 'المفضلة  (${list.length})',
          style: const TextStyle(
            color: _kGold, fontSize: 18, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: list.isEmpty
          ? _buildFavEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final h = list[i];
                return Dismissible(
                  key: ValueKey(h.number),
                  direction: DismissDirection.startToEnd,
                  background: _dismissBg(),
                  onDismissed: (_) => _toggleFav(h.number),
                  child: _HadithCard(
                    hadith:   h,
                    isFav:    true,
                    onToggle: _toggleFav,
                    onTap: () => Navigator.push(ctx, _slideRoute(
                      _DetailScreen(
                        list:     list,
                        index:    i,
                        favNums:  _favNums,
                        onToggle: _toggleFav,
                        onSaveLastRead: _saveLastRead,
                      ),
                    )),
                  ),
                );
              },
            ),
    );
  }

  // ── Resume Banner ────────────────────────────────────────────
  Widget _buildResumeBanner() {
    if (_lastReadNumber == null || _lastReadBookName == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2D45), Color(0xFF0F1929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6, offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _resumeReading,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kGold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_outline_rounded, color: _kGold, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'متابعة القراءة من حيث توقفت',
                        style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'حديث رقم $_lastReadNumber في $_lastReadBookName',
                        style: const TextStyle(color: _kText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: _kGold, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kBg,
      expandedHeight: 110,
      automaticallyImplyLeading: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'موسوعة الأحاديث الموثقة',
          style: TextStyle(color: _kGold, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        background: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [Color(0xFF0D1830), _kBg],
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 2, color: const Color(0x66D4A853)),
          ),
        ]),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _kGold),
          onPressed: () => _load(reset: true),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  // ── Search bar ───────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: _kText, fontSize: 15),
        onChanged: _search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: _kGold, size: 20),
          hintText: 'ابحث في الأحاديث…',
          hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
          filled: true,
          fillColor: _kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kGold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Book Source Chips
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'اختر كتاب الحديث (العدد المتوفر من الـ API):',
            style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sources.length,
            itemBuilder: (context, index) {
              final src = _sources[index];
              final isSelected = _selectedSource == src;
              final bId = _getBookId(src);
              
              // Find book metadata
              final bookMeta = _books.firstWhere(
                (b) => b.id == bId,
                orElse: () => HadithBookModel(
                  id: bId,
                  name: src,
                  available: bId == 'bukhari' ? 6638 : (bId == 'muslim' ? 4930 : 0)
                ),
              );

              final countStr = bookMeta.available > 0 ? ' (${bookMeta.available})' : '';

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    '$src$countStr',
                    style: TextStyle(
                      color: isSelected ? _kBg : _kText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _kGold,
                  backgroundColor: _kCard,
                  checkmarkColor: _kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: _kGold.withOpacity(isSelected ? 1.0 : 0.2)),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSource = src;
                        _load(reset: true);
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Category Chips
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'التصنيف الموضوعي للحديث:',
            style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? _kBg : _kMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _kGold.withOpacity(0.85),
                  backgroundColor: _kSurface,
                  checkmarkColor: _kBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _kGold.withOpacity(isSelected ? 0.8 : 0.1)),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                        _filterAndSearch();
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Empty / error states ─────────────────────────────────────
  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 52),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: _kMuted), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGold, foregroundColor: _kBg,
        ),
        onPressed: () => _load(reset: true),
        icon:  const Icon(Icons.refresh_rounded),
        label: const Text('إعادة المحاولة'),
      ),
    ]),
  );

  Widget _buildEmpty() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: _kMuted, size: 52),
      SizedBox(height: 12),
      Text('لا توجد نتائج', style: TextStyle(color: _kMuted, fontSize: 16)),
    ]),
  );

  Widget _buildFavEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: _kCard, shape: BoxShape.circle,
          border: Border.all(color: _kGoldDim, width: 1.5),
        ),
        child: const Icon(Icons.bookmark_outline_rounded, color: _kGoldDim, size: 36),
      ),
      const SizedBox(height: 20),
      const Text(
        'لا توجد أحاديث محفوظة',
        style: TextStyle(color: _kMuted, fontSize: 17, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      const Text(
        'اضغط على علامة الحفظ في أي حديث لإضافته هنا',
        style: TextStyle(color: _kMuted, fontSize: 13),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    ]),
  );

  Widget _dismissBg() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade900,
      borderRadius: BorderRadius.circular(18),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
  );
}

// ─────────────────────────────────────────────────────────────
//  HADITH CARD
// ─────────────────────────────────────────────────────────────
class _HadithCard extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;
  final VoidCallback               onTap;

  const _HadithCard({
    required this.hadith,
    required this.isFav,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFav ? _kGold.withOpacity(0.35) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote_rounded, color: _kTeal, size: 14),
                  const SizedBox(height: 4),
                  Text(
                    '${hadith.number}',
                    style: const TextStyle(
                      color: _kGold, fontSize: 13, fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Tag & Source
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hadith.category.isNotEmpty ? hadith.category : 'عام',
                            style: const TextStyle(color: _kTeal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          hadith.source.isNotEmpty ? hadith.source : 'موسوعة الأحاديث',
                          style: const TextStyle(color: _kMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Arabic Text
                    Text(
                      hadith.arab,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 15,
                        height: 1.75,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Narrator Footer
                    if (hadith.narrator.isNotEmpty)
                      Text(
                        'الراوي: ${hadith.narrator} • ${hadith.grade}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _kMuted, fontSize: 10.5),
                      )
                    else
                      Text(
                        hadith.grade.isNotEmpty ? hadith.grade : 'صحيح',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _kMuted, fontSize: 10.5),
                      ),
                  ],
                ),
              ),
            ),
            // Actions Column (Bookmark, Copy, Share)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: Column(
                children: [
                  _BookmarkButton(number: hadith.number, isFav: isFav, onToggle: onToggle),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: _kMuted, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ نص الحديث الشريف.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: _kMuted, size: 16),
                    onPressed: () {
                      Share.share(
                        '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED BOOKMARK BUTTON
// ─────────────────────────────────────────────────────────────
class _BookmarkButton extends StatefulWidget {
  final int                        number;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;

  const _BookmarkButton({
    required this.number,
    required this.isFav,
    required this.onToggle,
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 1.4)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _tap() async {
    await _ctrl.forward();
    await widget.onToggle(widget.number);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          widget.isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: widget.isFav ? _kGold : _kMuted,
          size: 22,
        ),
        onPressed: _tap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHIMMER CARD
// ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 90,
        decoration: BoxDecoration(
          color: _kCard.withOpacity(_anim.value + 0.3),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class _DetailScreen extends StatefulWidget {
  final List<HadithModel>          list;
  final int                        index;
  final Set<int>                   favNums;
  final Future<void> Function(int) onToggle;
  final Future<void> Function(HadithModel) onSaveLastRead;

  const _DetailScreen({
    required this.list,
    required this.index,
    required this.favNums,
    required this.onToggle,
    required this.onSaveLastRead,
  });

  @override
  State<_DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<_DetailScreen> {
  late final PageController _controller;
  late int      _current;
  late Set<int> _localFav; // local copy → instant UI update
  bool          _showEnglish = true;
  double        _arabicFontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _current    = widget.index;
    _localFav   = Set.of(widget.favNums);
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _toggle(int number) async {
    setState(() {
      _localFav.contains(number) ? _localFav.remove(number) : _localFav.add(number);
    });
    await widget.onToggle(number);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.list[_current];
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: Text(
          'حديث رقم ${h.number}',
          style: const TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: _kMuted, size: 20),
            onPressed: () {
              if (_arabicFontSize > 15) {
                setState(() => _arabicFontSize -= 2.0);
              }
            },
            tooltip: 'تصغير الخط',
          ),
          Center(
            child: Text(
              '${_arabicFontSize.toInt()}',
              style: const TextStyle(color: _kGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: _kMuted, size: 20),
            onPressed: () {
              if (_arabicFontSize < 34) {
                setState(() => _arabicFontSize += 2.0);
              }
            },
            tooltip: 'تكبير الخط',
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              _showEnglish ? Icons.translate_rounded : Icons.g_translate_rounded,
              color: _showEnglish ? _kGold : _kMuted,
            ),
            onPressed: () {
              setState(() {
                _showEnglish = !_showEnglish;
              });
            },
            tooltip: 'إظهار/إخفاء الترجمة',
          ),
          _BookmarkButton(
            number:   h.number,
            isFav:    _localFav.contains(h.number),
            onToggle: _toggle,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${_current + 1} / ${widget.list.length}',
              style: const TextStyle(color: _kGold, fontSize: 13, letterSpacing: 1),
            ),
          ),
          LinearProgressIndicator(
            value: (_current + 1) / widget.list.length,
            backgroundColor: _kCard,
            valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
            minHeight: 2,
          ),
          Expanded(
            child: PageView.builder(
              controller:    _controller,
              onPageChanged: (i) {
                setState(() => _current = i);
                widget.onSaveLastRead(widget.list[i]);
              },
              itemCount:     widget.list.length,
              itemBuilder:   (_, i) => _DetailPage(
                hadith:   widget.list[i],
                isFav:    _localFav.contains(widget.list[i].number),
                onToggle: _toggle,
                showEnglish: _showEnglish,
                fontSize: _arabicFontSize,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left,  color: _kMuted, size: 18),
                SizedBox(width: 4),
                Text('اسحب للتنقل بين الأحاديث',
                    style: TextStyle(color: _kMuted, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: _kMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETAIL PAGE  (single page inside PageView)
// ─────────────────────────────────────────────────────────────
class _DetailPage extends StatelessWidget {
  final HadithModel                hadith;
  final bool                       isFav;
  final Future<void> Function(int) onToggle;
  final bool                       showEnglish;
  final double                     fontSize;

  const _DetailPage({
    required this.hadith,
    required this.isFav,
    required this.onToggle,
    required this.showEnglish,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Determine translation text and label
    final hasRichEnglish = hadith.english.isNotEmpty;
    final hasIndonesian = hadith.id.isNotEmpty;
    
    String transText = '';
    String transLabel = '';
    
    if (hasRichEnglish) {
      transText = hadith.english;
      transLabel = 'English Translation';
    } else if (hasIndonesian) {
      transText = hadith.id;
      transLabel = 'الترجمة المتاحة للحديث (Indonesian)';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFav ? _kGold.withOpacity(0.4) : const Color(0xFF1E2D45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C1624),
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: _kTeal, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(hadith.source.isNotEmpty ? hadith.source : 'موسوعة الأحاديث',
                        style: const TextStyle(color: _kMuted, fontSize: 12)),
                  ]),
                  Text(
                    'الحديث ${hadith.number}',
                    style: const TextStyle(
                      color: _kGold, fontSize: 14, fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Arabic and English Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hadith.grade.isNotEmpty) ...[
                          _pillTag(hadith.grade, _kTeal),
                          const SizedBox(width: 8),
                        ],
                        if (hadith.category.isNotEmpty)
                          _pillTag(hadith.category, _kGold),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Narrator section
                    if (hadith.narrator.isNotEmpty) ...[
                      Text(
                        'رواه ${hadith.narrator} رضي الله عنه:',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kGold,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Arabic Hadith Text (Main)
                    Text(
                      hadith.arab,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kText,
                        fontSize: fontSize,
                        height: 1.95,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // English/Indonesian Translation (Secondary)
                    if (showEnglish && transText.isNotEmpty) ...[
                      const Divider(color: Color(0xFF1E2D45), thickness: 1),
                      const SizedBox(height: 12),
                      Text(
                        transLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kGold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kBg.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E2D45).withOpacity(0.5)),
                        ),
                        child: Text(
                          transText,
                          textDirection: hasRichEnglish ? TextDirection.ltr : TextDirection.rtl,
                          textAlign: hasRichEnglish ? TextAlign.left : TextAlign.center,
                          style: TextStyle(
                            color: _kMuted.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.55,
                            fontStyle: hasRichEnglish ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Card Footer Actions (Copy & Share)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C1624),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: _kGold, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الحديث النبوي الشريف إلى الحافظة.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'نسخ الحديث',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: _kGold, size: 20),
                    onPressed: () {
                      Share.share(
                        '${hadith.arab}\n\nالراوي: ${hadith.narrator}\nالمصدر: ${hadith.source}\nالدرجة: ${hadith.grade}',
                      );
                    },
                    tooltip: 'مشاركة الحديث',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ROUTE HELPER
// ─────────────────────────────────────────────────────────────
PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder:        (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 320),
);