import 'package:flutter/foundation.dart';
import 'package:rafiki_app/features/gamification/data/models/loot_box_model.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart';
import 'package:rafiki_app/features/gamification/data/services/loot_box_engine.dart';

class RewardEngine extends ChangeNotifier {
  final DiscoveryRepository _repository;
  final List<DiscoveryRecord> _records = [];

  RewardEngine(this._repository);

  List<DiscoveryRecord> get records => List.unmodifiable(_records);

  /// Initialize and run migration if needed
  Future<void> initialize() async {
    final allIds = allPossibleRewards.map((r) => r.id).toList();
    final loaded = await _repository.loadAll(allIds);
    _records.clear();
    _records.addAll(loaded);

    // Legacy Migration: Check existing LootBoxEngine inventory
    final legacyInventory = LootBoxEngine.instance.inventory.value;
    bool hasMigrationChanges = false;

    for (final item in legacyInventory) {
      if (item.id.isEmpty) continue;
      
      final index = _records.indexWhere((r) => r.rewardId == item.id);
      if (index != -1) {
        final record = _records[index];
        if (!record.discovered) {
          // Count occurrences in legacy inventory
          final count = legacyInventory.where((x) => x.id == item.id).length;
          final updated = record.copyWith(
            discovered: true,
            discoveredAt: DateTime.now(),
            timesObtained: count,
          );
          _records[index] = updated;
          await _repository.save(updated);
          hasMigrationChanges = true;
        }
      }
    }

    if (hasMigrationChanges) {
      notifyListeners();
    }
  }

  /// Processes rewards returned from opening a chest.
  /// Returns a list of records that were newly discovered (for first-time unlock animation).
  Future<List<DiscoveryRecord>> processRewards(List<RewardItem> rewards) async {
    final List<DiscoveryRecord> newlyDiscovered = [];

    for (final item in rewards) {
      if (item.id.isEmpty) continue;

      final index = _records.indexWhere((r) => r.rewardId == item.id);
      if (index != -1) {
        final record = _records[index];
        if (!record.discovered) {
          // First time discovery
          final updated = record.copyWith(
            discovered: true,
            discoveredAt: DateTime.now(),
            timesObtained: 1,
          );
          _records[index] = updated;
          await _repository.save(updated);
          newlyDiscovered.add(updated);
        } else {
          // Duplicate reward
          final updated = record.copyWith(
            timesObtained: record.timesObtained + 1,
          );
          _records[index] = updated;
          await _repository.save(updated);
        }
      }
    }

    if (rewards.isNotEmpty) {
      notifyListeners();
    }
    return newlyDiscovered;
  }

  /// Manually claim/discover a reward if it is completed (progress >= 1.0)
  Future<bool> claimReward(String rewardId) async {
    final index = _records.indexWhere((r) => r.rewardId == rewardId);
    if (index != -1) {
      final record = _records[index];
      if (!record.discovered) {
        final updated = record.copyWith(
          discovered: true,
          discoveredAt: DateTime.now(),
          timesObtained: 1,
        );
        _records[index] = updated;
        await _repository.save(updated);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Reset all discovery data (for testing)
  Future<void> clearAll() async {
    final allIds = allPossibleRewards.map((r) => r.id).toList();
    await _repository.clearAll(allIds);
    await initialize();
  }
}
