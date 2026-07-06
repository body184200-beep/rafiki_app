import 'package:adhan/adhan.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';
import 'prayer_streak_engine.dart';
import 'score_engine.dart';

class BonusEngine {
  BonusEngine._internal();
  static final BonusEngine instance = BonusEngine._internal();

  PrayerRepository get _prayerRepository => sl<PrayerRepository>();

  /// Attempts to complete a Sunnah prayer and grants bonus score.
  /// Returns true if successful.
  Future<bool> completeSunnah(Prayer prayer, int sunnahIndex, double score) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Create a unique transaction ID for this specific sunnah on this specific day
    final txId = 'sunnah_${prayer.name}_${sunnahIndex}_$dateKey';

    return await ScoreEngine.instance.addScore(txId, score);
  }

  /// Rule 1: Consistency Bonus (3 days of completing all Fardh prayers)
  /// If consistent, boosts the streaks in PrayerStreakEngine only.
  Future<void> checkAndApplyConsistencyBonus() async {
    final history = await _prayerRepository.loadHistory();
    if (history.length < 3) return;

    // Take the last 3 days of history
    final last3Days = history.sublist(history.length - 3);
    bool isConsistent = true;

    for (final day in last3Days) {
      int completedCount = 0;
      day.prayers.forEach((name, rec) {
        if (rec.state == PrayerState.completedIndividual || 
            rec.state == PrayerState.completedCongregation) {
          completedCount++;
        }
      });
      if (completedCount < 5) {
        isConsistent = false;
        break;
      }
    }

    if (isConsistent) {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // Boost Fardh streaks
      await PrayerStreakEngine.instance.boostStreaks(1.0);
      AppLogger.info('Consistency bonus applied for date: $dateKey', tag: 'BonusEngine');
    }
  }

  /// Rule 2: Congregation Bonus (7 congregation prayers out of last 15 Fardh prayers)
  /// Adds score to ScoreEngine only.
  Future<void> checkAndApplyCongregationBonus() async {
    final history = await _prayerRepository.loadHistory();
    
    // Flatten all Fardh prayer records from history
    final List<PrayerRecord> allRecords = [];
    for (final day in history) {
      day.prayers.forEach((_, rec) {
        allRecords.add(rec);
      });
    }

    if (allRecords.isEmpty) return;

    // Get the last 15 prayers
    final last15 = allRecords.length > 15 
        ? allRecords.sublist(allRecords.length - 15) 
        : allRecords;

    int congregationCount = 0;
    for (final rec in last15) {
      if (rec.state == PrayerState.completedCongregation) {
        congregationCount++;
      }
    }

    if (congregationCount >= 7) {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final txId = 'congregation_bonus_$dateKey';
      
      // Reward ScoreEngine only
      final rewarded = await ScoreEngine.instance.addScore(txId, 5.0); // +5.0 bonus score
      if (rewarded) {
        AppLogger.info('Congregation bonus (+5.0 score) awarded under Tx: $txId', tag: 'BonusEngine');
      }
    }
  }
}
