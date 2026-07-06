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

void main() {
  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    
    // Repositories
    sl.registerSingleton<ScoreRepository>(ScoreRepositoryImpl());
    sl.registerSingleton<StreakRepository>(StreakRepositoryImpl());
    sl.registerSingleton<PrayerRepository>(PrayerRepositoryImpl());

    // Engines & Services
    final coords = Coordinates(30.0, 31.0);
    final params = CalculationMethod.egyptian.getParameters();
    final now = DateTime(2026, 6, 26, 12, 0);
    final times = PrayerTimes(coords, DateComponents.from(now), params);

    sl.registerSingleton<ScoreEngine>(ScoreEngine.instance);
    sl.registerSingleton<PrayerStreakEngine>(PrayerStreakEngine.instance);
    sl.registerSingleton<PrayerEngine>(PrayerEngine.instance);
    sl.registerSingleton<PrayerRuleEngine>(PrayerRuleEngine(times));

    ScoreEngine.instance.clearStateForTesting();
    PrayerStreakEngine.instance.clearStateForTesting();
  });

  group('PrayerRuleEngine Window & Scoring Tests', () {
    test('isPrayerOpen returns true during active window and false otherwise', () {
      final coords = Coordinates(30.0, 31.0);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      expect(ruleEngine.isPrayerOpen(PrayerType.dhuhr, times.dhuhr.add(const Duration(minutes: 5))), isTrue);
      expect(ruleEngine.isPrayerOpen(PrayerType.fajr, times.dhuhr.add(const Duration(minutes: 5))), isFalse);
    });

    test('calculateScore calculates scores correctly for Fardh and Bonuses', () {
      final coords = Coordinates(30.0, 31.0);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      final dummyDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 0,
        missed: 0,
        isPerfect3DayStreak: false,
      );

      expect(ruleEngine.calculateScore(PrayerState.completedIndividual, dummyDay), 1.0);
      expect(ruleEngine.calculateScore(PrayerState.completedCongregation, dummyDay), 27.0);
      expect(ruleEngine.calculateScore(PrayerState.oadaCompleted, dummyDay), 0.5);
      expect(ruleEngine.calculateScore(PrayerState.oadaPending, dummyDay), -2.0);

      // Verify rollover congregation bonus (+30) and sunnah bonus (+50)
      final perfectDay = DayContext(
        allFardhCongregation: true,
        allFardhWithSunnah: true,
        completedOnTime: 5,
        missed: 0,
        isPerfect3DayStreak: false,
      );

      // When rollover triggers, state is usually locked (0 base), plus bonuses
      final rolloverScore = ruleEngine.calculateScore(PrayerState.locked, perfectDay, isMidnightRollover: true);
      expect(rolloverScore, 80.0); // 30 + 50
    });

    test('calculateStreak applies streaks and consistency bonus correctly', () {
      final coords = Coordinates(30.0, 31.0);
      final params = CalculationMethod.egyptian.getParameters();
      final now = DateTime(2026, 6, 26, 12, 0);
      final times = PrayerTimes(coords, DateComponents.from(now), params);
      final ruleEngine = PrayerRuleEngine(times);

      // 4 completed on time - 1 missed = +3 base change
      final typicalDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 4,
        missed: 1,
        isPerfect3DayStreak: false,
      );
      expect(ruleEngine.calculateStreak(typicalDay), 3);

      // Max clamp 5
      final perfectDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 5,
        missed: 0,
        isPerfect3DayStreak: false,
      );
      expect(ruleEngine.calculateStreak(perfectDay), 5);

      // Min clamp -5
      final badDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 0,
        missed: 5,
        isPerfect3DayStreak: false,
      );
      expect(ruleEngine.calculateStreak(badDay), -5);

      // Consistency perfect 3 day streak bonus (+15) on top of perfect day (+5) = 20
      final consistencyDay = DayContext(
        allFardhCongregation: false,
        allFardhWithSunnah: false,
        completedOnTime: 5,
        missed: 0,
        isPerfect3DayStreak: true,
      );
      expect(ruleEngine.calculateStreak(consistencyDay), 20);
    });
  });

  group('Score & Bonus Engine Rollover Integration Tests', () {
    test('Unit test: +30 congregation bonus condition works', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final mockRecord = DayRecord(dateKey: dateKey);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
        mockRecord.recordFor(name).state = PrayerState.completedCongregation;
      }
      await sl<PrayerRepository>().saveTodayRecord(mockRecord);

      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      // Populate completed today directly to avoid SharedPreferences mock issues
      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
        engine.addCompletedForTesting(p);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('score_engine_history', []);
      await prefs.setStringList('score_engine_transactions', []);
      await prefs.setString('score_engine_last_reset', todayKey);

      await engine.handleMidnightRollover();

      final txs = await sl<ScoreRepository>().loadProcessedTransactions();
      expect(txs.any((tx) => tx.startsWith('congregation_daily_bonus_')), isTrue);
    });

    test('Unit test: +50 sunnah bonus condition works', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final mockRecord = DayRecord(dateKey: dateKey);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
        mockRecord.recordFor(name).state = PrayerState.completedIndividual;
      }
      mockRecord.recordFor('الفجر').completedSunnah.add(0);
      mockRecord.recordFor('الظهر').completedSunnah.addAll([0, 1]);
      mockRecord.recordFor('المغرب').completedSunnah.add(0);
      mockRecord.recordFor('العشاء').completedSunnah.add(0);

      await sl<PrayerRepository>().saveTodayRecord(mockRecord);

      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
        engine.addCompletedForTesting(p);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('score_engine_transactions', []);
      await prefs.setString('score_engine_last_reset', todayKey);

      await engine.handleMidnightRollover();

      final txs = await sl<ScoreRepository>().loadProcessedTransactions();
      expect(txs.any((tx) => tx.startsWith('sunnah_daily_bonus_')), isTrue);
    });

    test('Unit test: +15 streak consistency bonus condition works', () async {
      final now = DateTime.now();
      final dateKeys = List.generate(3, (i) {
        final d = now.subtract(Duration(days: 3 - i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });

      final history = <DayRecord>[];
      for (int i = 0; i < 2; i++) {
        final r = DayRecord(dateKey: dateKeys[i]);
        for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
          r.recordFor(name).state = PrayerState.completedIndividual;
        }
        history.add(r);
      }
      await sl<PrayerRepository>().saveHistory(history);

      final yesterdayRecord = DayRecord(dateKey: dateKeys[2]);
      for (final name in ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
        yesterdayRecord.recordFor(name).state = PrayerState.completedIndividual;
      }
      await sl<PrayerRepository>().saveTodayRecord(yesterdayRecord);

      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      engine.globalStreak.value = 10;

      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
        engine.addCompletedForTesting(p);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('streak_consistency_bonus_${dateKeys[2]}');

      await engine.handleMidnightRollover();

      // globalStreak should be: 10 (base) + 5 (daily streak from yesterday completed) + 15 (consistency bonus) = 30
      expect(engine.globalStreak.value, 30);
    });

    test('Unit test: missed prayer penalties (-2) are applied', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final engine = PrayerStreakEngine.instance;
      await engine.initialize();
      await ScoreEngine.instance.initialize();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('score_engine_transactions', []);
      await prefs.setStringList('streak_engine_completed_today', []);
      await engine.initialize();

      await engine.handleMidnightRollover();

      final txs = await sl<ScoreRepository>().loadProcessedTransactions();
      expect(txs.any((tx) => tx.startsWith('penalty_')), isTrue);
    });
  });
}
