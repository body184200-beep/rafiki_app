import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Coordinates? _coords;
  double _qiblaDirection = 136.0;
  double _distanceKm = 0.0;
  bool _loading = true;

  // Compass sensor state
  StreamSubscription<CompassEvent>? _compassSub;
  double _currentHeading = 0.0;
  double? _targetHeading;
  bool _hasCompass = true;
  bool _isAligned = false;
  bool _wasAligned = false;

  // Kaaba Coordinates in Makkah
  static const double _makkahLat = 21.422487;
  static const double _makkahLng = 39.826206;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadQiblaData();
    _initCompass();
  }

  Future<void> _loadQiblaData() async {
    try {
      Position? pos;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        }
      }

      final double lat = pos?.latitude ?? (await PrayerConfig.getCoordinates()).latitude;
      final double lng = pos?.longitude ?? (await PrayerConfig.getCoordinates()).longitude;

      if (pos != null) {
        await PrayerConfig.saveCoordinates(lat, lng);
      }

      final coords = Coordinates(lat, lng);
      final qibla = Qibla(coords);
      final dist = _calculateDistanceKm(lat, lng, _makkahLat, _makkahLng);

      if (mounted) {
        setState(() {
          _coords = coords;
          _qiblaDirection = qibla.direction;
          _distanceKm = dist;
          _loading = false;
        });
      }
    } catch (_) {
      final fallbackCoords = await PrayerConfig.getCoordinates();
      final qibla = Qibla(fallbackCoords);
      if (mounted) {
        setState(() {
          _coords = fallbackCoords;
          _qiblaDirection = qibla.direction;
          _loading = false;
        });
      }
    }
  }

  void _initCompass() {
    try {
      _compassSub = FlutterCompass.events?.listen(
        (CompassEvent event) {
          if (!mounted) return;
          final rawHeading = event.heading;
          if (rawHeading != null) {
            // Normalize heading to [0, 360)
            final normalized = (rawHeading % 360 + 360) % 360;

            // Shortest signed difference to Kaaba: (-180, 180]
            final diff = ((_qiblaDirection - normalized + 540) % 360) - 180;
            final aligned = diff.abs() <= 3.5;

            if (aligned && !_wasAligned) {
              HapticFeedback.mediumImpact();
            }
            _wasAligned = aligned;

            setState(() {
              _targetHeading = normalized;
              // Smooth low-pass interpolation
              _currentHeading = _smoothHeading(_currentHeading, normalized);
              _isAligned = aligned;
              _hasCompass = true;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _hasCompass = false);
        },
      );
    } catch (_) {
      _hasCompass = false;
    }
  }

  double _smoothHeading(double current, double target) {
    double diff = ((target - current + 540) % 360) - 180;
    return (current + diff * 0.35) % 360;
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  String _getDirectionCardinal(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'شمال';
    if (deg >= 22.5 && deg < 67.5) return 'شمال شرق';
    if (deg >= 67.5 && deg < 112.5) return 'شرق';
    if (deg >= 112.5 && deg < 157.5) return 'جنوب شرق';
    if (deg >= 157.5 && deg < 202.5) return 'جنوب';
    if (deg >= 202.5 && deg < 247.5) return 'جنوب غرب';
    if (deg >= 247.5 && deg < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final heading = _targetHeading ?? _currentHeading;
        final turnDiff = ((_qiblaDirection - heading + 540) % 360) - 180;

        return Scaffold(
          backgroundColor: isLight ? const Color(0xFFF8F6F0) : const Color(0xFF070A12),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'القبلة الشريفة',
              style: TextStyle(
                color: isLight ? const Color(0xFF111827) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0E1728),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2A45),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLight ? const Color(0xFF111827) : const Color(0xFF8DA3C4),
                  size: 16,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // Top Info Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFE1F0F9) : const Color(0xFF0C1C2C),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isLight ? const Color(0xFFC7E6F3) : const Color(0xFF173B5B),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.explore_outlined, color: Color(0xFF38BDF8), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'اتجاه القبلة نحو مكة المكرمة',
                                      style: TextStyle(
                                        color: isLight ? const Color(0xFF111827) : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_qiblaDirection.toStringAsFixed(1)}° ${_getDirectionCardinal(_qiblaDirection)} • ${_distanceKm.toStringAsFixed(0)} كم',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Guidance Turn Indicator Pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAligned
                                ? const Color(0xFF10B981).withValues(alpha: 0.22)
                                : (isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728)),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isAligned
                                  ? const Color(0xFF10B981)
                                  : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1D2E4D)),
                              width: _isAligned ? 1.8 : 1,
                            ),
                            boxShadow: _isAligned
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAligned
                                    ? Icons.check_circle_rounded
                                    : (turnDiff > 0 ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded),
                                color: _isAligned
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF38BDF8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAligned
                                    ? 'أنت باتجاه القبلة الشريفة تماماً 🕋'
                                    : (turnDiff > 0
                                        ? 'أدر هاتفك يميناً ${turnDiff.round()}°'
                                        : 'أدر هاتفك يساراً ${turnDiff.abs().round()}°'),
                                style: TextStyle(
                                  color: _isAligned
                                      ? const Color(0xFF10B981)
                                      : (isLight ? const Color(0xFF111827) : const Color(0xFFCAD5E2)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Compass Dial View
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Top Alignment Triangle (Phone Header Marker)
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: 14,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _isAligned ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isAligned ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                                            .withValues(alpha: 0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Outer Pulse Glow
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, _) {
                                  final pulseColor = _isAligned
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF38BDF8);
                                  return Container(
                                    width: 284 + (_pulseCtrl.value * 12),
                                    height: 284 + (_pulseCtrl.value * 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: pulseColor.withValues(alpha: 0.12 + (_pulseCtrl.value * 0.15)),
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Mathematical High-Precision Custom Compass Painter
                              Container(
                                width: 270,
                                height: 270,
                                margin: const EdgeInsets.only(top: 8),
                                child: CustomPaint(
                                  painter: QiblaCompassPainter(
                                    heading: heading,
                                    qiblaDirection: _qiblaDirection,
                                    isAligned: _isAligned,
                                    isLight: isLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Instruction Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isAligned
                                ? (isLight ? const Color(0xFFE8FDF2) : const Color(0xFF072718))
                                : (isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1728)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isAligned
                                  ? const Color(0xFF10B981)
                                  : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1D2E4D)),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isAligned ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                color: _isAligned ? const Color(0xFF10B981) : const Color(0xFF3CD2A2),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isAligned
                                      ? 'أنت الآن باتجاه الكعبة المشرفة تماماً، تقبّل الله صلاتكم وطاعتكم.'
                                      : 'امسك هاتفك أفقياً ومستوياً في يدك، وقم بتدوير جسدك حتى يتطابق المؤشر العلوي مع علامة الكعبة بدقة.',
                                  style: TextStyle(
                                    color: isLight ? const Color(0xFF374151) : const Color(0xFFCAD5E2),
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: _isAligned ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!_hasCompass) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'حساس البوصلة غير متوفر أو يحتاج للمعايرة. قم بتحريك الهاتف في الهواء على شكل رقم 8.',
                                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class QiblaCompassPainter extends CustomPainter {
  final double heading; // phone heading in degrees [0, 360)
  final double qiblaDirection; // Qibla azimuth from North in degrees [0, 360)
  final bool isAligned;
  final bool isLight;

  QiblaCompassPainter({
    required this.heading,
    required this.qiblaDirection,
    required this.isAligned,
    required this.isLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dial base circle
    final bgPaint = Paint()
      ..color = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0C1425)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    // Subtle inner gradient
    final innerGrad = Paint()
      ..shader = RadialGradient(
        colors: [
          (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF131F38)).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 4));
    canvas.drawCircle(center, radius - 4, innerGrad);

    final borderPaint = Paint()
      ..color = isAligned
          ? const Color(0xFF10B981)
          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1E2E4A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 2.5 : 1.8;
    canvas.drawCircle(center, radius - 4, borderPaint);

    // Save canvas to rotate entire compass dial with phone heading
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);

    // 2. Draw degree tick marks
    final tickPaint = Paint()..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 5) {
      final rad = deg * math.pi / 180;
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;
      final tickLen = isCardinal ? 13.0 : (isMajor ? 8.0 : 4.5);

      tickPaint.color = isCardinal
          ? (deg == 0 ? const Color(0xFFEF4444) : (isLight ? const Color(0xFF6B7280) : const Color(0xFF8DA3C4)))
          : (isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2840));
      tickPaint.strokeWidth = isCardinal ? 2.2 : (isMajor ? 1.4 : 0.9);

      final outerX = (radius - 10) * math.sin(rad);
      final outerY = -(radius - 10) * math.cos(rad);
      final innerX = (radius - 10 - tickLen) * math.sin(rad);
      final innerY = -(radius - 10 - tickLen) * math.cos(rad);

      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // 3. Draw Cardinals: N, E, S, W
    void drawCardinal(String text, double angleDeg, Color color) {
      final rad = angleDeg * math.pi / 180;
      final dist = radius - 34;
      final x = dist * math.sin(rad);
      final y = -dist * math.cos(rad);

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(heading * math.pi / 180); // Keep cardinal letters upright
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    drawCardinal('N', 0, const Color(0xFFEF4444));
    drawCardinal('E', 90, isLight ? const Color(0xFF4B5563) : const Color(0xFF8DA3C4));
    drawCardinal('S', 180, isLight ? const Color(0xFF4B5563) : const Color(0xFF8DA3C4));
    drawCardinal('W', 270, isLight ? const Color(0xFF4B5563) : const Color(0xFF8DA3C4));

    // 4. Draw Kaaba Needle (pivoting with mathematical perfection at center!)
    canvas.save();
    canvas.rotate(qiblaDirection * math.pi / 180);

    final needleLength = radius - 44;
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isAligned ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
          isAligned ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(-3, -needleLength, 6, needleLength))
      ..style = PaintingStyle.fill;

    // Tapered needle shaft
    final needlePath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(3.2, -26)
      ..lineTo(1.5, 0)
      ..lineTo(-1.5, 0)
      ..lineTo(-3.2, -26)
      ..close();
    canvas.drawPath(needlePath, needlePaint);

    // Kaaba box at tip of needle
    final headCenter = Offset(0, -needleLength - 8);
    final boxPaint = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFF0F766E)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: headCenter, width: 24, height: 24),
        const Radius.circular(6),
      ),
      boxPaint,
    );

    // Gold Kiswa band
    final goldBand = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(headCenter.dx - 9, headCenter.dy - 8, 18, 3.5),
      goldBand,
    );

    canvas.restore(); // Restore needle rotation
    canvas.restore(); // Restore dial rotation

    // 5. Center metallic core hub
    final hubRadius = 24.0;
    final hubPaint = Paint()
      ..color = isLight ? const Color(0xFFF3F4F6) : const Color(0xFF111D32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubBorder = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, hubRadius, hubBorder);

    // Degree in center hub
    final degSpan = TextSpan(
      text: '${heading.round()}°',
      style: TextStyle(
        color: isLight ? const Color(0xFF111827) : Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final degTp = TextPainter(
      text: degSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    degTp.paint(canvas, Offset(center.dx - degTp.width / 2, center.dy - degTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter old) =>
      old.heading != heading ||
      old.qiblaDirection != qiblaDirection ||
      old.isAligned != isAligned ||
      old.isLight != isLight;
}
