import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/quran/domain/repositories/quran_repository.dart' as quran;
import 'package:rafiki_app/features/quran/data/datasources/juz_data.dart';
import 'package:rafiki_app/features/quran/presentation/widgets/quran_audio_view.dart';

class MushafPage extends StatefulWidget {
  const MushafPage({super.key});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage>
    with SingleTickerProviderStateMixin {
  final quran.QuranRepository _quranRepository = sl<quran.QuranRepository>();

  // ── Palette ───────────────────────────────────────────────────────────
  static const Color _bg         = Color(0xff070B10);
  static const Color _bgGrad     = Color(0xff0B1220);
  static const Color _surface    = Color(0xff0F1520);
  static const Color _surfaceAlt = Color(0xff131A28);
  static const Color _high       = Color(0xff192035);
  static const Color _border     = Color(0xff1C2540);
  static const Color _borderSoft = Color(0xff141C2E);
  static const Color _accent     = Color(0xff5DD3A8);
  static const Color _accentDim  = Color(0xff1F9E72);
  static const Color _gold       = Color(0xffD4A853);
  static const Color _textPri    = Color(0xffEDF1F8);
  static const Color _textSec    = Color(0xff7A8599);
  static const Color _textDim    = Color(0xff2E3A50);
  static const Color _meccanClr  = Color(0xff4A9ECC);
  static const Color _medinanClr = Color(0xff8B6ED4);

  // ── State ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _surahs         = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  bool   _isLoading   = true;
  bool   _hasError    = false;
  String _searchQuery = '';
  int    _filterIndex = 0; // 0: الكل, 1: مكية, 2: مدنية
  int    _mainTab     = 0; // 0: السور, 1: الأجزاء
  int?   _lastReadSurah;
  Map<String, dynamic>? _savedBookmark;

  // ── Controllers ───────────────────────────────────────────────────────
  final TextEditingController _searchCtrl   = TextEditingController();
  final ScrollController       _scrollCtrl  = ScrollController();
  late final AnimationController _listAnim;
  bool _showScrollTop = false;

  static const List<String> _filterLabels  = ['الكل', 'مكية', 'مدنية'];
  static const List<Color>  _filterColors  = [_accent, _meccanClr, _medinanClr];

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 300;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
    _fetchQuran();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────

  Future<void> _fetchQuran() async {
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final list = await _quranRepository.getSurahs();
      final prefs = await SharedPreferences.getInstance();
      final lastRead = prefs.getInt('quran_last_read_surah');

      Map<String, dynamic>? bookmark;
      try {
        final raw = prefs.getString('mushaf_global_bookmark');
        if (raw != null) {
          final parsed = jsonDecode(raw) as Map<String, dynamic>;
          if (parsed['surahNumber'] is int &&
              parsed['surahName'] is String &&
              parsed['pageIndex'] is int) {
            bookmark = parsed;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _surahs         = list;
          _filteredSurahs = list;
          _lastReadSurah  = lastRead;
          _savedBookmark  = bookmark;
          _isLoading      = false;
        });
        _listAnim.forward();
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filteredSurahs = _surahs.where((s) {
        final nameMatch = (s['name'] as String).contains(_searchQuery);
        final engMatch  = (s['englishName'] as String).toLowerCase().contains(q);
        final numMatch  = (s['number'] as int).toString() == _searchQuery;
        if (!nameMatch && !engMatch && !numMatch) return false;

        if (_filterIndex == 0) return true;
        final type = (s['revelationType'] as String).toLowerCase();
        if (_filterIndex == 1) return type == 'meccan';
        if (_filterIndex == 2) return type == 'medinan';
        return true;
      }).toList();
    });
  }

  void _onSearch(String q) {
    _searchQuery = q;
    _applyFilters();
  }

  void _onFilterTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _filterIndex = i);
    _applyFilters();
  }

  void _openSurah(Map<String, dynamic> surah, {int? initialPage}) async {
    HapticFeedback.selectionClick();
    final surahNum = surah['number'] as int;
    setState(() => _lastReadSurah = surahNum);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_last_read_surah', surahNum);
    } catch (_) {}
    if (!mounted) return;

    final ayahs = surah['ayahs'] as List?;
    final int startMushafPage = initialPage ?? (ayahs != null && ayahs.isNotEmpty ? (ayahs[0]['page'] as int) : 1);

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => SurahDetailPage(
          allSurahs: _surahs,
          initialSurahIndex: _surahs.indexWhere((s) => s['number'] == surahNum),
          surahName: surah['name'] as String,
          surahNumber: surah['number'] as int,
          ayat: List<String>.from(
            (surah['ayahs'] as List).map((a) => a['text']),
          ),
          initialPage: startMushafPage,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    ).then((_) => _refreshBookmark());
  }

  void _openJuz(QuranJuz juz) {
    if (_surahs.isEmpty) return;
    final surah = _surahs.firstWhere(
      (s) => s['number'] == juz.surahNumber,
      orElse: () => _surahs.first,
    );
    final ayahs = (surah['ayahs'] as List?) ?? [];
    final matchingAyah = ayahs.firstWhere(
      (a) => a['numberInSurah'] == juz.startAyah,
      orElse: () => ayahs.isNotEmpty ? ayahs.first : {'page': 1},
    );
    final int pageNumber = (matchingAyah['page'] as int?) ?? 1;
    _openSurah(surah, initialPage: pageNumber);
  }

  Future<void> _refreshBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('mushaf_global_bookmark');
      Map<String, dynamic>? bookmark;
      if (raw != null) {
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        if (parsed['surahNumber'] is int &&
            parsed['surahName'] is String &&
            parsed['pageIndex'] is int) {
          bookmark = parsed;
        }
      }
      if (mounted) {
        setState(() => _savedBookmark = bookmark);
      }
    } catch (_) {}
  }

  Widget _glass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    double radius = 18,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? _border,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Header hero ───────────────────────────────────────────────────────

  Widget _headerHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _high.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: _textSec,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المصحف الشريف',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: _textPri,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '١١٤ سورة • ٣٠ جزء • ٦٢٣٦ آية',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bookmark Card / Continue Reading ──────────────────────────────────

  Widget _bookmarkCard() {
    if (_isLoading || _hasError) return const SizedBox.shrink();

    if (_savedBookmark != null) {
      final surahNum = _savedBookmark!['surahNumber'] as int?;
      final surahName = _savedBookmark!['surahName'] as String? ?? '';
      final mushafPage = (_savedBookmark!['mushafPage'] as int?) ?? (_savedBookmark!['pageIndex'] as int? ?? 1);
      final ayahNum = _savedBookmark!['ayahNumber'] as int? ?? 1;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () {
            if (surahNum != null && _surahs.isNotEmpty) {
              final surah = _surahs.firstWhere(
                (s) => s['number'] == surahNum,
                orElse: () => _surahs.first,
              );
              _openSurah(surah, initialPage: mushafPage);
            } 
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: _gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'متابعة القراءة: سورة $surahName • آية $ayahNum',
                    style: const TextStyle(
                      color: _textPri,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_back_ios_rounded, color: _gold, size: 12),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Main Tab Switch (السور / الأجزاء) ──────────────────────────────────

  Widget _tabSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_mainTab != 0) {
                  HapticFeedback.selectionClick();
                  setState(() => _mainTab = 0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _mainTab == 0 ? _accent.withValues(alpha: 0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _mainTab == 0 ? _accent.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    'المصحف (${_surahs.isEmpty ? 114 : _surahs.length} سورة)',
                    style: TextStyle(
                      color: _mainTab == 0 ? _accent : _textSec,
                      fontSize: 13,
                      fontWeight: _mainTab == 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_mainTab != 1) {
                  HapticFeedback.selectionClick();
                  setState(() => _mainTab = 1);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _mainTab == 1 ? _gold.withValues(alpha: 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _mainTab == 1 ? _gold.withValues(alpha: 0.45) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.headphones_rounded, size: 15, color: _mainTab == 1 ? _gold : _textSec),
                      const SizedBox(width: 6),
                      Text(
                        'المصحف الصوتي',
                        style: TextStyle(
                          color: _mainTab == 1 ? _gold : _textSec,
                          fontSize: 13,
                          fontWeight: _mainTab == 1 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _searchBar() {
    final hint = _mainTab == 0
        ? 'ابحث باسم السورة أو رقمها...'
        : 'ابحث برقم الجزء، السورة، أو مطلع الآية...';

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: _textPri, fontSize: 14, fontWeight: FontWeight.w400,
        ),
        cursorColor: _accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: _textDim, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.search_rounded,
              color: _searchQuery.isNotEmpty ? _accent : _textDim,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: _textSec, size: 18),
            onPressed: () { _searchCtrl.clear(); _onSearch(''); },
          )
              : null,
        ),
      ),
    );
  }

  // ── Filter chips (Surahs only) ────────────────────────────────────────

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: List.generate(_filterLabels.length, (i) {
                final isSelected = _filterIndex == i;
                final color = _filterColors[i];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _onFilterTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.12) : _surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color.withValues(alpha: 0.5) : _border,
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        _filterLabels[i],
                        style: TextStyle(
                          color: isSelected ? color : _textSec,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            '${_filteredSurahs.length} سورة',
            style: const TextStyle(color: _textDim, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ── Surah card ────────────────────────────────────────────────────────

  Widget _surahCard(Map<String, dynamic> surah, int listIndex) {
    final num    = surah['number']         as int;
    final revType = surah['revelationType'] as String;
    final isMeccan = revType.toLowerCase() == 'meccan';
    final isLastRead = _lastReadSurah == num;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SurahTile(
        number:     num,
        name:       surah['name']        as String,
        engName:    surah['englishName'] as String,
        ayahCount:  surah['numberOfAyahs'] as int,
        isMeccan:   isMeccan,
        isLastRead: isLastRead,
        onTap:      () => _openSurah(surah),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.wifi_off_rounded, color: _textSec, size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text('تعذّر تحميل المصحف',
              style: TextStyle(color: _textPri, fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('حدث خطأ أثناء تحميل البيانات المحلية',
              style: TextStyle(color: _textSec, fontSize: 13)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _fetchQuran,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _accentDim.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentDim),
              ),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w700, fontSize: 14,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: _textDim, size: 48),
          const SizedBox(height: 14),
          Text('لا نتائج لـ "$_searchQuery"',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: _textSec, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('جرّب كلمة أخرى أو رقماً آخر',
              style: TextStyle(color: _textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.only(top: 4),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, i) => _ShimmerCard(delay: i * 70),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor:            Colors.transparent,
          statusBarIconBrightness:   Brightness.light,
          systemNavigationBarColor:  Color(0xff070B10),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          floatingActionButton: AnimatedScale(
            scale: _showScrollTop ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: FloatingActionButton.small(
              onPressed: () => _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              ),
              backgroundColor: _accentDim,
              elevation: 0,
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bg, _bgGrad],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Header ────────────────────────────────────
                  const SizedBox(height: 8),
                  _headerHero(),

                  const SizedBox(height: 10),

                  // ── Bookmark Card ──────────────────────────────────
                  _bookmarkCard(),

                  const SizedBox(height: 10),

                  // ── Main Tab Switch (السور / الأجزاء) ───────────────
                  _tabSwitch(),

                  const SizedBox(height: 10),

                  // ── Search & Filters (Only in Mushaf tab) ───────────
                  if (_mainTab == 0 && !_isLoading && !_hasError) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _searchBar(),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _filterRow(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── List (Mushaf Surahs or Audio View) ───────────────
                  Expanded(
                    child: _hasError
                        ? _errorState()
                        : _isLoading
                        ? _loadingState()
                        : _mainTab == 0
                        ? (_filteredSurahs.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                                itemCount: _filteredSurahs.length,
                                itemBuilder: (_, idx) => _surahCard(_filteredSurahs[idx], idx),
                              ))
                        : QuranAudioView(
                            surahs: _surahs,
                            surfaceColor: _surface,
                            accentColor: _accent,
                            goldColor: _gold,
                            textColor: _textPri,
                            textMutedColor: _textSec,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Surah tile ────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  final int number;
  final String name;
  final String engName;
  final int ayahCount;
  final bool isMeccan;
  final bool isLastRead;
  final VoidCallback onTap;

  const _SurahTile({
    required this.number,
    required this.name,
    required this.engName,
    required this.ayahCount,
    required this.isMeccan,
    required this.isLastRead,
    required this.onTap,
  });

  static const Color _surface = Color(0xff0F1520);
  static const Color _border  = Color(0xff1C2540);
  static const Color _accent  = Color(0xff5DD3A8);
  static const Color _gold    = Color(0xffD4A853);
  static const Color _textPri = Color(0xffEDF1F8);
  static const Color _textSec = Color(0xff7A8599);

  @override
  Widget build(BuildContext context) {
    final typeLabel = isMeccan ? 'مكية' : 'مدنية';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLastRead ? _gold.withValues(alpha: 0.35) : _border,
              width: isLastRead ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              // رقم السورة بتصميم بسيط
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isLastRead
                      ? _gold.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLastRead
                        ? _gold.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: isLastRead ? _gold : _textPri,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // اسم السورة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: _textPri,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isLastRead) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.bookmark_rounded, color: _gold, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$typeLabel • $ayahCount آية',
                      style: const TextStyle(
                        color: _textSec,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // الاسم الإنجليزي والسهم
              Text(
                engName,
                style: TextStyle(
                  color: _textSec.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_back_ios_rounded,
                color: _textSec.withValues(alpha: 0.35),
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shimmer card ──────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final int delay;
  const _ShimmerCard({required this.delay});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  static const Color _surface = Color(0xff0F1520);
  static const Color _high    = Color(0xff192035);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xff1C2540)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _high.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 110, height: 13, t: t),
                    const SizedBox(height: 8),
                    _shimmerBox(width: 75, height: 10, t: t, opacity: 0.6),
                  ],
                ),
              ),
              _shimmerBox(width: 26, height: 13, t: t),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double t,
    double opacity = 1.0,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _high.withValues(alpha: (0.3 + t * 0.35) * opacity),
            _high.withValues(alpha: (0.5 + t * 0.2) * opacity),
            _high.withValues(alpha: (0.3 + t * 0.35) * opacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
