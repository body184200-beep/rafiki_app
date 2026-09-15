import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rafiki_app/features/prophet/data/datasources/prophet_data.dart';


// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static const bg         = Color(0xFF07090F);
  static const surface    = Color(0xFF0D1018);
  static const surfaceAlt = Color(0xFF111520);
  static const gold       = Color(0xFFD4A843);
  static const goldLight  = Color(0xFFF0C870);
  static const onCard     = Color(0xFFF5EDD8);
  static const muted      = Color(0xFF4A5568);
  static const textBody   = Color(0xFFCBD5E1);
}

// ─── SECTION DATA ─────────────────────────────────────────────────────────────


// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class ProphetPage extends StatefulWidget {
  const ProphetPage({super.key});

  @override
  State<ProphetPage> createState() => _ProphetPageState();
}

class _ProphetPageState extends State<ProphetPage> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: _entryCtrl.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _entryCtrl.value) * -20),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          children: [
            const Text(
              "حياة الرسول ﷺ",
              style: TextStyle(
                color: _C.goldLight,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Color(0x33D4A843), blurRadius: 15)],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "السيرة النبوية العطرة",
              style: TextStyle(
                color: _C.muted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _C.gold.withValues(alpha: 0.25),
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

  // ── LIST ──────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: prophetSections.length,
      itemBuilder: (context, i) => ProphetBiographySectionCard(
        section: prophetSections[i],
        index: i,
        entryController: _entryCtrl,
        onTap: () => _openReader(context, prophetSections[i]),
      ),
    );
  }

  // ── FULL-SCREEN READER ────────────────────────────────────────────────────

  void _openReader(BuildContext context, ProphetBiographySection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProphetSectionReader(section: section),
      ),
    );
  }
}

// ─── SECTION CARD ────────────────────────────────────────────────────────────

class ProphetBiographySectionCard extends StatefulWidget {
  final ProphetBiographySection section;
  final int index;
  final AnimationController entryController;
  final VoidCallback onTap;

  const ProphetBiographySectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.entryController,
    required this.onTap,
  });

  @override
  State<ProphetBiographySectionCard> createState() => ProphetBiographySectionCardState();
}

class ProphetBiographySectionCardState extends State<ProphetBiographySectionCard>
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
      upperBound: 0.035,
    );

    final start = (widget.index * 0.07).clamp(0.0, 0.85);
    final end   = (start + 0.28).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: widget.entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _entryFade  = curve;
    _entrySlide = Tween<double>(begin: 30, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return AnimatedBuilder(
      animation: Listenable.merge([widget.entryController, _pressCtrl]),
      builder: (_, __) => Opacity(
        opacity: _entryFade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _entrySlide.value),
          child: Transform.scale(
            scale: 1.0 - _pressCtrl.value,
            child: _buildCard(s),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ProphetBiographySection s) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _C.surface,
          border: Border.all(color: s.accent.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: s.accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Left accent stripe
              Container(
                width: 3,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [s.accent.withValues(alpha: 0.0), s.accent, s.accent.withValues(alpha: 0.0)],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.accent.withValues(alpha: 0.12),
                  border: Border.all(color: s.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Icon(s.icon, color: s.accent, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          color: _C.onCard,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.subtitle,
                        style: TextStyle(
                          color: s.accent.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: s.accent.withValues(alpha: 0.6),
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PROPHET SECTION FULL-SCREEN READER ──────────────────────────────────────

class _ProphetSectionReader extends StatelessWidget {
  final ProphetBiographySection section;

  const _ProphetSectionReader({required this.section});

  @override
  Widget build(BuildContext context) {
    final s = section;
    final paragraphs = s.content
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: _C.surface,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: s.accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: s.accent,
                      size: 16,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  s.title,
                  style: const TextStyle(
                    color: _C.onCard,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            s.accent.withValues(alpha: 0.20),
                            _C.bg,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(s.icon, size: 80, color: s.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (s.subtitle.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: s.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: s.accent.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(s.icon, color: s.accent, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.subtitle,
                                style: TextStyle(
                                  color: s.accent,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ...paragraphs.map((p) => _buildParagraphCard(p, s.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphCard(String paragraph, Color accent) {
    final isHeader = paragraph.startsWith('أولاً:') ||
        paragraph.startsWith('ثانياً:') ||
        paragraph.startsWith('ثالثاً:') ||
        paragraph.startsWith('رابعاً:') ||
        paragraph.startsWith('خامساً:') ||
        paragraph.startsWith('سادساً:') ||
        paragraph.startsWith('سابعاً:');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHeader
              ? accent.withValues(alpha: 0.35)
              : _C.gold.withValues(alpha: 0.08),
          width: isHeader ? 1.2 : 0.8,
        ),
      ),
      child: Text(
        paragraph,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: _C.textBody,
          fontSize: 16.5,
          height: 2.1,
          letterSpacing: 0.2,
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
  static final _stars = List.generate(50, (i) {
    final r = math.Random(i * 41 + 9);
    return (x: r.nextDouble(), y: r.nextDouble(), rad: r.nextDouble() * 1.1 + 0.2, o: r.nextDouble() * 0.3 + 0.06);
  });

  @override
  void paint(Canvas canvas, Size sz) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF090B12), Color(0xFF07090F)],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    // Gold nebula
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sz.width, sz.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.5, -0.8),
          radius: 0.55,
          colors: [const Color(0xFFD4A843).withValues(alpha: 0.055), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height)),
    );

    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      p.color = Colors.white.withValues(alpha: s.o);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.rad, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}