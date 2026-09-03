import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:get_it/get_it.dart';

import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_rule_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/bonus_engine.dart';
import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';

void main() {
  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();
    SharedPreferences.setMockInitialValues({});

    sl.registerSingleton<ScoreRepository>(ScoreRepositoryImpl());
    sl.registerSingleton<StreakRepository>(StreakRepositoryImpl());
    sl.registerSingleton<PrayerRepository>(PrayerRepositoryImpl());

    final coords = Coordinates(30.0444, 31.2357);
    final params = CalculationMethod.egyptian.getParameters();
    final now = DateTime(2026, 6, 26, 12, 0);
    final times = PrayerTimes(coords, DateComponents.from(now), params);

    sl.registerSingleton<ScoreEngine>(ScoreEngine.instance);
    sl.registerSingleton<PrayerStreakEngine>(PrayerStreakEngine.instance);
    sl.registerSingleton<PrayerEngine>(PrayerEngine.instance);
    sl.registerSingleton<PrayerRuleEngine>(PrayerRuleEngine(times));
    sl.registerSingleton<BonusEngine>(BonusEngine.instance);

    PrayerEngine.instance.setTodayTimesForTesting(times);
    ScoreEngine.instance.clearStateForTesting();
    PrayerStreakEngine.instance.clearStateForTesting();
  });

  group('P0 Fix #1 — Score Double-Counting Prevention', () {
    test('First initialization starts with zero scores', () async {
      await ScoreEngine.instance.initialize();
      expect(ScoreEngine.instance.todayScore.value, 0.0);
      expect(ScoreEngine.instance.totalScore.value, 0.0);
    });

    test('Same-day restart preserves today and total scores without duplication', () async {
      await ScoreEngine.instance.initialize();
      await ScoreEngine.instance.addScore('fardh_fajr_2026-09-01', 27.0);
      await ScoreEngine.instance.addScore('fardh_dhuhr_2026-09-01', 1.0);

      expect(ScoreEngine.instance.todayScore.value, 28.0);
      expect(ScoreEngine.instance.totalScore.value, 28.0);

      // Simulate restart on same day
      await ScoreEngine.instance.initialize();
      expect(ScoreEngine.instance.todayScore.value, 28.0);
      expect(ScoreEngine.instance.totalScore.value, 28.0);
    });

    test('Next-day restart does NOT double count previous day score', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('score_engine_today', 100.0);
      await prefs.setDouble('score_engine_total', 100.0);
      await prefs.setString('score_engine_last_reset', '2026-09-01');

      // Initialize on Day 2
      await ScoreEngine.instance.initialize();

      // Total score must remain 100.0, NOT 200.0
      expect(ScoreEngine.instance.totalScore.value, 100.0);
    });

    test('Multiple restarts on next day keep total score completely stable', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('score_engine_today', 50.0);
      await prefs.setDouble('score_engine_total', 50.0);
      await prefs.setString('score_engine_last_reset', '2026-09-01');

      for (int i = 0; i < 5; i++) {
        await ScoreEngine.instance.initialize();
        expect(ScoreEngine.instance.totalScore.value, 50.0);
      }
    });

    test('Midnight rollover archives today score into history and resets today score to 0', () async {
      await ScoreEngine.instance.initialize();
      await ScoreEngine.instance.addScore('tx_1', 40.0);
      expect(ScoreEngine.instance.todayScore.value, 40.0);
      expect(ScoreEngine.instance.totalScore.value, 40.0);

      await ScoreEngine.instance.handleMidnightRollover('2026-09-02');

      expect(ScoreEngine.instance.todayScore.value, 0.0);
      expect(ScoreEngine.instance.totalScore.value, 40.0);

      final history = await sl<ScoreRepository>().loadScoreHistory();
      expect(history.length, 1);
      expect(history.first.contains('40.0'), isTrue);
    });
  });

  group('P0 Fix #2 — Isha / Midnight Prayer Window & Boundary Conditions', () {
    test('Isha window is open before midnight, at midnight, and until Fajr', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final day1 = DateTime(2026, 6, 26);
      final times = PrayerTimes(coords, DateComponents.from(day1), params);
      final ruleEngine = PrayerRuleEngine(times);

      // 1. Before midnight: 23:59 Day 1
      final beforeMidnight = DateTime(2026, 6, 26, 23, 59);
      expect(ruleEngine.isPrayerOpen(PrayerType.isha, beforeMidnight), isTrue);

      // 2. Exactly midnight: 00:00 Day 2
      final midnight = DateTime(2026, 6, 27, 0, 0);
      expect(ruleEngine.isPrayerOpen(PrayerType.isha, midnight), isTrue);

      // 3. After midnight: 01:30 AM Day 2
      final afterMidnight = DateTime(2026, 6, 27, 1, 30);
      expect(ruleEngine.isPrayerOpen(PrayerType.isha, afterMidnight), isTrue);

      // 4. Just before Fajr: 04:00 AM Day 2 (assuming Fajr is ~04:30)
      final day2Times = PrayerTimes(coords, DateComponents.from(DateTime(2026, 6, 27)), params);
      final justBeforeFajr = day2Times.fajr.subtract(const Duration(minutes: 5));
      expect(ruleEngine.isPrayerOpen(PrayerType.isha, justBeforeFajr), isTrue);

      // 5. At Fajr: Fajr opens, Isha closes
      final atFajr = day2Times.fajr.add(const Duration(seconds: 1));
      expect(ruleEngine.isPrayerOpen(PrayerType.isha, atFajr), isFalse);
      expect(ruleEngine.isPrayerOpen(PrayerType.fajr, atFajr), isTrue);
    });

    test('getActiveFardhPrayer returns Isha between midnight and Fajr', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 27, 2, 0); // 02:00 AM
      final times = PrayerTimes(coords, DateComponents.from(now), params);

      final engine = PrayerEngine.instance;
      engine.setTodayTimesForTesting(times);

      expect(now.isBefore(times.fajr), isTrue);
      expect(engine.getActiveFardhPrayer(now), Prayer.isha);
    });

    test('prayerDate maps post-midnight hours to previous prayer day', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final nightTime = DateTime(2026, 6, 27, 1, 30); // 1:30 AM on June 27
      final times = PrayerTimes(coords, DateComponents.from(nightTime), params);

      PrayerEngine.instance.setTodayTimesForTesting(times);

      final targetDate = prayerDate(nightTime);
      expect(targetDate.day, 26);
    });
  });

  group('P0 Fix #4 — Streak Unit Representation as Days', () {
    test('calculateStreak returns +1 day for 5 completed on-time prayers', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      final perfectDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 5,
        missed: 0,
        isPerfect3DayStreak: false,
      );
      expect(ruleEngine.calculateStreak(perfectDay), 1); // 1 day
    });

    test('calculateStreak preserves streak (0 change) for 1-3 missed prayers', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      for (int missed = 1; missed <= 3; missed++) {
        final day = DayContext(
          allFardhCongregation: false,
          allFardhWithSunnah: false,
          completedOnTime: 5 - missed,
          missed: missed,
          isPerfect3DayStreak: false,
        );
        expect(ruleEngine.calculateStreak(day), 0); // 0-3 missed: streak maintained
      }
    });

    test('3-day consistency bonus adds +1 bonus day to streak', () {
      final coords = Coordinates(30.0444, 31.2357);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      final consistencyDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 5,
        missed: 0,
        isPerfect3DayStreak: true,
      );
      expect(ruleEngine.calculateStreak(consistencyDay), 2); // 1 normal day + 1 bonus day
    });

    test('>3 missed prayers triggers full streak and total score reset', () async {
      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      // Seed active streak and score
      engine.globalStreak.value = 10;
      await ScoreEngine.instance.addScore('init_tx', 150.0);
      expect(ScoreEngine.instance.totalScore.value, 150.0);
      expect(engine.globalStreak.value, 10);

      // Only complete 1 prayer (4 missed > 3)
      engine.addCompletedForTesting(Prayer.fajr);

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final yesterdayRecord = DayRecord(dateKey: dateKey);
      yesterdayRecord.recordFor('الفجر').state = PrayerState.completedIndividual;
      await sl<PrayerRepository>().saveTodayRecord(yesterdayRecord);

      await engine.handleMidnightRollover();

      // Streak and Total Score must be reset to 0
      expect(engine.globalStreak.value, 0);
      expect(ScoreEngine.instance.totalScore.value, 0.0);
    });
  });

  group('P0 Fix #5 — Qada Completed Is Protected from Missed Penalties', () {
    test('Unprayed missed prayer receives -2.0 penalty at rollover', () async {
      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final yesterdayRecord = DayRecord(dateKey: dateKey);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب']) {
        yesterdayRecord.recordFor(name).state = PrayerState.completedIndividual;
      }
      yesterdayRecord.recordFor('العشاء').state = PrayerState.oadaPending;
      await sl<PrayerRepository>().saveTodayRecord(yesterdayRecord);

      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib]) {
        engine.addCompletedForTesting(p);
      }

      await engine.handleMidnightRollover();

      final txs = await sl<ScoreRepository>().loadProcessedTransactions();
      expect(txs.contains('penalty_isha_$dateKey'), isTrue);
    });

    test('Qada completed before rollover is NOT penalized with -2.0', () async {
      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final yesterdayRecord = DayRecord(dateKey: dateKey);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب']) {
        yesterdayRecord.recordFor(name).state = PrayerState.completedIndividual;
      }
      // Isha was missed but made up as Qada (oadaCompleted)
      yesterdayRecord.recordFor('العشاء').state = PrayerState.oadaCompleted;
      await sl<PrayerRepository>().saveTodayRecord(yesterdayRecord);

      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib]) {
        engine.addCompletedForTesting(p);
      }

      await engine.handleMidnightRollover();

      final txs = await sl<ScoreRepository>().loadProcessedTransactions();
      expect(txs.contains('penalty_isha_$dateKey'), isFalse);
    });

    test('4 Qada completed prayers do not trigger false >3 streak break', () async {
      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      engine.globalStreak.value = 5;
      await ScoreEngine.instance.addScore('seed_tx', 100.0);

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final yesterdayRecord = DayRecord(dateKey: dateKey);
      yesterdayRecord.recordFor('الفجر').state = PrayerState.completedIndividual;
      yesterdayRecord.recordFor('الظهر').state = PrayerState.oadaCompleted;
      yesterdayRecord.recordFor('العصر').state = PrayerState.oadaCompleted;
      yesterdayRecord.recordFor('المغرب').state = PrayerState.oadaCompleted;
      yesterdayRecord.recordFor('العشاء').state = PrayerState.oadaCompleted;
      await sl<PrayerRepository>().saveTodayRecord(yesterdayRecord);

      engine.addCompletedForTesting(Prayer.fajr);

      await engine.handleMidnightRollover();

      // Streak should NOT be reset to 0 because all prayers were completed
      expect(engine.globalStreak.value, greaterThan(0));
      expect(ScoreEngine.instance.totalScore.value, greaterThan(0.0));
    });
  });
}
