import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';
import 'package:rafiki_app/core/widgets/pinned_header.dart';
import 'package:rafiki_app/core/widgets/segmented_tabs.dart';
import 'package:rafiki_app/features/battles/data/models/battle_model.dart';
import 'package:rafiki_app/features/battles/data/datasources/battles_list_data.dart';

import 'package:rafiki_app/features/battles/presentation/pages/battle_details_page.dart';

// ─── COLOUR TOKENS ────────────────────────────────────────────────────────────

class _C {
  static bool get _l => ThemeProvider.instance.isLight;
  static Color get bg        => _l ? const Color(0xFFF8F6F0) : const Color(0xFF0A0B0F);
  static Color get surface   => _l ? const Color(0xFFFFFFFF) : const Color(0xFF13161E);
  static Color get border    => _l ? const Color(0xFFE5E7EB) : const Color(0xFF242836);
  static Color get gold      => _l ? const Color(0xFF8D5B18) : const Color(0xFFD4A843);
  static Color get goldLight => _l ? const Color(0xFFB48216) : const Color(0xFFF0C870);

  static Color get sandDim   => _l ? const Color(0xFF6B7280) : const Color(0xFF9A8860);
  static Color get onCard    => _l ? const Color(0xFF111827) : const Color(0xFFF5EDD8);
  static Color get muted     => _l ? const Color(0xFF6B7280) : const Color(0xFF5A6070);
}

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────

class BattlesPage extends StatefulWidget {
  const BattlesPage({super.key});

  @override
  State<BattlesPage> createState() => BattlesPageState();
}

class BattlesPageState extends State<BattlesPage> with TickerProviderStateMixin {
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
    final activeList = _selectedTab == 0 ? battlesList : sarayaList;

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
                    delegate: PinnedHeader(
                      height: 66,
                      background: _C.bg,
                      child: _buildSegmentedControl(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSubheader(activeList.length),
                        SizedBox(height: 4),
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
    return SegmentedTabs(
      labels: ['غزوات الرسول ﷺ', 'السرايا والبعوث'],
      index: _selectedTab,
      onChanged: (i) => setState(() => _selectedTab = i),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 40),
              Expanded(
                child: Text(
                  "المعارك والبعوث النبوية",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _C.goldLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Color(0x33D4A843), blurRadius: 15)],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.maybePop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.gold.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _C.goldLight,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            "الجهاد النبوي لحفظ كيان الدولة والدعوة",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 12.5),
          ),
          SizedBox(height: 12),
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
            style: TextStyle(
              color: _C.sandDim,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.gold,
                  ),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "السيرة النبوية المشرفة",
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _C.sandDim,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GRID ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<Battle> list) {
    return GridView.builder(
      key: ValueKey("$_selectedTab"),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) {
        final delay = Duration(milliseconds: 60 * index);
        return BattleCard(
          battle: list[index],
          index: index,
          entryController: _entryCtrl,
          entryDelay: delay,
          onTap: () => pushPage(
            context,
            BattleDetails.fromName(list[index].name),
          ),
        );
      },
    );
  }
}

// ─── BATTLE CARD ─────────────────────────────────────────────────────────────

class BattleCard extends StatefulWidget {
  final Battle battle;
  final int index;
  final AnimationController entryController;
  final Duration entryDelay;
  final VoidCallback onTap;

  const BattleCard({
    super.key,
    required this.battle,
    required this.index,
    required this.entryController,
    required this.entryDelay,
    required this.onTap,
  });

  @override
  State<BattleCard> createState() => BattleCardState();
}

class BattleCardState extends State<BattleCard> with SingleTickerProviderStateMixin {
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
              color: b.accent.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
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
                    color: b.accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 3,
                  color: b.accent.withValues(alpha: 0.85),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b.emoji,
                            style: TextStyle(fontSize: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: b.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: b.accent.withValues(alpha: 0.35), width: 0.8),
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
                      SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            b.name,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _C.onCard,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: _C.muted, size: 10),
                          SizedBox(width: 5),
                          Text(
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
      child: RepaintBoundary(child: CustomPaint(painter: _BgPainter())),
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
        ..shader = LinearGradient(
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
          colors: [const Color(0xFFD4A843).withValues(alpha: 0.04), Colors.transparent],
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
