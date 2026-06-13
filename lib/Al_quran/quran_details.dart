import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  THEME DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════
class _AyahTheme {
  final String name;
  final Color bg;
  final Color bgGrad;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color accent;
  final Color accentDim;
  final Color accentGlow;
  final Color textColor;
  final Color textSec;
  final Color numBg;
  final Color numText;
  final Brightness brightness;

  const _AyahTheme({
    required this.name,
    required this.bg,
    required this.bgGrad,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.accent,
    required this.accentDim,
    required this.accentGlow,
    required this.textColor,
    required this.textSec,
    required this.numBg,
    required this.numText,
    required this.brightness,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  THEMES
// ══════════════════════════════════════════════════════════════════════════════
const List<_AyahTheme> _kThemes = [
  _AyahTheme(
    name: 'ليلي',
    bg: Color(0xff060A10),
    bgGrad: Color(0xff0B1320),
    surface: Color(0xff0F1520),
    surfaceHigh: Color(0xff16202E),
    border: Color(0xff1E2A3E),
    accent: Color(0xff4ECCA3),
    accentDim: Color(0xff1D9E75),
    accentGlow: Color(0x334ECCA3),
    textColor: Color(0xffEEF2F8),
    textSec: Color(0xff8A96AA),
    numBg: Color(0xff1D9E75),
    numText: Color(0xffEEF2F8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'عنبري',
    bg: Color(0xff0C0804),
    bgGrad: Color(0xff1C1206),
    surface: Color(0xff1C1508),
    surfaceHigh: Color(0xff261C0C),
    border: Color(0xff2E2210),
    accent: Color(0xffF0C060),
    accentDim: Color(0xffA07830),
    accentGlow: Color(0x33F0C060),
    textColor: Color(0xffF5ECD8),
    textSec: Color(0xff907860),
    numBg: Color(0xffA07830),
    numText: Color(0xffF5ECD8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'بحري',
    bg: Color(0xff030C18),
    bgGrad: Color(0xff071828),
    surface: Color(0xff0C1E30),
    surfaceHigh: Color(0xff10283E),
    border: Color(0xff10283C),
    accent: Color(0xff60C8F0),
    accentDim: Color(0xff2880A8),
    accentGlow: Color(0x3360C8F0),
    textColor: Color(0xffDCF0F8),
    textSec: Color(0xff6090A8),
    numBg: Color(0xff2880A8),
    numText: Color(0xffDCF0F8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'ياقوتي',
    bg: Color(0xff100608),
    bgGrad: Color(0xff1E0C12),
    surface: Color(0xff200C14),
    surfaceHigh: Color(0xff2A101C),
    border: Color(0xff341422),
    accent: Color(0xffF06080),
    accentDim: Color(0xffA03050),
    accentGlow: Color(0x33F06080),
    textColor: Color(0xffF8E0E8),
    textSec: Color(0xff906070),
    numBg: Color(0xffA03050),
    numText: Color(0xffF8E0E8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'بنفسجي',
    bg: Color(0xff0A0610),
    bgGrad: Color(0xff140C20),
    surface: Color(0xff160C22),
    surfaceHigh: Color(0xff1E1030),
    border: Color(0xff281440),
    accent: Color(0xffC080F0),
    accentDim: Color(0xff7030A0),
    accentGlow: Color(0x33C080F0),
    textColor: Color(0xffF0E4F8),
    textSec: Color(0xff8060A8),
    numBg: Color(0xff7030A0),
    numText: Color(0xffF0E4F8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'فيروزي',
    bg: Color(0xff040E08),
    bgGrad: Color(0xff081810),
    surface: Color(0xff0A1C10),
    surfaceHigh: Color(0xff0E2416),
    border: Color(0xff102818),
    accent: Color(0xff60E8B0),
    accentDim: Color(0xff208858),
    accentGlow: Color(0x3360E8B0),
    textColor: Color(0xffDCF8E8),
    textSec: Color(0xff509070),
    numBg: Color(0xff208858),
    numText: Color(0xffDCF8E8),
    brightness: Brightness.dark,
  ),
  _AyahTheme(
    name: 'صحفي',
    bg: Color(0xffF7F2E8),
    bgGrad: Color(0xffEEE5D0),
    surface: Color(0xffFFFFFF),
    surfaceHigh: Color(0xffF5EFE0),
    border: Color(0xffD8CCBA),
    accent: Color(0xff2A6A4A),
    accentDim: Color(0xff1A4A30),
    accentGlow: Color(0x222A6A4A),
    textColor: Color(0xff1A1408),
    textSec: Color(0xff706050),
    numBg: Color(0xff2A6A4A),
    numText: Color(0xffFFFFFF),
    brightness: Brightness.light,
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
//  READ PROGRESS MODEL
// ══════════════════════════════════════════════════════════════════════════════
class _ReadProgress {
  final int totalPages;
  final int currentPage;

  const _ReadProgress(this.currentPage, this.totalPages);

  double get fraction => totalPages == 0 ? 0 : (currentPage + 1) / totalPages;
  String get label => '${((fraction) * 100).round()}%';
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN PAGE
// ══════════════════════════════════════════════════════════════════════════════
class SurahDetailPage extends StatefulWidget {
  final String surahName;
  final List<String> ayat;

  const SurahDetailPage({
    super.key,
    required this.surahName,
    required this.ayat,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late final PageController _pageCtrl;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  late final AnimationController _themeCtrl;

  late final AnimationController _panelCtrl;
  late final Animation<double> _panelAnim;

  late final AnimationController _flipCtrl;
  late final Animation<double> _flipFade;

  late final AnimationController _progressCtrl;

  // ── State ─────────────────────────────────────────────────────────────────
  List<List<String>> _pages = [];
  final int _ayatPerPage = 10;
  double _fontSize = 22;

  // _currentPage = 0 → الصفحة الأولى (بداية السورة)
  // PageView يعمل بـ LTR عادي (بدون عكس):
  //   pageIndex 0 = الصفحة الأولى (أول السورة) على اليمين
  //   السويب من اليمين لليسار → pageIndex يزيد → صفحة تالية ✓
  //   السويب من اليسار لليمين → pageIndex يقل  → صفحة سابقة ✓
  int _currentPage = 0;

  Set<int> _bookmarks = {};
  bool _showPanel = false;
  int _themeIndex = 0;

  // ── Derived ───────────────────────────────────────────────────────────────
  _AyahTheme get _t => _kThemes[_themeIndex];
  bool get _isDark => _t.brightness == Brightness.dark;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pageCtrl = PageController();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
    ));

    _themeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1.0;

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _panelAnim = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _flipFade = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeOut);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buildPages();
    _loadData();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entranceCtrl.dispose();
    _themeCtrl.dispose();
    _panelCtrl.dispose();
    _flipCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ── Pages ─────────────────────────────────────────────────────────────────
  void _buildPages() {
    _pages = [];
    final full = List<String>.from(widget.ayat);
    if (widget.surahName != 'التوبة') {
      full.insert(0, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
    }
    for (int i = 0; i < full.length; i += _ayatPerPage) {
      _pages.add(full.sublist(i, min(i + _ayatPerPage, full.length)));
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.surahName;

    final savedPg = prefs.getInt('surah_$key');
    final bmList = prefs.getStringList('bookmarks_$key');
    final themeIndex = prefs.getInt('theme_$key') ?? 0;

    if (!mounted) return;

    setState(() {
      _themeIndex = themeIndex.clamp(0, _kThemes.length - 1);
      if (bmList != null) {
        _bookmarks = bmList.map(int.parse).toSet();
      }
    });

    _entranceCtrl.forward();

    final startPage =
    (savedPg != null && savedPg < _pages.length) ? savedPg : 0;

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _pageCtrl.jumpToPage(startPage);
      setState(() => _currentPage = startPage);
    }
    _updateProgress();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.surahName;
    await Future.wait([
      prefs.setInt('surah_$key', _currentPage),
      prefs.setStringList(
        'bookmarks_$key',
        _bookmarks.map((e) => e.toString()).toList(),
      ),
      prefs.setInt('theme_$key', _themeIndex),
    ]);
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _updateProgress() {
    final target =
    _pages.isEmpty ? 0.0 : (_currentPage + 1) / _pages.length;
    _progressCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() {
      _bookmarks.contains(_currentPage)
          ? _bookmarks.remove(_currentPage)
          : _bookmarks.add(_currentPage);
    });
    _saveData();
  }

  void _changeFontSize(double d) {
    setState(() => _fontSize = (_fontSize + d).clamp(14.0, 40.0));
    HapticFeedback.selectionClick();
  }

  void _togglePanel() {
    HapticFeedback.selectionClick();
    setState(() => _showPanel = !_showPanel);
    _showPanel ? _panelCtrl.forward() : _panelCtrl.reverse();
  }

  void _selectTheme(int index) {
    if (index == _themeIndex) {
      _togglePanel();
      return;
    }
    HapticFeedback.lightImpact();
    _themeCtrl.reverse().then((_) {
      setState(() {
        _themeIndex = index;
        _showPanel = false;
      });
      _panelCtrl.reverse();
      _themeCtrl.forward();
      _saveData();
    });
  }

  // ── onPageChanged: pageIndex مباشر = logical index ──────────────────────
  void _onPageChanged(int pageIndex) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = pageIndex);
    _updateProgress();
    _saveData();
    _flipCtrl.reverse().then((_) => _flipCtrl.forward());
  }

  // ── التنقل بالأزرار ────────────────────────────────────────────────────────
  // "السابقة" = رقم أقل = pageIndex أصغر (تقليب لليمين)
  void _goPrev() {
    if (_currentPage <= 0) return;
    _pageCtrl.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  // "التالية" = رقم أكبر = pageIndex أكبر (تقليب لليسار)
  void _goNext() {
    if (_currentPage >= _pages.length - 1) return;
    _pageCtrl.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _glass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    double radius = 20,
    Color? bg,
    Border? border,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bg ?? _t.surface.withOpacity(0.88),
              borderRadius: BorderRadius.circular(radius),
              border: border ?? Border.all(color: _t.border, width: 0.8),
            ),
            child: child,
          ),
        ),
      );

  Widget _iconBtn({
    required Widget icon,
    required VoidCallback onTap,
    bool active = false,
    String? tooltip,
  }) =>
      Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? _t.accent.withOpacity(0.15) : _t.surfaceHigh,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: active ? _t.accent.withOpacity(0.5) : _t.border,
                width: 0.8,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _progressBar() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) => Stack(
        children: [
          Container(height: 2, color: _t.border),
          FractionallySizedBox(
            widthFactor: _progressCtrl.value,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_t.accentDim, _t.accent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIndicator() {
    if (_pages.length <= 1) return const SizedBox.shrink();
    const int window = 9;
    final int total = _pages.length;
    final int cur = _currentPage;
    final int start = (cur - window ~/ 2).clamp(0, max(0, total - window));
    final int end = min(start + window, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(end - start, (i) {
        final idx = start + i;
        final isActive = idx == cur;
        final dist = (idx - cur).abs();
        final w = isActive ? 22.0 : (dist <= 1 ? 8.0 : 5.0);
        final op = isActive ? 1.0 : (dist <= 1 ? 0.45 : 0.20);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: w,
          height: isActive ? 7.0 : 5.0,
          decoration: BoxDecoration(
            color: _t.accent.withOpacity(op),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _themePanel() {
    return SizeTransition(
      sizeFactor: _panelAnim,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _panelAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: _glass(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _t.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ثيم القراءة',
                      style: TextStyle(
                        color: _t.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_kThemes.length, (i) {
                    final theme = _kThemes[i];
                    final selected = i == _themeIndex;
                    return GestureDetector(
                      onTap: () => _selectTheme(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 44 : 38,
                        height: selected ? 44 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [theme.bgGrad, theme.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: selected ? _t.accent : _t.border,
                            width: selected ? 2.5 : 0.8,
                          ),
                          boxShadow: selected
                              ? [
                            BoxShadow(
                              color: theme.accent.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                              : [],
                        ),
                        child: selected
                            ? Icon(Icons.check_rounded,
                            color: theme.numText, size: 16)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_kThemes.length, (i) {
                    return Text(
                      _kThemes[i].name,
                      style: TextStyle(
                        color: i == _themeIndex ? _t.accent : _t.textSec,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bismillah ornament ────────────────────────────────────────────────────
  Widget _ornamentLine({bool reverse = false}) {
    return Expanded(
      child: Container(
        height: 0.6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reverse
                ? [_t.accent.withOpacity(0.4), Colors.transparent]
                : [Colors.transparent, _t.accent.withOpacity(0.4)],
          ),
        ),
      ),
    );
  }

  Widget _bismillah(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // إطار زخرفي علوي
          Row(
            children: [
              _ornamentLine(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.stars_rounded,
                    color: _t.accent.withOpacity(0.6), size: 12),
              ),
              _ornamentLine(reverse: true),
            ],
          ),
          const SizedBox(height: 18),
          // نص البسملة بخط أكبر وأجمل
          Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: _fontSize + 4,
              color: _t.accent,
              fontWeight: FontWeight.w800,
              height: 2.0,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 18),
          // إطار زخرفي سفلي
          Row(
            children: [
              _ornamentLine(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.stars_rounded,
                    color: _t.accent.withOpacity(0.6), size: 12),
              ),
              _ornamentLine(reverse: true),
            ],
          ),
        ],
      ),
    );
  }

  // ── Single ayah — شكل مصحف حقيقي ─────────────────────────────────────────
  // الآيات في المصحف الحقيقي تكون inline مع بعضها مش كل آية في سطر لوحدها
  Widget _ayahInlineText(List<String> items, bool startsWithBismillah, int pageLogical) {
    // نبني نص الآيات كـ TextSpan واحد مترابط
    final List<InlineSpan> spans = [];

    for (int i = 0; i < items.length; i++) {
      if (startsWithBismillah && i == 0) continue; // البسملة تتعرض منفردة

      final int offset = startsWithBismillah ? 1 : 0;
      final int ayahNum = pageLogical * _ayatPerPage + i + 1 - offset;

      // نص الآية
      spans.add(
        TextSpan(
          text: '${items[i]} ',
          style: TextStyle(
            fontSize: _fontSize,
            color: _t.textColor,
            height: 2.4,
            fontFamily: 'Scheherazade New', // أو أي خط عربي قرآني
          ),
        ),
      );

      // رقم الآية (﴿١﴾)
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _t.numBg.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _t.accent.withOpacity(0.3),
                width: 0.7,
              ),
            ),
            child: Text(
              '﴿$ayahNum﴾',
              style: TextStyle(
                color: _t.numText,
                fontSize: _fontSize * 0.55,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // ── Page content ──────────────────────────────────────────────────────────
  Widget _pageContent(int logicalIndex) {
    final items = _pages[logicalIndex];
    final startsWithBismillah =
        logicalIndex == 0 && widget.surahName != 'التوبة';

    return FadeTransition(
      opacity: _flipFade,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Column(
          children: [
            // البسملة منفردة في الأعلى
            if (startsWithBismillah) _bismillah(items[0]),

            // باقي الآيات كنص مترابط كالمصحف
            if (items.length > (startsWithBismillah ? 1 : 0))
              _ayahInlineText(items, startsWithBismillah, logicalIndex),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _appBarActions() {
    final isBookmarked = _bookmarks.contains(_currentPage);
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isBookmarked),
                color: isBookmarked ? _t.accent : _t.textSec,
                size: 18,
              ),
            ),
            onTap: _toggleBookmark,
            active: isBookmarked,
            tooltip: 'إشارة مرجعية',
          ),
          const SizedBox(width: 7),
          _iconBtn(
            icon: Icon(Icons.text_decrease_rounded,
                color: _t.textSec, size: 16),
            onTap: () => _changeFontSize(-2),
            tooltip: 'تصغير',
          ),
          const SizedBox(width: 7),
          _iconBtn(
            icon: Icon(Icons.text_increase_rounded,
                color: _t.textSec, size: 16),
            onTap: () => _changeFontSize(2),
            tooltip: 'تكبير',
          ),
          const SizedBox(width: 7),
          _iconBtn(
            icon: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_t.bg, _t.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            onTap: _togglePanel,
            active: _showPanel,
            tooltip: 'تغيير الثيم',
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _footerBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool iconFirst = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.22,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _t.surfaceHigh,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _t.border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconFirst
                ? [
              Icon(icon, color: _t.accent, size: 13),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: _t.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]
                : [
              Text(label,
                  style: TextStyle(
                      color: _t.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Icon(icon, color: _t.accent, size: 13),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final progress = _ReadProgress(_currentPage, _pages.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _progressBar(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
          decoration: BoxDecoration(
            color: _t.surface.withOpacity(0.95),
            border: Border(top: BorderSide(color: _t.border, width: 0.8)),
          ),
          child: Row(
            children: [
              // ── السابقة: تقليب لليمين = صفحة أصغر رقماً ──────────────────
              _footerBtn(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'السابقة',
                enabled: _currentPage > 0,
                onTap: _goPrev,
                iconFirst: true,
              ),

              // center
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: TextStyle(
                        color: _t.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_bookmarks.contains(_currentPage))
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.bookmark_rounded,
                                color: _t.accent, size: 10),
                          ),
                        Text(
                          'قرأت ${progress.label}',
                          style:
                          TextStyle(color: _t.textSec, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── التالية: تقليب لليسار = صفحة أكبر رقماً ─────────────────
              _footerBtn(
                icon: Icons.arrow_back_ios_rounded,
                label: 'التالية',
                enabled: _currentPage < _pages.length - 1,
                onTap: _goNext,
                iconFirst: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
          _isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: _t.surface,
          systemNavigationBarIconBrightness:
          _isDark ? Brightness.light : Brightness.dark,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut,
          color: _t.bg,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: _t.bg,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: _t.textSec, size: 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.surahName,
                    style: TextStyle(
                      color: _t.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_bookmarks.isNotEmpty)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_rounded,
                              color: _t.accent, size: 9),
                          const SizedBox(width: 4),
                          Text(
                            '${_bookmarks.length} إشارة',
                            style: TextStyle(
                                color: _t.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [_appBarActions()],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(height: 0.8, color: _t.border),
              ),
            ),
            body: FadeTransition(
              opacity: _entranceFade,
              child: SlideTransition(
                position: _entranceSlide,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_t.bg, _t.bgGrad],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.7],
                    ),
                  ),
                  child: Column(
                    children: [
                      _themePanel(),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الجزء ${_currentPage + 1}',
                              style: TextStyle(
                                  color: _t.textSec, fontSize: 10),
                            ),
                            _pageIndicator(),
                            Text(
                              '${widget.ayat.length} آية',
                              style: TextStyle(
                                  color: _t.textSec, fontSize: 10),
                            ),
                          ],
                        ),
                      ),

                      // ══════════════════════════════════════════════════════
                      //  PageView — LTR مباشر بدون عكس
                      //
                      //  الفكرة:
                      //  • الـ PageView يعمل بـ LTR عادي (بدون Directionality RTL)
                      //  • pageIndex 0 = الصفحة الأولى (أول السورة)
                      //  • السويب من اليمين لليسار → pageIndex يزيد → صفحة تالية ✓
                      //  • السويب من اليسار لليمين → pageIndex يقل  → صفحة سابقة ✓
                      //  • هذا هو السلوك الصحيح للمصحف
                      // ══════════════════════════════════════════════════════
                      Expanded(
                        child: Directionality(
                          // LTR للـ PageView عشان السويب يكون صح
                          textDirection: TextDirection.ltr,
                          child: PageView.builder(
                            controller: _pageCtrl,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: _onPageChanged,
                            itemCount: _pages.length,
                            itemBuilder: (_, pageIndex) {
                              return _pageContent(pageIndex);
                            },
                          ),
                        ),
                      ),

                      _footer(),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}