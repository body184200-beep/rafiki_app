import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:rafiki_app/features/quran/data/datasources/juz_data.dart';
import 'package:rafiki_app/features/quran/data/models/mushaf_page_model.dart';
import 'package:rafiki_app/features/quran/data/services/tafsir_service.dart';
import 'package:rafiki_app/features/quran/presentation/widgets/mushaf_page_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  MUSHAF THEME PROFILE
// ══════════════════════════════════════════════════════════════════════════════
class _MushafTheme {
  final String name;
  final Color bg;
  final Color primary; // Teal / Border
  final Color accent;  // Gold / Bronze
  final Color text;
  final bool isDark;

  const _MushafTheme({
    required this.name,
    required this.bg,
    required this.primary,
    required this.accent,
    required this.text,
    required this.isDark,
  });
}

const List<_MushafTheme> _kMushafThemes = [
  // 1. مصحف المدينة الأصيل (مطابق للمصحف المطبوع)
  _MushafTheme(
    name: 'مصحف المدينة',
    bg: Color(0xFFFDFBF7),
    primary: Color(0xFF1E5E72),
    accent: Color(0xFFC49A45),
    text: Color(0xFF14171A),
    isDark: false,
  ),
  // 2. عنبري دافئ (مريح للعين)
  _MushafTheme(
    name: 'عنبري دافئ',
    bg: Color(0xFFF5EAD4),
    primary: Color(0xFF5D3F1D),
    accent: Color(0xFFB57E28),
    text: Color(0xFF221609),
    isDark: false,
  ),
  // 3. ليلي ملكي
  _MushafTheme(
    name: 'ليلي ملكي',
    bg: Color(0xFF0D1219),
    primary: Color(0xFF245B6E),
    accent: Color(0xFFD4AF37),
    text: Color(0xFFECEBE6),
    isDark: true,
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
//  SURAH DETAIL PAGE — المصحف الشريف (٦٠٤ صفحة)
// ══════════════════════════════════════════════════════════════════════════════
class SurahDetailPage extends StatefulWidget {
  final String? surahName;
  final List<String>? ayat;
  final int surahNumber;
  final int? initialPage; // 1-based page number (1..604)
  final List<Map<String, dynamic>>? allSurahs;
  final int? initialSurahIndex;

  const SurahDetailPage({
    super.key,
    this.surahName,
    this.ayat,
    this.surahNumber = 1,
    this.initialPage,
    this.allSurahs,
    this.initialSurahIndex,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late PageController _pageCtrl;
  SharedPreferences? _prefs;
  List<MushafPage> _pages = [];
  bool _isLoading = true;

  int _currentPageIndex = 0; // 0..603 corresponds to pages 1..604
  int _themeIndex = 0;
  double _fontSize = 20.0;
  bool _showControls = true;
  int? _bookmarkedPage;

  // ── Zoom State ─────────────────────────────────────────────────────────────
  double _pinchBaseFontSize = 20.0;
  Timer? _zoomHudTimer;
  bool _showZoomHud = false;

  void _zoomIn() async {
    HapticFeedback.selectionClick();
    final newSize = (_fontSize + 2.0).clamp(14.0, 36.0);
    setState(() => _fontSize = newSize);
    _triggerZoomHud();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_font_size', newSize);
  }

  void _zoomOut() async {
    HapticFeedback.selectionClick();
    final newSize = (_fontSize - 2.0).clamp(14.0, 36.0);
    setState(() => _fontSize = newSize);
    _triggerZoomHud();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_font_size', newSize);
  }

  void _resetZoom() async {
    HapticFeedback.mediumImpact();
    setState(() => _fontSize = 20.0);
    _triggerZoomHud();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushaf_font_size', 20.0);
  }

  void _triggerZoomHud() {
    _zoomHudTimer?.cancel();
    setState(() => _showZoomHud = true);
    _zoomHudTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showZoomHud = false);
    });
  }

  _MushafTheme get _theme => _kMushafThemes[_themeIndex];
  MushafPage? get _currentPage =>
      _pages.isNotEmpty && _currentPageIndex < _pages.length ? _pages[_currentPageIndex] : null;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _initData();
  }

  @override
  void dispose() {
    _zoomHudTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final savedTheme = prefs.getInt('mushaf_theme_index') ?? 0;
    final savedFontSize = prefs.getDouble('mushaf_font_size') ?? 20.0;
    final bmRaw = prefs.getString('mushaf_global_bookmark');

    int? savedBmPage;
    if (bmRaw != null) {
      try {
        final map = jsonDecode(bmRaw);
        savedBmPage = map['mushafPage'] as int?;
      } catch (_) {}
    }

    final pages = await QuranLocalDataSource().getMushafPages();

    if (!mounted) return;

    // Determine target start page (1..604)
    int targetPage = 1;
    if (widget.initialPage != null && widget.initialPage! >= 1 && widget.initialPage! <= 604) {
      targetPage = widget.initialPage!;
    } else if (widget.surahNumber > 1) {
      // Find the page where this surah starts
      final match = pages.firstWhere(
        (p) => p.ayahs.any((a) => a.surahNumber == widget.surahNumber && a.isFirstInSurah),
        orElse: () => pages.first,
      );
      targetPage = match.pageNumber;
    } else {
      final lastRead = prefs.getInt('mushaf_last_read_page') ?? 1;
      targetPage = lastRead.clamp(1, 604);
    }

    final targetIndex = (targetPage - 1).clamp(0, pages.length - 1);

    setState(() {
      _pages = pages;
      _isLoading = false;
      _themeIndex = savedTheme.clamp(0, _kMushafThemes.length - 1);
      _fontSize = savedFontSize.clamp(14.0, 32.0);
      _bookmarkedPage = savedBmPage;
      _currentPageIndex = targetIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(targetIndex);
      }
    });
  }

  void _onPageChanged(int index) {
    if (_currentPageIndex == index) return;
    setState(() => _currentPageIndex = index);
    final pageNum = index + 1;
    _prefs?.setInt('mushaf_last_read_page', pageNum);
  }

  void _jumpToPage(int pageNumber) {
    final index = (pageNumber - 1).clamp(0, _pages.length - 1);
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(index);
    }
    setState(() => _currentPageIndex = index);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final page = _currentPage;
    if (page == null) return;

    final isAlready = _bookmarkedPage == page.pageNumber;

    if (isAlready) {
      await prefs.remove('mushaf_global_bookmark');
      setState(() => _bookmarkedPage = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة العلامة المرجعية'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final firstAyah = page.ayahs.isNotEmpty ? page.ayahs.first : null;
      final bm = {
        'mushafPage': page.pageNumber,
        'pageIndex': page.pageNumber,
        'surahNumber': firstAyah?.surahNumber ?? page.primarySurahNumber,
        'surahName': firstAyah?.surahName ?? page.primarySurahName,
        'ayahNumber': firstAyah?.numberInSurah ?? 1,
      };
      await prefs.setString('mushaf_global_bookmark', jsonEncode(bm));
      setState(() => _bookmarkedPage = page.pageNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الصفحة ${toArabicDigits(page.pageNumber)} في العلامات المرجعية'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Show Tafsir Bottom Sheet ───────────────────────────────────────────────
  void _showAyahTafsir(MushafAyah ayah) {
    HapticFeedback.mediumImpact();
    String currentEdition = 'ar.muyassar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: _theme.isDark ? const Color(0xFF161B22) : const Color(0xFFFAF8F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: _theme.accent.withValues(alpha: 0.5), width: 1.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _theme.accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with Ayah Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _theme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.auto_stories_rounded, color: _theme.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سُورَةُ ${ayah.surahName}',
                                  style: TextStyle(
                                    color: _theme.isDark ? _theme.text : _theme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'الآية رقم ${toArabicDigits(ayah.numberInSurah)} • ${ayah.juz == 0 ? "" : "الجزء " + toArabicDigits(ayah.juz)}',
                                  style: TextStyle(
                                    color: _theme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: _theme.text.withValues(alpha: 0.6), size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tafsir Edition Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: kTafsirEditions.map((edition) {
                        final isSel = edition.id == currentEdition;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (!isSel) {
                                HapticFeedback.selectionClick();
                                setModalState(() => currentEdition = edition.id);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? _theme.primary.withValues(alpha: 0.18) : (_theme.isDark ? const Color(0xFF21262D) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? _theme.accent : _theme.primary.withValues(alpha: 0.25),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (edition.isOffline)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.offline_pin_rounded,
                                        size: 13,
                                        color: isSel ? (_theme.isDark ? _theme.accent : _theme.primary) : const Color(0xFF4ECCA3),
                                      ),
                                    ),
                                  Text(
                                    edition.name,
                                    style: TextStyle(
                                      color: isSel ? (_theme.isDark ? _theme.accent : _theme.primary) : _theme.text.withValues(alpha: 0.65),
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Ayah Text Box
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _theme.isDark ? const Color(0xFF0D1117) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _theme.primary.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '« ${ayah.text} »',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: _theme.text,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                height: 2.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Live Tafsir FutureBuilder
                          FutureBuilder<String?>(
                            future: TafsirService.instance.getAyahTafsir(
                              surahNumber: ayah.surahNumber,
                              ayahNumber: ayah.numberInSurah,
                              edition: currentEdition,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 36),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: _theme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'جارٍ تحميل التفسير...',
                                        style: TextStyle(color: _theme.text.withValues(alpha: 0.6), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final tafsirText = snapshot.data;
                              if (tafsirText == null || tafsirText.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.wifi_off_rounded, color: _theme.text.withValues(alpha: 0.5), size: 28),
                                      const SizedBox(height: 8),
                                      Text(
                                        'تعذر جلب التفسير حالياً',
                                        style: TextStyle(color: _theme.text, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'يرجى التأكد من اتصال الإنترنت والمحاولة ثانيةً',
                                        style: TextStyle(color: _theme.text.withValues(alpha: 0.6), fontSize: 11),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () => setModalState(() {}),
                                        icon: Icon(Icons.refresh_rounded, size: 16, color: _theme.primary),
                                        label: Text('إعادة المحاولة', style: TextStyle(color: _theme.primary, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4ECCA3).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF4ECCA3).withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.offline_pin_rounded, color: Color(0xFF4ECCA3), size: 12),
                                            SizedBox(width: 4),
                                            Text(
                                              'تفسير مدمج (بدون إنترنت)',
                                              style: TextStyle(color: Color(0xFF4ECCA3), fontSize: 10.5, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tafsirText,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      color: _theme.text,
                                      fontSize: 14.5,
                                      height: 1.85,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      final copyText = '﴿${ayah.text}﴾\n\nتفسير الآية:\n$tafsirText\n[سورة ${ayah.surahName}: ${ayah.numberInSurah}]';
                                      Clipboard.setData(ClipboardData(text: copyText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم نسخ الآية والتفسير بنجاح'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _theme.primary,
                                      side: BorderSide(color: _theme.accent.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    label: const Text('نسخ الآية والتفسير', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Quick Jump Dialog (الانتقال السريع للصفحات والسور) ─────────────────────
  void _showJumpDialog() {
    HapticFeedback.selectionClick();
    int selectedPage = _currentPageIndex + 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: _theme.isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: _theme.accent.withValues(alpha: 0.5), width: 1.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _theme.accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الانتقال إلى صفحة بالمصحف',
                        style: TextStyle(
                          color: _theme.isDark ? _theme.text : _theme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _theme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'صفحة ${toArabicDigits(selectedPage)} من ٦٠٤',
                          style: TextStyle(
                            color: _theme.isDark ? _theme.accent : _theme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _theme.primary,
                      inactiveTrackColor: _theme.primary.withValues(alpha: 0.18),
                      thumbColor: _theme.accent,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: selectedPage.toDouble(),
                      min: 1,
                      max: 604,
                      divisions: 603,
                      onChanged: (val) {
                        setSheetState(() => selectedPage = val.round());
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quick Jump Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _quickJumpChip('بداية المصحف (١)', 1, setSheetState, (p) => selectedPage = p),
                      _quickJumpChip('الجزء ١٥ (٢٨٢)', 282, setSheetState, (p) => selectedPage = p),
                      _quickJumpChip('سورة طه (٣١٢)', 312, setSheetState, (p) => selectedPage = p),
                      _quickJumpChip('جزء عم (٥٨٢)', 582, setSheetState, (p) => selectedPage = p),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _jumpToPage(selectedPage);
                      },
                      child: const Text('انتقال الآن', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickJumpChip(String label, int page, StateSetter setSheetState, ValueChanged<int> onSelect) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setSheetState(() => onSelect(page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _theme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _theme.accent.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Text(
          label,
          style: TextStyle(color: _theme.isDark ? _theme.text : _theme.primary, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Index Modal (فهرس السور والأجزاء) ───────────────────────────────────────
  void _showIndexModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: BoxDecoration(
              color: _theme.isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: _theme.accent.withValues(alpha: 0.5), width: 1.2)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _theme.accent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                TabBar(
                  labelColor: _theme.isDark ? _theme.accent : _theme.primary,
                  unselectedLabelColor: _theme.text.withValues(alpha: 0.5),
                  indicatorColor: _theme.accent,
                  indicatorWeight: 2.5,
                  tabs: const [
                    Tab(text: 'السور (١١٤)'),
                    Tab(text: 'الأجزاء (٣٠)'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Surahs List
                      ListView.builder(
                        itemCount: (widget.allSurahs?.length ?? 0) > 0 ? widget.allSurahs!.length : 114,
                        itemBuilder: (_, i) {
                          final surah = (widget.allSurahs != null && i < widget.allSurahs!.length)
                              ? widget.allSurahs![i]
                              : null;
                          final sNum = surah != null ? (surah['number'] as int) : (i + 1);
                          final sName = surah != null ? (surah['name'] as String) : 'سورة $sNum';
                          final ayahs = surah != null ? (surah['ayahs'] as List?) : null;
                          final startPage = (ayahs != null && ayahs.isNotEmpty) ? (ayahs.first['page'] as int) : 1;

                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _theme.primary.withValues(alpha: 0.12),
                                border: Border.all(color: _theme.accent.withValues(alpha: 0.6)),
                              ),
                              child: Center(
                                child: Text(
                                  toArabicDigits(sNum),
                                  style: TextStyle(color: _theme.isDark ? _theme.accent : _theme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            title: Text(
                              sName,
                              style: TextStyle(color: _theme.text, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            trailing: Text(
                              'صفحة ${toArabicDigits(startPage)}',
                              style: TextStyle(color: _theme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _jumpToPage(startPage);
                            },
                          );
                        },
                      ),

                      // Ajza List
                      ListView.builder(
                        itemCount: kQuranAjza.length,
                        itemBuilder: (_, i) {
                          final juz = kQuranAjza[i];
                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _theme.accent.withValues(alpha: 0.15),
                                border: Border.all(color: _theme.accent),
                              ),
                              child: Center(
                                child: Text(
                                  toArabicDigits(juz.number),
                                  style: TextStyle(color: _theme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            title: Text(
                              juz.name,
                              style: TextStyle(color: _theme.text, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${juz.surahName} • آية ${toArabicDigits(juz.startAyah)}',
                              style: TextStyle(color: _theme.text.withValues(alpha: 0.6), fontSize: 11),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              // Match juz page
                              final matchPage = _pages.firstWhere(
                                (p) => p.juzNumber == juz.number,
                                orElse: () => _pages.first,
                              );
                              _jumpToPage(matchPage.pageNumber);
                            },
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
      },
    );
  }

  // ── Theme Selector Bottom Sheet ────────────────────────────────────────────
  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _theme.isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _theme.accent.withValues(alpha: 0.5), width: 1.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لون وهيئة المصحف',
                textAlign: TextAlign.center,
                style: TextStyle(color: _theme.text, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_kMushafThemes.length, (i) {
                  final t = _kMushafThemes[i];
                  final isSel = i == _themeIndex;
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _themeIndex = i);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('mushaf_theme_index', i);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: t.bg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? t.accent : t.primary.withValues(alpha: 0.3),
                              width: isSel ? 2.5 : 1,
                            ),
                            boxShadow: isSel
                                ? [BoxShadow(color: t.accent.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)]
                                : [],
                          ),
                          child: isSel ? Icon(Icons.check_rounded, color: t.primary, size: 20) : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.name,
                          style: TextStyle(
                            color: isSel ? _theme.accent : _theme.text.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('حجم الخط', style: TextStyle(color: _theme.text, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(toArabicDigits(_fontSize.round()), style: TextStyle(color: _theme.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 15.0,
                max: 30.0,
                activeColor: _theme.primary,
                inactiveColor: _theme.primary.withValues(alpha: 0.2),
                onChanged: (val) async {
                  setState(() => _fontSize = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('mushaf_font_size', val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _theme.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _theme.primary, strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                'جارٍ فتح المصحف الشريف...',
                style: TextStyle(color: _theme.primary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final isBookmarked = _currentPage != null && _bookmarkedPage == _currentPage!.pageNumber;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _theme.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: _theme.bg,
          systemNavigationBarIconBrightness: _theme.isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _theme.bg,
          appBar: _showControls
              ? AppBar(
                  backgroundColor: _theme.bg,
                  elevation: 0,
                  iconTheme: IconThemeData(color: _theme.primary),
                  title: Text(
                    _currentPage != null ? 'سُورَةُ ${_currentPage!.primarySurahName}' : 'المصحف الشريف',
                    style: TextStyle(color: _theme.isDark ? _theme.text : _theme.primary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.zoom_out_rounded, color: _theme.primary, size: 21),
                      tooltip: 'تصغير الخط',
                      onPressed: _zoomOut,
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_in_rounded, color: _theme.primary, size: 21),
                      tooltip: 'تكبير الخط',
                      onPressed: _zoomIn,
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isBookmarked ? _theme.accent : _theme.primary,
                        size: 20,
                      ),
                      tooltip: isBookmarked ? 'إزالة الفاصل' : 'حفظ موضع القراءة',
                      onPressed: _toggleBookmark,
                    ),
                    IconButton(
                      icon: Icon(Icons.palette_outlined, color: _theme.primary, size: 20),
                      tooltip: 'تغيير هيئة وثيم المصحف',
                      onPressed: _showThemeSelector,
                    ),
                  ],
                )
              : null,
          body: Stack(
            children: [
              GestureDetector(
                onDoubleTap: () => setState(() => _showControls = !_showControls),
                onScaleStart: (details) {
                  if (details.pointerCount >= 2) {
                    _pinchBaseFontSize = _fontSize;
                  }
                },
                onScaleUpdate: (details) {
                  if (details.pointerCount >= 2) {
                    final newSize = (_pinchBaseFontSize * details.scale).clamp(14.0, 36.0);
                    setState(() => _fontSize = newSize);
                    _triggerZoomHud();
                  }
                },
                onScaleEnd: (details) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('mushaf_font_size', _fontSize);
                },
                child: PageView.builder(
                  controller: _pageCtrl,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return MushafPageWidget(
                      page: page,
                      fontSize: _fontSize,
                      textColor: _theme.text,
                      primaryColor: _theme.primary,
                      accentColor: _theme.accent,
                      bgColor: _theme.bg,
                      isDark: _theme.isDark,
                      onAyahTap: _showAyahTafsir,
                      onSearchTap: _showJumpDialog,
                      onIndexTap: _showIndexModal,
                      onPageNumberTap: _showJumpDialog,
                    );
                  },
                ),
              ),

              // Floating Bottom Zoom Controller
              _buildFloatingZoomBar(),

              // Temporary Zoom Level Toast/HUD
              _buildZoomHud(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingZoomBar() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _theme.isDark
                    ? const Color(0xFF161E2E).withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _theme.accent.withValues(alpha: 0.45),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_rounded, color: _theme.primary, size: 20),
                    tooltip: 'تصغير الخط',
                    onPressed: _zoomOut,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_size_rounded, size: 14, color: _theme.accent),
                        const SizedBox(width: 4),
                        Text(
                          toArabicDigits(_fontSize.round()),
                          style: TextStyle(
                            color: _theme.isDark ? _theme.accent : _theme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: _theme.primary, size: 20),
                    tooltip: 'تكبير الخط',
                    onPressed: _zoomIn,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  if ((_fontSize - 20.0).abs() > 0.5) ...[
                    Container(
                      width: 1,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: _theme.primary.withValues(alpha: 0.2),
                    ),
                    IconButton(
                      icon: Icon(Icons.restart_alt_rounded, color: _theme.accent, size: 18),
                      tooltip: 'الحجم الافتراضي',
                      onPressed: _resetZoom,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomHud() {
    if (!_showZoomHud) return const SizedBox.shrink();
    return Positioned(
      top: 90,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _theme.accent.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.format_size_rounded, color: _theme.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                'حجم الخط: ${toArabicDigits(_fontSize.round())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
