import 'dart:math';
import 'package:flutter/material.dart';
import 'deeds_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ArcPainter – Circular Progress Arc with Glowing Tip
// ─────────────────────────────────────────────────────────────────────────────
class ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Color? glowColor;

  ArcPainter(
    this.progress,
    this.activeColor,
    this.trackColor, {
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;
    const startAngle = -pi / 2;
    const sweepFull = 2 * pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = trackColor.withValues(alpha: 0.15)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweep = (sweepFull * progress).clamp(0.0, sweepFull);

    // Progress Glow
    if (glowColor != null) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = (glowColor ?? activeColor).withValues(alpha: 0.35)
          ..strokeWidth = 7.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Main Progress Arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = activeColor
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip glow dot
    final angle = startAngle + sweep;
    final dx = cx + radius * cos(angle);
    final dy = cy + radius * sin(angle);
    canvas.drawCircle(
      Offset(dx, dy),
      6.5,
      Paint()
        ..color = (glowColor ?? activeColor).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(dx, dy),
      4.0,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(ArcPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MisbahaBeadRingPainter – 33 3D Spherical Gemstone Beads
// ─────────────────────────────────────────────────────────────────────────────
class MisbahaBeadRingPainter extends CustomPainter {
  final double rotation;
  final double progress;
  final int count;
  final MisbahaTheme theme;
  final double pulse;

  MisbahaBeadRingPainter({
    required this.rotation,
    required this.progress,
    required this.count,
    required this.theme,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = (size.width / 2) - 16;
    const totalBeads = 33;
    const stepAngle = (2 * pi) / totalBeads;

    // 1. Draw Braided Silk Thread with subtle shadow
    final threadShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center + const Offset(0, 2), ringRadius, threadShadow);

    final threadPaint = Paint()
      ..color = theme.threadColor.withValues(alpha: 0.70)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, ringRadius, threadPaint);

    // 2. Draw 33 Gemstone Beads with 3D Spherical Lighting
    for (int i = 0; i < totalBeads; i++) {
      final angle = (i * stepAngle) + rotation - (pi / 2);
      final bx = center.dx + ringRadius * cos(angle);
      final by = center.dy + ringRadius * sin(angle);
      final bCenter = Offset(bx, by);

      // Shahid (Separating) beads at positions 0, 11, 22
      final isShahid = (i == 0 || i == 11 || i == 22);
      final baseRadius = isShahid ? 11.5 : 9.5;
      final beadRadius = (i == 0) ? (baseRadius + pulse * 2.0) : baseRadius;

      // Drop shadow for bead
      canvas.drawCircle(
        bCenter + const Offset(1.5, 3.0),
        beadRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );

      // 3D Spherical Radial Gradient
      final gradientCenter = Offset(bx - beadRadius * 0.35, by - beadRadius * 0.35);

      final beadColors = isShahid
          ? [theme.accentLight, theme.accent, const Color(0xFF5A2A06)]
          : [theme.beadHighlight, theme.primaryLight, theme.primary, theme.primaryDark];

      final beadStops = isShahid
          ? const [0.0, 0.55, 1.0]
          : const [0.0, 0.35, 0.75, 1.0];

      final beadPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (gradientCenter.dx - bx) / beadRadius,
            (gradientCenter.dy - by) / beadRadius,
          ),
          radius: 0.95,
          colors: beadColors,
          stops: beadStops,
        ).createShader(Rect.fromCircle(center: bCenter, radius: beadRadius));

      canvas.drawCircle(bCenter, beadRadius, beadPaint);

      // Metallic golden rim on Shahid bead
      if (isShahid) {
        canvas.drawCircle(
          bCenter,
          beadRadius,
          Paint()
            ..color = theme.accentLight.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }

      // Specular highlight (reflective shine dot)
      final highlightPos = Offset(bx - beadRadius * 0.30, by - beadRadius * 0.30);
      canvas.drawCircle(
        highlightPos,
        beadRadius * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MisbahaBeadRingPainter old) =>
      old.rotation != rotation ||
      old.progress != progress ||
      old.count != count ||
      old.theme.id != theme.id ||
      old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
//  IslamicStarPainter – Eight-pointed Rosette in Counter Dial
// ─────────────────────────────────────────────────────────────────────────────
class IslamicStarPainter extends CustomPainter {
  final Color color;
  final double radius;

  IslamicStarPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw an eight-pointed star using two overlapping rotated squares
    final side = radius * 1.35;

    // Square 1
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: side, height: side), paint);

    // Square 2 (rotated 45 degrees)
    canvas.rotate(pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: side, height: side), paint);

    // Inner delicate circle
    canvas.drawCircle(Offset.zero, radius * 0.70, paint..strokeWidth = 0.8);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IslamicStarPainter old) =>
      old.color != color || old.radius != radius;
}

// ─────────────────────────────────────────────────────────────────────────────
//  RipplePainter – Expanding Waves on Tap
// ─────────────────────────────────────────────────────────────────────────────
class RipplePainter extends CustomPainter {
  final double progress;
  final double burst;
  final Color primary;
  final Color gold;

  RipplePainter(this.progress, this.burst, this.primary, this.gold);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.width * 0.36;

    // Static ambient aura
    canvas.drawCircle(
      center,
      baseR + 8,
      Paint()
        ..color = primary.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    if (progress > 0) {
      final ringR = baseR + 10 + progress * 60;
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = primary.withValues(alpha: (1 - progress) * 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1 - progress),
      );

      if (progress > 0.15) {
        final r2 = baseR + 5 + (progress - 0.15) * 40;
        canvas.drawCircle(
          center,
          r2,
          Paint()
            ..color = primary.withValues(alpha: (1 - progress) * 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3 * (1 - progress),
        );
      }
    }

    // Golden celebratory rings on target/cycle milestone
    if (burst > 0) {
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.15;
        final p = (burst - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final r = baseR + 10 + p * (80 + i * 25);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = gold.withValues(alpha: (1 - p) * 0.50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (2.6 - i * 0.5) * (1 - p),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RipplePainter old) =>
      old.progress != progress || old.burst != burst || old.primary != primary;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Spark & SparkPainter – Particle Effects
// ─────────────────────────────────────────────────────────────────────────────
class Spark {
  final double angle;
  final double speed;
  final double radius;
  final bool isGold;
  Spark({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.isGold,
  });
}

class SparkPainter extends CustomPainter {
  final List<Spark> sparks;
  final double tapProg;
  final double burstProg;
  final Color jade;
  final Color gold;

  SparkPainter(
    this.sparks,
    this.tapProg,
    this.burstProg, {
    required this.jade,
    required this.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in sparks) {
      final prog = s.isGold ? burstProg : tapProg;
      if (prog <= 0) continue;
      final dist = s.speed * prog;
      final dx = cos(s.angle) * dist;
      final dy = sin(s.angle) * dist;
      final opacity = (1 - prog).clamp(0.0, 1.0);
      final color = s.isGold ? gold : jade;
      canvas.drawCircle(
        center + Offset(dx, dy),
        s.radius * opacity,
        Paint()..color = color.withValues(alpha: opacity * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(SparkPainter old) =>
      old.tapProg != tapProg ||
      old.burstProg != burstProg ||
      old.sparks.length != sparks.length;
}
