import 'package:flutter/foundation.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/features/prayer/data/services/score_engine.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_streak_engine.dart';
import 'package:rafiki_app/features/gamification/data/services/loot_box_engine.dart';
import 'package:rafiki_app/features/gamification/data/models/loot_box_model.dart';
import 'package:rafiki_app/features/gamification/data/services/reward_engine.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart';

enum RewardFilter { all, locked, unlocked, common, rare, epic, legendary }
enum RewardSort { discoveryDate, rarity, name, lockedFirst, unlockedFirst }

class EncyclopediaItemDisplay {
  final EncyclopediaRewardDef def;
  final bool discovered;
  final DateTime? discoveredAt;
  final int timesObtained;
  final String obtainMethod;
  final double progress;
  final String progressText;
  final bool isSecret;

  EncyclopediaItemDisplay({
    required this.def,
    required this.discovered,
    this.discoveredAt,
    this.timesObtained = 0,
    required this.obtainMethod,
    required this.progress,
    required this.progressText,
    required this.isSecret,
  });
}

class RewardController extends ChangeNotifier {
  final RewardEngine _engine;
  
  RewardFilter _filter = RewardFilter.all;
  RewardSort _sort = RewardSort.unlockedFirst;

  RewardController(this._engine) {
    _engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _onEngineChanged() {
    notifyListeners();
  }

  RewardFilter get filter => _filter;
  RewardSort get sort => _sort;

  void setFilter(RewardFilter newFilter) {
    if (_filter != newFilter) {
      _filter = newFilter;
      notifyListeners();
    }
  }

  void setSort(RewardSort newSort) {
    if (_sort != newSort) {
      _sort = newSort;
      notifyListeners();
    }
  }

  // --- Progress Metadata ---
  int get totalCount => allPossibleRewards.length;
  
  int get discoveredCount {
    return _engine.records.where((r) => r.discovered).length;
  }

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return discoveredCount / totalCount;
  }

  int get remainingCount => totalCount - discoveredCount;

  // --- Processed Display Items ---
  List<EncyclopediaItemDisplay> get items {
    final records = _engine.records;
    final discCount = discoveredCount;

    List<EncyclopediaItemDisplay> list = allPossibleRewards.map((def) {
      final record = records.firstWhere(
        (r) => r.rewardId == def.id,
        orElse: () => DiscoveryRecord(rewardId: def.id, discovered: false),
      );

      final progData = _calculateProgress(def.id, discCount);
      final int current = progData['current'] as int;
      final int target = progData['target'] as int;
      final bool secret = progData['secret'] as bool;

      final double progressRatio = (target == 0) ? 1.0 : (current / target).clamp(0.0, 1.0);
      final String progressText = '$current / $target';
      final String obtainMethod = (secret && !record.discovered) 
          ? '؟؟؟ (مكافأة سرية)' 
          : (progData['method'] as String);

      return EncyclopediaItemDisplay(
        def: def,
        discovered: record.discovered,
        discoveredAt: record.discoveredAt,
        timesObtained: record.timesObtained,
        obtainMethod: obtainMethod,
        progress: progressRatio,
        progressText: progressText,
        isSecret: secret,
      );
    }).toList();

    // 1. Filtering
    switch (_filter) {
      case RewardFilter.all: break;
      case RewardFilter.locked:
        list = list.where((item) => !item.discovered).toList();
        break;
      case RewardFilter.unlocked:
        list = list.where((item) => item.discovered).toList();
        break;
      case RewardFilter.common:
        list = list.where((item) => item.def.rarity == RewardRarity.common).toList();
        break;
      case RewardFilter.rare:
        list = list.where((item) => item.def.rarity == RewardRarity.rare).toList();
        break;
      case RewardFilter.epic:
        list = list.where((item) => item.def.rarity == RewardRarity.epic).toList();
        break;
      case RewardFilter.legendary:
        list = list.where((item) => item.def.rarity == RewardRarity.legendary).toList();
        break;
    }

    // 2. Sorting
    switch (_sort) {
      case RewardSort.discoveryDate:
        list.sort((a, b) {
          if (a.discovered && b.discovered) {
            return b.discoveredAt!.compareTo(a.discoveredAt!);
          }
          if (a.discovered) return -1;
          if (b.discovered) return 1;
          return a.def.id.compareTo(b.def.id);
        });
        break;
      case RewardSort.rarity:
        list.sort((a, b) {
          final aVal = _rarityValue(a.def.rarity);
          final bVal = _rarityValue(b.def.rarity);
          if (aVal != bVal) return bVal.compareTo(aVal);
          return a.def.name.compareTo(b.def.name);
        });
        break;
      case RewardSort.name:
        list.sort((a, b) => a.def.name.compareTo(b.def.name));
        break;
      case RewardSort.lockedFirst:
        list.sort((a, b) {
          if (a.discovered != b.discovered) return a.discovered ? 1 : -1;
          return a.def.name.compareTo(b.def.name);
        });
        break;
      case RewardSort.unlockedFirst:
        list.sort((a, b) {
          if (a.discovered != b.discovered) return a.discovered ? -1 : 1;
          return a.def.name.compareTo(b.def.name);
        });
        break;
    }

    return list;
  }

  int _rarityValue(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common: return 1;
      case RewardRarity.rare: return 2;
      case RewardRarity.epic: return 3;
      case RewardRarity.legendary: return 4;
    }
  }

  Map<String, dynamic> _calculateProgress(String id, int discCount) {
    final lootBox = sl<LootBoxEngine>();
    final score = sl<ScoreEngine>();
    final streak = sl<PrayerStreakEngine>();

    final chestsOpened = lootBox.chestsOpened;
    final totalScore = score.totalScore.value;
    final fajrStreak = streak.fardhStreaks.value['الفجر'] ?? 0.0;
    
    double maxFardhStreak = 0.0;
    streak.fardhStreaks.value.forEach((k, v) {
      if (v > maxFardhStreak) maxFardhStreak = v;
    });

    switch (id) {
      case 'badge_0':
        return {
          'method': 'افتح أول صندوق مكافآت.',
          'current': chestsOpened,
          'target': 1,
          'secret': false,
        };
      case 'badge_1':
        return {
          'method': 'حافظ على ستريك صلاة الفجر لمدة 7 أيام.',
          'current': fajrStreak.toInt(),
          'target': 7,
          'secret': false,
        };
      case 'badge_2':
        return {
          'method': 'حافظ على ستريك أي صلاة لمدة 15 يوماً.',
          'current': maxFardhStreak.toInt(),
          'target': 15,
          'secret': false,
        };
      case 'badge_3':
        return {
          'method': 'حافظ على ستريك أي صلاة لمدة 30 يوماً.',
          'current': maxFardhStreak.toInt(),
          'target': 30,
          'secret': false,
        };
      case 'badge_4':
        return {
          'method': 'اجمع 500 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 500,
          'secret': false,
        };
      case 'badge_5':
        return {
          'method': 'اكتشف 5 مكافآت مختلفة.',
          'current': discCount,
          'target': 5,
          'secret': false,
        };
      case 'badge_6':
        return {
          'method': 'جمع 1500 نقطة إجمالية لتنشيط شعلة الترتيل.',
          'current': totalScore.toInt(),
          'target': 1500,
          'secret': true,
        };
      case 'badge_7':
        return {
          'method': 'اجمع 5000 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 5000,
          'secret': false,
        };
      case 'badge_8':
        return {
          'method': 'افتح 10 صناديق.',
          'current': chestsOpened,
          'target': 10,
          'secret': false,
        };
      case 'badge_9':
        return {
          'method': 'افتح 50 صندوقاً.',
          'current': chestsOpened,
          'target': 50,
          'secret': false,
        };

      case 'frame_0':
        return {
          'method': 'افتح صندوقين.',
          'current': chestsOpened,
          'target': 2,
          'secret': false,
        };
      case 'frame_1':
        return {
          'method': 'اجمع 1000 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 1000,
          'secret': false,
        };
      case 'frame_2':
        return {
          'method': 'اجمع 2500 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 2500,
          'secret': false,
        };
      case 'frame_3':
        return {
          'method': 'وصل ستريك صلاة الفجر إلى 14 يوماً متواصلة.',
          'current': fajrStreak.toInt(),
          'target': 14,
          'secret': true,
        };
      case 'frame_4':
        return {
          'method': 'افتح 30 صندوقاً.',
          'current': chestsOpened,
          'target': 30,
          'secret': false,
        };

      case 'theme_0':
        return {
          'method': 'مفتوح تلقائياً للجميع.',
          'current': 1,
          'target': 1,
          'secret': false,
        };
      case 'theme_1':
        return {
          'method': 'افتح 5 صناديق.',
          'current': chestsOpened,
          'target': 5,
          'secret': false,
        };
      case 'theme_2':
        return {
          'method': 'اجمع 7777 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 7777,
          'secret': false,
        };

      case 'artifact_0':
        return {
          'method': 'اجمع 150 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 150,
          'secret': false,
        };
      case 'artifact_1':
        return {
          'method': 'افتح 15 صندوقاً.',
          'current': chestsOpened,
          'target': 15,
          'secret': false,
        };
      case 'artifact_2':
        return {
          'method': 'افتح 20 صندوقاً قديماً للكشف عن المصحف.',
          'current': chestsOpened,
          'target': 20,
          'secret': true,
        };
      case 'artifact_3':
        return {
          'method': 'احصل على 10000 نقطة إجمالية للوصول لكسوة الكعبة.',
          'current': totalScore.toInt(),
          'target': 10000,
          'secret': true,
        };
      case 'artifact_4':
        return {
          'method': 'اجمع 4000 نقطة إجمالية.',
          'current': totalScore.toInt(),
          'target': 4000,
          'secret': false,
        };

      default:
        return {
          'method': 'صلواتك وأذكارك تمنحك المكافأة.',
          'current': 0,
          'target': 1,
          'secret': false,
        };
    }
  }

  Future<bool> claimReward(String rewardId) async {
    final success = await _engine.claimReward(rewardId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
}
