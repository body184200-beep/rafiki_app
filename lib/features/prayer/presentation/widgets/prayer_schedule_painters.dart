import 'dart:math';
import 'package:flutter/material.dart';

class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const ArcProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      canvas.drawCircle(
        Offset(center.dx + radius * cos(angle),
            center.dy + radius * sin(angle)),
        5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(ArcProgressPainter old) =>
      old.progress != progress;
}

class BgPainter extends CustomPainter {
  final double t;
  const BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080D12),
            Color(0xFF0C1520),
            Color(0xFF080D12)
          ],
        ).createShader(
            Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final c1 = Offset(size.width * 0.85, size.height * 0.08 + sin(t * 2 * pi) * 25);
    canvas.drawCircle(
      c1,
      200,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2EC4A0).withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c1, radius: 200)),
    );
    final c2 = Offset(size.width * 0.1, size.height * 0.85 + cos(t * 2 * pi) * 20);
    canvas.drawCircle(
      c2,
      180,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD4A030).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c2, radius: 180)),
    );
    final dot =
    Paint()..color = Colors.white.withValues(alpha: 0.02);
    const s = 36.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(BgPainter old) => old.t != t;
}
