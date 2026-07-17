import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/battles/data/datasources/battles_data.dart';

// ══════════════════════════════════════════════════════════
//  BATTLE DETAILS — PREMIUM REDESIGN
// ══════════════════════════════════════════════════════════

class BattleDetails extends StatefulWidget {
  final String name;
  final String description;
  final String location;
  final String date;
  final List<String> participants;
  final String muslimLeader;
  final String enemyLeader;
  final dynamic muslimCasualties;
  final dynamic enemyCasualties;
  final String winner;
  final String ahdas;

  const BattleDetails({
    super.key,
    required this.name,
    required this.description,
    required this.location,
    required this.date,
    required this.participants,
    required this.muslimLeader,
    required this.enemyLeader,
    required this.muslimCasualties,
    required this.enemyCasualties,
    required this.winner,
    required this.ahdas,
  });

  // ── DATA ──────────────────────────────────────────────




  // ── fromName مع معالجة آمنة ──────────────────────────
  static BattleDetails fromName(String name) {
    // البحث المباشر أولاً
    Map<String, dynamic>? data = battlesData[name];

    // لو مش لاقيه، ابحث بعد trim
    if (data == null) {
      final trimmed = name.trim();
      final match = battlesData.entries.where(
            (e) => e.key.trim() == trimmed,
      );
      if (match.isNotEmpty) data = match.first.value;
    }

    // لو لسه null، ارجع بيانات فاضية بدل ما تـ crash
    if (data == null || data.isEmpty) {
      return BattleDetails(
        name: name,
        description: "لا توجد بيانات",
        location: "-",
        date: "-",
        participants: [],
        muslimLeader: "-",
        enemyLeader: "-",
        muslimCasualties: 0,
        enemyCasualties: 0,
        winner: "-",
        ahdas: "",
      );
    }

    return BattleDetails(
      name: name,
      description: data["description"] ?? "",
      location: data["location"] ?? "",
      date: data["date"] ?? "",
      participants: List<String>.from(data["participants"] ?? []),
      muslimLeader: data["muslimLeader"] ?? "",
      enemyLeader: data["enemyLeader"] ?? "",
      muslimCasualties: data["muslimCasualties"] ?? 0,
      enemyCasualties: data["enemyCasualties"] ?? 0,
      winner: data["winner"] ?? "",
      ahdas: data["Ahdas"] ?? "",
    );
  }

  @override
  State<BattleDetails> createState() => _BattleDetailsState();
}

class _BattleDetailsState extends State<BattleDetails>
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
  static const Color _bg        = Color(0xFF080C18);
  static const Color _surface   = Color(0xFF0F1525);
  static const Color _crimson   = Color(0xFFC0392B);
  static const Color _crimsonLt = Color(0xFFE74C3C);
  static const Color _gold      = Color(0xFFD4A853);
  static const Color _goldLight = Color(0xFFF0C97A);
  static const Color _text      = Color(0xFFF0EAD6);
  static const Color _textMuted = Color(0xFF7A7468);
  static const Color _green     = Color(0xFF27AE60);

  bool get _muslimWon => widget.winner == "المسلمون";

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _orbCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _orbRotate  = CurvedAnimation(parent: _orbCtrl, curve: Curves.linear);
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
    return Directionality(
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
                        _buildWinnerBanner(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildLeadersCard(),
                        const SizedBox(height: 20),
                        _buildCasualtiesCard(),
                        const SizedBox(height: 20),
                        if (widget.participants.isNotEmpty) _buildParticipantsCard(),
                        const SizedBox(height: 4),
                        if (widget.ahdas.isNotEmpty) _buildAhdasCard(),
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
    );
  }

  // ── BACKGROUND ────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _orbRotate,
      builder: (_, __) {
        final t = _orbRotate.value * 2 * math.pi;
        return Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.2, -0.5),
                radius: 1.5,
                colors: [Color(0xFF1A0A08), _bg],
              ),
            ),
          ),
          CustomPaint(painter: _WarMeshPainter(), size: Size.infinite),
          _orb(-0.1 + 0.05 * math.sin(t),       -0.6, 300, _crimson,              0.07),
          _orb(0.5  + 0.04 * math.cos(t * 0.8),  0.3, 220, const Color(0xFF1A3A5C), 0.09),
          _orb(-0.4 + 0.03 * math.sin(t * 1.4),  0.6, 160, _gold,                 0.05),
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
      top: 0, left: 0, right: 0, height: 90,
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
    final collapsed = _scrollOffset > 200;
    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      backgroundColor: collapsed ? _surface : Colors.transparent,
      elevation: collapsed ? 4 : 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
              border: Border.all(color: _crimson.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _crimsonLt, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
        title: collapsed
            ? Text(widget.name,
            style: const TextStyle(
                color: Color(0xFFE57373), fontSize: 17, fontWeight: FontWeight.bold))
            : null,
        centerTitle: true,
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0808), Color(0xFF080C18)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) {
              return Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _crimson.withValues(alpha: 0.3 + 0.15 * _shimmer.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A0808),
                    border: Border.all(
                      color: _crimson.withValues(alpha: 0.5 + 0.3 * _shimmer.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(color: _crimson.withValues(alpha: 0.4), blurRadius: 20),
                    ],
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: _crimsonLt, size: 36),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Text(widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _pill(Icons.calendar_today_rounded, widget.date, _gold),
            const SizedBox(width: 10),
            _pill(Icons.location_on_rounded, widget.location, _crimsonLt),
          ]),
        ]),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── WINNER BANNER ─────────────────────────────────────
  Widget _buildWinnerBanner() {
    final color  = _muslimWon ? _green : _crimson;
    final colorL = _muslimWon ? const Color(0xFF52D68A) : _crimsonLt;
    final icon   = _muslimWon ? Icons.emoji_events_rounded : Icons.handshake_outlined;
    final label  = _muslimWon ? "انتصر المسلمون" : "هزيمة / تعادل: ${widget.winner}";

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.18 + 0.06 * _shimmer.value),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.centerRight, end: Alignment.centerLeft,
            ),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: -2),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: colorL, size: 24),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  color: colorL, fontSize: 18,
                  fontWeight: FontWeight.bold, letterSpacing: 0.5,
                )),
          ]),
        );
      },
    );
  }

  // ── STATS GRID ────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Row(children: [
      Expanded(child: _statTile(Icons.location_on_rounded, "الموقع", widget.location, _gold)),
      const SizedBox(width: 12),
      Expanded(child: _statTile(Icons.schedule_rounded, "التاريخ", widget.date, _crimsonLt)),
    ]);
  }

  Widget _statTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F1525),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── LEADERS CARD ──────────────────────────────────────
  Widget _buildLeadersCard() {
    return _Card(
      child: Column(children: [
        _sectionLabel("القادة", Icons.person_pin_rounded),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _leaderTile("قائد المسلمين", widget.muslimLeader, _green, Icons.star_rounded)),
          Container(width: 1, height: 60, color: const Color(0xFF2A2416)),
          Expanded(child: _leaderTile("قائد الخصم", widget.enemyLeader, _crimsonLt, Icons.shield_outlined)),
        ]),
      ]),
    );
  }

  Widget _leaderTile(String title, String name, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: _textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── CASUALTIES CARD ───────────────────────────────────
  Widget _buildCasualtiesCard() {
    final mC = widget.muslimCasualties;
    final eC = widget.enemyCasualties;

    // تحويل آمن لأي نوع
    final mVal = mC is int ? mC : int.tryParse(mC.toString()) ?? 0;
    final eVal = eC is int ? eC : int.tryParse(eC.toString()) ?? 0;
    final total = mVal + eVal;
    final mRatio = total > 0 ? mVal / total : 0.5;

    // النص اللي هيتعرض
    final mText = mC.toString();
    final eText = eC.toString();

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel("الخسائر البشرية", Icons.people_outline_rounded),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            flex: (mRatio * 10).ceil().clamp(1, 9),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                color: _green.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: ((1 - mRatio) * 10).ceil().clamp(1, 9),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                color: _crimson.withValues(alpha: 0.7),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _casualtyBox("شهداء المسلمين", mText, _green)),
          const SizedBox(width: 12),
          Expanded(child: _casualtyBox("خسائر العدو", eText, _crimsonLt)),
        ]),
      ]),
    );
  }

  Widget _casualtyBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMuted, fontSize: 12)),
      ]),
    );
  }

  // ── PARTICIPANTS CARD ─────────────────────────────────
  Widget _buildParticipantsCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel("المشاركون", Icons.groups_rounded),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: widget.participants.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _gold.withValues(alpha: 0.1),
                border: Border.all(color: _gold.withValues(alpha: 0.25)),
              ),
              child: Text(p, style: const TextStyle(color: _goldLight, fontSize: 13)),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  // ── AHDAS CARD ────────────────────────────────────────
  Widget _buildAhdasCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF140A08), Color(0xFF0A0F1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: _crimson.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(color: _crimson.withValues(alpha: 0.08), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              colors: [_crimson.withValues(alpha: 0.2), _crimson.withValues(alpha: 0.04)],
            ),
          ),
          child: Row(children: [
            const Icon(Icons.history_edu_rounded, color: _crimsonLt, size: 24),
            const SizedBox(width: 12),
            const Text("أحداث الغزوة",
                style: TextStyle(
                  color: Color(0xFFE57373), fontSize: 18,
                  fontWeight: FontWeight.bold, letterSpacing: 0.8,
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _crimson.withValues(alpha: 0.15),
                border: Border.all(color: _crimson.withValues(alpha: 0.3)),
              ),
              child: const Text("رواية", style: TextStyle(color: _crimsonLt, fontSize: 11)),
            ),
          ]),
        ),
        Container(height: 1, color: _crimson.withValues(alpha: 0.1)),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Text(widget.ahdas,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _text, fontSize: 15, height: 2.0)),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            colors: [_gold, _goldLight],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(icon, color: _gold, size: 20),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              color: _goldLight, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  SHARED CARD WIDGET
// ══════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0F1525),
        border: Border.all(color: const Color(0xFF1E2535), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  WAR MESH PAINTER
// ══════════════════════════════════════════════════════════
class _WarMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.025)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const s = 70.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final paint2 = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.012)
      ..strokeWidth = 0.4;
    for (double i = -size.height; i < size.width + size.height; i += 100) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint2);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}