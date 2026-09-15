import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/guide/data/models/dua_model.dart';
import 'package:rafiki_app/features/guide/data/datasources/adeia_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Adeia – الأدعية والأذكار (Max-Level Royal Islamic UI)
// ─────────────────────────────────────────────────────────────────────────────

class AdeiaPage extends StatefulWidget {
  const AdeiaPage({super.key});

  @override
  State<AdeiaPage> createState() => _AdeiaPageState();
}

class _AdeiaPageState extends State<AdeiaPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entryCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  // ── Design Tokens ──────────────────────────────────────────────────────────
  static const Color _bgDeep = Color(0xFF020A12);
  static const Color _bgMid = Color(0xFF071829);
  static const Color _cardBg = Color(0xFF0C1F33);
  static const Color _cardHigh = Color(0xFF142C48);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldGlow = Color(0xFFF7DE8A);
  static const Color _goldDark = Color(0xFF8B6914);
  static const Color _textMain = Color(0xFFF5F0E1);
  static const Color _textSub = Color(0xFF8DA3B8);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  int _selectedCategory = 0;

  // Filter mode: 0 = all/selected category, 1 = favorites, 2 = repeated (tasbeeh), 3 = featured
  int _filterMode = 0;

  // Font size scale: 0 = normal (17), 1 = large (20), 2 = extra large (23)
  int _fontSizeLevel = 0;
  double get _currentFontSize {
    switch (_fontSizeLevel) {
      case 1:
        return 20.0;
      case 2:
        return 23.0;
      default:
        return 17.0;
    }
  }

  Set<String> _favorites = {};
  // In-memory counter for tasbeeh on each dua: duaId -> count
  final Map<String, int> _counts = {};

  late final List<_StarDot> _stars;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final rng = Random(88);
    _stars = List.generate(
      42,
      (_) => _StarDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: 0.5 + rng.nextDouble() * 1.3,
        opacity: 0.08 + rng.nextDouble() * 0.22,
      ),
    );

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList("adeia_favorites_v1") ?? [];
      if (mounted) {
        setState(() {
          _favorites = favList.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String id) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("adeia_favorites_v1", _favorites.toList());
    } catch (_) {}
  }

  void _incrementCount(DuaData dua) {
    final current = _counts[dua.id] ?? 0;
    if (current < dua.repeat) {
      final next = current + 1;
      _counts[dua.id] = next;
      if (next == dua.repeat) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      setState(() {});
    } else {
      // If already finished, reset
      HapticFeedback.mediumImpact();
      setState(() {
        _counts[dua.id] = 0;
      });
    }
  }

  void _resetCount(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _counts[id] = 0;
    });
  }

  void _toggleFontSize() {
    HapticFeedback.selectionClick();
    setState(() {
      _fontSizeLevel = (_fontSizeLevel + 1) % 3;
    });
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

  List<DuaData> get _filtered {
    List<DuaData> list = allDuas;

    // Filter mode
    if (_filterMode == 1) {
      list = list.where((d) => _favorites.contains(d.id)).toList();
    } else if (_filterMode == 2) {
      list = list.where((d) => d.repeat > 1).toList();
    } else if (_filterMode == 3) {
      list = list.where((d) => d.isFeatured).toList();
    } else {
      // Category filter
      if (_selectedCategory > 0 && _selectedCategory < duaCategories.length) {
        final label = duaCategories[_selectedCategory].label;
        list = list.where((d) => d.category == label).toList();
      }
    }

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.dua.toLowerCase().contains(q) ||
            d.fadl.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q) ||
            d.when.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgDeep,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Hero Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                      child: _buildHeader(filtered.length),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildSearchBar(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Quick Filter Mode Tabs
                  SliverToBoxAdapter(
                    child: _buildFilterTabs(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Category Chips (visible when in mode 0)
                  if (_filterMode == 0)
                    SliverToBoxAdapter(
                      child: _buildCategoryRow(),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // Dua list or empty
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final dua = filtered[i];
                            final isFav = _favorites.contains(dua.id);
                            final currentCount = _counts[dua.id] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _DuaCard(
                                dua: dua,
                                isFavorite: isFav,
                                currentCount: currentCount,
                                fontSize: _currentFontSize,
                                onToggleFavorite: () => _toggleFavorite(dua.id),
                                onIncrementCount: () => _incrementCount(dua),
                                onResetCount: () => _resetCount(dua.id),
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
            color: _cardHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: _gold, size: 18),
            onPressed: () => Navigator.pop(context),
            tooltip: "رجوع",
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [_goldDark, _goldGlow, _gold, _goldGlow],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(r),
        child: const Text(
          "الأدعية والأذكار",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        // Font Size Adjuster Button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: _cardHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.format_size_rounded, color: _goldGlow, size: 20),
            tooltip: "تغيير حجم الخط",
            onPressed: _toggleFontSize,
          ),
        ),
        // Favorites Shortcut
        Container(
          margin: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _cardHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _filterMode == 1 ? _gold : _gold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              _filterMode == 1 ? Icons.star_rounded : Icons.star_border_rounded,
              color: _filterMode == 1 ? _gold : _textSub,
              size: 22,
            ),
            tooltip: "المفضلة",
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _filterMode = _filterMode == 1 ? 0 : 1;
              });
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Background
  // ─────────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    0.3 - _bgCtrl.value * 0.5,
                    -0.4 + _bgCtrl.value * 0.3,
                  ),
                  radius: 1.6,
                  colors: const [Color(0xFF0A1F32), Color(0xFF040E1B), _bgDeep],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _StaticStarPainter(_stars))),
          Positioned(
            top: -20,
            right: -30,
            child: _CrescentWidget(
              color: _gold.withValues(alpha: 0.06),
              bgColor: _bgDeep,
              size: 240,
            ),
          ),
          Positioned(
            top: 130,
            left: -80,
            child: _GlowBlob(
              color: const Color(0xFF0D5C61).withValues(alpha: 0.12),
              size: 300,
            ),
          ),
          Positioned(
            bottom: 120,
            right: -70,
            child: _GlowBlob(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              size: 260,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Top Header Card
  // ─────────────────────────────────────────────
  Widget _buildHeader(int count) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _goldDark.withValues(alpha: 0.24),
                _bgMid.withValues(alpha: 0.50),
                _cardBg.withValues(alpha: 0.70),
              ],
            ),
            border: Border.all(color: _gold.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_goldDark, _gold, _goldGlow]),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.25 + 0.2 * _pulseCtrl.value),
                        blurRadius: 14 + 8 * _pulseCtrl.value,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Center(
                  child: Text("📿", style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "حصن المسلم والذكر المبارك",
                      style: TextStyle(
                        color: _textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "يحتوي على $count دعاء وذكر • مع عداد تسبيح تفاعلي",
                      style: const TextStyle(color: _textSub, fontSize: 11.5),
                    ),
                  ],
                ),
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
        color: _cardBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2), width: 1),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _textMain, fontSize: 14),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "ابحث في الأدعية، الأذكار، أو الفضل...",
          hintStyle: const TextStyle(color: _textSub, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _gold, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _textSub, size: 18),
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
  //  Filter Tabs (الكل / المفضلة / المكررة / المميزة)
  // ─────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final repeatedCount = allDuas.where((d) => d.repeat > 1).length;
    final featuredCount = allDuas.where((d) => d.isFeatured).length;

    final tabs = [
      {"label": "الجميع", "mode": 0, "count": allDuas.length, "icon": Icons.auto_awesome_rounded},
      {"label": "المفضلة", "mode": 1, "count": _favorites.length, "icon": Icons.star_rounded},
      {"label": "الأذكار المكررة", "mode": 2, "count": repeatedCount, "icon": Icons.repeat_rounded},
      {"label": "المختارة", "mode": 3, "count": featuredCount, "icon": Icons.verified_rounded},
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
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? _gold.withValues(alpha: 0.18)
                      : _cardBg.withValues(alpha: 0.4),
                  border: Border.all(
                    color: isSelected ? _gold : _gold.withValues(alpha: 0.12),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t["icon"] as IconData,
                      size: 13,
                      color: isSelected ? _goldGlow : _textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${t["label"]} (${t["count"]})",
                      style: TextStyle(
                        color: isSelected ? _goldGlow : _textSub,
                        fontSize: 11,
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
  //  Category Selector Chips
  // ─────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: duaCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = duaCategories[i];
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: selected
                    ? const LinearGradient(colors: [_goldDark, _gold])
                    : null,
                color: selected ? null : _cardBg.withValues(alpha: 0.6),
                border: Border.all(
                  color: selected
                      ? _goldGlow.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: selected
                    ? [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 12)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 13,
                    color: selected ? Colors.black87 : _textSub,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: selected ? Colors.black87 : _textSub,
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
              color: _cardHigh,
              border: Border.all(color: _gold.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.search_off_rounded, color: _gold, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد أدعية مطابقة",
            style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "جرّب البحث بكلمات أخرى أو اختر تصنيفاً مختلفاً",
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSub, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchCtrl.clear();
                _searchQuery = "";
                _selectedCategory = 0;
                _filterMode = 0;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: _gold, size: 18),
            label: const Text(
              "عرض جميع الأدعية",
              style: TextStyle(color: _goldGlow, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DuaCard with Interactive Tasbeeh Counter & Fast Actions
// ─────────────────────────────────────────────────────────────────────────────

class _DuaCard extends StatefulWidget {
  final DuaData dua;
  final bool isFavorite;
  final int currentCount;
  final double fontSize;
  final VoidCallback onToggleFavorite;
  final VoidCallback onIncrementCount;
  final VoidCallback onResetCount;

  const _DuaCard({
    required this.dua,
    required this.isFavorite,
    required this.currentCount,
    required this.fontSize,
    required this.onToggleFavorite,
    required this.onIncrementCount,
    required this.onResetCount,
  });

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _copied = false;

  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final d = widget.dua;
    final text = "📿 ${d.title}\n\n${d.dua}\n\n✦ الفضل: ${d.fadl}\n📚 ${d.source}";
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _share() async {
    final d = widget.dua;
    final text =
        "📿 ${d.title} 📿\n\n${d.dua}\n\n✦ الفضل: ${d.fadl}\n📚 المصدر: ${d.source}\n\n«الدال على الخير كفاعله» 🌿";
    try {
      await Share.share(text, subject: d.title);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "تم نسخ الدعاء مع التفاصيل ✓",
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: const Color(0xFF1A5C30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    final isDone = widget.currentCount >= d.repeat && d.repeat > 0;
    final hasMultipleRepeats = d.repeat > 1;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          setState(() => _expanded = !_expanded);
          HapticFeedback.selectionClick();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    d.accentA.withValues(alpha: _expanded ? 0.35 : 0.20),
                    Colors.white.withValues(alpha: 0.03),
                    d.accentB.withValues(alpha: isDone ? 0.20 : 0.08),
                  ],
                  stops: const [0, 0.5, 1],
                ),
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : d.accentB.withValues(alpha: _expanded ? 0.45 : 0.24),
                  width: isDone ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.accentA.withValues(alpha: _expanded ? 0.30 : 0.14),
                    blurRadius: _expanded ? 32 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shimmer top line
                  Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: isDone
                            ? [Colors.transparent, const Color(0xFF10B981), Colors.transparent]
                            : [
                                Colors.transparent,
                                d.accentB.withValues(alpha: 0.65),
                                d.accentB.withValues(alpha: 0.90),
                                d.accentB.withValues(alpha: 0.50),
                                Colors.transparent,
                              ],
                        stops: const [0, 0.2, 0.5, 0.8, 1],
                      ),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        // Icon with Glow
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [d.accentA, d.accentB],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: d.accentB.withValues(alpha: 0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(d.icon, color: Colors.white, size: 22),
                            ),
                            if (d.isFeatured)
                              Positioned(
                                top: -2,
                                left: -2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF8B6914), Color(0xFFF5D882)],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.black87,
                                    size: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Title, Category & Timing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: d.accentB.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      d.category,
                                      style: TextStyle(
                                        color: d.accentB,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (d.repeat > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: isDone
                                            ? Border.all(color: const Color(0xFF10B981), width: 0.8)
                                            : null,
                                      ),
                                      child: Text(
                                        isDone ? "مكتمل ✓" : "× ${d.repeat}",
                                        style: TextStyle(
                                          color: isDone
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF7A9AAD),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                d.title,
                                style: const TextStyle(
                                  color: Color(0xFFEEE8D5),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                d.when,
                                style: TextStyle(
                                  color: d.accentB.withValues(alpha: 0.75),
                                  fontSize: 10.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Favorite Toggle
                        IconButton(
                          icon: Icon(
                            widget.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: widget.isFavorite ? const Color(0xFFD4AF37) : const Color(0xFF7A9AAD),
                            size: 22,
                          ),
                          onPressed: widget.onToggleFavorite,
                          tooltip: "المفضلة",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),

                        // Expand/Collapse Chevron
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: d.accentB.withValues(alpha: 0.12),
                              border: Border.all(color: d.accentB.withValues(alpha: 0.25)),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: d.accentB,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dua Preview snippet (if collapsed)
                  if (!_expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: d.accentB.withValues(alpha: 0.12)),
                        ),
                        child: Text(
                          d.dua,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFE2D8C0),
                            fontSize: widget.fontSize * 0.75,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),

                  // Interactive Tasbeeh Strip (Always accessible!)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        // Tap-to-count button
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onIncrementCount,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isDone
                                      ? [const Color(0xFF065F46), const Color(0xFF10B981)]
                                      : [d.accentA.withValues(alpha: 0.5), d.accentB.withValues(alpha: 0.35)],
                                ),
                                border: Border.all(
                                  color: isDone
                                      ? const Color(0xFF10B981)
                                      : d.accentB.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.touch_app_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDone
                                        ? "أتممت الذكر (اضغط لإعادة البدء)"
                                        : (hasMultipleRepeats
                                            ? "تسبيح: ${widget.currentCount} / ${d.repeat}"
                                            : "قرأتُ هذا الدعاء ✓"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Reset button if count > 0
                        if (widget.currentCount > 0) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onResetCount,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF8DA3B8),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expanded Details Body
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeOutCubic,
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  d.accentB.withValues(alpha: 0.28),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dua text in decorative frame
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(color: d.accentB.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                                  style: TextStyle(
                                    color: d.accentB.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  d.dua,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    color: const Color(0xFFF7F2E4),
                                    fontSize: widget.fontSize,
                                    height: 2.1,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Details Section (الفضل - المصدر - الوقت)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.auto_awesome_rounded,
                                label: "الفضل",
                                value: d.fadl,
                                accentB: d.accentB,
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.menu_book_rounded,
                                label: "المصدر",
                                value: d.source,
                                accentB: d.accentB,
                              ),
                              if (d.repeat > 1) ...[
                                const SizedBox(height: 8),
                                _DetailRow(
                                  icon: Icons.repeat_rounded,
                                  label: "التكرار",
                                  value: "${d.repeat} مرة",
                                  accentB: d.accentB,
                                ),
                              ],
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.schedule_rounded,
                                label: "الوقت",
                                value: d.when,
                                accentB: d.accentB,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action buttons (Copy & Native Share)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          child: Row(
                            children: [
                              // Copy button
                              Expanded(
                                child: GestureDetector(
                                  onTap: _copy,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: _copied
                                            ? [const Color(0xFF1A5C30), const Color(0xFF2ECC71)]
                                            : [
                                                d.accentA.withValues(alpha: 0.55),
                                                d.accentB.withValues(alpha: 0.40),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: _copied
                                            ? const Color(0xFF2ECC71).withValues(alpha: 0.6)
                                            : d.accentB.withValues(alpha: 0.40),
                                      ),
                                      boxShadow: _copied
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF2ECC71).withValues(alpha: 0.30),
                                                blurRadius: 16,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _copied ? "تم النسخ بنجاح ✓" : "نسخ الدعاء والتفاصيل",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Share button
                              GestureDetector(
                                onTap: _share,
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withValues(alpha: 0.08),
                                    border: Border.all(color: d.accentB.withValues(alpha: 0.30)),
                                  ),
                                  child: Icon(Icons.share_rounded, color: d.accentB, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _DetailRow Widget
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentB;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: accentB.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentB, size: 16),
          const SizedBox(width: 9),
          Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              color: accentB.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(
                      color: accentB,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFFB5CDE0),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers: Crescent, GlowBlob, Stars
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 0.7)],
        ),
      );
}

class _CrescentWidget extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final double size;
  const _CrescentWidget({required this.color, required this.bgColor, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CrescentPainter(color, bgColor)),
      );
}

class _CrescentPainter extends CustomPainter {
  final Color color;
  final Color bgColor;
  const _CrescentPainter(this.color, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.width * 0.44;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      Offset(c.dx + r * 0.32, c.dy - r * 0.08),
      r * 0.80,
      Paint()..color = bgColor,
    );
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => old.color != color || old.bgColor != bgColor;
}

class _StarDot {
  final double x, y, r, opacity;
  const _StarDot({required this.x, required this.y, required this.r, required this.opacity});
}

class _StaticStarPainter extends CustomPainter {
  final List<_StarDot> stars;
  const _StaticStarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: s.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StaticStarPainter old) => false;
}