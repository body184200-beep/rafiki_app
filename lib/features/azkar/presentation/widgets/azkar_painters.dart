import 'dart:math';
import 'package:flutter/material.dart';

class ArcRingPainter extends CustomPainter {
  final double progress;
  final double animValue;
  final Color  goldColor;
  final Color  tealColor;
  final Color  bgColor;

  const ArcRingPainter({
    required this.progress,
    required this.animValue,
    required this.goldColor,
    required this.tealColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final radius = size.width  / 2 - 5;
    final stroke = 5.0;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = bgColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Progress arc (animated)
    final sweepAngle = 2 * pi * progress * animValue;
    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final arcColor = progress >= 1.0 ? tealColor : goldColor;

      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle:   -pi / 2 + sweepAngle,
          colors: [
            arcColor.withValues(alpha: 0.4),
            arcColor,
          ],
        ).createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);

      // Glow dot at tip
      if (sweepAngle > 0.1) {
        final tipAngle = -pi / 2 + sweepAngle;
        final tipX     = cx + radius * cos(tipAngle);
        final tipY     = cy + radius * sin(tipAngle);
        canvas.drawCircle(
          Offset(tipX, tipY),
          4.5,
          Paint()
            ..color     = arcColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          Offset(tipX, tipY),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArcRingPainter old) =>
      old.progress != progress || old.animValue != animValue;
}

class Star {
  final double x, y, r, phase;
  const Star({
    required this.x, required this.y,
    required this.r, required this.phase,
  });
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final double      twinkle;
  const StarPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity =
          0.12 + 0.5 * (0.5 + 0.5 * sin((twinkle + s.phase) * 2 * pi));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter old) => old.twinkle != twinkle;
}
