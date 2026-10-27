import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';
import 'package:rafiki_app/features/battles/presentation/pages/battles_page.dart';
import 'package:rafiki_app/features/companions/presentation/pages/companions_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/guide_page.dart';
import 'package:rafiki_app/features/main/presentation/controllers/home_controller.dart';
import 'package:rafiki_app/features/main/presentation/widgets/home_prayer_strip.dart';
import 'package:rafiki_app/features/main/presentation/widgets/home_top_bar.dart';
import 'package:rafiki_app/features/prayer/presentation/pages/prayer_schedule_page.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, ThemeProvider.instance]),
      builder: (context, _) {
        final light = ThemeProvider.instance.isLight;
        final text = light ? const Color(0xFF111827) : const Color(0xFFF3EEDD);
        final muted = light ? const Color(0xFF6B7280) : const Color(0xFF8B9CB2);
        return Column(
          children: [
            HomeTopBar(controller: controller),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  HomePrayerStrip(controller: controller),
                  const SizedBox(height: 16),
                  Text(
                    'استكشف',
                    style: TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.35,
                    children: [
                      _Shortcut(
                        icon: Icons.fact_check_rounded,
                        title: 'سجل الصلاة',
                        subtitle: 'الفروض والسنن والسلسلة',
                        color: light ? const Color(0xFF0F4A39) : const Color(0xFF4ECCA3),
                        text: text,
                        muted: muted,
                        onTap: () => pushPage(context, const PrayerSchedulePage()),
                      ),
                      _Shortcut(
                        icon: Icons.auto_stories_rounded,
                        title: 'الدليل',
                        subtitle: 'حديث، أدعية، سنن وبودكاست',
                        color: light ? const Color(0xFF8D5B18) : const Color(0xFFD4A843),
                        text: text,
                        muted: muted,
                        onTap: () => pushPage(context, const GuidePage()),
                      ),
                      _Shortcut(
                        icon: Icons.groups_rounded,
                        title: 'الصحابة',
                        subtitle: 'سير مختصرة',
                        color: light ? const Color(0xFF1D4E89) : const Color(0xFF7AB4FF),
                        text: text,
                        muted: muted,
                        onTap: () => pushPage(context, const CompanionsPage()),
                      ),
                      _Shortcut(
                        icon: Icons.shield_rounded,
                        title: 'الغزوات',
                        subtitle: 'أحداث السيرة',
                        color: light ? const Color(0xFF7A3E2E) : const Color(0xFFE8A07A),
                        text: text,
                        muted: muted,
                        onTap: () => pushPage(context, const BattlesPage()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.text,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color text;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
