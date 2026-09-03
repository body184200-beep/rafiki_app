import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';

import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/gamification/data/models/loot_box_model.dart';

class LootBoxEngine {
  static final LootBoxEngine instance = LootBoxEngine._internal();
  LootBoxEngine._internal();

  final ValueNotifier<int> keys = ValueNotifier(0);
  final ValueNotifier<List<Chest>> unopenedChests = ValueNotifier([]);
  final ValueNotifier<List<RewardItem>> inventory = ValueNotifier([]);
  
  final Set<String> _processedTxs = {};
  int _rngSeed = 0;
  int _chestsForged = 0;
  int _chestsOpened = 0;

  int get chestsForged => _chestsForged;
  int get chestsOpened => _chestsOpened;

  static const String _kKeys = 'loot_box_keys';
  static const String _kChests = 'loot_box_chests';
  static const String _kInventory = 'loot_box_inventory';
  static const String _kProcessedTxs = 'loot_box_txs';
  static const String _kRngSeed = 'loot_box_rng_seed';
  static const String _kChestsForged = 'loot_box_forged';
  static const String _kChestsOpened = 'loot_box_opened';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    
    keys.value = prefs.getInt(_kKeys) ?? 0;
    
    final chestsStr = prefs.getString(_kChests);
    if (chestsStr != null) {
      try {
        final List j = jsonDecode(chestsStr);
        unopenedChests.value = j.map((e) => Chest.fromJson(e)).toList();
      } catch (e, st) {
        AppLogger.warning('Failed to restore unopened chests', error: e, stackTrace: st);
      }
    }

    final invStr = prefs.getString(_kInventory);
    if (invStr != null) {
      try {
        final List j = jsonDecode(invStr);
        inventory.value = j.map((e) => RewardItem.fromJson(e)).toList();
      } catch (e, st) {
        AppLogger.warning('Failed to restore inventory', error: e, stackTrace: st);
      }
    }

    _processedTxs.addAll(prefs.getStringList(_kProcessedTxs) ?? []);
    
    _rngSeed = prefs.getInt(_kRngSeed) ?? Random().nextInt(999999);
    if (!prefs.containsKey(_kRngSeed)) await prefs.setInt(_kRngSeed, _rngSeed);

    _chestsForged = prefs.getInt(_kChestsForged) ?? 0;
    _chestsOpened = prefs.getInt(_kChestsOpened) ?? 0;

    // --- Retroactive Syncing ---
    // Safely sync transactions that occurred while Gamification was unloaded
    final scorePrefsStrList = prefs.getStringList('score_engine_transactions') ?? [];
    for (final txId in scorePrefsStrList) {
      if (!_processedTxs.contains(txId)) {
        _handleRetroactiveEvent(txId, 0.0);
        _processedTxs.add(txId);
      }
    }
    
    // Save the retroactively processed txs
    await prefs.setStringList(_kProcessedTxs, _processedTxs.toList());
    await prefs.setInt(_kKeys, keys.value);

    // Listen to ScoreEngine explicitly for future live events
    ScoreEngine.instance.eventStream.listen(_handleScoreEvent);
  }

  void _handleRetroactiveEvent(String txId, double amount) {
    int keysToGrant = 0;
    final tx = txId.toLowerCase();

    if (tx.contains('fardh') || tx.contains('sunnah') || tx.contains('prayer')) {
      keysToGrant = 1;
    } else if (tx.contains('azkar')) {
      keysToGrant = 1;
    } else if (tx.contains('quran')) {
      keysToGrant = (amount / 10).floor().clamp(1, 10);
    } else if (tx.contains('streak')) {
      keysToGrant = 2; // Bonus
    }

    if (keysToGrant > 0) {
      keys.value += keysToGrant;
    }
  }

  void _handleScoreEvent(ScoreEvent event) {
    if (_processedTxs.contains(event.transactionId)) return;

    int keysToGrant = 0;
    final tx = event.transactionId.toLowerCase();

    if (tx.contains('fardh') || tx.contains('sunnah') || tx.contains('prayer')) {
      keysToGrant = 1;
    } else if (tx.contains('azkar')) {
      keysToGrant = 1;
    } else if (tx.contains('quran')) {
      // Dynamic: 1 key per 10 points (assuming 1 page = 1 point)
      keysToGrant = (event.amount / 10).floor().clamp(1, 10);
    } else if (tx.contains('streak')) {
      keysToGrant = 2; // Bonus
    }

    if (keysToGrant > 0) {
      _grantKeys(event.transactionId, keysToGrant);
    }
  }

  Future<void> _grantKeys(String txId, int amount) async {
    _processedTxs.add(txId);
    keys.value += amount;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_kKeys, keys.value),
      prefs.setStringList(_kProcessedTxs, _processedTxs.toList()),
    ]);
  }

  // ── GAMIFICATION LOGIC ──────────────────────────────────────────────

  /// Exchange 5 keys for a Chest
  Future<void> forgeChest() async {
    if (keys.value < 5) throw Exception('لا يوجد لديك مفاتيح كافية (المطلوب 5)');
    
    // Deterministic random type based on user seed + forged count
    final r = Random(_rngSeed + _chestsForged);
    _chestsForged++;

    final roll = r.nextDouble();
    ChestType type;
    if (roll < 0.05) {
      type = ChestType.legendary; // 5%
    } else if (roll < 0.15) {
      type = ChestType.gold;      // 10%
    } else if (roll < 0.40) {
      type = ChestType.silver;    // 25%
    } else {
      type = ChestType.wooden;    // 60%
    }

    final chest = Chest(id: UniqueKey().toString(), type: type);
    
    // Atomic state update
    keys.value -= 5;
    final newChests = List<Chest>.from(unopenedChests.value)..add(chest);
    unopenedChests.value = newChests;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_kKeys, keys.value),
      prefs.setInt(_kChestsForged, _chestsForged),
      prefs.setString(_kChests, jsonEncode(newChests.map((e) => e.toJson()).toList())),
    ]);
  }

  /// Open a chest and get deterministic rewards
  Future<List<RewardItem>> openChest(String chestId) async {
    final chestIndex = unopenedChests.value.indexWhere((c) => c.id == chestId);
    if (chestIndex == -1) throw Exception('الصندوق غير موجود');
    
    final chest = unopenedChests.value[chestIndex];
    
    // Generate rewards deterministically
    final r = Random(_rngSeed + _chestsOpened * 100);
    _chestsOpened++;
    
    final List<RewardItem> generatedRewards = [];
    
    // Coins logic
    int coinMin = 10, coinMax = 50;
    if (chest.type == ChestType.silver) { coinMin = 50; coinMax = 100; }
    else if (chest.type == ChestType.gold) { coinMin = 100; coinMax = 300; }
    else if (chest.type == ChestType.legendary) { coinMin = 300; coinMax = 1000; }
    
    final coins = coinMin + r.nextInt(coinMax - coinMin);
    generatedRewards.add(RewardItem(type: RewardType.coin, amount: coins, name: 'عملات ذهبية'));

    // Special items logic
    final roll = r.nextDouble();
    if (chest.type == ChestType.legendary || (chest.type == ChestType.gold && roll > 0.3) || (chest.type == ChestType.silver && roll > 0.7)) {
      final badgeNames = [
        'شارة البداية', 'شارة الفجر', 'شارة الجماعة', 'شارة المثابرة', 'شارة النور',
        'شارة الذاكرين', 'شارة الترتيل', 'شارة رمضان', 'شارة الصبر', 'شارة التفوق'
      ];
      final frameNames = ['إطار الخشب', 'إطار الفضة', 'إطار الذهب', 'إطار الياقوت', 'إطار الأسطورة'];
      final themeNames = ['المظهر الكلاسيكي', 'المظهر الليلي الهادئ', 'المظهر الذهبي الفاخر'];
      final artifactNames = ['مسبحة العقيق', 'سجادة أثرية', 'مصحف مذهب', 'مسك الكعبة', 'مكحلة قديمة'];

      final itemRoll = r.nextDouble();
      if (itemRoll < 0.4) {
        final idx = r.nextInt(10);
        generatedRewards.add(RewardItem(type: RewardType.badge, id: 'badge_$idx', name: badgeNames[idx]));
      } else if (itemRoll < 0.7) {
        final idx = r.nextInt(5);
        generatedRewards.add(RewardItem(type: RewardType.frame, id: 'frame_$idx', name: frameNames[idx]));
      } else if (itemRoll < 0.9) {
        final idx = r.nextInt(3);
        generatedRewards.add(RewardItem(type: RewardType.theme, id: 'theme_$idx', name: themeNames[idx]));
      } else {
        final idx = r.nextInt(5);
        generatedRewards.add(RewardItem(type: RewardType.artifact, id: 'artifact_$idx', name: artifactNames[idx]));
      }
    }

    // Atomic write
    final newChests = List<Chest>.from(unopenedChests.value)..removeAt(chestIndex);
    unopenedChests.value = newChests;
    
    final newInventory = List<RewardItem>.from(inventory.value)..addAll(generatedRewards);
    inventory.value = newInventory;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_kChestsOpened, _chestsOpened),
      prefs.setString(_kChests, jsonEncode(newChests.map((e) => e.toJson()).toList())),
      prefs.setString(_kInventory, jsonEncode(newInventory.map((e) => e.toJson()).toList())),
    ]);

    return generatedRewards;
  }

  void resetForTesting() {
    _isInitialized = false;
    keys.value = 0;
    unopenedChests.value = [];
    inventory.value = [];
    _processedTxs.clear();
    _chestsForged = 0;
    _chestsOpened = 0;
  }
}
