import 'dart:math';
import 'package:flutter/material.dart';

/// Authentic Islamic Mushaf Frame CustomPainter
/// Draws the ornate dual-line borders, Islamic arabesque corners,
/// top header cartouches (Surah / Juz banners), and bottom page number bracket.
class MushafFramePainter extends CustomPainter {
  final Color primaryColor; // Islamic Teal / Slate
  final Color accentColor;  // Gold / Bronze
  final Color innerBgColor; // Parchment / Paper
  final bool isDark;

  const MushafFramePainter({
    required this.primaryColor,
    required this.accentColor,
    required this.innerBgColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const margin = 10.0;
    const outerRadius = 14.0;
    const innerRadius = 8.0;

    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2),
      const Radius.circular(outerRadius),
    );

    // 1. Outer decorative scalloped / dual border
    final outerPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.6 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRRect(outerRect, outerPaint);

    // 2. Middle gold accent line
    final midPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.5 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final midRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin + 3.5, margin + 3.5, w - (margin + 3.5) * 2, h - (margin + 3.5) * 2),
      const Radius.circular(outerRadius - 2),
    );
    canvas.drawRRect(midRect, midPaint);

    // 3. Inner fine teal border
    final innerPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.4 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin + 6.5, margin + 6.5, w - (margin + 6.5) * 2, h - (margin + 6.5) * 2),
      const Radius.circular(innerRadius),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // 4. Draw 4 Corner Arabesque Ornaments
    _drawCornerOrnament(canvas, margin + 6.5, margin + 6.5, 0); // Top-Left
    _drawCornerOrnament(canvas, w - margin - 6.5, margin + 6.5, pi / 2); // Top-Right
    _drawCornerOrnament(canvas, w - margin - 6.5, h - margin - 6.5, pi); // Bottom-Right
    _drawCornerOrnament(canvas, margin + 6.5, h - margin - 6.5, -pi / 2); // Bottom-Left

    // 5. Draw decorative header division line
    const headerH = 46.0;
    final headerDividerY = margin + headerH;
    final divPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.35 : 0.5)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(margin + 8, headerDividerY),
      Offset(w - margin - 8, headerDividerY),
      divPaint,
    );

    // 6. Draw decorative footer division line
    const footerH = 42.0;
    final footerDividerY = h - margin - footerH;
    canvas.drawLine(
      Offset(margin + 8, footerDividerY),
      Offset(w - margin - 8, footerDividerY),
      divPaint,
    );

    // 7. Small Islamic rosettes on horizontal dividers
    _drawSmallRosette(canvas, w / 2, headerDividerY);
    _drawSmallRosette(canvas, w / 2, footerDividerY);
  }

  void _drawCornerOrnament(Canvas canvas, double x, double y, double rotation) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final p = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.7 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillP = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.25 : 0.2)
      ..style = PaintingStyle.fill;

    // Corner Islamic stepped / arched petal
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(14, 0)
      ..quadraticBezierTo(10, 10, 0, 14)
      ..close();

    canvas.drawPath(path, fillP);
    canvas.drawPath(path, p);

    // Small inner diagonal leaf
    final leaf = Path()
      ..moveTo(0, 0)
      ..lineTo(7, 0)
      ..quadraticBezierTo(4, 4, 0, 7)
      ..close();
    canvas.drawPath(leaf, p);

    canvas.restore();
  }

  void _drawSmallRosette(Canvas canvas, double cx, double cy) {
    final p = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.6 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final fillP = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.4 : 0.3)
      ..style = PaintingStyle.fill;

    const r = 3.5;
    // Diamond motif
    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();

    canvas.drawPath(diamond, fillP);
    canvas.drawPath(diamond, p);
  }

  @override
  bool shouldRepaint(covariant MushafFramePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.innerBgColor != innerBgColor ||
        oldDelegate.isDark != isDark;
  }
}
