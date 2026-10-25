import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';
import 'package:rafiki_app/features/guide/presentation/pages/adeia_page.dart';
import 'package:rafiki_app/features/hadith/presentation/pages/hadith_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/podcast_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/reciters_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/sunnah_page.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  Qu  –  Islamic Educational Hub
// ─────────────────────────────────────────────────────────────────────────────

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Controllers ──────────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _starCtrl;
  late final AnimationController _pulseCtrl;

  // ── Palette ──────────────────────────────────────────────────────────────────
  static const Color _bgDeep    = Color(0xff020A12);
  static const Color _bgMid     = Color(0xff071829);
  static const Color _gold      = Color(0xffC9A84C);
  static const Color _goldGlow  = Color(0xffF5D882);
  static const Color _goldDark  = Color(0xff8B6914);
  static const Color _textMain  = Color(0xffEEE8D5);
  static const Color _textSub   = Color(0xff7A9AAD);


  // ── Stars ─────────────────────────────────────────────────────────────────────
  late final List<_Star> _stars;

  // ── Cards ─────────────────────────────────────────────────────────────────────
  late final List<_CardData> _cards;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final rng = Random(42);
    // Three depth layers: distant (small, dim), mid, near (large, bright)
    _stars = [
      // distant
      ...List.generate(30, (_) => _Star(
        x: rng.nextDouble(), y: rng.nextDouble(),
        r: 0.4 + rng.nextDouble() * 0.5,
        phase: rng.nextDouble(),
        layer: 0,
      )),
      // mid
      ...List.generate(18, (_) => _Star(
        x: rng.nextDouble(), y: rng.nextDouble(),
        r: 0.9 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble(),
        layer: 1,
      )),
      // near
      ...List.generate(7, (_) => _Star(
        x: rng.nextDouble(), y: rng.nextDouble(),
        r: 1.6 + rng.nextDouble() * 1.0,
        phase: rng.nextDouble(),
        layer: 2,
      )),
    ];

    _cards = [
      _CardData(
        title: "مجتمع القراء",
        subtitle: "أساطير القراءة عبر التاريخ الإسلامي",
        icon: Icons.menu_book_rounded,
        accentA: const Color(0xff0D5C61),
        accentB: const Color(0xff12C4A0),
        arabicLabel: "تفسير",
        destination: () => RecitersPage(),
      ),
      _CardData(
        title: "بودكاست إسلامي",
        subtitle: "سلاسل صوتية وبرامج دينية لنخبة من كبار الدعاة",
        icon: Icons.podcasts_rounded,
        accentA: const Color(0xff1A2560),
        accentB: const Color(0xff6C82FF),
        arabicLabel: "بودكاست",
        destination: () => const PrayerPodcastPage(),
      ),
      _CardData(
        title: "الأحاديث النبوية",
        subtitle: "أحاديث مختارة من كتب السنة المعتمدة",
        icon: Icons.auto_stories_rounded,
        accentA: const Color(0xff6B3000),
        accentB: const Color(0xffF0953A),
        arabicLabel: "حديث",
        destination: () => HadithScreen(),
      ),
      _CardData(
        title: "سنة الرسول ﷺ",
        subtitle: "هديه وسيرته وأخلاقه الشريفة",
        icon: Icons.history_edu_rounded,
        accentA: const Color(0xff5C0A30),
        accentB: const Color(0xffE8417A),
        arabicLabel: "سنة",
        destination: () => SunnahPage(),
      ),
      _CardData(
        title: "الأدعية والأذكار",
        subtitle: "أدعية مأثورة وأذكار يومية مباركة",
        icon: Icons.volunteer_activism_rounded,
        accentA: const Color(0xff1A5C30),
        accentB: const Color(0xff2ECC71),
        arabicLabel: "دعاء",
        destination: () => AdeiaPage(),
      ),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _starCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context)) {
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
      if (!_starCtrl.isAnimating) _starCtrl.repeat(reverse: true);
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      if (_bgCtrl.isAnimating) _bgCtrl.stop();
      if (_starCtrl.isAnimating) _starCtrl.stop();
      if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!TickerMode.of(context)) return;
      if (!_bgCtrl.isAnimating) _bgCtrl.repeat(reverse: true);
      if (!_starCtrl.isAnimating) _starCtrl.repeat(reverse: true);
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _bgCtrl.stop();
      _starCtrl.stop();
      _pulseCtrl.stop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgDeep,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [_goldDark, _gold, _goldGlow, _gold],
              stops: [0, 0.3, 0.6, 1],
            ).createShader(r),
            child: const Text(
              "✦  رفيقي  ✦",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // ── Animated gradient background ───────────────────────────────────
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        -0.4 + _bgCtrl.value * 0.8,
                        -0.6 + _bgCtrl.value * 0.4,
                      ),
                      radius: 1.6,
                      colors: const [
                        Color(0xff0A2035),
                        Color(0xff041018),
                        _bgDeep,
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),

            // ── Star field (layered depth) ─────────────────────────────────────
            AnimatedBuilder(
              animation: _starCtrl,
              builder: (_, __) => Positioned.fill(
                child: CustomPaint(
                  painter: _StarFieldPainter(
                    stars: _stars,
                    twinkle: _starCtrl.value,
                  ),
                ),
              ),
            ),

            // ── Crescent motif ─────────────────────────────────────────────────
            Positioned(
              top: -20,
              left: -40,
              child: _CrescentPainterWidget(
                color: _gold.withValues(alpha: 0.07),
                bgColor: _bgDeep,
                size: 280,
              ),
            ),

            // ── Ambient glow blobs ─────────────────────────────────────────────
            Positioned(
              top: 80,
              right: -100,
              child: _GlowBlob(
                color: const Color(0xff0D5C61).withValues(alpha: 0.18),
                size: 320,
              ),
            ),
            Positioned(
              bottom: 60,
              left: -80,
              child: _GlowBlob(
                color: const Color(0xff6C82FF).withValues(alpha: 0.12),
                size: 280,
              ),
            ),
            Positioned(
              bottom: 200,
              right: -60,
              child: _GlowBlob(
                color: const Color(0xff2ECC71).withValues(alpha: 0.07),
                size: 200,
              ),
            ),

            // ── Content ────────────────────────────────────────────────────────
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildAyahBanner(),
                        const SizedBox(height: 20),
                        _buildSectionLabel("استكشف المحتوى"),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final card = _cards[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FadeSlide(
                              animation: _entryCtrl,
                              delay: 0.20 + i * 0.10,
                              child: _ContentCard(
                                data: card,
                                index: i,
                                onTap: () => pushPage(
                                  context,
                                  card.destination(),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _cards.length,
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

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return _FadeSlide(
      animation: _entryCtrl,
      delay: 0.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: _gold.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Gold moon badge
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_gold, _goldGlow],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(
                                alpha: 0.3 + 0.2 * _pulseCtrl.value),
                            blurRadius: 18 + 8 * _pulseCtrl.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: const Center(
                      child: Text("☽",
                          style: TextStyle(fontSize: 24, color: Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "أهلاً وسهلاً ❤️",
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "رحلتك الإسلامية التفاعلية تبدأ هنا ✨",
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
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

  // ── Ayah banner ───────────────────────────────────────────────────────────────
  Widget _buildAyahBanner() {
    return _FadeSlide(
      animation: _entryCtrl,
      delay: 0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              _goldDark.withValues(alpha: 0.28),
              _bgMid.withValues(alpha: 0.40),
            ],
          ),
          border: Border.all(color: _gold.withValues(alpha: 0.28), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border:
                    Border.all(color: _gold.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    "آية اليوم",
                    style: TextStyle(
                      color: _goldGlow,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "﴿ إِنَّ مَعَ الْعُسْرِ يُسْرًا ﴾",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.6,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "سورة الشرح — الآية ٦",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSub,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return _FadeSlide(
      animation: _entryCtrl,
      delay: 0.14,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_gold, _goldDark],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: _textMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            "${_cards.length} أقسام",
            style: const TextStyle(
              color: _textSub,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────────────────────

class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentA;
  final Color accentB;
  final String arabicLabel;
  final Widget Function() destination;

  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentA,
    required this.accentB,
    required this.arabicLabel,
    required this.destination,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Content Card  – enhanced with shimmer top line + numbered index badge
// ─────────────────────────────────────────────────────────────────────────────

class _ContentCard extends StatefulWidget {
  final _CardData data;
  final int index;
  final VoidCallback onTap;

  const _ContentCard({
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.965)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    HapticFeedback.selectionClick();
    _pressCtrl.forward();
  }

  void _onTapUp(_) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    d.accentA.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.04),
                    d.accentB.withValues(alpha: 0.06),
                  ],
                  stops: const [0, 0.5, 1],
                ),
                border: Border.all(color: d.accentB.withValues(alpha: 0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: d.accentA.withValues(alpha: 0.20),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top shimmer line ──────────────────────────────────────────
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          d.accentB.withValues(alpha: 0.7),
                          d.accentB.withValues(alpha: 0.9),
                          d.accentB.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.2, 0.5, 0.8, 1],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        // ── Icon bubble ───────────────────────────────────────
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [d.accentA, d.accentB],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: d.accentB.withValues(alpha: 0.50),
                                    blurRadius: 22,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(d.icon,
                                  color: Colors.white, size: 28),
                            ),
                            // Number badge
                            Positioned(
                              bottom: -2,
                              left: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xff020A12),
                                  border: Border.all(
                                      color: d.accentB.withValues(alpha: 0.5),
                                      width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    "${widget.index + 1}",
                                    style: TextStyle(
                                      color: d.accentB,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // ── Text ──────────────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: d.accentB.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  d.arabicLabel,
                                  style: TextStyle(
                                    color: d.accentB,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d.title,
                                style: const TextStyle(
                                  color: Color(0xffEEE8D5),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.subtitle,
                                style: const TextStyle(
                                  color: Color(0xff7A9AAD),
                                  fontSize: 11.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ── Arrow badge (RTL: pointing left) ─────────────────
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                d.accentA.withValues(alpha: 0.6),
                                d.accentB.withValues(alpha: 0.35),
                              ],
                            ),
                            border: Border.all(
                                color: d.accentB.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded, // ← RTL correct
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
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
//  _FadeSlide  –  staggered entrance animation
// ─────────────────────────────────────────────────────────────────────────────

class _FadeSlide extends StatefulWidget {
  final AnimationController animation;
  final double delay;
  final Widget child;

  const _FadeSlide({
    required this.animation,
    required this.delay,
    required this.child,
  });

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide> {
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    final start = widget.delay.clamp(0.0, 0.88);
    final end   = (widget.delay + 0.38).clamp(0.0, 1.0);
    _curved = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GlowBlob
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

// ─────────────────────────────────────────────────────────────────────────────
//  _CrescentPainterWidget
// ─────────────────────────────────────────────────────────────────────────────

class _CrescentPainterWidget extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final double size;

  const _CrescentPainterWidget({
    required this.color,
    required this.bgColor,
    required this.size,
  });

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
  bool shouldRepaint(_CrescentPainter old) =>
      old.color != color || old.bgColor != bgColor;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _Star  +  _StarFieldPainter  (layered depth)
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, phase;
  final int layer; // 0=distant 1=mid 2=near

  const _Star({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.layer,
  });
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkle;

  // Base opacity by layer: distant very dim, near bright
  static const _baseOpacity = [0.12, 0.28, 0.60];
  static const _twinkleAmp  = [0.10, 0.25, 0.35];

  const _StarFieldPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final base = _baseOpacity[s.layer];
      final amp  = _twinkleAmp[s.layer];
      final opacity = (base + amp * sin((twinkle + s.phase) * 2 * pi))
          .clamp(0.0, 1.0);

      // Near stars get a soft halo
      if (s.layer == 2) {
        canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height),
          s.r * 2.5,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.twinkle != twinkle;
}