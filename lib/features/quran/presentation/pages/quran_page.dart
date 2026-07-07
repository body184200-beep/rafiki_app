import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/quran/presentation/pages/quran_details_page.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/quran/domain/repositories/quran_repository.dart' as quran;

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
  static const Color _accent     = Color(0xff5DD3A8);   // teal
  static const Color _accentDim  = Color(0xff1F9E72);
  static const Color _gold       = Color(0xffD4A853);   // Islamic gold
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
  int    _filterIndex = 0;
  int?   _lastReadSurah;

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

      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _surahs         = list;
          _filteredSurahs = list;
          _lastReadSurah  = lastRead;
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

  void _onSearch(String q) { _searchQuery = q; _applyFilters(); }

  void _onFilterTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _filterIndex = i);
    _applyFilters();
  }

  void _openSurah(Map<String, dynamic> surah) async {
    HapticFeedback.selectionClick();
    final surahNum = surah['number'] as int;
    setState(() => _lastReadSurah = surahNum);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_last_read_surah', surahNum);
    } catch (_) {}
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => SurahDetailPage(
          surahName: surah['name'] as String,
          surahNumber: surah['number'] as int,
          ayat: List<String>.from(
            (surah['ayahs'] as List).map((a) => a['text']),
          ),
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
    );
  }

  // ── Glass helper ──────────────────────────────────────────────────────

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
            color: _surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? _border),
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
      child: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _GeometricPatternPainter()),
            ),
          ),
          // Glass layer
          _glass(
            radius: 24,
            borderColor: _gold.withValues(alpha: 0.3),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _high.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _textSec,
                          size: 15,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Dot indicators
                    Row(
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: i == 1 ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == 1
                              ? _gold.withValues(alpha: 0.8)
                              : _gold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bismillah line
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: _gold.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 6),

                // Main title
                const Text(
                  'المصحف الشريف',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: _textPri,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // Stats pills row
                if (!_isLoading && !_hasError)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statsPill('١١٤', 'سورة', _accent),
                      const SizedBox(width: 10),
                      _statsPill('٦٢٣٦', 'آية', _gold),
                      const SizedBox(width: 10),
                      _statsPill('٣٠', 'جزء', _medinanClr),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 11, fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: _glass(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        radius: 16,
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: _textPri, fontSize: 15, fontWeight: FontWeight.w400,
          ),
          cursorColor: _accent,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12,
            ),
            hintText: 'ابحث باسم السورة أو رقمها...',
            hintStyle: const TextStyle(color: _textDim, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.search_rounded,
                color: _searchQuery.isNotEmpty ? _accent : _textDim,
                size: 20,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: _textSec, size: 18),
              onPressed: () { _searchCtrl.clear(); _onSearch(''); },
            )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────

  Widget _filterRow() {
    return Row(
      children: [
        // Filter chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL scroll
            child: Row(
              children: List.generate(_filterLabels.length, (i) {
                final isSelected = _filterIndex == i;
                final color = _filterColors[i];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _onFilterTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : _surfaceAlt,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.5)
                              : _border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 0,
                          )
                        ]
                            : [],
                      ),
                      child: Text(
                        _filterLabels[i],
                        style: TextStyle(
                          color: isSelected ? color : _textSec,
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // Result count
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              key: ValueKey(_filteredSurahs.length),
              '${_filteredSurahs.length} سورة',
              style: const TextStyle(color: _textDim, fontSize: 11.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section divider ───────────────────────────────────────────────────

  Widget _divider(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: _borderSoft),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: _textDim, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: _borderSoft),
          ),
        ],
      ),
    );
  }

  // ── Surah card ────────────────────────────────────────────────────────

  Widget _surahCard(Map<String, dynamic> surah, int listIndex) {
    final num    = surah['number']         as int;
    final revType = surah['revelationType'] as String;
    final isMeccan = revType.toLowerCase() == 'meccan';
    final isLastRead = _lastReadSurah == num;

    final delay = (listIndex * 0.025).clamp(0.0, 0.75);
    final end   = (delay + 0.35).clamp(0.0, 1.0);
    final anim  = CurvedAnimation(
      parent: _listAnim,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: _SurahTile(
          number:     num,
          name:       surah['name']        as String,
          engName:    surah['englishName'] as String,
          ayahCount:  surah['numberOfAyahs'] as int,
          isMeccan:   isMeccan,
          isLastRead: isLastRead,
          onTap:      () => _openSurah(surah),
        ),
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
          const Text('جرّب كلمة أخرى أو رقم السورة',
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

                  const SizedBox(height: 16),

                  // ── Search ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _searchBar(),
                  ),

                  const SizedBox(height: 12),

                  // ── Filter + count ─────────────────────────────────
                  if (!_isLoading && !_hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _filterRow(),
                    ),

                  const SizedBox(height: 8),

                  // ── List ───────────────────────────────────────────
                  Expanded(
                    child: _hasError
                        ? _errorState()
                        : _isLoading
                        ? _loadingState()
                        : _filteredSurahs.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          16, 4, 16, 32),
                      itemCount: _filteredSurahs.length + 1,
                      itemBuilder: (_, i) {
                        // Juz dividers (simplified: surah 1, 2, 10, 18...)
                        // Just one divider example at top for aesthetics
                        if (i == 0) {
                          return _searchQuery.isEmpty && _filterIndex == 0
                              ? _divider('السور القرآنية الكريمة')
                              : const SizedBox(height: 4);
                        }
                        final idx = i - 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _surahCard(
                              _filteredSurahs[idx], idx),
                        );
                      },
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

// ── Geometric pattern painter (Islamic art motif) ─────────────────────────

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Radial glow behind header
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          const Color(0xff5DD3A8).withValues(alpha: 0.07),
          const Color(0xffD4A853).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Subtle geometric octagon pattern in corners
    final patPaint = Paint()
      ..color = const Color(0xffD4A853).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    void drawOctagon(Offset center, double r) {
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = math.pi / 8 + i * math.pi / 4;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, patPaint);
    }

    // Draw layered octagons in top-left and bottom-right corners
    for (int layer = 1; layer <= 3; layer++) {
      drawOctagon(Offset(-10, -10), layer * 28.0);
      drawOctagon(Offset(size.width + 10, size.height + 10), layer * 28.0);
    }
    // Small stars top-right
    for (int layer = 1; layer <= 2; layer++) {
      drawOctagon(Offset(size.width + 10, -10), layer * 22.0);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Surah tile ────────────────────────────────────────────────────────────

class _SurahTile extends StatefulWidget {
  final int    number;
  final String name;
  final String engName;
  final int    ayahCount;
  final bool   isMeccan;
  final bool   isLastRead;
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

  @override
  State<_SurahTile> createState() => _SurahTileState();
}

class _SurahTileState extends State<_SurahTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  bool _isHovered = false;

  static const Color _surface    = Color(0xff0F1520);
  static const Color _surfaceAlt = Color(0xff131A28);
  static const Color _border     = Color(0xff1C2540);
  static const Color _accent     = Color(0xff5DD3A8);
  static const Color _gold       = Color(0xffD4A853);
  static const Color _textPri    = Color(0xffEDF1F8);
  static const Color _textSec    = Color(0xff7A8599);
  static const Color _textDim    = Color(0xff2E3A50);
  static const Color _meccanClr  = Color(0xff4A9ECC);
  static const Color _medinanClr = Color(0xff8B6ED4);

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  Color get _typeColor => widget.isMeccan ? _meccanClr : _medinanClr;
  String get _typeLabel => widget.isMeccan ? 'مكية' : 'مدنية';

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown:   (_) { _press.reverse(); setState(() => _isHovered = true); },
        onTapUp:     (_) { _press.forward(); setState(() => _isHovered = false); },
        onTapCancel: ()  { _press.forward(); setState(() => _isHovered = false); },
        onTap:       widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _isHovered ? _surfaceAlt : _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isLastRead
                  ? _gold.withValues(alpha: 0.35)
                  : _isHovered
                  ? _border.withValues(alpha: 1.5)
                  : _border,
              width: widget.isLastRead ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: _accent.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: 0,
              )
            ]
                : [],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Left accent bar ─────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? _accent.withValues(alpha: 0.7)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                    child: Row(
                      children: [
                        // ── Number badge ───────────────────────────
                        _OctaBadge(
                          number: widget.number,
                          isLastRead: widget.isLastRead,
                        ),

                        const SizedBox(width: 14),

                        // ── Name block ─────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.name,
                                      style: const TextStyle(
                                        color: _textPri,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (widget.isLastRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _gold.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: _gold.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text('آخر قراءة',
                                          style: TextStyle(
                                            color: _gold,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(widget.engName,
                                      style: const TextStyle(
                                          color: _textSec, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Container(
                                      width: 1, height: 10, color: _textDim),
                                  const SizedBox(width: 8),
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _typeColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _typeColor
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      _typeLabel,
                                      style: TextStyle(
                                        color: _typeColor.withValues(alpha: 0.85),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Ayah count ─────────────────────────────
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.ayahCount}',
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text('آية',
                                style: TextStyle(
                                  color: _textDim,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),

                        const SizedBox(width: 10),

                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _isHovered ? _accent : _textDim,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Octagonal number badge ────────────────────────────────────────────────

class _OctaBadge extends StatelessWidget {
  final int  number;
  final bool isLastRead;

  const _OctaBadge({required this.number, required this.isLastRead});

  static const Color _accent    = Color(0xff5DD3A8);
  static const Color _gold      = Color(0xffD4A853);

  @override
  Widget build(BuildContext context) {
    final color = isLastRead ? _gold : _accent;
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _OctaPainter(color: color, isLastRead: isLastRead),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: color,
              fontSize: number > 99 ? 11 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OctaPainter extends CustomPainter {
  final Color color;
  final bool isLastRead;
  const _OctaPainter({required this.color, required this.isLastRead});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 2;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = math.pi / 8 + i * math.pi / 4;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _OctaPainter old) =>
      old.color != color || old.isLastRead != isLastRead;
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
              // Octagon placeholder
              SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: _ShimmerOctaPainter(t: t),
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

class _ShimmerOctaPainter extends CustomPainter {
  final double t;
  const _ShimmerOctaPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 3;
    final opacity = 0.15 + t * 0.2;

    final paint = Paint()
      ..color = const Color(0xff192035).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = math.pi / 8 + i * math.pi / 4;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerOctaPainter old) => old.t != t;
}