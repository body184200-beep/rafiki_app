import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/guide/data/models/sunnah_model.dart';
import 'package:rafiki_app/features/guide/data/datasources/sunnah_data.dart';

// ─────────────────────────────────────────────────────────────
//  Palette & Tokens
// ─────────────────────────────────────────────────────────────
class _P {
  static const bg0 = Color(0xFF060B14);
  static const bg1 = Color(0xFF0C182B);
  static const bg2 = Color(0xFF12223D);
  static const card = Color(0xFF121F35);
  static const cardHigh = Color(0xFF192B4A);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF7DE8A);
  static const goldDim = Color(0xFF8B6B1E);
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF065F46);
  static const textPrimary = Color(0xFFF8F5EE);
  static const textSecondary = Color(0xFFA5B2C3);
  static const textMuted = Color(0xFF728096);
}

// ─────────────────────────────────────────────────────────────
//  Main Sunnah Page Widget
// ─────────────────────────────────────────────────────────────
class SunnahPage extends StatefulWidget {
  const SunnahPage({super.key});

  @override
  State<SunnahPage> createState() => _SunnahPageState();
}

class _SunnahPageState extends State<SunnahPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entryCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;

  // Filter mode: 0 = all/selected category, 1 = completed today, 2 = favorites
  int _filterMode = 0;

  Set<String> _completedToday = {};
  Set<String> _favorites = {};
  bool _isLoadingPrefs = true;

  late final List<_StarParticle> _stars;

  String get _todayKey {
    final now = DateTime.now();
    return "sunan_done_${now.year}_${now.month}_${now.day}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final rng = Random(42);
    _stars = List.generate(
      36,
      (_) => _StarParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.5 + rng.nextDouble() * 1.5,
        opacity: 0.08 + rng.nextDouble() * 0.25,
      ),
    );

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedList = prefs.getStringList(_todayKey) ?? [];
      final favList = prefs.getStringList("sunan_favorites_v1") ?? [];
      if (mounted) {
        setState(() {
          _completedToday = completedList.toSet();
          _favorites = favList.toSet();
          _isLoadingPrefs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPrefs = false);
      }
    }
  }

  Future<void> _toggleCompleted(String sunnahId) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_completedToday.contains(sunnahId)) {
        _completedToday.remove(sunnahId);
      } else {
        _completedToday.add(sunnahId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_todayKey, _completedToday.toList());
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String sunnahId) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(sunnahId)) {
        _favorites.remove(sunnahId);
      } else {
        _favorites.add(sunnahId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("sunan_favorites_v1", _favorites.toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _bgCtrl.stop();
      _pulseCtrl.stop();
    }
  }

  List<SunnahItem> get _filteredSunan {
    List<SunnahItem> list = allSunan;

    // Quick filter modes
    if (_filterMode == 1) {
      list = list.where((s) => _completedToday.contains(s.id)).toList();
    } else if (_filterMode == 2) {
      list = list.where((s) => _favorites.contains(s.id)).toList();
    } else {
      // Category filter
      if (_selectedCategoryIndex > 0 &&
          _selectedCategoryIndex < sunnahCategories.length) {
        final cat = sunnahCategories[_selectedCategoryIndex].label;
        list = list.where((s) => s.category == cat).toList();
      }
    }

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.hadith.toLowerCase().contains(q) ||
            s.fadl.toLowerCase().contains(q) ||
            s.practicalTip.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSunan;
    final totalCount = allSunan.length;
    final doneCount = _completedToday.length;
    final progress = totalCount > 0 ? (doneCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _P.bg0,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Card with Daily Tracker
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: _buildTrackerHeader(doneCount, totalCount, progress),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildSearchBar(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // Filter Modes (الكل - طبقتها اليوم - المفضلة)
                  SliverToBoxAdapter(
                    child: _buildFilterTabsRow(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Category selector (when in 'all' mode)
                  if (_filterMode == 0)
                    SliverToBoxAdapter(
                      child: _buildCategoryRow(),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // Items List or Empty State
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filtered[index];
                            final isDone = _completedToday.contains(item.id);
                            final isFav = _favorites.contains(item.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _SunnahCardWidget(
                                item: item,
                                index: index,
                                isDone: isDone,
                                isFav: isFav,
                                onToggleDone: () => _toggleCompleted(item.id),
                                onToggleFav: () => _toggleFavorite(item.id),
                                onTap: () => _openDetailsSheet(item),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  App Bar
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: _P.cardHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.gold.withValues(alpha: 0.25), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: _P.gold, size: 18),
            onPressed: () => Navigator.pop(context),
            tooltip: "رجوع",
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_P.goldDim, _P.goldLight, _P.gold, _P.goldLight],
        ).createShader(bounds),
        child: const Text(
          "السنن النبوية الشريفة",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _P.cardHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _filterMode == 2 ? _P.gold : _P.gold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              _filterMode == 2 ? Icons.star_rounded : Icons.star_border_rounded,
              color: _filterMode == 2 ? _P.gold : _P.textSecondary,
              size: 22,
            ),
            tooltip: "المفضلة",
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _filterMode = _filterMode == 2 ? 0 : 2;
              });
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Background Painting
  // ─────────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      0.3 - _bgCtrl.value * 0.6,
                      -0.5 + _bgCtrl.value * 0.4,
                    ),
                    radius: 1.5,
                    colors: const [
                      Color(0xFF0E223D),
                      Color(0xFF081424),
                      _P.bg0,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _StaticStarsPainter(_stars)),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _P.gold.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -50,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D5C61).withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Daily Tracker Header
  // ─────────────────────────────────────────────
  Widget _buildTrackerHeader(int done, int total, double progress) {
    final percent = (progress * 100).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _P.goldDim.withValues(alpha: 0.22),
                _P.cardHigh.withValues(alpha: 0.6),
                _P.bg1.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: _P.gold.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_P.goldDim, _P.gold, _P.goldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _P.gold.withValues(
                              alpha: 0.3 + 0.2 * _pulseCtrl.value,
                            ),
                            blurRadius: 12 + 6 * _pulseCtrl.value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.brightness_5_rounded,
                        color: Color(0xFF1B1300),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "«مَنْ أَحْيَا سُنَّتِي فَقَدْ أَحَبَّنِي»",
                          style: TextStyle(
                            color: _P.goldLight,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoadingPrefs
                              ? "جاري تحميل سجل السنن..."
                              : "طبّقت اليوم $done من أصل $total سنة مباركة",
                          style: const TextStyle(
                            color: _P.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _P.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _P.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      "$percent%",
                      style: const TextStyle(
                        color: _P.goldLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress > 0 ? progress : 0.01,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_P.goldDim, _P.gold, _P.goldLight],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: _P.gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Search Bar
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _P.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.gold.withValues(alpha: 0.2), width: 1),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _P.textPrimary, fontSize: 14),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "ابحث في السنن، الأحاديث، أو الفضل...",
          hintStyle: const TextStyle(color: _P.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _P.gold, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _P.textSecondary, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Filter Tabs Row (الكل / المطبقة / المفضلة)
  // ─────────────────────────────────────────────
  Widget _buildFilterTabsRow() {
    final completedCount = _completedToday.length;
    final favCount = _favorites.length;

    final tabs = [
      {"label": "جميع السنن", "mode": 0, "count": allSunan.length, "icon": Icons.view_agenda_rounded},
      {"label": "طبقتها اليوم", "mode": 1, "count": completedCount, "icon": Icons.check_circle_rounded},
      {"label": "المفضلة", "mode": 2, "count": favCount, "icon": Icons.star_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _filterMode == t["mode"];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filterMode = t["mode"] as int);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? _P.gold.withValues(alpha: 0.18)
                      : _P.card.withValues(alpha: 0.4),
                  border: Border.all(
                    color: isSelected
                        ? _P.gold
                        : _P.gold.withValues(alpha: 0.12),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t["icon"] as IconData,
                      size: 14,
                      color: isSelected ? _P.goldLight : _P.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${t["label"]} (${t["count"]})",
                      style: TextStyle(
                        color: isSelected ? _P.goldLight : _P.textSecondary,
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Category Row Chips
  // ─────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: sunnahCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = sunnahCategories[i];
          final selected = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: selected
                    ? const LinearGradient(colors: [_P.goldDim, _P.gold])
                    : null,
                color: selected ? null : _P.card.withValues(alpha: 0.6),
                border: Border.all(
                  color: selected
                      ? _P.goldLight.withValues(alpha: 0.6)
                      : _P.gold.withValues(alpha: 0.15),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _P.gold.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14,
                    color: selected ? const Color(0xFF1A1200) : _P.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF1A1200) : _P.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Empty State
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _P.cardHigh,
              border: Border.all(color: _P.gold.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: _P.gold,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد نتائج مطابقة",
            style: TextStyle(
              color: _P.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "جرّب البحث بكلمات أخرى أو تغيير التصنيف المختار",
            textAlign: TextAlign.center,
            style: TextStyle(color: _P.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchCtrl.clear();
                _searchQuery = "";
                _selectedCategoryIndex = 0;
                _filterMode = 0;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: _P.gold, size: 18),
            label: const Text(
              "عرض جميع السنن",
              style: TextStyle(color: _P.goldLight, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Bottom Sheet Details Modal
  // ─────────────────────────────────────────────
  void _openDetailsSheet(SunnahItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDone = _completedToday.contains(item.id);
            final isFav = _favorites.contains(item.id);

            return _SunnahBottomSheet(
              item: item,
              isDone: isDone,
              isFav: isFav,
              onToggleDone: () {
                _toggleCompleted(item.id);
                setSheetState(() {});
              },
              onToggleFav: () {
                _toggleFavorite(item.id);
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Sunnah Card Widget
// ─────────────────────────────────────────────────────────────
class _SunnahCardWidget extends StatefulWidget {
  final SunnahItem item;
  final int index;
  final bool isDone;
  final bool isFav;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleFav;
  final VoidCallback onTap;

  const _SunnahCardWidget({
    required this.item,
    required this.index,
    required this.isDone,
    required this.isFav,
    required this.onToggleDone,
    required this.onToggleFav,
    required this.onTap,
  });

  @override
  State<_SunnahCardWidget> createState() => _SunnahCardWidgetState();
}

class _SunnahCardWidgetState extends State<_SunnahCardWidget>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.accentA.withValues(alpha: widget.isDone ? 0.35 : 0.22),
                    _P.card.withValues(alpha: 0.85),
                    item.accentB.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: widget.isDone
                      ? _P.emerald.withValues(alpha: 0.55)
                      : _P.gold.withValues(alpha: 0.22),
                  width: widget.isDone ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Status Strip
                  Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDone
                            ? [_P.emerald, _P.emeraldDark, Colors.transparent]
                            : [item.accentA, item.accentB, Colors.transparent],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with Icon, Title, and Action Buttons
                        Row(
                          children: [
                            // Icon Box
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [item.accentA, item.accentB],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.accentB.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(item.icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            // Title & Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: _P.textPrimary,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        item.category,
                                        style: const TextStyle(
                                          color: _P.goldLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: _P.textMuted,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.badge,
                                        style: const TextStyle(
                                          color: _P.textSecondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Favorite button
                            IconButton(
                              icon: Icon(
                                widget.isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                color: widget.isFav ? _P.gold : _P.textMuted,
                                size: 22,
                              ),
                              onPressed: widget.onToggleFav,
                              tooltip: "حفظ في المفضلة",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),

                            // Quick "Done" Toggle Button
                            GestureDetector(
                              onTap: widget.onToggleDone,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: widget.isDone
                                      ? _P.emerald.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: widget.isDone
                                        ? _P.emerald
                                        : Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.isDone
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 15,
                                      color: widget.isDone ? _P.emerald : _P.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.isDone ? "طبقتها" : "تطبيق",
                                      style: TextStyle(
                                        color: widget.isDone ? _P.emerald : _P.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Description preview
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _P.textSecondary.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Hadith highlight box snippet
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _P.gold.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                color: _P.gold,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.hadith,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _P.goldLight,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _P.gold,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────
//  Detailed Bottom Sheet Modal
// ─────────────────────────────────────────────────────────────
class _SunnahBottomSheet extends StatelessWidget {
  final SunnahItem item;
  final bool isDone;
  final bool isFav;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleFav;

  const _SunnahBottomSheet({
    required this.item,
    required this.isDone,
    required this.isFav,
    required this.onToggleDone,
    required this.onToggleFav,
  });

  Future<void> _copy(BuildContext context) async {
    final text =
        "✨ ${item.title} ✨\n\n📖 الحديث الشريف:\n${item.hadith}\n\n✦ الفضل والأجر:\n${item.fadl}\n\n📚 التخريج: ${item.source}\n💡 تطبيق عملي: ${item.practicalTip}\n\n(من تطبيق رفيقي 🌿)";
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "تم نسخ تفاصيل السنة والحديث إلى الحافظة ✓",
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF135A3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _share() async {
    final text =
        "✨ ${item.title} ✨\n\n📖 قال رسول الله ﷺ:\n${item.hadith}\n\n✦ فضلها:\n${item.fadl}\n\n📚 المصدر: ${item.source}\n💡 كيف تطبقها: ${item.practicalTip}\n\n«الدال على الخير كفاعله» 🌿";
    try {
      await Share.share(text, subject: item.title);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: _P.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
              decoration: BoxDecoration(
                color: _P.card.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: _P.gold.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _P.gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Top Action Icons (Close / Share / Copy / Favorite)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _P.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                color: isFav ? _P.gold : _P.textSecondary,
                              ),
                              tooltip: "المفضلة",
                              onPressed: onToggleFav,
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: _P.goldLight, size: 20),
                              tooltip: "نسخ الحديث",
                              onPressed: () => _copy(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: _P.gold, size: 20),
                              tooltip: "مشاركة",
                              onPressed: _share,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Icon & Title
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [item.accentA, item.accentB],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.accentB.withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _P.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category & Badge Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _P.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _P.gold.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: _P.goldLight,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.badge,
                            style: const TextStyle(
                              color: _P.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Hadith Box with Islamic Border
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _P.bg2.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _P.gold.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.menu_book_rounded, color: _P.gold, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "نص الحديث الشريف",
                                style: TextStyle(
                                  color: _P.goldLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.hadith,
                            style: const TextStyle(
                              color: _P.textPrimary,
                              fontSize: 15.5,
                              height: 1.75,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                item.source,
                                style: const TextStyle(
                                  color: _P.goldDim,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Virtue / Fadl Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _P.cardHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _P.emerald.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome_rounded, color: _P.emerald, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "فضل هذه السنة وثوابها",
                                style: TextStyle(
                                  color: _P.emerald,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.fadl,
                            style: const TextStyle(
                              color: _P.textPrimary,
                              fontSize: 13.5,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Practical Tip Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _P.cardHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _P.gold.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb_rounded, color: _P.gold, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "كيف تطبقها في يومك؟",
                                style: TextStyle(
                                  color: _P.goldLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.practicalTip,
                            style: const TextStyle(
                              color: _P.textSecondary,
                              fontSize: 13.5,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Big "Completed Today" Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDone ? _P.emerald : _P.goldDim,
                          foregroundColor: isDone ? Colors.white : _P.bg0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          onToggleDone();
                        },
                        icon: Icon(
                          isDone ? Icons.check_circle_rounded : Icons.check_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isDone
                              ? "تم تطبيق هذه السنة اليوم ✓ (إلغاء)"
                              : "طبّقتُ هذه السنة اليوم ✨",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Background Star Particle & Painter
// ─────────────────────────────────────────────────────────────
class _StarParticle {
  final double x;
  final double y;
  final double radius;
  final double opacity;

  const _StarParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

class _StaticStarsPainter extends CustomPainter {
  final List<_StarParticle> stars;

  _StaticStarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in stars) {
      paint.color = _P.goldLight.withValues(alpha: s.opacity);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StaticStarsPainter oldDelegate) => false;
}