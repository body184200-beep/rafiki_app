import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rafiki_app/features/companions/data/models/sahabi_model.dart';
import 'package:rafiki_app/features/companions/data/datasources/sahaba_list_data.dart';

import 'package:rafiki_app/features/companions/presentation/pages/companion_details_page.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static const bg        = Color(0xFF07090F);
  static const surface   = Color(0xFF0D1120);
  static const gold      = Color(0xFFD4A843);
  static const goldLight = Color(0xFFF0C870);
  static const onCard    = Color(0xFFF5EDD8);
  static const muted     = Color(0xFF4A5568);
}

// ─── SAHABA DATA ──────────────────────────────────────────────────────────────


// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class CompanionsPage extends StatefulWidget {
  const CompanionsPage({super.key});

  @override
  State<CompanionsPage> createState() => _CompanionsPageState();
}

class _CompanionsPageState extends State<CompanionsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  int _selectedTab = 0; // 0 = الصحابة الكرام, 1 = كبار التابعين
  String _selectedCategory = "الكل";

  final List<String> _categories = [
    "الكل",
    "الخلفاء الراشدون",
    "العشرة المبشرون",
    "آل البيت",
    "المهاجرون",
    "الأنصار",
    "أهل بدر",
    "أهل الرضوان",
    "رواة الحديث",
    "القادة والفرسان",
    "الشهداء",
    "الصحابيات"
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedTab == 0 ? sahabaList : tabiList;
    final filteredList = _selectedCategory == "الكل"
        ? activeList
        : activeList.where((s) => s.categories.contains(_selectedCategory)).toList();

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildHeader(),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverHeaderDelegate(
                      height: 66.0,
                      child: _buildSegmentedControl(),
                    ),
                  ),
                  if (_selectedTab == 0)
                    SliverToBoxAdapter(
                      child: _buildCategoryRow(),
                    ),
                ];
              },
              body: _buildGrid(filteredList),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEGMENTED CONTROL ──────────────────────────────────────────────────────

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _C.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Future.microtask(() {
                if (mounted) setState(() { _selectedTab = 0; _selectedCategory = "الكل"; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "الصحابة الكرام",
                    style: TextStyle(
                      color: _selectedTab == 0 ? _C.bg : _C.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => Future.microtask(() {
                if (mounted) setState(() { _selectedTab = 1; _selectedCategory = "الكل"; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "كبار التابعين",
                    style: TextStyle(
                      color: _selectedTab == 1 ? _C.bg : _C.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? _C.bg : _C.goldLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              selectedColor: _C.gold,
              backgroundColor: _C.surface,
              checkmarkColor: _C.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _C.gold.withOpacity(isSelected ? 1.0 : 0.2)),
              ),
              onSelected: (selected) {
                if (selected) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: (_entryCtrl.value * 2).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _entryCtrl.value) * -16),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          children: [
            const Text(
              "الموسوعة الإسلامية",
              style: TextStyle(
                color: _C.goldLight,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Color(0x33D4A843), blurRadius: 15)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "سير الأعلام والشخصيات الإسلامية",
              style: TextStyle(color: _C.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _C.gold.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GRID ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<Sahabi> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد عناصر في هذا التصنيف",
          style: TextStyle(color: _C.muted, fontSize: 15),
        ),
      );
    }
    return GridView.builder(
      key: ValueKey("$_selectedTab-$_selectedCategory"),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.80,
      ),
      itemBuilder: (context, index) {
        return SahabiCard(
          sahabi: list[index],
          index: index,
          entryController: _entryCtrl,
          onTap: () => Navigator.push(
            context,
            slideRoute(SahabiDetails.fromName(list[index].name)),
          ),
        );
      },
    );
  }
}

// ─── SAHABI CARD ─────────────────────────────────────────────────────────────

class SahabiCard extends StatefulWidget {
  final Sahabi sahabi;
  final int index;
  final AnimationController entryController;
  final VoidCallback onTap;

  const SahabiCard({
    super.key,
    required this.sahabi,
    required this.index,
    required this.entryController,
    required this.onTap,
  });

  @override
  State<SahabiCard> createState() => SahabiCardState();
}

class SahabiCardState extends State<SahabiCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _entryFade;
  late final Animation<double> _entrySlide;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.04,
    );

    final start = (widget.index * 0.065).clamp(0.0, 0.82);
    final end   = (start + 0.30).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _entryFade  = curve;
    _entrySlide = Tween<double>(begin: 28, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.entryController, _pressCtrl]),
      builder: (_, __) => Opacity(
        opacity: _entryFade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _entrySlide.value),
          child: Transform.scale(
            scale: 1.0 - _pressCtrl.value,
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final s = widget.sahabi;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: Hero(
        tag: s.name,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: _C.surface,
            border: Border.all(color: s.accent.withOpacity(0.28), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: s.accent.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: -24,
                  right: -24,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent.withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          s.accent.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.accent.withOpacity(0.12),
                          border: Border.all(color: s.accent.withOpacity(0.45), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: s.accent.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            s.initial,
                            style: TextStyle(
                              color: s.accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.accent.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: _C.muted, size: 9),
                          const SizedBox(width: 4),
                          const Text(
                            "اقرأ السيرة",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: _C.muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
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

// ─── HELPERS ─────────────────────────────────────────────────────────────────



// ─── BACKGROUND ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BgPainter()),
    );
  }
}

class _BgPainter extends CustomPainter {
  static final _stars = List.generate(60, (i) {
    final r = math.Random(i * 37 + 11);
    return (
    x: r.nextDouble(),
    y: r.nextDouble(),
    rad: r.nextDouble() * 1.2 + 0.2,
    o: r.nextDouble() * 0.28 + 0.05,
    );
  });

  @override
  void paint(Canvas canvas, Size sz) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080A12), Color(0xFF07090F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.75, -0.75),
          radius: 0.55,
          colors: [const Color(0xFFD4A843).withOpacity(0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withOpacity(s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF07090F),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

Route slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}