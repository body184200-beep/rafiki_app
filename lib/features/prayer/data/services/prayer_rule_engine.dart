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
  final PrayerTimes times;

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

  // Streak Consistency Bonus (adds to global streak, not score)
  static const int streakConsistencyBonus = 15;

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

  /// STREAK CALCULATION
  int calculateStreak(DayContext day) {
    int base = day.completedOnTime - day.missed;

    // Clamp base change between [-5, 5] as per day-based streak tracker specifications
    int clampedChange = base.clamp(-5, 5);

    if (day.isPerfect3DayStreak) {
      clampedChange += streakConsistencyBonus;
    }

    return clampedChange;
  }

  /// PRAYER WINDOW (PURE)
  bool isPrayerOpen(PrayerType type, DateTime now) {
    final start = getStart(type);
    final end = getEnd(type, now);

    return !now.isBefore(start) && now.isBefore(end);
  }

  DateTime getStart(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return times.fajr;
      case PrayerType.dhuhr:
        return times.dhuhr;
      case PrayerType.asr:
        return times.asr;
      case PrayerType.maghrib:
        return times.maghrib;
      case PrayerType.isha:
        return times.isha;
    }
  }

  DateTime getEnd(PrayerType type, DateTime now) {
    switch (type) {
      case PrayerType.fajr:
        return times.dhuhr;
      case PrayerType.dhuhr:
        return times.asr;
      case PrayerType.asr:
        return times.maghrib;
      case PrayerType.maghrib:
        return times.isha;
      case PrayerType.isha:
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(times.coordinates, DateComponents.from(tomorrow), times.calculationParameters);
        return tomorrowTimes.fajr;
    }
  }
}
