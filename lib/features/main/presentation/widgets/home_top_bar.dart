import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';
import 'package:rafiki_app/features/azkar/presentation/pages/azkar_page.dart';
import 'package:rafiki_app/features/notification/presentation/pages/notification_page.dart';
import 'package:rafiki_app/features/quran/presentation/pages/quran_page.dart';
import 'package:rafiki_app/features/settings/presentation/pages/profile_page.dart';

import '../controllers/home_controller.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final light = ThemeProvider.instance.isLight;
    final label = light ? const Color(0xFF6B7280) : AppColors.textSecondary;
    final countdown = light ? const Color(0xFF0F4A39) : AppColors.accent;
    final icon = light ? const Color(0xFF0F4A39) : Colors.white.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            _IconBtn(
              icon: Icons.menu_book_rounded,
              color: icon,
              tooltip: loc.tooltip_quran,
              onTap: () => pushPage(context, const MushafPage()),
            ),
            _IconBtn(
              icon: Icons.auto_awesome_rounded,
              color: icon,
              tooltip: loc.tooltip_azkar,
              onTap: () => pushPage(context, const AzkarPage()),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.tooltip_next_prayer,
                    style: TextStyle(
                      color: label,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: controller.countdown,
                    builder: (_, value, __) => Text(
                      value.isEmpty ? '...' : value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: countdown,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _IconBtn(
              icon: Icons.notifications_rounded,
              color: icon,
              tooltip: loc.tooltip_notifications,
              onTap: () => pushPage(context, const NotificationPage()),
            ),
            _IconBtn(
              icon: Icons.person_rounded,
              color: icon,
              tooltip: loc.tooltip_settings,
              onTap: () => pushPage(context, const ProfilePage()),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accent.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
