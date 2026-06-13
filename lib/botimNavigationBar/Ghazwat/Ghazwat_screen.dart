import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'GHazwat_details.dart';

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
  _Battle(name: "غزوة بدر الكبرى",        year: "٢ هـ",  emoji: "⚔️",  accent: Color(0xFF8B2020)),
  _Battle(name: "غزوة بني قينقاع",        year: "٢ هـ",  emoji: "🏰",  accent: Color(0xFF1A5276)),
  _Battle(name: "غزوة أحد",               year: "٣ هـ",  emoji: "🗡",  accent: Color(0xFF6E2F1A)),
  _Battle(name: "غزوة حمراء الأسد",       year: "٣ هـ",  emoji: "🦁",  accent: Color(0xFF7D3C12)),
  _Battle(name: "غزوة بني النضير",        year: "٤ هـ",  emoji: "🌴",  accent: Color(0xFF1E6B3E)),
  _Battle(name: "غزوة الخندق",            year: "٥ هـ",  emoji: "⛏",  accent: Color(0xFF4A235A)),
  _Battle(name: "غزوة بني قريظة",         year: "٥ هـ",  emoji: "🏯",  accent: Color(0xFF1A3A5C)),
  _Battle(name: "صلح الحديبية",           year: "٦ هـ",  emoji: "🕊",  accent: Color(0xFF1A5276)),
  _Battle(name: "غزوة خيبر",              year: "٧ هـ",  emoji: "🏰",  accent: Color(0xFF6B2D2D)),
  _Battle(name: "غزوة مؤتة",              year: "٨ هـ",  emoji: "🛡",  accent: Color(0xFF2C3E50)),
  _Battle(name: "فتح مكة",                year: "٨ هـ",  emoji: "🕌",  accent: Color(0xFF7D6608)),
  _Battle(name: "غزوة حنين",              year: "٨ هـ",  emoji: "🏹",  accent: Color(0xFF6E2F1A)),
  _Battle(name: "غزوة تبوك",              year: "٩ هـ",  emoji: "🐪",  accent: Color(0xFF7B3F00)),
];

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class Sh2 extends StatefulWidget {
  const Sh2({super.key});

  @override
  State<Sh2> createState() => _Sh2State();
}

class _Sh2State extends State<Sh2> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;

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
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSubheader(),
                const SizedBox(height: 4),
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
            "غزوات النبي ﷺ",
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _C.goldLight,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              shadows: [Shadow(color: Color(0x66D4A843), blurRadius: 16)],
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _C.gold.withOpacity(0.5)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_battles.length} غزوة",
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

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _battles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final delay = Duration(milliseconds: 60 * index);
        return _BattleCard(
          battle: _battles[index],
          index: index,
          entryController: _entryCtrl,
          entryDelay: delay,
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: BattleDetails.fromName(_battles[index].name),
              ),
              transitionDuration: const Duration(milliseconds: 350),
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

class _BattleCardState extends State<_BattleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  bool _pressed = false;

  // Staggered entry
  late final Animation<double> _fade;
  late final Animation<double> _slideY;

  @override
  void initState() {
    super.initState();

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.04,
    );

    final intervalStart = (widget.index * 0.06).clamp(0.0, 0.9);
    final intervalEnd   = (intervalStart + 0.25).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );
    _fade   = curve;
    _slideY = Tween<double>(begin: 24, end: 0).animate(curve);
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
      builder: (_, __) {
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _slideY.value),
            child: Transform.scale(
              scale: 1.0 - _pressCtrl.value,
              child: _buildCardContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    final accent = widget.battle.accent;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _pressCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _pressCtrl.reverse();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _C.surface,
          border: Border.all(
            color: _pressed
                ? _C.gold.withOpacity(0.5)
                : accent.withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(_pressed ? 0.35 : 0.18),
              blurRadius: _pressed ? 22 : 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Accent glow in corner
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.15),
                  ),
                ),
              ),
              // Thin top accent bar
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.0), accent, accent.withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji in ornate container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.15),
                        border: Border.all(
                          color: accent.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.battle.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Battle name
                    Text(
                      widget.battle.name,
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
                    const SizedBox(height: 6),
                    // Year badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _C.gold.withOpacity(0.1),
                        border: Border.all(
                          color: _C.gold.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.battle.year,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: _C.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tap hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "اقرأ التفاصيل",
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: _C.muted,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _C.muted,
                          size: 9,
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
    final rng = math.Random(i * 31 + 13);
    return (
    x: rng.nextDouble(),
    y: rng.nextDouble(),
    r: rng.nextDouble() * 1.2 + 0.3,
    o: rng.nextDouble() * 0.35 + 0.07,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C0E14), Color(0xFF0A0B0F), Color(0xFF080A0E)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Gold nebula top-right
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.8, -0.7),
          radius: 0.6,
          colors: [
            const Color(0xFFD4A843).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Crimson nebula bottom-left
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, 0.9),
          radius: 0.5,
          colors: [
            const Color(0xFF8B2020).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withOpacity(s.o);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}