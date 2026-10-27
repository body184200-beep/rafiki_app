
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppSpacing.radiusLg,
    this.borderColor,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final light = ThemeProvider.instance.isLight;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background ??
            (light ? Colors.white : Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              (light
                  ? const Color(0xFFE5E7EB)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: child,
    );
  }
}

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

void pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(AppPageRoute(page: page));
}
