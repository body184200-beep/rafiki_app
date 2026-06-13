import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'Shabah_details.dart';

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

class _Sahabi {
  final String name;
  final String title;
  final String initial;
  final Color accent;

  const _Sahabi({
    required this.name,
    required this.title,
    required this.initial,
    required this.accent,
  });
}

const List<_Sahabi> _sahabaList = [
  _Sahabi(name: "أبو بكر الصديق",      title: "الصدّيق",         initial: "أ", accent: Color(0xFFD4A843)),
  _Sahabi(name: "عمر بن الخطاب",       title: "الفاروق",         initial: "ع", accent: Color(0xFF8B2020)),
  _Sahabi(name: "عثمان بن عفان",       title: "ذو النورين",      initial: "ع", accent: Color(0xFF1A6B50)),
  _Sahabi(name: "علي بن أبي طالب",     title: "باب مدينة العلم", initial: "ع", accent: Color(0xFF4A6BD4)),
  _Sahabi(name: "خالد بن الوليد",      title: "سيف الله المسلول",initial: "خ", accent: Color(0xFFB85C20)),
  _Sahabi(name: "عمرو بن العاص",       title: "فاتح مصر",        initial: "ع", accent: Color(0xFF6B3FA0)),
  _Sahabi(name: "عبدالرحمن بن عوف",    title: "من العشرة المبشرين", initial: "ع", accent: Color(0xFF2D8A6B)),
  _Sahabi(name: "سعد بن أبي وقاص",    title: "أسد الإسلام",     initial: "س", accent: Color(0xFF8B6020)),
  _Sahabi(name: "معاذ بن جبل",         title: "أعلم الحلال والحرام", initial: "م", accent: Color(0xFF1A5C8B)),
  _Sahabi(name: "مصعب بن عمير",        title: "أول سفير في الإسلام",  initial: "م", accent: Color(0xFF6B2D5E)),
  _Sahabi(name: "بلال بن رباح",        title: "مؤذّن الرسول ﷺ", initial: "ب", accent: Color(0xFF8B4020)),
  _Sahabi(name: "حذيفة بن اليمان",     title: "صاحب السر",       initial: "ح", accent: Color(0xFF2D5C8B)),
];

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class HomeGrid extends StatefulWidget {
  const HomeGrid({super.key});

  @override
  State<HomeGrid> createState() => _HomeGridState();
}

class _HomeGridState extends State<HomeGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;

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
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGrid()),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          children: [
            Row(
              children: [
                _GoldLine(leftToRight: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "✦",
                    style: TextStyle(
                      color: _C.gold,
                      fontSize: 16,
                      shadows: [Shadow(color: _C.gold.withOpacity(0.6), blurRadius: 14)],
                    ),
                  ),
                ),
                _GoldLine(leftToRight: true),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "أصحاب النبي ﷺ",
              style: TextStyle(
                color: _C.goldLight,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                shadows: [Shadow(color: Color(0x55D4A843), blurRadius: 18)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "رضي الله عنهم أجمعين",
              style: TextStyle(color: _C.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _C.gold.withOpacity(0.35),
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

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: _sahabaList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return _SahabiCard(
          sahabi: _sahabaList[index],
          index: index,
          entryController: _entryCtrl,
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: SahabiDetails.fromName(_sahabaList[index].name),
              ),
              transitionDuration: const Duration(milliseconds: 320),
            ),
          ),
        );
      },
    );
  }
}

// ─── SAHABI CARD ─────────────────────────────────────────────────────────────

class _SahabiCard extends StatefulWidget {
  final _Sahabi sahabi;
  final int index;
  final AnimationController entryController;
  final VoidCallback onTap;

  const _SahabiCard({
    required this.sahabi,
    required this.index,
    required this.entryController,
    required this.onTap,
  });

  @override
  State<_SahabiCard> createState() => _SahabiCardState();
}

class _SahabiCardState extends State<_SahabiCard>
    with SingleTickerProviderStateMixin {
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
                // Corner glow
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
                // Top accent line
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
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.accent.withOpacity(0.12),
                          border: Border.all(color: s.accent.withOpacity(0.45), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: s.accent.withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            s.initial,
                            style: TextStyle(
                              color: s.accent,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Name
                      Text(
                        s.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Title badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: s.accent.withOpacity(0.1),
                          border: Border.all(color: s.accent.withOpacity(0.3), width: 0.8),
                        ),
                        child: Text(
                          s.title,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: s.accent.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tap hint
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

class _GoldLine extends StatelessWidget {
  final bool leftToRight;
  const _GoldLine({required this.leftToRight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: leftToRight
                ? [_C.gold.withOpacity(0.4), Colors.transparent]
                : [Colors.transparent, _C.gold.withOpacity(0.4)],
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
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080A12), Color(0xFF07090F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    // Gold nebula top-right
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.75, -0.75),
          radius: 0.55,
          colors: [const Color(0xFFD4A843).withOpacity(0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    // Stars
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withOpacity(s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}