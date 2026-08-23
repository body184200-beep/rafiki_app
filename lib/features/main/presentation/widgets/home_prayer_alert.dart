import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/constants/app_constants.dart';
import 'package:rafiki_app/core/l10n/app_localizations.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/utils/prayer_names.dart';

import '../controllers/home_controller.dart';

class HomePrayerAlert extends StatelessWidget {
  const HomePrayerAlert({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prayer = controller.activePrayer!;
    final name = PrayerNames.of(loc, prayer);
    final msg = PrayerNames.alerts(loc)[prayer] ?? loc.alert_now(name);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, -8 * (1 - v)),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Dismissible(
        key: ValueKey('alert_${prayer.name}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => controller.dismissAlert(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.30),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        const Text('🕌', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${loc.alert_now(name)}  ',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: msg.split('\n').last,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.dismissAlert();
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: controller.alertSeconds,
                      builder: (_, seconds, __) => LinearProgressIndicator(
                        value: seconds / AppConstants.prayerAlertDurationSeconds,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
