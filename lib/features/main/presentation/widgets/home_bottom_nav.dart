import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';

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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavTab(
                  item: items[i],
                  selected: controller.tabIndex == i,
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
    final activeColor = AppColors.accent;
    final inactiveColor = Colors.white.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: selected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? activeColor : inactiveColor,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? activeColor : Colors.transparent,
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
    return const SizedBox.shrink();
  }
}
