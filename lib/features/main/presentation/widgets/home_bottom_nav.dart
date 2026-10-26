import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/theme/theme_provider.dart';
import '../controllers/home_controller.dart';

class _NavDest {
  const _NavDest(this.icon, this.label, {this.isTasbih = false});
  final IconData icon;
  final String label;
  final bool isTasbih;
}

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.controller,
    required this.sizeFactor,
  });

  final HomeController controller;
  final Animation<double> sizeFactor;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavDest(Icons.home_rounded, 'الرئيسية'),
      _NavDest(Icons.star_border_rounded, 'الرسول'),
      _NavDest(Icons.circle_outlined, 'السبحة', isTasbih: true),
      _NavDest(Icons.menu_book_rounded, 'القرآن الكريم'),
      _NavDest(Icons.graphic_eq_rounded, 'إذاعة القرآن'),
    ];

    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final navBg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF070B14);
        final navBorder = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF141D2D);

        return SizeTransition(
          sizeFactor: sizeFactor,
          axisAlignment: 1,
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(color: navBorder, width: 0.8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavTab(
                      item: items[i],
                      selected: controller.tabIndex == i,
                      isLight: isLight,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setTab(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.isLight,
    required this.onTap,
  });

  final _NavDest item;
  final bool selected;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isLight ? const Color(0xFF0F4A39) : const Color(0xFF3CD2A2);
    final inactiveColor = isLight ? const Color(0xFF64748B) : const Color(0xFF506882);
    final color = selected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.isTasbih)
              SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(
                  painter: _TasbihBeadsPainter(color: color),
                ),
              )
            else
              Icon(
                item.icon,
                size: 22,
                color: color,
              ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TasbihBeadsPainter extends CustomPainter {
  const _TasbihBeadsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;
    const beadsCount = 8;
    const beadRadius = 1.6;

    for (var i = 0; i < beadsCount; i++) {
      final angle = (i * 2 * math.pi / beadsCount) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), beadRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihBeadsPainter oldDelegate) =>
      color != oldDelegate.color;
}
