import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/prayer_repository.dart' as domain;
import 'package:rafiki_app/features/prayer/data/models/prayer_models.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';

class PrayerRepositoryImpl implements domain.PrayerRepository {
  static const String _kPrefToday   = 'pt2_today';
  static const String _kPrefHistory = 'pt2_history';
  static const String _kPrefQada    = 'pt2_qada';

  @override
  Future<DayRecord> loadTodayRecord(String todayKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefToday);
      if (raw != null) {
        final record = DayRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (record.dateKey == todayKey) {
          return record;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load today record: $e', tag: 'Repository');
    }
    return DayRecord(dateKey: todayKey);
  }

  @override
  Future<void> saveTodayRecord(DayRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefToday, jsonEncode(record.toJson()));
      AppLogger.info('Saved today record for date ${record.dateKey}', tag: 'Repository');
    } catch (e) {
      AppLogger.error('Failed to save today record: $e', tag: 'Repository');
    }
  }

  @override
  Future<List<DayRecord>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefHistory);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => DayRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.error('Failed to load history: $e', tag: 'Repository');
    }
    return [];
  }

  @override
  Future<void> saveHistory(List<DayRecord> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefHistory, jsonEncode(history.map((e) => e.toJson()).toList()));
      AppLogger.info('Saved history with ${history.length} records', tag: 'Repository');
    } catch (e) {
      AppLogger.error('Failed to save history: $e', tag: 'Repository');
    }
  }

  @override
  Future<List<QadaEntry>> loadQadaEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefQada);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => QadaEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.error('Failed to load qada: $e', tag: 'Repository');
    }
    return [];
  }

  @override
  Future<void> saveQadaEntries(List<QadaEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefQada, jsonEncode(entries.map((e) => e.toJson()).toList()));
    } catch (e) {
      AppLogger.error('Failed to save qada: $e', tag: 'Repository');
    }
  }
}

class ScoreRepositoryImpl implements domain.ScoreRepository {
  static const String _kTotalScore = 'score_engine_total';
  static const String _kTodayScore = 'score_engine_today';
  static const String _kTransactions = 'score_engine_transactions';
  static const String _kHistory = 'score_engine_history';
  static const String _kLastResetDate = 'score_engine_last_reset';

  @override
  Future<double> loadTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kTotalScore) ?? 0.0;
  }

  @override
  Future<void> saveTotalScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTotalScore, score);
  }

  @override
  Future<double> loadTodayScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kTodayScore) ?? 0.0;
  }

  @override
  Future<void> saveTodayScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTodayScore, score);
  }

  @override
  Future<List<String>> loadProcessedTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kTransactions) ?? [];
  }

  @override
  Future<void> saveProcessedTransactions(List<String> txs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kTransactions, txs);
  }

  @override
  Future<List<String>> loadScoreHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHistory) ?? [];
  }

  @override
  Future<void> saveScoreHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHistory, history);
  }

  @override
  Future<String?> loadLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastResetDate);
  }

  @override
  Future<void> saveLastResetDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastResetDate, date);
  }

  @override
  Future<void> saveScoreState({
    required double todayScore,
    required double totalScore,
    required List<String> processedTransactions,
    String? lastResetDate,
    List<String>? history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final futures = <Future>[
      prefs.setDouble(_kTodayScore, todayScore),
      prefs.setDouble(_kTotalScore, totalScore),
      prefs.setStringList(_kTransactions, processedTransactions),
    ];
    if (lastResetDate != null) {
      futures.add(prefs.setString(_kLastResetDate, lastResetDate));
    }
    if (history != null) {
      futures.add(prefs.setStringList(_kHistory, history));
    }
    await Future.wait(futures);
  }
}

class StreakRepositoryImpl implements domain.StreakRepository {
  static const String _kGlobalStreak = 'streak_engine_global_v2';
  static const String _kFardhStreaks = 'streak_engine_fardh_streaks';

  @override
  Future<int> loadGlobalStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kGlobalStreak) ?? prefs.getInt('streak_engine_global') ?? 0;
  }

  @override
  Future<void> saveGlobalStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGlobalStreak, streak);
  }

  @override
  Future<Map<String, double>> loadFardhStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFardhStreaks);
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }
    return {};
  }

  @override
  Future<void> saveFardhStreaks(Map<String, double> streaks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFardhStreaks, jsonEncode(streaks));
  }
}
