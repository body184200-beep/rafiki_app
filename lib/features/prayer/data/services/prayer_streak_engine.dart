import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'prayer_engine.dart';
import 'score_engine.dart';
import 'prayer_rule_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
class PrayerStreakEngine {
  PrayerStreakEngine._internal();
  static final PrayerStreakEngine instance = PrayerStreakEngine._internal();

  final ValueNotifier<Map<String, double>> fardhStreaks = ValueNotifier<Map<String, double>>({
    'الفجر': 0.0,
    'الظهر': 0.0,
    'العصر': 0.0,
    'المغرب': 0.0,
    'العشاء': 0.0,
  });
  
  final ValueNotifier<int> globalStreak = ValueNotifier<int>(0);
  final ValueNotifier<int> dailyStreak = ValueNotifier<int>(0);
  final Set<Prayer> _completedToday = {};
  
  StreakRepository get _repository => sl<StreakRepository>();

  Future<void> initialize() async {
    AppLogger.info('Initializing PrayerStreakEngine...', tag: 'StreakEngine');
    
    globalStreak.value = await _repository.loadGlobalStreak();
    
    final savedStreaks = await _repository.loadFardhStreaks();
    final currentMap = Map<String, double>.from(fardhStreaks.value);
    savedStreaks.forEach((key, val) {
      currentMap[key] = val.toDouble();
    });
    fardhStreaks.value = currentMap;

    // Load completed today for backward compatibility (only if date is today)
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final savedDate = prefs.getString('streak_engine_date');

      if (savedDate != null && savedDate != todayKey) {
        // We have missed days!
        // Load the completed today list for the saved day before running rollovers
        final completedList = prefs.getStringList('streak_engine_completed_today') ?? [];
        _completedToday.clear();
        for (var name in completedList) {
          final p = Prayer.values.firstWhere((e) => e.name == name, orElse: () => Prayer.none);
          if (p != Prayer.none) _completedToday.add(p);
        }
        dailyStreak.value = prefs.getInt('streak_engine_daily') ?? _completedToday.length;

        // Parse and loop through each missed day
        try {
          final parts = savedDate.split('-');
          DateTime current = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          final todayDate = DateTime(now.year, now.month, now.day);

          while (current.isBefore(todayDate)) {
            await handleMidnightRollover(overrideDate: current, isHistoricalCatchUp: true);
            current = current.add(const Duration(days: 1));
          }

          // Safe recovery ordering: Score state first, then Streak state
          await ScoreEngine.instance.saveCurrentState();
          await _saveState(overrideToday: todayDate);
        } catch (_) {}
      } else if (savedDate == todayKey) {
        final completedList = prefs.getStringList('streak_engine_completed_today') ?? [];
        _completedToday.clear();
        for (var name in completedList) {
          final p = Prayer.values.firstWhere((e) => e.name == name, orElse: () => Prayer.none);
          if (p != Prayer.none) _completedToday.add(p);
        }
        dailyStreak.value = prefs.getInt('streak_engine_daily') ?? _completedToday.length;
      } else {
        _completedToday.clear();
        dailyStreak.value = 0;
        await prefs.setStringList('streak_engine_completed_today', []);
        await prefs.setString('streak_engine_date', todayKey);
        await prefs.setInt('streak_engine_daily', 0);
      }
    } catch (_) {}

    // Listen to prayer engine events
    PrayerEngine.instance.eventStream.listen((event) {
      if (event == PrayerEvent.midnight) {
        handleMidnightRollover();
      }
    });

    // Run ScoreEngine midnight check now that StreakEngine has initialized
    await ScoreEngine.instance.checkMidnightReset();
  }

  void clearStateForTesting() {
    _completedToday.clear();
    dailyStreak.value = 0;
    globalStreak.value = 0;
    fardhStreaks.value = {
      'الفجر': 0.0,
      'الظهر': 0.0,
      'العصر': 0.0,
      'المغرب': 0.0,
      'العشاء': 0.0,
    };
  }

  void addCompletedForTesting(Prayer prayer) {
    _completedToday.add(prayer);
  }

  bool isCompletedToday(Prayer prayer) {
    return _completedToday.contains(prayer);
  }

  String _getPrayerArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }

  Future<bool> completePrayer(Prayer prayer, double score, {bool isQada = false, String? dateKey}) async {
    if (prayer == Prayer.none || prayer == Prayer.sunrise) return false;
    
    // Prevent duplicate completions (for today's fardh)
    if (!isQada && _completedToday.contains(prayer)) {
      AppLogger.warning('Prayer ${prayer.name} already completed today. Skipping.', tag: 'StreakEngine');
      return false; 
    }

    final now = DateTime.now();
    final effectiveDateKey = dateKey ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final txId = isQada 
        ? 'qada_${prayer.name}_$effectiveDateKey'
        : 'fardh_${prayer.name}_$effectiveDateKey';

    // Grant Score through ScoreEngine (idempotent check)
    final scoreAdded = await ScoreEngine.instance.addScore(txId, score);
    if (!scoreAdded) {
      AppLogger.warning('Transaction $txId was already recorded. Skipping duplicate credit.', tag: 'StreakEngine');
      return false;
    }

    if (!isQada) {
      _completedToday.add(prayer);
      dailyStreak.value = _completedToday.length;
    }
    
    final prayerName = _getPrayerArabicName(prayer);
    final currentMap = Map<String, double>.from(fardhStreaks.value);
    
    if (isQada) {
      // +0.5 for Qada
      currentMap[prayerName] = (currentMap[prayerName] ?? 0.0) + 0.5;
    } else {
      // +1.0 for on time
      currentMap[prayerName] = (currentMap[prayerName] ?? 0.0) + 1.0;
    }
    
    fardhStreaks.value = currentMap;

    // Save State
    await _saveState();
    
    return true;
  }

  /// Boosts all Fardh streaks (Consistency Bonus)
  Future<void> boostStreaks(double amount) async {
    final currentMap = Map<String, double>.from(fardhStreaks.value);
    currentMap.forEach((key, val) {
      currentMap[key] = val + amount;
    });
    fardhStreaks.value = currentMap;
    await _saveState();
    AppLogger.info('Streaks boosted by +$amount via BonusEngine consistency rule', tag: 'StreakEngine');
  }

  Future<void> handleMidnightRollover({DateTime? overrideDate, bool isHistoricalCatchUp = false}) async {
    final allFardh = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];
    final yesterday = overrideDate ?? DateTime.now().subtract(const Duration(days: 1));
    final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final currentMap = Map<String, double>.from(fardhStreaks.value);
    
    final coords = await PrayerConfig.getCoordinates();
    final params = PrayerConfig.params;
    final times = PrayerTimes(coords, DateComponents.from(yesterday), params);
    final ruleEngine = PrayerRuleEngine(times);

    // Load yesterday's DayRecord to ensure state is preserved across app restarts
    DayRecord? yesterdayRecord;
    try {
      yesterdayRecord = await sl<PrayerRepository>().loadTodayRecord(dateKey);
    } catch (_) {}

    // Check if a prayer was completed either in memory/preferences or in DayRecord (including Qada)
    bool isCompleted(Prayer p) {
      if (_completedToday.contains(p)) return true;
      if (yesterdayRecord != null) {
        final rec = yesterdayRecord.recordFor(_getPrayerArabicName(p));
        if (rec.state == PrayerState.completedIndividual ||
            rec.state == PrayerState.completedCongregation ||
            rec.state == PrayerState.oadaCompleted) {
          return true;
        }
      }
      return false;
    }

    for (final p in allFardh) {
      if (!isCompleted(p)) {
        // Penalty for missed prayer score from PrayerRuleEngine
        final dummyContext = DayContext(
          allFardhCongregation: false,
          allFardhWithSunnah: false,
          completedOnTime: 0,
          missed: 0,
          isPerfect3DayStreak: false,
        );
        final scorePenalty = ruleEngine.calculateScore(PrayerState.oadaPending, dummyContext);
        await ScoreEngine.instance.addScore('penalty_${p.name}_$dateKey', scorePenalty, saveToDisk: !isHistoricalCatchUp);
      }
    }

    // ── Streak break check ───────────────────────────────────────────────
    // Count missed prayers using both _completedToday and DayRecord
    int missedCount = 0;
    for (final p in allFardh) {
      if (!isCompleted(p)) {
        missedCount++;
      }
    }

    if (missedCount > 3) {
      // STREAK BREAK: More than 3 missed prayers in that day -> FULL streak/total score reset
      AppLogger.info(
        'Streak break! $missedCount missed prayers on $dateKey (>3). '
        'Resetting total score and global streak.',
        tag: 'StreakEngine',
      );

      await ScoreEngine.instance.resetTotalScore(saveToDisk: !isHistoricalCatchUp);
      globalStreak.value = 0;

      // Update Fardh-specific streaks
      for (final p in allFardh) {
        final prayerName = _getPrayerArabicName(p);
        if (!isCompleted(p)) {
          currentMap[prayerName] = ((currentMap[prayerName] ?? 0.0) - 1.0).clamp(0.0, double.infinity);
        }
      }

      fardhStreaks.value = currentMap;
      _completedToday.clear();
      dailyStreak.value = 0;
      final nextDay = yesterday.add(const Duration(days: 1));
      if (!isHistoricalCatchUp) {
        await _saveState(overrideToday: nextDay);
        // Tell score engine to check/perform rollover for the new day
        await ScoreEngine.instance.checkMidnightReset();
      }
      return; // Skip all bonus calculations
    }

    // ── Day had ≤3 missed prayers — proceed with bonus evaluation ─────

    // Load yesterday's DayRecord to evaluate congregation and sunnah bonuses
    try {
      final yesterdayRecord = await sl<PrayerRepository>().loadTodayRecord(dateKey);
      int yesterdayCongregation = 0;
      int yesterdayOnTime = 0;
      int yesterdayMissed = 0;

      for (final p in allFardh) {
        final rec = yesterdayRecord.recordFor(_getPrayerArabicName(p));
        if (rec.state == PrayerState.completedCongregation) {
          yesterdayCongregation++;
        }
        if (rec.state == PrayerState.completedIndividual || rec.state == PrayerState.completedCongregation) {
          yesterdayOnTime++;
        }
        if (rec.state == PrayerState.oadaPending) {
          yesterdayMissed++;
        }
      }

      // Daily Congregation Bonus (+30 score)
      final bool allCongregation = (yesterdayCongregation == 5);

      // Daily Sunnah Bonus (+50 score)
      final fajrRec = yesterdayRecord.recordFor('الفجر');
      final dhuhrRec = yesterdayRecord.recordFor('الظهر');
      final maghribRec = yesterdayRecord.recordFor('المغرب');
      final ishaRec = yesterdayRecord.recordFor('العشاء');

      final bool allSunnahDone = fajrRec.completedSunnah.contains(0) &&
                                 dhuhrRec.completedSunnah.contains(0) &&
                                 dhuhrRec.completedSunnah.contains(1) &&
                                 maghribRec.completedSunnah.contains(0) &&
                                 ishaRec.completedSunnah.contains(0);
      final bool allFardhWithSunnah = (yesterdayOnTime == 5 && allSunnahDone);

      // Check 3-Day Consistency Streak Perfect Check
      bool isPerfect3DayStreak = false;
      try {
        final history = await sl<PrayerRepository>().loadHistory();
        if (history.length >= 2) {
          final last2HistoryDays = history.sublist(history.length - 2);
          bool consistent = true;

          for (final day in last2HistoryDays) {
            int dayOnTime = 0;
            day.prayers.forEach((_, rec) {
              if (rec.state == PrayerState.completedIndividual || rec.state == PrayerState.completedCongregation) {
                dayOnTime++;
              }
            });
            if (dayOnTime < 5) {
              consistent = false;
              break;
            }
          }

          if (yesterdayOnTime < 5) {
            consistent = false;
          }
          isPerfect3DayStreak = consistent;
        }
      } catch (_) {}

      final dayContext = DayContext(
        allFardhCongregation: allCongregation,
        allFardhWithSunnah: allFardhWithSunnah,
        completedOnTime: yesterdayOnTime,
        missed: yesterdayMissed,
        isPerfect3DayStreak: isPerfect3DayStreak,
      );

      // Apply bonuses using calculateScore from PrayerRuleEngine
      if (allCongregation) {
        final bonusScore = ruleEngine.calculateScore(PrayerState.locked, dayContext, isMidnightRollover: true);
        // Since calculateScore returns total score including base state (here base state is locked -> 0, plus Congregation daily bonus 30),
        // we add the congregation daily bonus to ScoreEngine
        if (bonusScore >= PrayerRuleEngine.congregationDailyBonus) {
          await ScoreEngine.instance.addScore('congregation_daily_bonus_$dateKey', PrayerRuleEngine.congregationDailyBonus, saveToDisk: !isHistoricalCatchUp);
          AppLogger.info('Daily Congregation Bonus (+30 score) applied for date: $dateKey', tag: 'StreakEngine');
        }
      }

      if (allFardhWithSunnah) {
        // Sunnah daily bonus is 50
        await ScoreEngine.instance.addScore('sunnah_daily_bonus_$dateKey', PrayerRuleEngine.perfectSunnahDailyBonus, saveToDisk: !isHistoricalCatchUp);
        AppLogger.info('Daily Sunnah Bonus (+50 score) applied for date: $dateKey', tag: 'StreakEngine');
      }

      // Calculate streak change via Streak calculation rule (applied once per dateKey)
      final prefs = await SharedPreferences.getInstance();
      final streakTxId = 'streak_daily_change_$dateKey';
      if (!prefs.containsKey(streakTxId)) {
        await prefs.setBool(streakTxId, true);
        final int netStreakChange = ruleEngine.calculateStreak(dayContext);
        globalStreak.value = (globalStreak.value + netStreakChange).clamp(0, 999999);
      }

      if (isPerfect3DayStreak) {
        final txId = 'streak_consistency_bonus_$dateKey';
        if (!prefs.containsKey(txId)) {
          await prefs.setBool(txId, true);
          AppLogger.info('3-Day consistency streak bonus (+15 global streak) applied.', tag: 'StreakEngine');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to process yesterday record bonuses: $e', tag: 'StreakEngine');
    }

    // Update Fardh-specific streaks
    for (final p in allFardh) {
      final prayerName = _getPrayerArabicName(p);
      if (!_completedToday.contains(p)) {
        currentMap[prayerName] = ((currentMap[prayerName] ?? 0.0) - 1.0).clamp(0.0, double.infinity);
      }
    }

    fardhStreaks.value = currentMap;
    _completedToday.clear();
    dailyStreak.value = 0;
    final nextDay = yesterday.add(const Duration(days: 1));
    if (!isHistoricalCatchUp) {
      await _saveState(overrideToday: nextDay);
      // Tell score engine to check/perform rollover
      await ScoreEngine.instance.checkMidnightReset();
    }
  }

  Future<void> _saveState({DateTime? overrideToday}) async {
    await _repository.saveGlobalStreak(globalStreak.value);

    // Persist highest streak reached (never decreases even if streak resets to 0)
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHighest = prefs.getInt('highest_prayer_streak') ?? 0;
      if (globalStreak.value > currentHighest) {
        await prefs.setInt('highest_prayer_streak', globalStreak.value);
      }
    } catch (_) {}
    
    // Save fardh streaks
    await _repository.saveFardhStreaks(fardhStreaks.value);

    // Save completed list for backward compatibility
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = overrideToday ?? DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('streak_engine_date', todayKey);
      await prefs.setStringList('streak_engine_completed_today', _completedToday.map((e) => e.name).toList());
      await prefs.setInt('streak_engine_daily', dailyStreak.value);
    } catch (_) {}
  }
}
