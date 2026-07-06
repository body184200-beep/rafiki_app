import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:rafiki_app/features/battles/presentation/pages/battle_details_page.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static const bg        = Color(0xFF0A0B0F);
  static const surface   = Color(0xFF13161E);
  static const border    = Color(0xFF242836);
  static const gold      = Color(0xFFD4A843);
  static const goldLight = Color(0xFFF0C870);
  static const goldDim   = Color(0xFF8A6820);
  static const crimson   = Color(0xFF8B2020);
  static const crimsonLt = Color(0xFFBF3A3A);
  static const sand      = Color(0xFFE8D5A3);
  static const sandDim   = Color(0xFF9A8860);
  static const onCard    = Color(0xFFF5EDD8);
  static const muted     = Color(0xFF5A6070);
}

// ─── BATTLE DATA ─────────────────────────────────────────────────────────────

class _Battle {
  final String name;
  final String year;   // Hijri year
  final String emoji;
  final Color accent;

  const _Battle({
    required this.name,
    required this.year,
    required this.emoji,
    required this.accent,
  });
}

const List<_Battle> _battles = [
  _Battle(name: "غزوة الأبواء",           year: "٢ هـ",  emoji: "🏜",  accent: Color(0xFF8B6914)),
  _Battle(name: "غزوة بواط",              year: "٢ هـ",  emoji: "🏞",  accent: Color(0xFF5D4037)),
  _Battle(name: "غزوة العشيرة",           year: "٢ هـ",  emoji: "🌴",  accent: Color(0xFF33691E)),
  _Battle(name: "غزوة سفوان (بدر الأولى)",  year: "٢ هـ",  emoji: "🐫",  accent: Color(0xFF795548)),
  _Battle(name: "غزوة بدر الكبرى",        year: "٢ هـ",  emoji: "⚔️",  accent: Color(0xFF8B2020)),
  _Battle(name: "غزوة بني سليم (الكدر)",   year: "٢ هـ",  emoji: "💧",  accent: Color(0xFF00796B)),
  _Battle(name: "غزوة بني قينقاع",        year: "٢ هـ",  emoji: "🏰",  accent: Color(0xFF1A5276)),
  _Battle(name: "غزوة السويق",            year: "٢ هـ",  emoji: "🌾",  accent: Color(0xFFE65100)),
  _Battle(name: "غزوة ذي أمر (غطفان)",    year: "٣ هـ",  emoji: "🗡",  accent: Color(0xFFBF360C)),
  _Battle(name: "غزوة بحران",             year: "٣ هـ",  emoji: "⛏",  accent: Color(0xFF3E2723)),
  _Battle(name: "غزوة أحد",               year: "٣ هـ",  emoji: "🗡",  accent: Color(0xFF6E2F1A)),
  _Battle(name: "غزوة حمراء الأسد",       year: "٣ هـ",  emoji: "🦁",  accent: Color(0xFF7D3C12)),
  _Battle(name: "غزوة بني النضير",        year: "٤ هـ",  emoji: "🌴",  accent: Color(0xFF1E6B3E)),
  _Battle(name: "غزوة ذات الرقاع",        year: "٤ هـ",  emoji: "🧳",  accent: Color(0xFF5D4037)),
  _Battle(name: "غزوة بدر الآخرة (بدر الموعد)", year: "٤ هـ", emoji: "🏹", accent: Color(0xFF1B5E20)),
  _Battle(name: "غزوة دومة الجندل",        year: "٥ هـ",  emoji: "🏰",  accent: Color(0xFF4A148C)),
  _Battle(name: "غزوة الخندق",            year: "٥ هـ",  emoji: "⛏",  accent: Color(0xFF4A235A)),
  _Battle(name: "غزوة بني قريظة",         year: "٥ هـ",  emoji: "🏰",  accent: Color(0xFF1A3A5C)),
  _Battle(name: "غزوة بني المصطلق",       year: "٥ هـ",  emoji: "🏕",  accent: Color(0xFF33691E)),
  _Battle(name: "صلح الحديبية",           year: "٦ هـ",  emoji: "🕊",  accent: Color(0xFF1A5276)),
  _Battle(name: "غزوة بني لحيان",         year: "٦ هـ",  emoji: "🛡",  accent: Color(0xFF0D47A1)),
  _Battle(name: "غزوة خيبر",              year: "٧ هـ",  emoji: "🏰",  accent: Color(0xFF6B2D2D)),
  _Battle(name: "غزوة مؤتة",              year: "٨ هـ",  emoji: "🛡",  accent: Color(0xFF2C3E50)),
  _Battle(name: "فتح مكة",                year: "٨ هـ",  emoji: "🕌",  accent: Color(0xFF7D6608)),
  _Battle(name: "غزوة حنين",              year: "٨ هـ",  emoji: "🏹",  accent: Color(0xFF6E2F1A)),
  _Battle(name: "غزوة الطائف",            year: "٨ هـ",  emoji: "🏹",  accent: Color(0xFF4E342E)),
  _Battle(name: "غزوة تبوك",              year: "٩ هـ",  emoji: "🐪",  accent: Color(0xFF7B3F00)),
];

const List<_Battle> _sarayaList = [
  _Battle(name: "سرية سيف البحر", year: "١ هـ", emoji: "⛵", accent: Color(0xFF00897B)),
  _Battle(name: "سرية نخلة", year: "٢ هـ", emoji: "🌴", accent: Color(0xFF7CB342)),
  _Battle(name: "سرية بئر معونة", year: "٤ هـ", emoji: "💧", accent: Color(0xFFE53935)),
  _Battle(name: "سرية الرجيع", year: "٤ هـ", emoji: "🛡", accent: Color(0xFFD81B60)),
  _Battle(name: "سرية ذات السلاسل", year: "٨ هـ", emoji: "⛓", accent: Color(0xFF5E35B1)),
  _Battle(name: "سرية أسامة بن زيد", year: "١١ هـ", emoji: "🚩", accent: Color(0xFF3949AB)),
];

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class Sh2 extends StatefulWidget {
  const Sh2({super.key});

  @override
  State<Sh2> createState() => _Sh2State();
}

class _Sh2State extends State<Sh2> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  int _selectedTab = 0; // 0 = غزوات الرسول ﷺ, 1 = السرايا والبعوث

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedTab == 0 ? _battles : _sarayaList;

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
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSubheader(activeList.length),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ];
              },
              body: _buildGrid(activeList),
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
                if (mounted) setState(() { _selectedTab = 0; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "غزوات الرسول ﷺ",
                    style: TextStyle(
                      color: _selectedTab == 0 ? Colors.black : _C.goldLight,
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
                if (mounted) setState(() { _selectedTab = 1; });
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? _C.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "السرايا والبعوث",
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.black : _C.goldLight,
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

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dividerLine(align: CrossAxisAlignment.end),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    const Text(
                      "⚔",
                      style: TextStyle(
                        color: _C.gold,
                        fontSize: 28,
                        shadows: [Shadow(color: Color(0x88D4A843), blurRadius: 20)],
                      ),
                    ),
                  ],
                ),
              ),
              _dividerLine(align: CrossAxisAlignment.start),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "المعارك والبعوث النبوية",
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _C.sand,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              shadows: [Shadow(color: Color(0x33D4A843), blurRadius: 15)],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "الجهاد النبوي لحفظ كيان الدولة والدعوة",
            textDirection: TextDirection.rtl,
            style: TextStyle(color: _C.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _C.gold.withOpacity(0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine({required CrossAxisAlignment align}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: align == CrossAxisAlignment.end
                    ? [Colors.transparent, _C.gold.withOpacity(0.55)]
                    : [_C.gold.withOpacity(0.55), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheader(int count) {
    final label = _selectedTab == 0 ? "غزوة" : "سرية";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$count $label",
            style: const TextStyle(
              color: _C.sandDim,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.gold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "السيرة النبوية المشرفة",
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: _C.sandDim,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── GRID ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<_Battle> list) {
    return GridView.builder(
      key: ValueKey("$_selectedTab"),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (context, index) {
        final delay = Duration(milliseconds: 60 * index);
        return _BattleCard(
          battle: list[index],
          index: index,
          entryController: _entryCtrl,
          entryDelay: delay,
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: BattleDetails.fromName(list[index].name),
              ),
              transitionDuration: const Duration(milliseconds: 320),
            ),
          ),
        );
      },
    );
  }
}

// ─── BATTLE CARD ─────────────────────────────────────────────────────────────

class _BattleCard extends StatefulWidget {
  final _Battle battle;
  final int index;
  final AnimationController entryController;
  final Duration entryDelay;
  final VoidCallback onTap;

  const _BattleCard({
    required this.battle,
    required this.index,
    required this.entryController,
    required this.entryDelay,
    required this.onTap,
  });

  @override
  State<_BattleCard> createState() => _BattleCardState();
}

class _BattleCardState extends State<_BattleCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _entryFade;
  late final Animation<double> _entrySlide;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.045,
    );

    final start = (widget.index * 0.075).clamp(0.0, 0.8);
    final end   = (start + 0.35).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _entryFade  = curve;
    _entrySlide = Tween<double>(begin: 32, end: 0).animate(curve);
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
    final b = widget.battle;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _C.surface,
          border: Border.all(color: _C.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: b.accent.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                left: -28,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: b.accent.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 3,
                  color: b.accent.withOpacity(0.85),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: b.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: b.accent.withOpacity(0.35), width: 0.8),
                          ),
                          child: Text(
                            b.year,
                            style: TextStyle(
                              color: b.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        b.name,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, color: _C.muted, size: 12),
                        const SizedBox(width: 6),
                        const Text(
                          "التفاصيل",
                          style: TextStyle(
                            color: _C.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }
}

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
  static final _stars = List.generate(55, (i) {
    final r = math.Random(i * 47 + 13);
    return (
    x: r.nextDouble(),
    y: r.nextDouble(),
    rad: r.nextDouble() * 1.3 + 0.3,
    o: r.nextDouble() * 0.22 + 0.04,
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
          colors: [Color(0xFF090A0E), Color(0xFF0A0B0F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.8, -0.8),
          radius: 0.65,
          colors: [const Color(0xFFD4A843).withOpacity(0.04), Colors.transparent],
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
      color: const Color(0xFF0A0B0F),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}