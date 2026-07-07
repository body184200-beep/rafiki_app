import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/gamification/data/services/loot_box_engine.dart';
import 'package:rafiki_app/features/gamification/data/models/loot_box_model.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart';
import 'package:rafiki_app/features/gamification/data/services/reward_engine.dart';
import 'package:rafiki_app/features/gamification/presentation/controllers/reward_controller.dart';

import 'package:get_it/get_it.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'package:rafiki_app/features/prayer/data/repositories/prayer_repository_impl.dart';
import 'package:rafiki_app/features/gamification/data/repositories/discovery_repository_impl.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final sl = GetIt.instance;
    
    // Repositories
    if (!sl.isRegistered<ScoreRepository>()) {
      sl.registerSingleton<ScoreRepository>(ScoreRepositoryImpl());
    }
    if (!sl.isRegistered<StreakRepository>()) {
      sl.registerSingleton<StreakRepository>(StreakRepositoryImpl());
    }
    if (!sl.isRegistered<DiscoveryRepository>()) {
      sl.registerSingleton<DiscoveryRepository>(DiscoveryRepositoryImpl());
    }
    if (!sl.isRegistered<PrayerRepository>()) {
      sl.registerSingleton<PrayerRepository>(PrayerRepositoryImpl());
    }

    // Engines
    if (!sl.isRegistered<ScoreEngine>()) {
      sl.registerSingleton<ScoreEngine>(ScoreEngine.instance);
    }
    if (!sl.isRegistered<PrayerStreakEngine>()) {
      sl.registerSingleton<PrayerStreakEngine>(PrayerStreakEngine.instance);
    }
    if (!sl.isRegistered<LootBoxEngine>()) {
      sl.registerSingleton<LootBoxEngine>(LootBoxEngine.instance);
    }

    LootBoxEngine.instance.resetForTesting();
    ScoreEngine.instance.clearStateForTesting();
    PrayerStreakEngine.instance.clearStateForTesting();
  });

  group('ScoreEngine Tests', () {
    test('addScore is idempotent', () async {
      final engine = ScoreEngine.instance;
      await engine.initialize();
      
      final first = await engine.addScore('fajr_1', 10.0);
      expect(first, isTrue);
      expect(engine.todayScore.value, 10.0);

      final second = await engine.addScore('fajr_1', 10.0);
      expect(second, isFalse);
      expect(engine.todayScore.value, 10.0); // should not increment
    });
  });

  group('LootBoxEngine Tests', () {
    test('forgeChest deducts 5 keys and adds chest', () async {
      SharedPreferences.setMockInitialValues({
        'loot_box_keys': 5,
        'loot_box_rng_seed': 1234,
      });
      final engine = LootBoxEngine.instance;
      await engine.initialize();
      expect(engine.keys.value, 5);

      await engine.forgeChest();
      expect(engine.keys.value, 0);
      expect(engine.unopenedChests.value.length, 1);
    });

    test('forgeChest throws if insufficient keys', () async {
      SharedPreferences.setMockInitialValues({
        'loot_box_keys': 4,
      });
      final engine = LootBoxEngine.instance;
      await engine.initialize();

      expect(() => engine.forgeChest(), throwsException);
    });

    test('openChest deterministic generation', () async {
      final mockChestId = 'test_chest_1';
      final chest = Chest(id: mockChestId, type: ChestType.legendary);
      
      SharedPreferences.setMockInitialValues({
        'loot_box_chests': jsonEncode([chest.toJson()]),
        'loot_box_rng_seed': 999,
        'loot_box_opened': 0,
      });

      final engine = LootBoxEngine.instance;
      await engine.initialize();
      expect(engine.unopenedChests.value.length, 1);

      final rewards = await engine.openChest(mockChestId);
      expect(rewards, isNotEmpty);
      expect(engine.unopenedChests.value, isEmpty);
      expect(engine.inventory.value.length, rewards.length);
      
      final hasCoins = rewards.any((r) => r.type == RewardType.coin);
      expect(hasCoins, isTrue);
    });

    test('LootBoxEngine retroactively syncs plain transaction IDs correctly', () async {
      SharedPreferences.setMockInitialValues({
        'score_engine_transactions': ['fardh_fajr_2026-07-06', 'streak_bonus_2026-07-06'],
        'loot_box_keys': 0,
      });

      final engine = LootBoxEngine.instance;
      await engine.initialize();

      // 'fardh_fajr_2026-07-06' should award 1 key
      // 'streak_bonus_2026-07-06' should award 2 keys
      // Total keys: 3
      expect(engine.keys.value, 3);
    });
  });

  group('Discovery & Encyclopedia Tests', () {
    test('RewardEngine migrates legacy inventory correctly', () async {
      final legacyItem = RewardItem(type: RewardType.badge, id: 'badge_0', name: 'شارة البداية');
      SharedPreferences.setMockInitialValues({
        'loot_box_inventory': jsonEncode([legacyItem.toJson(), legacyItem.toJson()]),
      });

      final lootBox = LootBoxEngine.instance;
      await lootBox.initialize();
      expect(lootBox.inventory.value.length, 2);

      final repo = DiscoveryRepositoryImpl();
      final engine = RewardEngine(repo);
      await engine.initialize();

      final record = engine.records.firstWhere((r) => r.rewardId == 'badge_0');
      expect(record.discovered, isTrue);
      expect(record.timesObtained, 2);
    });

    test('RewardEngine processes rewards and identifies new discoveries', () async {
      final repo = DiscoveryRepositoryImpl();
      final engine = RewardEngine(repo);
      await engine.initialize();
      await engine.clearAll();

      final items = [
        RewardItem(type: RewardType.badge, id: 'badge_1', name: 'شارة الفجر'),
        RewardItem(type: RewardType.badge, id: 'badge_1', name: 'شارة الفجر'), // Duplicate
        RewardItem(type: RewardType.coin, amount: 100, name: 'عملات ذهبية'), // Coin (no ID)
      ];

      final newDiscoveries = await engine.processRewards(items);
      expect(newDiscoveries.length, 1);
      expect(newDiscoveries.first.rewardId, 'badge_1');

      final record = engine.records.firstWhere((r) => r.rewardId == 'badge_1');
      expect(record.discovered, isTrue);
      expect(record.timesObtained, 2);
    });

    test('RewardController filters and sorts correctly', () async {
      final repo = DiscoveryRepositoryImpl();
      final engine = RewardEngine(repo);
      await engine.initialize();
      await engine.clearAll();

      // Make badge_0 (Common) and badge_7 (Legendary) unlocked
      await engine.processRewards([
        RewardItem(type: RewardType.badge, id: 'badge_0', name: 'شارة البداية'),
        RewardItem(type: RewardType.badge, id: 'badge_7', name: 'شارة رمضان'),
      ]);

      final controller = RewardController(engine);

      // Verify progress
      expect(controller.discoveredCount, 2);
      expect(controller.remainingCount, 21);
      expect(controller.progressPercentage, 2 / 23);

      // Verify locked filtering
      controller.setFilter(RewardFilter.locked);
      expect(controller.items.every((item) => !item.discovered), isTrue);
      expect(controller.items.length, 21);

      // Verify unlocked filtering
      controller.setFilter(RewardFilter.unlocked);
      expect(controller.items.every((item) => item.discovered), isTrue);
      expect(controller.items.length, 2);

      // Verify legendary filtering
      controller.setFilter(RewardFilter.legendary);
      expect(controller.items.every((item) => item.def.rarity == RewardRarity.legendary), isTrue);

      // Reset filter and verify sorting (rarity)
      controller.setFilter(RewardFilter.all);
      controller.setSort(RewardSort.rarity);
      expect(controller.items.first.def.rarity, RewardRarity.legendary);
    });
  });
}
