import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/features/battles/data/datasources/battles_data.dart';

// ══════════════════════════════════════════════════════════
//  BATTLE DETAILS — LIGHT & DARK THEMED
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

  // ── fromName مع معالجة آمنة ──────────────────────────
  static BattleDetails fromName(String name) {
    final trimmed = name.trim();
    Map<String, dynamic>? data = battlesData[name] ?? sarayaData[name];

    if (data == null) {
      final match = battlesData.entries.where(
        (e) => e.key.trim() == trimmed || e.key.contains(trimmed) || trimmed.contains(e.key),
      );
      if (match.isNotEmpty) {
        data = match.first.value;
      } else {
        final matchSaraya = sarayaData.entries.where(
          (e) => e.key.trim() == trimmed || e.key.contains(trimmed) || trimmed.contains(e.key),
        );
        if (matchSaraya.isNotEmpty) data = matchSaraya.first.value;
      }
    }

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
  static bool get _l => ThemeProvider.instance.isLight;
  static Color get _bg        => _l ? const Color(0xFFF8F6F0) : const Color(0xFF080C18);
  static Color get _surface   => _l ? const Color(0xFFFFFFFF) : const Color(0xFF0F1525);
  static Color get _cardBorder=> _l ? const Color(0xFFE5E7EB) : const Color(0xFF1E2535);
  static Color get _crimson   => _l ? const Color(0xFFB91C1C) : const Color(0xFFC0392B);
  static Color get _crimsonLt => _l ? const Color(0xFFDC2626) : const Color(0xFFE74C3C);
  static Color get _gold      => _l ? const Color(0xFF926315) : const Color(0xFFD4A843);
  static Color get _goldLight => _l ? const Color(0xFFB48216) : const Color(0xFFF0C97A);
  static Color get _text      => _l ? const Color(0xFF111827) : const Color(0xFFF0EAD6);
  static Color get _textMuted => _l ? const Color(0xFF4B5563) : const Color(0xFF8E9BAE);
  static Color get _green     => _l ? const Color(0xFF15803D) : const Color(0xFF27AE60);

  bool get _muslimWon => widget.winner == "المسلمون";

  @override
  void initState() {
    super.initState();
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
      ),
    );
  }

  // ── BACKGROUND ────────────────────────────────────────
  Widget _buildBackground() {
    if (_l) {
      return Container(
        color: _bg,
      );
    }
    return AnimatedBuilder(
      animation: _orbRotate,
      builder: (_, __) {
        final t = _orbRotate.value * 2 * math.pi;
        return Stack(children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.5),
                radius: 1.5,
                colors: [const Color(0xFF1A0A08), _bg],
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
      elevation: collapsed ? 2 : 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _l ? const Color(0xFFFEE2E2) : Colors.black38,
              border: Border.all(color: _crimson.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: _crimson, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroHeader(),
        title: collapsed
            ? Text(widget.name,
            style: TextStyle(
                color: _crimson, fontSize: 17, fontWeight: FontWeight.bold))
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
              ? [const Color(0xFFFEE2E2), const Color(0xFFF8F6F0)]
              : [const Color(0xFF1A0808), const Color(0xFF080C18)],
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
                      _crimson.withValues(alpha: 0.25 + 0.1 * _shimmer.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _l ? const Color(0xFFFEE2E2) : const Color(0xFF1A0808),
                    border: Border.all(
                      color: _crimson.withValues(alpha: 0.5 + 0.3 * _shimmer.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(color: _crimson.withValues(alpha: _l ? 0.15 : 0.4), blurRadius: 20),
                    ],
                  ),
                  child: Icon(Icons.local_fire_department_rounded, color: _crimsonLt, size: 36),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(widget.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMuted, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _pill(Icons.calendar_today_rounded, widget.date, _gold),
              _pill(Icons.location_on_rounded, widget.location, _crimsonLt),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: _l ? 0.10 : 0.12),
        border: Border.all(color: color.withValues(alpha: _l ? 0.35 : 0.3)),
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
    final colorL = _muslimWon ? (_l ? _green : const Color(0xFF52D68A)) : _crimsonLt;
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
                color.withValues(alpha: _l ? 0.12 : (0.18 + 0.06 * _shimmer.value)),
                color.withValues(alpha: _l ? 0.04 : 0.05),
              ],
              begin: Alignment.centerRight, end: Alignment.centerLeft,
            ),
            border: Border.all(color: color.withValues(alpha: _l ? 0.35 : 0.35)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: _l ? 0.06 : 0.15), blurRadius: 16),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorL, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorL,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
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
        color: _surface,
        border: Border.all(color: _l ? _cardBorder : color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _l ? 0.04 : 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _l ? _text : color, fontSize: 15, fontWeight: FontWeight.bold)),
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
          Container(width: 1, height: 60, color: _l ? _cardBorder : const Color(0xFF2A2416)),
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
        Text(title, style: TextStyle(color: _textMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(color: _l ? _text : color, fontSize: 14.5, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── CASUALTIES CARD ───────────────────────────────────
  Widget _buildCasualtiesCard() {
    final mC = widget.muslimCasualties;
    final eC = widget.enemyCasualties;

    final mVal = mC is int ? mC : int.tryParse(mC.toString()) ?? 0;
    final eVal = eC is int ? eC : int.tryParse(eC.toString()) ?? 0;
    final total = mVal + eVal;
    final mRatio = total > 0 ? mVal / total : 0.5;

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
        color: color.withValues(alpha: _l ? 0.08 : 0.08),
        border: Border.all(color: color.withValues(alpha: _l ? 0.3 : 0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
                color: _gold.withValues(alpha: _l ? 0.08 : 0.1),
                border: Border.all(color: _gold.withValues(alpha: _l ? 0.35 : 0.25)),
              ),
              child: Text(p, style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ]),
      ),
    );
  }

  // ── AHDAS / STORY CARD ────────────────────────────────
  Widget _buildAhdasCard() {
    final paragraphs = widget.ahdas
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
                colors: [Color(0xFF140A08), Color(0xFF0A0F1A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: _l ? _cardBorder : _crimson.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _l
                ? Colors.black.withValues(alpha: 0.04)
                : _crimson.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          if (!_l)
            BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: _l ? const Color(0xFFFEF2F2) : null,
            gradient: _l
                ? null
                : LinearGradient(
                    colors: [_crimson.withValues(alpha: 0.2), _crimson.withValues(alpha: 0.04)],
                  ),
          ),
          child: Row(children: [
            Icon(Icons.history_edu_rounded, color: _crimson, size: 22),
            const SizedBox(width: 10),
            Text(
              "أحداث ورواية الغزوة",
              style: TextStyle(
                color: _crimson,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _BattleBookReaderPage(
                    name: widget.name,
                    story: widget.ahdas,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _crimson.withValues(alpha: _l ? 0.1 : 0.2),
                  border: Border.all(color: _crimson.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, color: _crimson, size: 16),
                    const SizedBox(width: 5),
                    Text("وضع القراءة",
                        style: TextStyle(
                            color: _crimson,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: _l ? _cardBorder : _crimson.withValues(alpha: 0.1)),
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
                        color: _crimson.withValues(alpha: _l ? 0.08 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          right: BorderSide(
                              color: _crimson.withValues(alpha: 0.7), width: 3),
                        ),
                      )
                    : null,
                child: Text(
                  p,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: isHeader ? _crimson : _text,
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

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [_gold, _goldLight],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(icon, color: _gold, size: 20),
      const SizedBox(width: 10),
      Text(text,
          style: TextStyle(
              color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
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
    final l = ThemeProvider.instance.isLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: l ? const Color(0xFFFFFFFF) : const Color(0xFF0F1525),
        border: Border.all(
          color: l ? const Color(0xFFE5E7EB) : const Color(0xFF1E2535),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: l ? 0.04 : 0.5),
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

    const spacing = 45.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════
//  BATTLE FULL-SCREEN BOOK READER
// ══════════════════════════════════════════════════════════
class _BattleBookReaderPage extends StatelessWidget {
  final String name;
  final String story;

  const _BattleBookReaderPage({
    required this.name,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    final l = ThemeProvider.instance.isLight;
    final bg = l ? const Color(0xFFF8F6F0) : const Color(0xFF080C18);
    final cardBg = l ? const Color(0xFFFFFFFF) : const Color(0xFF0F1525);
    final cardBorder = l ? const Color(0xFFE5E7EB) : const Color(0xFFC0392B).withValues(alpha: 0.08);
    final text = l ? const Color(0xFF111827) : const Color(0xFFF0EAD6);
    final crimson = l ? const Color(0xFFB91C1C) : const Color(0xFFE74C3C);

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
                      color: crimson.withValues(alpha: 0.15),
                      border: Border.all(
                        color: crimson.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: crimson,
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
                            crimson.withValues(alpha: l ? 0.08 : 0.22),
                            bg,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Opacity(
                        opacity: l ? 0.06 : 0.12,
                        child: Icon(Icons.history_edu_rounded,
                            size: 80, color: crimson),
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
                        color: crimson.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: crimson.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: crimson, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "وقائع وأحداث الغزوة — رواية تاريخية موثقة",
                              style: TextStyle(
                                color: crimson,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...paragraphs.map((p) => _buildParagraphCard(p, cardBg, cardBorder, text, crimson, l)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraphCard(String p, Color cardBg, Color cardBorder, Color text, Color crimson, bool l) {
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
          color: isHeader ? crimson.withValues(alpha: 0.4) : cardBorder,
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
          color: isHeader ? crimson : text,
          fontSize: 16.5,
          height: 2.1,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
