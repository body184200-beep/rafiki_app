import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';

abstract class PrayerRepository {
  Future<DayRecord> loadTodayRecord(String todayKey);
  Future<void> saveTodayRecord(DayRecord record);
  Future<List<DayRecord>> loadHistory();
  Future<void> saveHistory(List<DayRecord> history);
  Future<List<QadaEntry>> loadQadaEntries();
  Future<void> saveQadaEntries(List<QadaEntry> entries);
}

abstract class ScoreRepository {
  Future<double> loadTotalScore();
  Future<void> saveTotalScore(double score);
  Future<double> loadTodayScore();
  Future<void> saveTodayScore(double score);
  Future<List<String>> loadProcessedTransactions();
  Future<void> saveProcessedTransactions(List<String> txs);
  Future<List<String>> loadScoreHistory();
  Future<void> saveScoreHistory(List<String> history);
  Future<String?> loadLastResetDate();
  Future<void> saveLastResetDate(String date);
  Future<void> saveScoreState({
    required double todayScore,
    required double totalScore,
    required List<String> processedTransactions,
    String? lastResetDate,
    List<String>? history,
  });
}

abstract class StreakRepository {
  Future<int> loadGlobalStreak();
  Future<void> saveGlobalStreak(int streak);
  Future<Map<String, double>> loadFardhStreaks();
  Future<void> saveFardhStreaks(Map<String, double> streaks);
}
