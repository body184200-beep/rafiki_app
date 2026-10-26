import 'package:flutter/material.dart';
import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';

// ─────────────────────────────────────────────────────────────
//  Qada Carry Over Models & Widgets
// ─────────────────────────────────────────────────────────────
class QadaCarryEntry {
  final String prayerName;
  final String dateKey;
  bool completed = false;

  QadaCarryEntry({
    required this.prayerName,
    required this.dateKey,
  });
}

class QadaCarryCard extends StatelessWidget {
  final QadaCarryEntry entry;
  final VoidCallback onComplete;

  const QadaCarryCard({
    super.key,
    required this.entry,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: T.ruby.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: T.ruby.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: T.ruby.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, color: T.rubyL, size: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.prayerName,
                  style: TextStyle(
                    color: T.t1,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'فائتة من يوم ${entry.dateKey}',
                  style: TextStyle(
                    color: T.rubyL,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onComplete,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: T.ruby.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: T.ruby.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: T.rubyL, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'قضيتها',
                      style: TextStyle(
                        color: T.rubyL,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Banner Widget
// ─────────────────────────────────────────────────────────────
class BannerWidget extends StatelessWidget {
  final String text;
  const BannerWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  1. Hero Prayer Score Section (Unlimited Scale)
// ─────────────────────────────────────────────────────────────
class PrayerScoreHero extends StatelessWidget {
  final double totalScore;
  final double todayGain;
  final int streak;

  const PrayerScoreHero({
    super.key,
    required this.totalScore,
    required this.todayGain,
    required this.streak,
  });

  static String formatScore(num score) {
    final int val = score.toInt();
    final s = val.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  static String streakGrammar(int count) {
    if (count == 1) return 'يوم متتالي';
    if (count == 2) return 'يومان متتاليان';
    if (count >= 3 && count <= 10) return 'أيام متتالية';
    return 'يوم متتالي';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Mosque Emblem
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.mosque_rounded,
                color: AppColors.accent,
                size: 26,
              ),
            ),
          ),

          SizedBox(height: 14),

          // Huge Unlimited Score Number with Smooth Tween Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: totalScore),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatScore(value),
                  style: TextStyle(
                    color: T.t1,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 4),

          // Score Label
          Text(
            'مجموع نقاط الصلاة',
            style: TextStyle(
              color: T.t2,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 12),

          // Sub-row: Today's Gain & Streak Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Daily Gain Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: todayGain > 0
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: todayGain > 0
                        ? AppColors.accent.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      todayGain > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.add_rounded,
                      color: todayGain > 0 ? AppColors.accent : T.t3,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      todayGain > 0
                          ? '+${formatScore(todayGain)} اليوم'
                          : '٠ اليوم',
                      style: TextStyle(
                        color: todayGain > 0 ? AppColors.accent : T.t2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: T.flame.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: T.flame.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 5),
                    Text(
                      '$streak ${streakGrammar(streak)}',
                      style: TextStyle(
                        color: T.flameL,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. Today's Prayers Section (Unified Compact Container)
// ─────────────────────────────────────────────────────────────
class TodayPrayersCard extends StatelessWidget {
  final DayRecord today;
  final void Function(PrayerDef p, bool isCongregation) onComplete;
  final void Function(PrayerDef p) onQada;
  final void Function(PrayerDef p, int sunnahIndex) onMarkSunnah;
  final VoidCallback onCompleteDuha;

  const TodayPrayersCard({
    super.key,
    required this.today,
    required this.onComplete,
    required this.onQada,
    required this.onMarkSunnah,
    required this.onCompleteDuha,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = kPrayers.where((p) {
      final s = today.recordFor(p).state;
      return s == PrayerState.completedIndividual ||
          s == PrayerState.completedCongregation ||
          s == PrayerState.oadaCompleted;
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'صلوات اليوم',
                      style: TextStyle(
                        color: T.t1,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedCount == kPrayers.length
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: completedCount == kPrayers.length
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '$completedCount من ${kPrayers.length} مكتملة',
                    style: TextStyle(
                      color: completedCount == kPrayers.length
                          ? AppColors.accent
                          : T.t2,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Unified Container for 5 Prayers
          Container(
            decoration: BoxDecoration(
              color: T.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: List.generate(kPrayers.length, (index) {
                  final prayer = kPrayers[index];
                  final record = today.recordFor(prayer);
                  final isLast = index == kPrayers.length - 1;

                  return Column(
                    children: [
                      CompactPrayerRow(
                        prayer: prayer,
                        record: record,
                        onComplete: (isCongregation) =>
                            onComplete(prayer, isCongregation),
                        onQada: () => onQada(prayer),
                        onMarkSunnah: (i) => onMarkSunnah(prayer, i),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // Duha Prayer Card
          DuhaPrayerCard(
            record: today.recordFor('الضحى'),
            onComplete: onCompleteDuha,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  3. Compact Prayer Row Widget
// ─────────────────────────────────────────────────────────────
class CompactPrayerRow extends StatelessWidget {
  final PrayerDef prayer;
  final PrayerRecord record;
  final ValueChanged<bool> onComplete;
  final VoidCallback onQada;
  final ValueChanged<int> onMarkSunnah;

  const CompactPrayerRow({
    super.key,
    required this.prayer,
    required this.record,
    required this.onComplete,
    required this.onQada,
    required this.onMarkSunnah,
  });

  @override
  Widget build(BuildContext context) {
    final state = record.state;
    final isAvailable = state == PrayerState.available;
    final isCompleted = state == PrayerState.completedIndividual ||
        state == PrayerState.completedCongregation ||
        state == PrayerState.oadaCompleted;
    final isQada = state == PrayerState.oadaPending;

    return Container(
      color: isAvailable
          ? prayer.tint.withValues(alpha: 0.25)
          : isCompleted
              ? const Color(0xFF0D1714).withValues(alpha: 0.4)
              : isQada
                  ? T.ruby.withValues(alpha: 0.06)
                  : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Row: Icon + Name/Rakats + State/Actions
          Row(
            children: [
              // Icon Box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? prayer.accent.withValues(alpha: 0.15)
                      : isCompleted
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : isQada
                              ? T.ruby.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAvailable
                        ? prayer.accent.withValues(alpha: 0.35)
                        : isCompleted
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : isQada
                                ? T.ruby.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  state == PrayerState.locked
                      ? Icons.lock_outline_rounded
                      : prayer.icon,
                  color: isAvailable
                      ? prayer.accent
                      : isCompleted
                          ? AppColors.accent
                          : isQada
                              ? T.rubyL
                              : T.t3,
                  size: 18,
                ),
              ),

              SizedBox(width: 12),

              // Name & Rakats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.name,
                      style: TextStyle(
                        color: state == PrayerState.locked ? T.t2 : T.t1,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${prayer.rakats} ركعات',
                      style: TextStyle(
                        color: T.t3,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge or Action Buttons
              _buildTrailingStatus(context, state),
            ],
          ),

          // Inline Quick Actions when Available
          if (isAvailable) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    label: 'صليتها جماعة',
                    icon: Icons.groups_rounded,
                    color: AppColors.gold,
                    onTap: () => onComplete(true),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionBtn(
                    label: 'صليتها فردي',
                    icon: Icons.person_rounded,
                    color: AppColors.accent,
                    onTap: () => onComplete(false),
                  ),
                ),
              ],
            ),
          ],

          // Inline Qada Action when Missed
          if (isQada) ...[
            SizedBox(height: 10),
            _buildActionBtn(
              label: 'قضيها',
              icon: Icons.refresh_rounded,
              color: T.rubyL,
              onTap: onQada,
            ),
          ],

          // Sunnah Chips (independent of Fardh locking)
          if (prayer.sunnah.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(prayer.sunnah.length, (i) {
                final sel = record.completedSunnah.contains(i);
                return GestureDetector(
                  onTap: sel ? null : () => onMarkSunnah(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.gold.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppColors.gold.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sel)
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.check_rounded,
                                color: AppColors.gold, size: 11),
                          ),
                        Text(
                          prayer.sunnah[i],
                          style: TextStyle(
                            color: sel ? AppColors.gold : T.t2,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrailingStatus(BuildContext context, PrayerState state) {
    switch (state) {
      case PrayerState.completedIndividual:
        return _statusBadge(
          label: '✓ أديتها فردي',
          color: AppColors.accent,
          icon: Icons.check_circle_rounded,
        );
      case PrayerState.completedCongregation:
        return _statusBadge(
          label: '✓ أديتها جماعة',
          color: AppColors.gold,
          icon: Icons.groups_rounded,
        );
      case PrayerState.oadaCompleted:
        return _statusBadge(
          label: '✓ قُضيت',
          color: T.violet,
          icon: Icons.check_circle_outline_rounded,
        );
      case PrayerState.available:
        return _statusBadge(
          label: 'متاحة الآن',
          color: prayer.accent,
          icon: Icons.radio_button_checked_rounded,
        );
      case PrayerState.oadaPending:
        return _statusBadge(
          label: 'فات وقتها',
          color: T.ruby,
          icon: Icons.warning_amber_rounded,
        );
      case PrayerState.locked:
        return Text(
          'لم يحن وقتها',
          style: TextStyle(
            color: T.t3,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _statusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  4. Duha Prayer Card Widget
// ─────────────────────────────────────────────────────────────
class DuhaPrayerCard extends StatelessWidget {
  final PrayerRecord record;
  final VoidCallback onComplete;

  const DuhaPrayerCard({
    super.key,
    required this.record,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final state = record.state;
    final isAvailable = state == PrayerState.available;
    final isCompleted = state == PrayerState.completedIndividual ||
        state == PrayerState.completedCongregation ||
        state == PrayerState.oadaCompleted;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? AppColors.gold.withValues(alpha: 0.4)
              : isCompleted
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: isAvailable
              ? AppColors.gold.withValues(alpha: 0.06)
              : isCompleted
                  ? const Color(0xFF0D1714).withValues(alpha: 0.4)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Icon Box
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : isCompleted
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAvailable
                            ? AppColors.gold.withValues(alpha: 0.35)
                            : isCompleted
                                ? AppColors.accent.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: isAvailable
                          ? AppColors.gold
                          : isCompleted
                              ? AppColors.accent
                              : T.t3,
                      size: 18,
                    ),
                  ),

                  SizedBox(width: 12),

                  // Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'صلاة الضحى',
                              style: TextStyle(
                                color: T.t1,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '(سنة مؤكدة)',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'تفتح قبل الظهر بـ ٣ ساعات',
                          style: TextStyle(
                            color: T.t3,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trailing status
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'تمت ✓ (+3.6)',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radio_button_checked_rounded, color: AppColors.gold, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'متاحة الآن',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'لم يحن وقتها',
                      style: TextStyle(
                        color: T.t3,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              // Inline Action when Available
              if (isAvailable) ...[
                SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onComplete,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: AppColors.gold, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'صليت الضحى (+3.6)',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  5. Minimal Motivation Footer
// ─────────────────────────────────────────────────────────────
class MinimalMotivationFooter extends StatelessWidget {
  const MinimalMotivationFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'استمر... كل صلاة بتفرق 🤍',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: T.t2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '«وَأَقِمِ الصَّلَاةَ لِذِكْرِي» — سورة طه: ١٤',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gold.withValues(alpha: 0.8),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
