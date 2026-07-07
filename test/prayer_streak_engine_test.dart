import 'dart:convert';
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

    test('PrayerStreakEngine retroactively rolls over missed days on initialize', () async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final dateKeyTwoDaysAgo = '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('streak_engine_date', dateKeyTwoDaysAgo);
      await prefs.setStringList('streak_engine_completed_today', ['fajr']); // Fajr completed 2 days ago
      await prefs.setInt('streak_engine_daily', 1);

      final engine = PrayerStreakEngine.instance;
      engine.fardhStreaks.value = {
        'الفجر': 10.0,
        'الظهر': 10.0,
        'العصر': 10.0,
        'المغرب': 10.0,
        'العشاء': 10.0,
      };

      await engine.initialize();

      // Fajr was completed 2 days ago (not decremented for 2 days ago, but decremented for yesterday -> 10.0 - 1.0 = 9.0)
      // Others missed both days (decremented twice -> 10.0 - 2.0 = 8.0)
      expect(engine.fardhStreaks.value['الفجر'], 9.0);
      expect(engine.fardhStreaks.value['الظهر'], 8.0);
      expect(engine.fardhStreaks.value['العصر'], 8.0);
      expect(engine.fardhStreaks.value['المغرب'], 8.0);
      expect(engine.fardhStreaks.value['العشاء'], 8.0);
      
      final savedDate = prefs.getString('streak_engine_date');
      expect(savedDate, todayKey);
    });

    test('ScoreEngine and PrayerStreakEngine rollover coordination test (Race Condition Prevention)', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dateKeyYesterday = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      
      // Simulate yesterday's initial state
      await prefs.setString('streak_engine_date', dateKeyYesterday);
      await prefs.setStringList('streak_engine_completed_today', []); // Yesterday all missed
      await prefs.setInt('streak_engine_daily', 0);
      
      await prefs.setString('score_engine_last_reset', dateKeyYesterday);
      await prefs.setDouble('score_engine_today', 10.0); // Yesterday's base score
      await prefs.setDouble('score_engine_total', 20.0);
      await prefs.setStringList('score_engine_transactions', []);

      // Re-initialize engines to simulate app launch
      await ScoreEngine.instance.initialize();
      await PrayerStreakEngine.instance.initialize();

      // Check results:
      // Yesterday's score was 10.0.
      // Yesterday had 5 missed prayers (all missed), which is -10.0 penalty.
      // Net yesterday's score: 10.0 - 10.0 = 0.0.
      // When rolled over correctly:
      // totalScore should be: 20.0 (prev total) + 0.0 (net yesterday) = 20.0.
      // todayScore (for today, fresh start) should be: 0.0.
      expect(ScoreEngine.instance.totalScore.value, 20.0);
      expect(ScoreEngine.instance.todayScore.value, 0.0);
      
      final savedResetDate = prefs.getString('score_engine_last_reset');
      expect(savedResetDate, todayKey);
    });

    test('PrayerStreakEngine saves and loads fardh streaks decimals correctly without rounding', () async {
      final engine = PrayerStreakEngine.instance;
      
      // Inject some decimal values
      engine.fardhStreaks.value = {
        'الفجر': 1.5,
        'الظهر': 2.75,
        'العصر': 0.0,
        'المغرب': 4.5,
        'العشاء': 0.5,
      };

      final repo = sl<StreakRepository>();
      await repo.saveFardhStreaks(engine.fardhStreaks.value);

      final loaded = await repo.loadFardhStreaks();
      expect(loaded['الفجر'], 1.5);
      expect(loaded['الظهر'], 2.75);
      expect(loaded['العصر'], 0.0);
      expect(loaded['المغرب'], 4.5);
      expect(loaded['العشاء'], 0.5);
    });

    test('ScoreRepository saveScoreState writes all score-related states atomically', () async {
      final repo = sl<ScoreRepository>();
      
      await repo.saveScoreState(
        todayScore: 5.5,
        totalScore: 120.0,
        processedTransactions: ['tx_1', 'tx_2'],
        lastResetDate: '2026-07-07',
        history: ['2026-07-06:10.0'],
      );

      final today = await repo.loadTodayScore();
      final total = await repo.loadTotalScore();
      final txs = await repo.loadProcessedTransactions();
      final lastReset = await repo.loadLastResetDate();
      final history = await repo.loadScoreHistory();

      expect(today, 5.5);
      expect(total, 120.0);
      expect(txs, ['tx_1', 'tx_2']);
      expect(lastReset, '2026-07-07');
      expect(history, ['2026-07-06:10.0']);
    });

    test('ScoreEngine totalScore is updated in real-time when addScore is called', () async {
      final engine = ScoreEngine.instance;
      engine.clearStateForTesting();
      
      expect(engine.todayScore.value, 0.0);
      expect(engine.totalScore.value, 0.0);

      // Add a score event
      await engine.addScore('tx_realtime_1', 15.0);

      // Both todayScore and totalScore should be updated instantly
      expect(engine.todayScore.value, 15.0);
      expect(engine.totalScore.value, 15.0);

      // Add another score event
      await engine.addScore('tx_realtime_2', 10.0);
      expect(engine.todayScore.value, 25.0);
      expect(engine.totalScore.value, 25.0);
    });

    test('BonusEngine checkAndApplyConsistencyBonus only applies consistency bonus once per day', () async {
      final prefs = await SharedPreferences.getInstance();

      final perfectDay1 = DayRecord(dateKey: '2026-06-23', prayers: {
        'الفجر': PrayerRecord(state: PrayerState.completedIndividual),
        'الظهر': PrayerRecord(state: PrayerState.completedIndividual),
        'العصر': PrayerRecord(state: PrayerState.completedIndividual),
        'المغرب': PrayerRecord(state: PrayerState.completedIndividual),
        'العشاء': PrayerRecord(state: PrayerState.completedIndividual),
      });
      final perfectDay2 = DayRecord(dateKey: '2026-06-24', prayers: {
        'الفجر': PrayerRecord(state: PrayerState.completedIndividual),
        'الظهر': PrayerRecord(state: PrayerState.completedIndividual),
        'العصر': PrayerRecord(state: PrayerState.completedIndividual),
        'المغرب': PrayerRecord(state: PrayerState.completedIndividual),
        'العشاء': PrayerRecord(state: PrayerState.completedIndividual),
      });
      final perfectDay3 = DayRecord(dateKey: '2026-06-25', prayers: {
        'الفجر': PrayerRecord(state: PrayerState.completedIndividual),
        'الظهر': PrayerRecord(state: PrayerState.completedIndividual),
        'العصر': PrayerRecord(state: PrayerState.completedIndividual),
        'المغرب': PrayerRecord(state: PrayerState.completedIndividual),
        'العشاء': PrayerRecord(state: PrayerState.completedIndividual),
      });

      final historyJson = jsonEncode([
        perfectDay1.toJson(),
        perfectDay2.toJson(),
        perfectDay3.toJson(),
      ]);
      await prefs.setString('pt2_history', historyJson);

      final streakEngine = PrayerStreakEngine.instance;
      streakEngine.fardhStreaks.value = {
        'الفجر': 5.0,
        'الظهر': 5.0,
        'العصر': 5.0,
        'المغرب': 5.0,
        'العشاء': 5.0,
      };

      final bonusEngine = BonusEngine.instance;
      
      // First check
      await bonusEngine.checkAndApplyConsistencyBonus();
      expect(streakEngine.fardhStreaks.value['الفجر'], 6.0);

      // Second check (on the same day)
      await bonusEngine.checkAndApplyConsistencyBonus();
      expect(streakEngine.fardhStreaks.value['الفجر'], 6.0); // Should remain 6.0, not 7.0!
    });

    test('PrayerEngine reloadCoordinates updates coordinates and propagates them to PrayerRuleEngine', () async {
      final prayerEngine = PrayerEngine.instance;
      final ruleEngine = sl<PrayerRuleEngine>();

      // Mock new coordinates in SharedPreferences via PrayerConfig
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prayer_lat', 24.4539); // Abu Dhabi
      await prefs.setDouble('prayer_lng', 54.3773);
      
      // Call reloadCoordinates
      await prayerEngine.reloadCoordinates();

      // Verify that coordinates were updated and times recalculated
      final updatedCoords = ruleEngine.times.coordinates;
      expect(updatedCoords.latitude, 24.4539);
      expect(updatedCoords.longitude, 54.3773);
    });
  });
}
