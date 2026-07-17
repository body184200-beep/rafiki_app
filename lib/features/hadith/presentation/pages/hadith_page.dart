import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/hadith/domain/entities/hadith.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:rafiki_app/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_local_data_source.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_remote_data_source.dart';
import 'package:rafiki_app/features/hadith/presentation/widgets/hadith_widgets.dart';
import 'package:rafiki_app/features/hadith/presentation/pages/hadith_details_page.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF070D1A);
const _kCard    = Color(0xFF131F33);
const _kGold    = Color(0xFFD4A853);
const _kGoldDim = Color(0xFF8A6A2A);
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
        Navigator.push(context, slideRoute(
          HadithDetailsPage(
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
                (_, __) => const ShimmerCard(),
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
                  (ctx, i) => HadithCard(
                    hadith:   _filtered[i],
                    isFav:    _favNums.contains(_filtered[i].number),
                    onToggle: _toggleFav,
                    onTap: () {
                      _saveLastRead(_filtered[i]);
                      Navigator.push(ctx, slideRoute(
                        HadithDetailsPage(
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
                  child: HadithCard(
                    hadith:   h,
                    isFav:    true,
                    onToggle: _toggleFav,
                    onTap: () => Navigator.push(ctx, slideRoute(
                      HadithDetailsPage(
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
