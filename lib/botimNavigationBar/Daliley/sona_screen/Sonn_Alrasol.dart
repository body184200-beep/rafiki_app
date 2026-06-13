import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../Daliley_page/dalieley_screen.dart';

// ─────────────────────────────────────────────
//  Color Palette
// ─────────────────────────────────────────────
class _Palette {
  static const bg0 = Color(0xFF080C14);
  static const bg1 = Color(0xFF0E1628);
  static const bg2 = Color(0xFF13203A);
  static const gold = Color(0xFFD4A847);
  static const goldLight = Color(0xFFF5D680);
  static const goldDim = Color(0xFF8A6A20);
  static const teal = Color(0xFF2BBFAA);
  static const tealDim = Color(0xFF1A7A6E);
  static const surface = Color(0xFF14213D);
  static const surfaceHigh = Color(0xFF1C2D50);
  static const textPrimary = Color(0xFFF0EAD6);
  static const textSecondary = Color(0xFFAEAA97);
}

// ─────────────────────────────────────────────
//  Sona Data Model
// ─────────────────────────────────────────────
class SonaItem {
  final String title;
  final String content;
  final IconData icon;
  final List<Color> gradient;

  const SonaItem({
    required this.title,
    required this.content,
    required this.icon,
    required this.gradient,
  });
}

// ─────────────────────────────────────────────
//  Main Widget
// ─────────────────────────────────────────────
class Sona extends StatefulWidget {
  const Sona({super.key});

  @override
  State<Sona> createState() => _SonaState();
}

class _SonaState extends State<Sona> with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _patternCtrl;

  static final List<SonaItem> sonaData = [
    SonaItem(
      title: "سنة النوم",
      content:
      "كان النبي ﷺ ينام على وضوء، ويقرأ آية الكرسي قبل النوم، وينام على جنبه الأيمن مستقبلًا القبلة.",
      icon: Icons.bedtime_rounded,
      gradient: [const Color(0xFF1A3A5C), const Color(0xFF0D2137)],
    ),
    SonaItem(
      title: "سنة الأكل",
      content:
      "كان النبي ﷺ يأكل بيمينه ويقول بسم الله، ويأكل مما يليه، ويحمد الله بعد الانتهاء.",
      icon: Icons.restaurant_rounded,
      gradient: [const Color(0xFF1A3A2E), const Color(0xFF0D2118)],
    ),
    SonaItem(
      title: "سنة الاستيقاظ",
      content:
      "الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور. وكان يمسح النوم عن وجهه ويستاك.",
      icon: Icons.wb_sunny_rounded,
      gradient: [const Color(0xFF3A2A10), const Color(0xFF211808)],
    ),
    SonaItem(
      title: "سنة دخول المنزل",
      content:
      "كان ﷺ يذكر الله عند دخوله ويسلم على أهل بيته، ويقول: اللهم إني أسألك خير المولج وخير المخرج.",
      icon: Icons.home_rounded,
      gradient: [const Color(0xFF2A1A3A), const Color(0xFF180D21)],
    ),
    SonaItem(
      title: "سنة الخروج",
      content:
      "بسم الله، توكلت على الله، ولا حول ولا قوة إلا بالله. وكان يخرج برجله اليسرى أولًا.",
      icon: Icons.directions_walk_rounded,
      gradient: [const Color(0xFF1A3A38), const Color(0xFF0D2120)],
    ),
    SonaItem(
      title: "سنة الصلاة",
      content:
      "كان ﷺ يحافظ على السنن الرواتب: ركعتان قبل الفجر، وأربع قبل الظهر وركعتان بعدها، وركعتان بعد المغرب والعشاء.",
      icon: Icons.mosque_rounded,
      gradient: [const Color(0xFF1A2E3A), const Color(0xFF0D1A21)],
    ),
    SonaItem(
      title: "سنة السلام",
      content:
      "كان ﷺ يبدأ الناس بالسلام ويبتسم في وجوههم، وقال: «لا تحقرنَّ من المعروف شيئًا ولو أن تلقى أخاك بوجه طلق».",
      icon: Icons.handshake_rounded,
      gradient: [const Color(0xFF1A3A20), const Color(0xFF0D2110)],
    ),
    SonaItem(
      title: "سنة اللباس",
      content:
      "كان ﷺ يبدأ باليمين عند لبس الثياب ويقول: الحمد لله الذي كساني هذا ورزقنيه من غير حول مني ولا قوة.",
      icon: Icons.checkroom_rounded,
      gradient: [const Color(0xFF2E1A3A), const Color(0xFF1A0D21)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _patternCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )
      ..repeat();

    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _patternCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _Palette.bg0,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _buildHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                          _SonaCard(
                            item: sonaData[index],
                            index: index,
                          ),
                      childCount: sonaData.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _Palette.gold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "السنن النبوية",
              style: TextStyle(
                color: _Palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _Palette.gold,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _Palette.surfaceHigh.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Palette.gold.withOpacity(0.2)),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(
                context,
                MaterialPageRoute(
                  builder: (_) => const Qu(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: _Palette.gold,
              size: 20,
            ),
          ),)
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _patternCtrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _IslamicPatternPainter(_patternCtrl.value),
          size: Size.infinite,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_Palette.bg0, _Palette.bg1, _Palette.bg2],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _Palette.goldDim.withOpacity(0.18),
                      _Palette.surfaceHigh.withOpacity(0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _Palette.gold.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    // Decorative star
                    _GoldStar(size: 36),
                    const SizedBox(height: 14),
                    const Text(
                      "سنن الرسول ﷺ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        color: _Palette.goldLight,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _Palette.gold,
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "اقتدِ بالنبي ﷺ في يومك كاملًا",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _Palette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        sonaData.length,
                            (i) =>
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2.5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == 0
                                    ? _Palette.gold
                                    : _Palette.gold.withOpacity(0.25),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sona Card
// ─────────────────────────────────────────────
class _SonaCard extends StatefulWidget {
  final SonaItem item;
  final int index;

  const _SonaCard({required this.item, required this.index});

  @override
  State<_SonaCard> createState() => _SonaCardState();
}

class _SonaCardState extends State<_SonaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 + widget.index * 80),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              _showSheet(context);
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: _buildCardBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _Palette.gold.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle geometric accent
            Positioned(
              right: -20,
              top: -20,
              child: _GeometricAccent(size: 100),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _Palette.gold.withOpacity(0.12),
                      border: Border.all(
                        color: _Palette.gold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: _Palette.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            color: _Palette.goldLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.item.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _Palette.textSecondary.withOpacity(0.8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _Palette.gold.withOpacity(0.12),
                      border: Border.all(
                          color: _Palette.gold.withOpacity(0.25), width: 1),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: _Palette.gold,
                      size: 20,
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

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SonaBottomSheet(item: widget.item),
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom Sheet
// ─────────────────────────────────────────────
class _SonaBottomSheet extends StatelessWidget {
  final SonaItem item;

  const _SonaBottomSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Palette.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
            decoration: BoxDecoration(
              color: _Palette.bg2.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: _Palette.gold.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _Palette.gold.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        _Palette.goldDim.withOpacity(0.3),
                        _Palette.gold.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _Palette.gold.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(item.icon, color: _Palette.gold, size: 28),
                ),
                // Title
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _Palette.goldLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                          color: _Palette.gold.withOpacity(0.2), height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _GoldStar(size: 14),
                    ),
                    Expanded(
                      child: Divider(
                          color: _Palette.gold.withOpacity(0.2), height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _Palette.surfaceHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _Palette.gold.withOpacity(0.12), width: 1),
                  ),
                  child: Text(
                    item.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _Palette.textPrimary,
                      fontSize: 17,
                      height: 1.8,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.goldDim,
                      foregroundColor: _Palette.bg0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "حفظ هذه السنة ✨",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ─────────────────────────────────────────────
//  Gold Star Widget
// ─────────────────────────────────────────────
class _GoldStar extends StatelessWidget {
  final double size;

  const _GoldStar({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Palette.gold
      ..style = PaintingStyle.fill;

    const points = 8;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.45;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  Geometric Accent (card overlay)
// ─────────────────────────────────────────────
class _GeometricAccent extends StatelessWidget {
  final double size;

  const _GeometricAccent({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GeometricPainter(),
    );
  }
}

class _GeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Palette.gold.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, i * size.width / 8, paint);
    }
    // Octagon
    final path = Path();
    const sides = 8;
    final r = size.width / 2;
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  Islamic Background Pattern
// ─────────────────────────────────────────────
class _IslamicPatternPainter extends CustomPainter {
  final double t;

  _IslamicPatternPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Palette.gold.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 80.0;
    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;

    // Slow drift
    final offsetX = (t * 20) % spacing;
    final offsetY = (t * 10) % spacing;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * spacing + offsetX;
        final cy = row * spacing + offsetY;
        _drawIslamicTile(canvas, paint, Offset(cx, cy), spacing * 0.45);
      }
    }
  }

  void _drawIslamicTile(Canvas canvas, Paint paint, Offset center,
      double radius) {
    const sides = 8;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner star lines
    for (int i = 0; i < sides; i++) {
      final a1 = (2 * pi * i / sides) - pi / 2;
      final a2 = (2 * pi * ((i + 2) % sides) / sides) - pi / 2;
      canvas.drawLine(
        Offset(center.dx + radius * cos(a1), center.dy + radius * sin(a1)),
        Offset(center.dx + radius * cos(a2), center.dy + radius * sin(a2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_IslamicPatternPainter old) => old.t != t;
}