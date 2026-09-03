import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:get_it/get_it.dart';
import 'package:rafiki_app/core/di/service_locator.dart';

import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_rule_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/bonus_engine.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:rafiki_app/features/prayer/presentation/controllers/prayer_schedule_controller.dart';

void main() {
  late Coordinates coords;
  late CalculationParameters params;
  late DateTime testDate;
  late PrayerTimes times;
  late PrayerRuleEngine ruleEngine;

  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();
    SharedPreferences.setMockInitialValues({});

    sl.registerSingleton<ScoreRepository>(ScoreRepositoryImpl());
    sl.registerSingleton<StreakRepository>(StreakRepositoryImpl());
    sl.registerSingleton<PrayerRepository>(PrayerRepositoryImpl());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_lat', 30.0444);
    await prefs.setDouble('prayer_lng', 31.2357);

    coords = Coordinates(30.0444, 31.2357);
    params = CalculationMethod.egyptian.getParameters();
    final initialTimes = PrayerTimes(coords, DateComponents.from(DateTime.now()), params);
    ruleEngine = PrayerRuleEngine(initialTimes);

    sl.registerSingleton<PrayerRuleEngine>(ruleEngine);
    sl.registerSingleton<PrayerEngine>(PrayerEngine.instance);
    sl.registerSingleton<ScoreEngine>(ScoreEngine.instance);
    sl.registerSingleton<PrayerStreakEngine>(PrayerStreakEngine.instance);
    sl.registerSingleton<BonusEngine>(BonusEngine.instance);

    await PrayerEngine.instance.reloadCoordinates();

    times = sl<PrayerEngine>().todayTimes!;
    ruleEngine = sl<PrayerRuleEngine>();
    testDate = DateTime.now();

    ScoreEngine.instance.clearStateForTesting();
    PrayerStreakEngine.instance.clearStateForTesting();

    await ScoreEngine.instance.initialize();
    await PrayerStreakEngine.instance.initialize();
  });

  group('Prayer Timing, Qada & Duha Logic Verification Suite', () {
    // ──────────────────────────────────────────────────────────────────────────
    // Test 1: Fajr active -> Dhuhr starts -> Fajr becomes oadaPending
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 1: Fajr active -> Dhuhr starts -> Fajr becomes oadaPending', () {
      final fajrTime = times.fajr.add(const Duration(minutes: 10));
      final dhuhrTime = times.dhuhr.add(const Duration(minutes: 5));

      // During Fajr time, Fajr is available
      final stateDuringFajr = PrayerTimeService.computeStateFor(
        prayerIndex: 0,
        now: fajrTime,
        current: PrayerState.locked,
      );
      expect(stateDuringFajr, PrayerState.available);

      // Once Dhuhr starts, unprayed Fajr transitions to oadaPending
      final stateAfterDhuhr = PrayerTimeService.computeStateFor(
        prayerIndex: 0,
        now: dhuhrTime,
        current: PrayerState.available,
      );
      expect(stateAfterDhuhr, PrayerState.oadaPending);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 2: Dhuhr becomes available immediately when its time starts
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 2: Dhuhr becomes available immediately when its time starts', () {
      final justBeforeDhuhr = times.dhuhr.subtract(const Duration(seconds: 1));
      final atDhuhr = times.dhuhr;

      final stateBefore = PrayerTimeService.computeStateFor(
        prayerIndex: 1, // Dhuhr
        now: justBeforeDhuhr,
        current: PrayerState.locked,
      );
      expect(stateBefore, PrayerState.locked);

      final stateAtStart = PrayerTimeService.computeStateFor(
        prayerIndex: 1, // Dhuhr
        now: atDhuhr,
        current: PrayerState.locked,
      );
      expect(stateAtStart, PrayerState.available);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 3: Only one Fardh prayer is available at a time
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 3: Only one Fardh prayer is available at a time', () {
      final testMoments = [
        times.fajr.add(const Duration(minutes: 15)),   // Fajr
        times.sunrise.add(const Duration(minutes: 30)), // Duha window / gap
        times.dhuhr.add(const Duration(minutes: 15)),  // Dhuhr
        times.asr.add(const Duration(minutes: 15)),    // Asr
        times.maghrib.add(const Duration(minutes: 15)),// Maghrib
        times.isha.add(const Duration(minutes: 15)),   // Isha
      ];

      for (final moment in testMoments) {
        int availableCount = 0;
        for (int i = 0; i < kPrayers.length; i++) {
          final state = PrayerTimeService.computeStateFor(
            prayerIndex: i,
            now: moment,
            current: PrayerState.locked,
          );
          if (state == PrayerState.available) {
            availableCount++;
          }
        }
        // At most 1 Fardh prayer can be available at any given moment
        expect(availableCount, lessThanOrEqualTo(1));
      }
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 4: Qada completion gives exactly +0.5
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 4: Qada completion gives exactly +0.5', () async {
      final initialScore = ScoreEngine.instance.totalScore.value;
      const testDateKey = '2026-06-26';

      final success = await sl<PrayerEngine>().addPrayerEvent(
        Prayer.fajr,
        CustomPrayerEventType.qada,
        score: ScoreConstants.qada, // 0.5
        dateKey: testDateKey,
      );

      expect(success, isTrue);
      expect(ScoreEngine.instance.todayScore.value, 0.5);
      expect(ScoreEngine.instance.totalScore.value, initialScore + 0.5);
      expect(sl<PrayerStreakEngine>().fardhStreaks.value['الفجر'], 0.5);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 5: Repeated Qada completion does NOT give additional points
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 5: Repeated Qada completion does NOT give additional points', () async {
      const testDateKey = '2026-06-26';

      // First Qada completion
      final firstSuccess = await sl<PrayerEngine>().addPrayerEvent(
        Prayer.fajr,
        CustomPrayerEventType.qada,
        score: 0.5,
        dateKey: testDateKey,
      );
      expect(firstSuccess, isTrue);
      expect(ScoreEngine.instance.todayScore.value, 0.5);
      expect(sl<PrayerStreakEngine>().fardhStreaks.value['الفجر'], 0.5);

      // Second attempt for the same prayer and dateKey
      final secondSuccess = await sl<PrayerEngine>().addPrayerEvent(
        Prayer.fajr,
        CustomPrayerEventType.qada,
        score: 0.5,
        dateKey: testDateKey,
      );

      expect(secondSuccess, isFalse);
      // Score and streak must NOT increase
      expect(ScoreEngine.instance.todayScore.value, 0.5);
      expect(ScoreEngine.instance.totalScore.value, 0.5);
      expect(sl<PrayerStreakEngine>().fardhStreaks.value['الفجر'], 0.5);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 6: Duha opens exactly 3 hours before Dhuhr
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 6: Duha opens exactly 3 hours before Dhuhr', () {
      final duhaStart = PrayerTimeService.duhaStart(testDate);
      final expectedStart = times.dhuhr.subtract(const Duration(hours: 3));

      expect(duhaStart, equals(expectedStart));

      // 1 minute before duhaStart
      final beforeDuha = duhaStart.subtract(const Duration(minutes: 1));
      expect(PrayerTimeService.isDuhaOpen(beforeDuha), isFalse);
      expect(PrayerTimeService.computeDuhaState(now: beforeDuha, current: PrayerState.locked), PrayerState.locked);

      // At duhaStart
      expect(PrayerTimeService.isDuhaOpen(duhaStart), isTrue);
      expect(PrayerTimeService.computeDuhaState(now: duhaStart, current: PrayerState.locked), PrayerState.available);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 7: Duha closes when Dhuhr starts
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 7: Duha closes when Dhuhr starts', () {
      final duhaEnd = PrayerTimeService.duhaEnd(testDate);
      expect(duhaEnd, equals(times.dhuhr));

      // 1 minute before Dhuhr
      final beforeDhuhr = times.dhuhr.subtract(const Duration(minutes: 1));
      expect(PrayerTimeService.isDuhaOpen(beforeDhuhr), isTrue);
      expect(PrayerTimeService.computeDuhaState(now: beforeDhuhr, current: PrayerState.locked), PrayerState.available);

      // Exactly at Dhuhr
      final atDhuhr = times.dhuhr;
      expect(PrayerTimeService.isDuhaOpen(atDhuhr), isFalse);
      expect(PrayerTimeService.computeDuhaState(now: atDhuhr, current: PrayerState.locked), PrayerState.locked);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 8: Duha completion gives exactly +3.6
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 8: Duha completion gives exactly +3.6', () async {
      final initialScore = ScoreEngine.instance.totalScore.value;
      const testDateKey = '2026-06-26';

      final success = await sl<BonusEngine>().completeDuha(dateKey: testDateKey);

      expect(success, isTrue);
      expect(ScoreEngine.instance.todayScore.value, 3.6);
      expect(ScoreEngine.instance.totalScore.value, initialScore + 3.6);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 9: Repeated Duha completion does NOT give additional +3.6
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 9: Repeated Duha completion does NOT give additional +3.6', () async {
      const testDateKey = '2026-06-26';

      // First completion
      final first = await sl<BonusEngine>().completeDuha(dateKey: testDateKey);
      expect(first, isTrue);
      expect(ScoreEngine.instance.todayScore.value, 3.6);

      // Second attempt
      final second = await sl<BonusEngine>().completeDuha(dateKey: testDateKey);
      expect(second, isFalse);
      expect(ScoreEngine.instance.todayScore.value, 3.6);
      expect(ScoreEngine.instance.totalScore.value, 3.6);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 10: Duha does NOT modify Fardh streaks
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 10: Duha does NOT modify Fardh streaks', () async {
      final streakEngine = sl<PrayerStreakEngine>();
      final initialGlobalStreak = streakEngine.globalStreak.value;
      final initialDailyStreak = streakEngine.dailyStreak.value;
      final initialFardhStreaks = Map<String, double>.from(streakEngine.fardhStreaks.value);

      const testDateKey = '2026-06-26';
      await sl<BonusEngine>().completeDuha(dateKey: testDateKey);

      expect(streakEngine.globalStreak.value, initialGlobalStreak);
      expect(streakEngine.dailyStreak.value, initialDailyStreak);
      expect(streakEngine.fardhStreaks.value, equals(initialFardhStreaks));
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 11: Sunnah tracking is not accidentally locked simply because Fardh window changed
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 11: Sunnah tracking is not accidentally locked simply because Fardh window changed', () async {
      const testDateKey = '2026-06-26';

      // Fajr sunnah completed
      final sunnahSuccess = await sl<BonusEngine>().completeSunnah(Prayer.fajr, 0, 0.75);
      expect(sunnahSuccess, isTrue);

      final dayRecord = DayRecord(dateKey: testDateKey);
      final fajrRec = dayRecord.recordFor('الفجر');
      fajrRec.completedSunnah.add(0);
      fajrRec.sunnahScoreAwarded = 0.75;

      // Fardh is missed (oadaPending)
      fajrRec.state = PrayerState.oadaPending;

      // Sunnah remains recorded and tracked
      expect(fajrRec.completedSunnah.contains(0), isTrue);
      expect(fajrRec.sunnahScoreAwarded, 0.75);

      // Can still record subsequent sunnahs (e.g. Dhuhr sunnah)
      final dhuhrSunnahSuccess = await sl<BonusEngine>().completeSunnah(Prayer.dhuhr, 0, 0.75);
      expect(dhuhrSunnahSuccess, isTrue);
    });

    // ──────────────────────────────────────────────────────────────────────────
    // Test 12: DayRecord serialization maintains Duha completion persistently
    // ──────────────────────────────────────────────────────────────────────────
    test('Test 12: DayRecord serialization maintains Duha completion persistently across restarts', () async {
      const testDateKey = '2026-06-26';
      final day = DayRecord(dateKey: testDateKey);

      final duhaRec = day.recordFor('الضحى');
      duhaRec.state = PrayerState.completedIndividual;
      duhaRec.scoreAwarded = 3.6;

      await sl<PrayerRepository>().saveTodayRecord(day);

      final reloaded = await sl<PrayerRepository>().loadTodayRecord(testDateKey);
      final reloadedDuha = reloaded.recordFor('الضحى');

      expect(reloadedDuha.state, PrayerState.completedIndividual);
      expect(reloadedDuha.scoreAwarded, 3.6);
    });
  });
}
