import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rafiki_app/core/theme/theme_provider.dart';
import 'package:rafiki_app/core/utils/hijri_helper.dart';
import 'package:rafiki_app/features/azkar/presentation/pages/azkar_page.dart';
import 'package:rafiki_app/features/battles/presentation/pages/battles_page.dart';
import 'package:rafiki_app/features/companions/presentation/pages/companions_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/adeia_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/podcast_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/reciters_page.dart';
import 'package:rafiki_app/features/guide/presentation/pages/sunnah_page.dart';
import 'package:rafiki_app/features/hadith/presentation/pages/hadith_page.dart';
import 'package:rafiki_app/features/notification/presentation/pages/notification_page.dart';
import 'package:rafiki_app/features/prayer/presentation/pages/prayer_schedule_page.dart';
import 'package:rafiki_app/features/prayer/presentation/pages/qibla_page.dart';
import 'package:rafiki_app/features/prophet_stories/presentation/pages/prophet_stories_page.dart';
import 'package:rafiki_app/features/settings/presentation/pages/profile_page.dart';

import '../controllers/home_controller.dart';

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key, required this.controller});

  final HomeController controller;

  void _push(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) {
        final isLight = ThemeProvider.instance.isLight;
        final timesMap = controller.prayerScheduleTimes;
        final currentPrayer = controller.currentPrayerEnum;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────────────────────
              _buildTopBar(context, isLight),

              const SizedBox(height: 14),

              // ── Hero Next Prayer Card ─────────────────────────────────────────────
              _buildPrayerCard(context, timesMap, currentPrayer, isLight),

              const SizedBox(height: 14),

              // ── Row 1: Calendar (Hijri & Gregorian) & Al-Qibla ───────────────────
              Row(
                children: [
                  // Left: Calendar Card (Hijri & Gregorian)
                  Expanded(
                    child: _buildActionCard(
                      height: 78,
                      bgColor: isLight ? const Color(0xFFFDF7EC) : const Color(0xFF1F1A12),
                      borderColor: isLight ? const Color(0xFFF5DEC0) : const Color(0xFF4A3820),
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    HijriDate.now().formattedArabic,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatGregorianDateArabic(DateTime.now()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9EABB8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right: Al-Qibla (Cyan Card)
                  _buildActionCard(
                    width: 112,
                    height: 78,
                    bgColor: isLight ? const Color(0xFFE1F0F9) : const Color(0xFF0C1D2E),
                    borderColor: isLight ? const Color(0xFFC7E6F3) : const Color(0xFF173D61),
                    onTap: () => _push(context, const QiblaPage()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          color: isLight ? const Color(0xFF0D6E94) : const Color(0xFF38BDF8),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'القبلة',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF0D6E94) : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 2: Sunnah & Duas/Azkar ─────────────────────────────────────────
              Row(
                children: [
                  // Left: Duas & Azkar (Purple Card)
                  _buildActionCard(
                    width: 112,
                    height: 74,
                    bgColor: isLight ? const Color(0xFFEEE7FA) : const Color(0xFF19132E),
                    borderColor: isLight ? const Color(0xFFDECFF6) : const Color(0xFF382761),
                    onTap: () => _push(context, const AdeiaPage()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: isLight ? const Color(0xFF4A2E80) : const Color(0xFFA78BFA),
                          size: 20,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'الأدعية\nوالأذكار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLight ? const Color(0xFF4A2E80) : Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right: Sunnah (Wide Green Card)
                  Expanded(
                    child: _buildActionCard(
                      height: 74,
                      bgColor: isLight ? const Color(0xFFD9F3EA) : const Color(0xFF0B291F),
                      borderColor: isLight ? const Color(0xFFBDE9DA) : const Color(0xFF13533D),
                      onTap: () => _push(context, const SunnahPage()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'سُنّة الرسول',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF0A5840) : const Color(0xFF3CD2A2),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star_border_rounded,
                            color: isLight ? const Color(0xFF0A5840) : const Color(0xFF3CD2A2),
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 3: Prayer Podcast (Full Width Card) ───────────────────────────
              _buildActionCard(
                height: 60,
                bgColor: isLight ? const Color(0xFFEEE7FA) : const Color(0xFF141529),
                borderColor: isLight ? const Color(0xFFDECFF6) : const Color(0xFF2A2353),
                onTap: () => _push(context, const PrayerPodcastPage()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'بودكاست الصلاة',
                      style: TextStyle(
                        color: isLight ? const Color(0xFF4A2E80) : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.mic_none_rounded,
                      color: isLight ? const Color(0xFF5E35B1) : const Color(0xFFA78BFA),
                      size: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── 3x2 Grid Section ──────────────────────────────────────────────────
              // Row A of Grid
              Row(
                children: [
                  Expanded(
                    child: _buildGridItem(
                      title: 'مجتمع\nالقرّاء',
                      icon: Icons.menu_book_outlined,
                      color: isLight ? const Color(0xFF0A5840) : const Color(0xFF3CD2A2),
                      bgColor: isLight ? const Color(0xFFD9F3EA) : const Color(0xFF0B281E),
                      borderColor: isLight ? const Color(0xFFBDE9DA) : const Color(0xFF13533D),
                      onTap: () => _push(context, const RecitersPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGridItem(
                      title: 'جدول\nالصلاة',
                      icon: Icons.calendar_month_outlined,
                      color: isLight ? const Color(0xFF0D6E94) : const Color(0xFF38BDF8),
                      bgColor: isLight ? const Color(0xFFE1F0F9) : const Color(0xFF0C1B2C),
                      borderColor: isLight ? const Color(0xFFC7E6F3) : const Color(0xFF163959),
                      onTap: () => _push(context, const PrayerSchedulePage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGridItem(
                      title: 'الأحاديث',
                      icon: Icons.book_outlined,
                      color: isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C),
                      bgColor: isLight ? const Color(0xFFFDF1DB) : const Color(0xFF23180B),
                      borderColor: isLight ? const Color(0xFFF5DEC0) : const Color(0xFF483214),
                      onTap: () => _push(context, const HadithScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row B of Grid
              Row(
                children: [
                  Expanded(
                    child: _buildGridItem(
                      title: 'قصص\nالأنبياء',
                      icon: Icons.auto_stories_outlined,
                      color: isLight ? const Color(0xFF4A2E80) : const Color(0xFFA78BFA),
                      bgColor: isLight ? const Color(0xFFEEE7FA) : const Color(0xFF19132E),
                      borderColor: isLight ? const Color(0xFFDECFF6) : const Color(0xFF382761),
                      onTap: () => _push(context, const Anbiaa()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGridItem(
                      title: 'الغزوات',
                      icon: Icons.outlined_flag_rounded,
                      color: isLight ? const Color(0xFF0D6E94) : const Color(0xFF2DD4BF),
                      bgColor: isLight ? const Color(0xFFE1F0F9) : const Color(0xFF0B1F28),
                      borderColor: isLight ? const Color(0xFFC7E6F3) : const Color(0xFF144256),
                      onTap: () => _push(context, const BattlesPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGridItem(
                      title: 'الصحابة',
                      icon: Icons.people_outline_rounded,
                      color: isLight ? const Color(0xFF8D5B18) : const Color(0xFFE5A93C),
                      bgColor: isLight ? const Color(0xFFFDF1DB) : const Color(0xFF23180B),
                      borderColor: isLight ? const Color(0xFFF5DEC0) : const Color(0xFF483214),
                      onTap: () => _push(context, const CompanionsPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Top Bar Widget ────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isLight) {
    return Row(
      children: [
        // 1. Profile Icon Button
        GestureDetector(
          onTap: () => _push(context, const ProfilePage()),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFE8F5E9) : const Color(0xFF0D2521),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? const Color(0xFFD1E7DD) : const Color(0xFF144D3F),
                width: 0.9,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isLight ? const Color(0xFF0B4633) : const Color(0xFF3CD2A2),
              size: 22,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 2. Notification Bell Button
        GestureDetector(
          onTap: () => _push(context, const NotificationPage()),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F1829),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? const Color(0xFFE5E7EB) : const Color(0xFF1B2E4D),
                width: 0.9,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isLight ? const Color(0xFF374151) : const Color(0xFF8DA3C4),
              size: 22,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // 3. Azkar Pill Bar
        Expanded(
          child: GestureDetector(
            onTap: () => _push(context, const AzkarPage()),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1EDF9) : const Color(0xFF16152B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLight ? const Color(0xFFDECFF6) : const Color(0xFF2E2457),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'أذكار الصباح والمساء',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF4A2E80) : const Color(0xFFF1F5F9),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.nightlight_round,
                    color: isLight ? const Color(0xFF5E35B1) : const Color(0xFFA78BFA),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Prayer Card ──────────────────────────────────────────────────────
  Widget _buildPrayerCard(
    BuildContext context,
    Map<Prayer, String> timesMap,
    Prayer currentPrayer,
    bool isLight,
  ) {
    final prayers = [
      (Prayer.fajr, 'الفجر'),
      (Prayer.dhuhr, 'الظهر'),
      (Prayer.asr, 'العصر'),
      (Prayer.maghrib, 'المغرب'),
      (Prayer.isha, 'العشاء'),
    ];

    final cardBg = isLight ? const Color(0xFF0F4A39) : const Color(0xFF0C1425);
    final cardBorder = isLight ? const Color(0xFF145D47) : const Color(0xFF192A48);

    final highlightBg = isLight ? const Color(0xFF1D5A46) : const Color(0xFF0E3834);
    final highlightBorder = isLight ? const Color(0xFF2C745B) : const Color(0xFF186253);
    final highlightText = isLight ? const Color(0xFFF6E0A4) : const Color(0xFF3CD2A2);

    final normalTimeColor = isLight ? const Color(0xFFB4D8CC) : const Color(0xFF8DA3C4);
    final normalNameColor = isLight ? const Color(0xFFD1E7DD) : const Color(0xFFCAD5E2);

    final nextPrayerTitleColor = isLight ? const Color(0xFFB4D8CC) : const Color(0xFF7E97B8);
    final nextPrayerNameColor = isLight ? const Color(0xFFF6E0A4) : const Color(0xFF3CD2A2);
    final countdownLabelColor = isLight ? const Color(0xFFB4D8CC) : const Color(0xFF7E97B8);

    return GestureDetector(
      onTap: () => _push(context, const PrayerSchedulePage()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cardBorder, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Prayers Timetable
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: prayers.map((entry) {
                  final prayer = entry.$1;
                  final name = entry.$2;
                  final time = timesMap[prayer] ?? '--:--';
                  final isCurrent = prayer == currentPrayer;

                  if (isCurrent) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2.5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: highlightBg,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: highlightBorder, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: highlightText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            name,
                            style: TextStyle(
                              color: highlightText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    child: Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: normalTimeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          name,
                          style: TextStyle(
                            color: normalNameColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(width: 14),

            // Right Column: Next Prayer & Countdown
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      color: nextPrayerTitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.nextPrayerArabicName,
                    style: TextStyle(
                      color: nextPrayerNameColor,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'متبقي عليها',
                    style: TextStyle(
                      color: countdownLabelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: controller.countdown,
                    builder: (_, __, ___) {
                      return Text(
                        controller.countdownDigitsOnly,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Action Card ────────────────────────────────────────────────────
  Widget _buildActionCard({
    double? width,
    required double height,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: Center(child: child),
      ),
    );
  }

  // ── Helper Grid Item ──────────────────────────────────────────────────────
  Widget _buildGridItem({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGregorianDateArabic(DateTime date) {
    const weekdays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dayName = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = HijriDate.toArabicDigits(date.day);
    final year = HijriDate.toArabicDigits(date.year);
    return '$dayName، $day $monthName $year م';
  }
}
