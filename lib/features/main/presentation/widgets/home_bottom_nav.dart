import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';

import '../controllers/home_controller.dart';

class _NavDest {
  const _NavDest(this.icon, this.label);
  final IconData icon;
  final String label;
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
    final loc = AppLocalizations.of(context)!;
    final items = [
      _NavDest(Icons.groups_rounded, loc.nav_companions),
      _NavDest(Icons.military_tech_rounded, loc.nav_battles),
      _NavDest(Icons.auto_awesome_rounded, loc.nav_prophet),
      _NavDest(Icons.explore_rounded, loc.nav_guide),
      _NavDest(Icons.favorite_rounded, loc.nav_deeds),
    ];

    return SizeTransition(
      sizeFactor: sizeFactor,
      axisAlignment: 1,
      child: GlassPanel(
        radius: 0,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavTab(
                item: items[i],
                selected: controller.tabIndex == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setTab(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavDest item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentDim.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accentDim.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: selected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeNavToggle extends StatelessWidget {
  const HomeNavToggle({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.toggleNavBar();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          controller.showNavBar
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }
}
