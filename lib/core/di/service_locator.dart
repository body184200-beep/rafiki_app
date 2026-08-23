/// Dependency Injection using GetIt service locator.
///
/// All services, repositories, and engines are registered here.
/// Call [ServiceLocator.initialize] once at app startup.
///
/// Access services anywhere via:
/// ```dart
/// final prayerRepo = sl<PrayerRepository>();
/// ```
library;

import 'package:get_it/get_it.dart';

import '../logging/app_logger.dart';
import '../persistence/hive_config.dart';
import '../persistence/migration_manager.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/bonus_engine.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/gamification/data/services/loot_box_engine.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart';
import 'package:rafiki_app/features/gamification/data/services/reward_engine.dart';
import 'package:rafiki_app/features/gamification/presentation/controllers/reward_controller.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_rule_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:rafiki_app/features/quran/domain/repositories/quran_repository.dart' as quran;
import 'package:rafiki_app/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:rafiki_app/features/gamification/data/repositories/discovery_repository_impl.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_local_data_source.dart';
import 'package:rafiki_app/features/hadith/data/datasources/hadith_remote_data_source.dart';
import 'package:rafiki_app/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:rafiki_app/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:rafiki_app/core/services/location_service.dart';
import 'package:adhan/adhan.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initialises and registers all core services.
///
/// This is called once from main.dart before runApp.
/// Feature-specific services will be registered in their own
/// setup methods (added in Phase 2+).
class ServiceLocator {
  ServiceLocator._();

  static bool _initialized = false;

  /// Whether the service locator has been initialised.
  static bool get isInitialized => _initialized;

  /// Initialise core infrastructure services.
  ///
  /// Order matters — dependencies must be registered before dependents.
  static Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.info('Initializing service locator...', tag: 'DI');

    // ── 1. Persistence Layer ─────────────────────────────────
    await HiveConfig.initialize();

    // ── 2. Data Migration ────────────────────────────────────
    await MigrationManager.runAll();

    // ── 3. Core Repositories ─────────────────────────────────
    sl.registerLazySingleton<PrayerRepository>(() => PrayerRepositoryImpl());
    sl.registerLazySingleton<ScoreRepository>(() => ScoreRepositoryImpl());
    sl.registerLazySingleton<StreakRepository>(() => StreakRepositoryImpl());
    sl.registerLazySingleton<quran.QuranRepository>(() => QuranRepository());
    sl.registerLazySingleton<HadithRemoteDataSource>(
      () => HadithRemoteDataSource(),
    );
    sl.registerLazySingleton<HadithLocalDataSource>(
      () => HadithLocalDataSource(),
    );
    sl.registerLazySingleton<HadithRepository>(
      () => HadithRepositoryImpl(
        sl<HadithRemoteDataSource>(),
        sl<HadithLocalDataSource>(),
      ),
    );
    sl.registerLazySingleton<LocationService>(() => LocationService());
    
    // Register PrayerRuleEngine with current coordinates
    final coords = await PrayerConfig.getCoordinates();
    final times = PrayerTimes.today(coords, PrayerConfig.params);
    sl.registerLazySingleton<PrayerRuleEngine>(() => PrayerRuleEngine(times));

    // ── 4. Engines / Services ────────────────────────────────
    final scoreEngine = ScoreEngine.instance;
    await scoreEngine.initialize();
    sl.registerSingleton<ScoreEngine>(scoreEngine);

    final prayerEngine = PrayerEngine.instance;
    prayerEngine.initialize();
    sl.registerSingleton<PrayerEngine>(prayerEngine);

    final prayerStreakEngine = PrayerStreakEngine.instance;
    await prayerStreakEngine.initialize();
    sl.registerSingleton<PrayerStreakEngine>(prayerStreakEngine);

    final bonusEngine = BonusEngine.instance;
    sl.registerSingleton<BonusEngine>(bonusEngine);

    final notificationEngine = NotificationEngine.instance;
    await notificationEngine.initialize();
    sl.registerSingleton<NotificationEngine>(notificationEngine);

    final lootBoxEngine = LootBoxEngine.instance;
    await lootBoxEngine.initialize();
    sl.registerSingleton<LootBoxEngine>(lootBoxEngine);

    final discoveryRepo = DiscoveryRepositoryImpl();
    sl.registerSingleton<DiscoveryRepository>(discoveryRepo);

    final rewardEngine = RewardEngine(discoveryRepo);
    await rewardEngine.initialize();
    sl.registerSingleton<RewardEngine>(rewardEngine);

    sl.registerFactory<RewardController>(() => RewardController(sl<RewardEngine>()));

    _initialized = true;
    AppLogger.info('Service locator initialized', tag: 'DI');
  }

  /// Reset all registrations (useful for testing).
  static Future<void> reset() async {
    await sl.reset();
    _initialized = false;
    AppLogger.info('Service locator reset', tag: 'DI');
  }
}
