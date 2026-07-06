import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_rule_engine.dart';

// ─────────────────────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────────────────────
class T {
  static const bg      = Color(0xFF080D12);
  static const surface = Color(0xFF0E1620);
  static const card    = Color(0xFF121C2A);
  static const cardHi  = Color(0xFF182435);

  static const jade    = Color(0xFF2EC4A0);
  static const jadeDim = Color(0xFF1A7060);
  static const jadeSoft= Color(0xFF80DFCA);

  static const gold    = Color(0xFFD4A030);
  static const goldSoft= Color(0xFFF0C860);

  static const flame   = Color(0xFFFF6B30);
  static const flameL  = Color(0xFFFFAA60);

  static const violet  = Color(0xFF9B59B6);
  static const violetL = Color(0xFFBB8FD4);

  static const ruby    = Color(0xFFE74C3C);
  static const rubyL   = Color(0xFFF1948A);

  static const sky     = Color(0xFF3498DB);
  static const skyL    = Color(0xFF7FB3D3);

  static const t1 = Color(0xFFEEE8D8);
  static const t2 = Color(0xFFAAA498);
  static const t3 = Color(0xFF585450);

  static const List<List<Color>> prayerColors = [
    [Color(0xFF0E1E2A), Color(0xFF60C8F0)],
    [Color(0xFF1A1808), Color(0xFFD4A030)],
    [Color(0xFF1A1208), Color(0xFFE87840)],
    [Color(0xFF10180A), Color(0xFF80C840)],
    [Color(0xFF0E1020), Color(0xFF8890E0)],
  ];

  static const List<IconData> prayerIcons = [
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.light_mode_rounded,
    Icons.wb_cloudy_rounded,
    Icons.nights_stay_rounded,
  ];
}

// ─────────────────────────────────────────────────────────────
//  Scoring Constants  (modify here to adjust)
// ─────────────────────────────────────────────────────────────
class ScoreConstants {
  static const double congregation = 27.0;
  static const double individual   = 1.0;
  static const double qada         = 0.5;
  static const double missed       = -2.0;
  static const double sunnah       = 0.75;
}

// ─────────────────────────────────────────────────────────────
//  Prayer Definition
// ─────────────────────────────────────────────────────────────
class PrayerDef {
  final String name;
  final int rakats;
  final List<String> sunnah;
  final List<Color> colors;
  final IconData icon;
  final Prayer adhanPrayer;

  const PrayerDef({
    required this.name,
    required this.rakats,
    required this.sunnah,
    required this.colors,
    required this.icon,
    required this.adhanPrayer,
  });

  Color get accent => colors[1];
  Color get tint   => colors[0];

  DateTime start(DateTime day) {
    final times = sl<PrayerEngine>().todayTimes;
    if (times == null) {
      switch (adhanPrayer) {
        case Prayer.fajr: return DateTime(day.year, day.month, day.day, 5, 0);
        case Prayer.dhuhr: return DateTime(day.year, day.month, day.day, 12, 0);
        case Prayer.asr: return DateTime(day.year, day.month, day.day, 15, 30);
        case Prayer.maghrib: return DateTime(day.year, day.month, day.day, 18, 0);
        case Prayer.isha: return DateTime(day.year, day.month, day.day, 19, 30);
        default: return DateTime.now();
      }
    }
    switch (adhanPrayer) {
      case Prayer.fajr: return times.fajr;
      case Prayer.dhuhr: return times.dhuhr;
      case Prayer.asr: return times.asr;
      case Prayer.maghrib: return times.maghrib;
      case Prayer.isha: return times.isha;
      default: return DateTime.now();
    }
  }

  DateTime end(DateTime day) {
    final times = sl<PrayerEngine>().todayTimes;
    if (times == null) {
      switch (adhanPrayer) {
        case Prayer.fajr: return DateTime(day.year, day.month, day.day, 12, 0);
        case Prayer.dhuhr: return DateTime(day.year, day.month, day.day, 15, 30);
        case Prayer.asr: return DateTime(day.year, day.month, day.day, 18, 0);
        case Prayer.maghrib: return DateTime(day.year, day.month, day.day, 19, 30);
        case Prayer.isha:
          final tomorrow = day.add(const Duration(days: 1));
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0);
        default: return DateTime.now();
      }
    }
    switch (adhanPrayer) {
      case Prayer.fajr: return times.dhuhr;
      case Prayer.dhuhr: return times.asr;
      case Prayer.asr: return times.maghrib;
      case Prayer.maghrib: return times.isha;
      case Prayer.isha:
        final tomorrow = day.add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(times.coordinates, DateComponents.from(tomorrow), times.calculationParameters);
        return tomorrowTimes.fajr;
      default: return DateTime.now();
    }
  }
}

final List<PrayerDef> kPrayers = [
  PrayerDef(name: "الفجر",  rakats: 2, sunnah: ["٢ سنة قبلية"],
      colors: T.prayerColors[0], icon: T.prayerIcons[0], adhanPrayer: Prayer.fajr),
  PrayerDef(name: "الظهر",  rakats: 4, sunnah: ["٤ سنة قبلية", "٢ سنة بعدية"],
      colors: T.prayerColors[1], icon: T.prayerIcons[1], adhanPrayer: Prayer.dhuhr),
  PrayerDef(name: "العصر",  rakats: 4, sunnah: [],
      colors: T.prayerColors[2], icon: T.prayerIcons[2], adhanPrayer: Prayer.asr),
  PrayerDef(name: "المغرب", rakats: 3, sunnah: ["٢ سنة بعدية"],
      colors: T.prayerColors[3], icon: T.prayerIcons[3], adhanPrayer: Prayer.maghrib),
  PrayerDef(name: "العشاء", rakats: 4, sunnah: ["٢ سنة بعدية"],
      colors: T.prayerColors[4], icon: T.prayerIcons[4], adhanPrayer: Prayer.isha),
];

const int kTotalSunnah  = 5;
const int kTotalPrayers = 5;
const double kMaxDayScore = 3.0;

// ─────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayKey() => dateKey(DateTime.now());

// ─────────────────────────────────────────────────────────────
//  Prayer Time Service
// ─────────────────────────────────────────────────────────────
class PrayerTimeService {
  /// Returns the index (in kPrayers) of the prayer whose window is currently
  /// active at [now], or -1 if none is active yet (e.g., before Fajr).
  ///
  /// KEY RULE: Only ONE prayer can be "available" at any given moment.
  /// When prayer N+1 starts, prayer N is locked from interaction and moves
  /// to oadaPending if not completed.
  static int activePrayerIndex(DateTime now) {
    final times = sl<PrayerEngine>().todayTimes;
    if (times == null) return -1;
    final ruleEngine = sl<PrayerRuleEngine>();
    if (ruleEngine.isPrayerOpen(PrayerType.fajr, now)) return 0;
    if (ruleEngine.isPrayerOpen(PrayerType.dhuhr, now)) return 1;
    if (ruleEngine.isPrayerOpen(PrayerType.asr, now)) return 2;
    if (ruleEngine.isPrayerOpen(PrayerType.maghrib, now)) return 3;
    if (ruleEngine.isPrayerOpen(PrayerType.isha, now)) return 4;
    return -1; // before Fajr or after Isha-end (next day)
  }

  /// Compute the correct [PrayerState] for prayer at [index] given [now].
  ///
  /// Rules:
  ///  - If the prayer is already finalized (completed / oadaCompleted), keep it.
  ///  - If it's already oadaPending, keep it (it was missed).
  ///  - Otherwise:
  ///      • Before start → locked
  ///      • During its window AND it is the active prayer → available
  ///      • After its window without completion → oadaPending
  static PrayerState computeStateFor({
    required int prayerIndex,
    required DateTime now,
    required PrayerState current,
  }) {
    if (current.isFinal) return current;
    if (current == PrayerState.oadaPending) return current;

    final active = activePrayerIndex(now);
    if (active == prayerIndex) return PrayerState.available;

    final prayer = kPrayers[prayerIndex];
    final today  = DateTime(now.year, now.month, now.day);
    final start  = prayer.start(today);
    final end    = prayer.end(today);

    if (now.isBefore(start)) return PrayerState.locked;
    if (now.isAfter(end) || (active != -1 && active > prayerIndex)) {
      return PrayerState.oadaPending;
    }

    return current;
  }

  /// Score for a completed fardh state — unchanged from original.
  static double scoreFor(PrayerState state) {
    switch (state) {
      case PrayerState.completedCongregation: return ScoreConstants.congregation;
      case PrayerState.completedIndividual:   return ScoreConstants.individual;
      case PrayerState.oadaCompleted:         return ScoreConstants.qada;
      case PrayerState.oadaPending:           return ScoreConstants.missed;
      default: return 0;
    }
  }

  /// Score for completed sunnah prayers — unchanged from original.
  static double sunnahScoreFor(int completedCount) =>
      double.parse((completedCount * ScoreConstants.sunnah).toStringAsFixed(2));
}

// ─────────────────────────────────────────────────────────────
//  Streak Service  [NEW]
// ─────────────────────────────────────────────────────────────
/// Manages the daily streak counter independently from score.
///
/// Rules:
///  - Each completed fardh prayer adds +1 to today's streak count (max 5).
///  - A prayer is counted at most once (guarded by [PrayerRecord.countedInStreak]).
///  - Completing all 5 fardh prayers gives a bonus so dailyStreakCount == 5.
///  - The global streak (consecutive days with all 5) lives in _streak on the
///    page state and is updated on day rollover.
class StreakService {
  /// Call this when a prayer is newly completed. Returns the updated
  /// [dailyStreakCount] for the day, ensuring no double-counting.
  static int onPrayerCompleted({
    required DayRecord day,
    required PrayerDef prayer,
  }) {
    final rec = day.recordFor(prayer);

    // Guard: only count once per prayer per day.
    if (rec.countedInStreak) return day.dailyStreakCount;

    rec.countedInStreak = true;
    day.dailyStreakCount = (day.dailyStreakCount + 1).clamp(0, kTotalPrayers);

    return day.dailyStreakCount;
  }

  /// Compute the global (multi-day) streak delta for a finished day.
  ///  +1  if all 5 fardh completed on time (not qada)
  ///   0  if partial
  ///  -1  if zero prayers completed
  static int globalStreakDelta(DayRecord day) {
    final onTimePrayers = kPrayers.where((p) {
      final s = day.recordFor(p).state;
      return s == PrayerState.completedIndividual ||
          s == PrayerState.completedCongregation;
    }).length;

    if (onTimePrayers == kPrayers.length) return 1;
    if (onTimePrayers == 0) return -1;
    return 0;
  }
}
