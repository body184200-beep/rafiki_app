import 'package:adhan/adhan.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';

enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

class DayContext {
  final bool allFardhCongregation;
  final bool allFardhWithSunnah;
  final int completedOnTime;
  final int missed;
  final bool isPerfect3DayStreak;

  DayContext({
    required this.allFardhCongregation,
    required this.allFardhWithSunnah,
    required this.completedOnTime,
    required this.missed,
    required this.isPerfect3DayStreak,
  });
}

class PrayerRuleEngine {
  PrayerTimes times;

  PrayerRuleEngine(this.times);

  /// BASE RULES
  static const double soloScore = 1.0;
  static const double congregationScore = 27.0;
  static const double qadaScore = 0.5;
  static const double missedPenalty = -2.0;

  // Sunnah score weight
  static const double sunnahScoreWeight = 0.75;

  // Daily Bonuses
  static const double congregationDailyBonus = 30.0;
  static const double perfectSunnahDailyBonus = 50.0;

  // Streak Consistency Bonus (adds to global streak days, not score)
  static const int streakConsistencyBonus = 1;

  /// SCORE CALCULATION (ONLY ENTRY POINT)
  double calculateScore(PrayerState state, DayContext day, {bool isMidnightRollover = false}) {
    double score = 0;

    // BASE RULES
    switch (state) {
      case PrayerState.completedCongregation:
        score += congregationScore;
        break;
      case PrayerState.completedIndividual:
        score += soloScore;
        break;
      case PrayerState.oadaCompleted:
        score += qadaScore;
        break;
      case PrayerState.oadaPending:
        score += missedPenalty;
        break;
      default:
        break;
    }

    if (isMidnightRollover) {
      // DAILY BONUS RULES (applied only on midnight rollover)
      if (day.allFardhCongregation) {
        score += congregationDailyBonus;
      }

      if (day.allFardhWithSunnah) {
        score += perfectSunnahDailyBonus;
      }
    }

    return score;
  }

  /// STREAK CALCULATION (Day unit: +1 for 5 on-time prayers, 0 for 1-3 missed, bonus for 3-day consistency)
  int calculateStreak(DayContext day) {
    int change = 0;
    if (day.completedOnTime == 5 && day.missed == 0) {
      change = 1;
    } else if (day.missed > 0 && day.missed <= 3) {
      // 0–3 missed prayers: streak is maintained (change = 0)
      change = 0;
    } else if (day.missed > 3) {
      change = -1;
    }

    if (day.isPerfect3DayStreak) {
      change += streakConsistencyBonus;
    }

    return change;
  }

  /// PRAYER WINDOW (PURE)
  bool isPrayerOpen(PrayerType type, DateTime now) {
    final dayTimes = PrayerTimes(times.coordinates, DateComponents.from(now), times.calculationParameters);
    if (type == PrayerType.isha) {
      if (now.isBefore(dayTimes.fajr)) {
        // Between midnight and Fajr, Isha from yesterday is still open until Fajr
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayTimes = PrayerTimes(times.coordinates, DateComponents.from(yesterday), times.calculationParameters);
        return !now.isBefore(yesterdayTimes.isha) && now.isBefore(dayTimes.fajr);
      } else {
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(times.coordinates, DateComponents.from(tomorrow), times.calculationParameters);
        return !now.isBefore(dayTimes.isha) && now.isBefore(tomorrowTimes.fajr);
      }
    }
    final start = getStart(type, now);
    final end = getEnd(type, now);

    return !now.isBefore(start) && now.isBefore(end);
  }

  DateTime getStart(PrayerType type, DateTime date) {
    final dayTimes = PrayerTimes(times.coordinates, DateComponents.from(date), times.calculationParameters);
    switch (type) {
      case PrayerType.fajr:
        return dayTimes.fajr;
      case PrayerType.dhuhr:
        return dayTimes.dhuhr;
      case PrayerType.asr:
        return dayTimes.asr;
      case PrayerType.maghrib:
        return dayTimes.maghrib;
      case PrayerType.isha:
        return dayTimes.isha;
    }
  }

  DateTime getEnd(PrayerType type, DateTime date) {
    final dayTimes = PrayerTimes(times.coordinates, DateComponents.from(date), times.calculationParameters);
    switch (type) {
      case PrayerType.fajr:
        return dayTimes.sunrise;
      case PrayerType.dhuhr:
        return dayTimes.asr;
      case PrayerType.asr:
        return dayTimes.maghrib;
      case PrayerType.maghrib:
        return dayTimes.isha;
      case PrayerType.isha:
        final today = DateTime(date.year, date.month, date.day);
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(times.coordinates, DateComponents.from(tomorrow), times.calculationParameters);
        return tomorrowTimes.fajr;
    }
  }
}
