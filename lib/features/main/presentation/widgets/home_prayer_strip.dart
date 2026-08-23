import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/widgets/glass_panel.dart';

import '../controllers/home_controller.dart';

class HomePrayerStrip extends StatelessWidget {
  const HomePrayerStrip({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loadingPrayer) {
      return const GlassPanel(
        child: SizedBox(
          height: 52,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final current = controller.currentPrayer;
    final times = controller.prayerTimes;
    final entries = [
      (Prayer.fajr, loc.prayer_fajr, times?['Fajr'] ?? '--'),
      (Prayer.dhuhr, loc.prayer_dhuhr, times?['Dhuhr'] ?? '--'),
      (Prayer.asr, loc.prayer_asr, times?['Asr'] ?? '--'),
      (Prayer.maghrib, loc.prayer_maghrib, times?['Maghrib'] ?? '--'),
      (Prayer.isha, loc.prayer_isha, times?['Isha'] ?? '--'),
    ];
    final currentIdx = entries.indexWhere((e) => e.$1 == current);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < entries.length; i++)
            _PrayerCell(
              name: entries[i].$2,
              time: entries[i].$3,
              isNow: entries[i].$1 == current,
              isPast: currentIdx >= 0 && i < currentIdx,
            ),
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({
    required this.name,
    required this.time,
    required this.isNow,
    required this.isPast,
  });

  final String name;
  final String time;
  final bool isNow;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final nameColor = isNow
        ? AppColors.accent
        : isPast
            ? AppColors.textSecondary.withValues(alpha: 0.45)
            : AppColors.textSecondary;
    final timeColor = isNow
        ? AppColors.textPrimary
        : isPast
            ? AppColors.textPrimary.withValues(alpha: 0.3)
            : AppColors.textPrimary.withValues(alpha: 0.7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isNow ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNow
              ? AppColors.accentDim.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: nameColor,
              fontSize: 11,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: timeColor, fontSize: 11)),
          const SizedBox(height: 4),
          if (isNow) const _PulseDot() else const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused) {
      _ctrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.0).animate(_anim),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class HomeFajrBanner extends StatelessWidget {
  const HomeFajrBanner({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: const Color(0xFF3A6EA5).withValues(alpha: 0.4),
      child: Row(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.banner_isha_ended,
                  style: const TextStyle(
                    color: Color(0xFF7AB4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.banner_next_tomorrow_fajr(controller.tomorrowFajrLabel()),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text('🌅', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
