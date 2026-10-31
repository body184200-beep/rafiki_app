import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/companions/data/datasources/sahaba_details_data.dart';

// ══════════════════════════════════════════════════════════
//  COMPANION DETAILS — LIGHT & DARK THEMED
// ══════════════════════════════════════════════════════════

class SahabiDetails extends StatefulWidget {
  final String name;
  final String description;
  final String biography;
  final List<String> battles;
  final List<String> attributes;
  final String day;
  final String additionalInfo;

  const SahabiDetails({
    super.key,
    required this.name,
    required this.description,
    required this.biography,
    required this.battles,
    required this.attributes,
    required this.day,
    required this.additionalInfo,
  });

  // ── fromName مع معالجة آمنة ──────────────────────────
  static SahabiDetails fromName(String name) {
    final trimmed = name.trim();
    Map<String, dynamic>? data = sahabaData[name];

    if (data == null) {
      final match = sahabaData.entries.where(
        (e) => e.key.trim() == trimmed || e.key.contains(trimmed) || trimmed.contains(e.key),
      );
      if (match.isNotEmpty) {
        data = match.first.value;
      }
    }

    if (data == null || data.isEmpty) {
      return SahabiDetails(
        name: name,
        description: "لا توجد بيانات",
        biography: "",
        battles: [],
        attributes: [],
        day: "",
        additionalInfo: "",
      );
    }

    return SahabiDetails(
      name: name,
      description: data["description"] ?? "",
      biography: data["biography"] ?? "",
      battles: List<String>.from(data["battles"] ?? []),
      attributes: List<String>.from(data["attributes"] ?? []),
      day: data["day"] ?? "",
      additionalInfo: data["additionalInfo"] ?? "",
    );
  }

  @override
  State<SahabiDetails> createState() => _SahabiDetailsState();
}

typedef CompanionDetails = SahabiDetails;

class _SahabiDetailsState extends State<SahabiDetails>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _orbRotate;
  late Animation<double>   _shimmer;

  final ScrollController _scroll = ScrollController();
  double _scrollOffset = 0;

  // ── PALETTE ───────────────────────────────────────────
  static bool get _l => ThemeProvider.instance.isLight;
  static Color get _bg        => _l ? const Color(0xFFF8F6F0) : const Color(0xFF080D1A);
  static Color get _surface   => _l ? const Color(0xFFFFFFFF) : const Color(0xFF0E1628);
  static Color get _cardBorder=> _l ? const Color(0xFFE5E7EB) : const Color(0xFF1C2840);
  static Color get _gold      => _l ? const Color(0xFF926315) : const Color(0xFFD4A843);
  static Color get _goldLight => _l ? const Color(0xFFB48216) : const Color(0xFFF0C97A);
  static Color get _text      => _l ? const Color(0xFF111827) : const Color(0xFFF0EAD6);
  static Color get _textMuted => _l ? const Color(0xFF4B5563) : const Color(0xFF8E9BAE);
  static Color get _teal      => _l ? const Color(0xFF0F766E) : const Color(0xFF1ABC9C);
  static Color get _purple    => _l ? const Color(0xFF7E22CE) : const Color(0xFF6C3483);
  static Color get _blue      => _l ? const Color(0xFF1E40AF) : const Color(0xFF1A3A5C);

  @override
  void initState() {
    super.initState();
    _entryCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _orbCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _orbRotate  = CurvedAnimation(parent: _orbCtrl,  curve: Curves.linear);
    _shimmer    = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);

    _entryCtrl.forward();
    _scroll.addListener(() => setState(() => _scrollOffset = _scroll.offset));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _shimmerCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(children: [
            _buildBackground(),
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: SlideTransition(
                      position: _entrySlide,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 60),
                        child: Column(children: [
                          const SizedBox(height: 24),
                          _buildDescriptionBanner(),
                          if (widget.biography.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildBiographyCard(),
                          ],
                          if (widget.battles.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildBattlesCard(),
                          ],
                          if (widget.attributes.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildAttributesCard(),
                          ],
                          if (widget.additionalInfo.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildInfoCard(),
                          ],
                          if (widget.day.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildDayCard(),
                          ],
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _buildTopGradient(),
          ]),
        ),
      ),
    );
  }

  // ── BACKGROUND ────────────────────────────────────────
  Widget _buildBackground() {
    if (_l) {
      return Container(color: _bg);
    }
    return AnimatedBuilder(
      animation: _orbRotate,
      builder: (_, __) {
        final t = _orbRotate.value * 2 * math.pi;
        return Stack(children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.4),
                radius: 1.4,
                colors: [const Color(0xFF0A1628), _bg],
              ),
            ),
          ),
          CustomPaint(painter: _MeshPainter(), size: Size.infinite),
          _orb(-0.1 + 0.05 * math.sin(t),       -0.5, 280, _teal,   0.06),
          _orb(0.5  + 0.04 * math.cos(t * 0.7),  0.2, 200, _blue,   0.10),
          _orb(-0.3 + 0.03 * math.sin(t * 1.3),  0.7, 150, _gold,   0.05),
          _orb(0.2  + 0.04 * math.cos(t * 1.1), -0.2, 180, _purple, 0.04),
        ]);
      },
    );
  }

  Widget _orb(double x, double y, double size, Color color, double opacity) {
    return Positioned(
      left: MediaQuery.of(context).size.width  * (x + 0.5) - size / 2,
      top:  MediaQuery.of(context).size.height * (y + 0.5) - size / 2,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 100,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_bg, _bg.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────
  Widget _buildSliverAppBar() {
    final collapsed = _scrollOffset > 210;
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: collapsed ? _surface : Colors.transparent,
      elevation: collapsed ? 2 : 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _l ? const Color(0xFFFEF3C7) : Colors.black38,
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: _gold, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
        title: collapsed
            ? Text(widget.name,
            style: TextStyle(
                color: _gold, fontSize: 18, fontWeight: FontWeight.bold))
            : null,
        centerTitle: true,
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _l
              ? [const Color(0xFFFEF3C7), const Color(0xFFF8F6F0)]
              : [const Color(0xFF0A1628), const Color(0xFF080D1A)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          // ── Avatar ──────────────────────────────────
          AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) {
              return Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.25 + 0.1 * _shimmer.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _l
                          ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                          : [const Color(0xFF1A2A40), const Color(0xFF0E1628)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.5 + 0.3 * _shimmer.value),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(color: _gold.withValues(alpha: _l ? 0.15 : 0.3), blurRadius: 24),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.name.isNotEmpty ? widget.name[0] : "؟",
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(widget.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _text, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(widget.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _textMuted, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 16),
          // ── Quick Stats Row ──────────────────────────
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
            _statPill(Icons.military_tech_rounded,
                "${widget.battles.length} غزوة", _teal),
            const SizedBox(width: 10),
            _statPill(Icons.star_rounded,
                "${widget.attributes.length} صفة", _gold),
          ]),
        ]),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: _l ? 0.10 : 0.12),
        border: Border.all(color: color.withValues(alpha: _l ? 0.35 : 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── DESCRIPTION BANNER ────────────────────────────────
  Widget _buildDescriptionBanner() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              _teal.withValues(alpha: _l ? 0.10 : (0.15 + 0.05 * _shimmer.value)),
              _teal.withValues(alpha: _l ? 0.04 : 0.04),
            ],
            begin: Alignment.centerRight, end: Alignment.centerLeft,
          ),
          border: Border.all(color: _teal.withValues(alpha: _l ? 0.35 : 0.3)),
          boxShadow: [
            BoxShadow(
                color: _teal.withValues(alpha: _l ? 0.05 : 0.1), blurRadius: 20, spreadRadius: -2),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Text(widget.description,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: _text, fontSize: 15, height: 1.6,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: _l ? 0.15 : 0.15),
              border: Border.all(color: _teal.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.person_rounded, color: _teal, size: 22),
          ),
        ]),
      ),
    );
  }

  // ── BIOGRAPHY CARD ────────────────────────────────────
  Widget _buildBiographyCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("السيرة العطرة", Icons.menu_book_rounded, _gold),
        const SizedBox(height: 14),
        Text(widget.biography,
            textAlign: TextAlign.right,
            style: TextStyle(
                color: _text, fontSize: 15, height: 1.85, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── BATTLES CARD ──────────────────────────────────────
  Widget _buildBattlesCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("الغزوات والمشاركات", Icons.shield_rounded, _teal),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.battles.map((b) => _chip(b, _teal)).toList(),
        ),
      ]),
    );
  }

  // ── ATTRIBUTES CARD ───────────────────────────────────
  Widget _buildAttributesCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("الصفات والمناقب", Icons.auto_awesome_rounded, _gold),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.attributes.map((a) => _chip(a, _gold)).toList(),
        ),
      ]),
    );
  }

  // ── INFO CARD ─────────────────────────────────────────
  Widget _buildInfoCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader("معلومة إضافية", Icons.lightbulb_rounded, _gold),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _gold.withValues(alpha: _l ? 0.08 : 0.07),
            border: Border.all(color: _gold.withValues(alpha: _l ? 0.3 : 0.2)),
          ),
          child: Text(widget.additionalInfo,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: _l ? _text : _goldLight, fontSize: 14.5, height: 1.7, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  // ── DAY / STORY CARD ──────────────────────────────────
  Widget _buildDayCard() {
    final paragraphs = widget.day
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: _surface,
        gradient: _l
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0A1020), Color(0xFF0D1A2E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: _l ? _cardBorder : _gold.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _l
                ? Colors.black.withValues(alpha: 0.04)
                : _gold.withValues(alpha: 0.07),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          if (!_l)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: _l ? const Color(0xFFFEF3C7) : null,
            gradient: _l
                ? null
                : LinearGradient(
                    colors: [_gold.withValues(alpha: 0.18), _gold.withValues(alpha: 0.04)],
                  ),
          ),
          child: Row(children: [
            Icon(Icons.auto_stories_rounded, color: _gold, size: 22),
            const SizedBox(width: 10),
            Text("القصة والسيرة",
                style: TextStyle(
                    color: _gold, fontSize: 17,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _SahabiBookReaderPage(
                    name: widget.name,
                    story: widget.day,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _gold.withValues(alpha: _l ? 0.15 : 0.2),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, color: _gold, size: 16),
                    const SizedBox(width: 5),
                    Text("وضع القراءة",
                        style: TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: _l ? _cardBorder : _gold.withValues(alpha: 0.1)),
        // ── Content ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: paragraphs.map((p) {
              final isHeader = p.startsWith('أولاً:') ||
                  p.startsWith('ثانياً:') ||
                  p.startsWith('ثالثاً:') ||
                  p.startsWith('رابعاً:') ||
                  p.startsWith('خامساً:') ||
                  p.startsWith('سادساً:') ||
                  p.startsWith('سابعاً:');

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: isHeader
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                    : EdgeInsets.zero,
                decoration: isHeader
                    ? BoxDecoration(
                        color: _gold.withValues(alpha: _l ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          right: BorderSide(
                              color: _gold.withValues(alpha: 0.7), width: 3),
                        ),
                      )
                    : null,
                child: Text(
                  p,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: isHeader ? _gold : _text,
                    fontSize: 16,
                    height: 2.1,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.15,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── HELPERS ───────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.4)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: _l ? 0.08 : 0.1),
        border: Border.all(color: color.withValues(alpha: _l ? 0.35 : 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  GLASS CARD
// ══════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final l = ThemeProvider.instance.isLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: l ? const Color(0xFFFFFFFF) : const Color(0xFF0E1628),
        border: Border.all(
          color: l ? const Color(0xFFE5E7EB) : const Color(0xFF1C2840),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: l ? 0.04 : 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MESH PAINTER
// ══════════════════════════════════════════════════════════
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFF1ABC9C).withValues(alpha: 0.025)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const s = 65.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p1);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p1);
    }
    final p2 = Paint()
      ..color = const Color(0xFFD4A853).withValues(alpha: 0.015)
      ..strokeWidth = 0.4;
    for (double i = -size.height; i < size.width + size.height; i += 90) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p2);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════
//  SAHABI FULL-SCREEN BOOK READER
// ══════════════════════════════════════════════════════════
class _SahabiBookReaderPage extends StatelessWidget {
  final String name;
  final String story;

  const _SahabiBookReaderPage({
    required this.name,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    final l = ThemeProvider.instance.isLight;
    final bg = l ? const Color(0xFFF8F6F0) : const Color(0xFF080D1A);
    final cardBg = l ? const Color(0xFFFFFFFF) : const Color(0xFF0E1628);
    final cardBorder = l ? const Color(0xFFE5E7EB) : const Color(0xFFD4A853).withValues(alpha: 0.08);
    final text = l ? const Color(0xFF111827) : const Color(0xFFF0EAD6);
    final gold = l ? const Color(0xFF926315) : const Color(0xFFD4A853);

    final paragraphs = story
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: cardBg,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: gold,
                      size: 16,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  name,
                  style: TextStyle(
                    color: text,
                    fontSize: 16.5,
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
                            gold.withValues(alpha: l ? 0.08 : 0.22),
                            bg,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Opacity(
                        opacity: l ? 0.06 : 0.12,
                        child: Icon(Icons.menu_book_rounded,
                            size: 80, color: gold),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded, color: gold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "سيرة وقصة الصحابي — رواية موثقة",
                              style: TextStyle(
                                color: gold,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...paragraphs.map((p) => _buildParagraphCard(p, cardBg, cardBorder, text, gold, l)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphCard(String p, Color cardBg, Color cardBorder, Color text, Color gold, bool l) {
    final isHeader = p.startsWith('أولاً:') ||
        p.startsWith('ثانياً:') ||
        p.startsWith('ثالثاً:') ||
        p.startsWith('رابعاً:') ||
        p.startsWith('خامساً:') ||
        p.startsWith('سادساً:') ||
        p.startsWith('سابعاً:');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHeader ? gold.withValues(alpha: 0.4) : cardBorder,
          width: isHeader ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: l ? 0.03 : 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        p,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: isHeader ? gold : text,
          fontSize: 16.5,
          height: 2.1,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
