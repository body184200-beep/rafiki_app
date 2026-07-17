import 'dart:math';
import 'package:flutter/material.dart';

class ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  ArcPainter(this.progress, this.activeColor, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 6;
    const startAngle = -pi / 2;
    const sweepFull = 2 * pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull, false,
      Paint()
        ..color = trackColor.withValues(alpha: 0.18)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepFull * progress, false,
      Paint()
        ..color = activeColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip glow dot
    final angle = startAngle + sweepFull * progress;
    final dx = cx + radius * cos(angle);
    final dy = cy + radius * sin(angle);
    canvas.drawCircle(Offset(dx, dy), 6,
        Paint()..color = activeColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(dx, dy), 4, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(ArcPainter old) => old.progress != progress;
}

class RipplePainter extends CustomPainter {
  final double progress;
  final double burst;
  final Color jade;
  final Color gold;
  RipplePainter(this.progress, this.burst, this.jade, this.gold);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.width * 0.41;

    // Static glow
    canvas.drawCircle(center, baseR + 6,
        Paint()
          ..color = jade.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    if (progress > 0) {
      // Expanding ring
      final ringR = baseR + 20 + progress * 70;
      canvas.drawCircle(center, ringR,
          Paint()
            ..color = jade.withValues(alpha: (1 - progress) * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * (1 - progress));

      if (progress > 0.15) {
        final r2 = baseR + 6 + (progress - 0.15) * 45;
        canvas.drawCircle(center, r2,
            Paint()
              ..color = jade.withValues(alpha: (1 - progress) * 0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2 * (1 - progress));
      }
    }

    // Gold burst rings when target hit
    if (burst > 0) {
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.15;
        final p = (burst - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final r = baseR + 10 + p * (80 + i * 20);
        canvas.drawCircle(center, r,
            Paint()
              ..color = gold.withValues(alpha: (1 - p) * 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (2.5 - i * 0.5) * (1 - p));
      }
    }
  }

  @override
  bool shouldRepaint(RipplePainter old) =>
      old.progress != progress || old.burst != burst;
}

class Spark {
  final double angle;
  final double speed;
  final double radius;
  final bool isGold;
  Spark({required this.angle, required this.speed,
    required this.radius, required this.isGold});
}

class SparkPainter extends CustomPainter {
  final List<Spark> sparks;
  final double tapProg;
  final double burstProg;
  final Color jade;
  final Color gold;
  SparkPainter(this.sparks, this.tapProg, this.burstProg, {required this.jade, required this.gold});

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
      old.tapProg != tapProg || old.burstProg != burstProg ||
          old.sparks.length != sparks.length;
}
