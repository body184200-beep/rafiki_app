import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rafiki_app/core/di/service_locator.dart';
import 'package:rafiki_app/core/logging/app_logger.dart';
import 'package:rafiki_app/features/prayer/domain/repositories/prayer_repository.dart';

class ScoreEvent {
  final String transactionId;
  final double amount;
  ScoreEvent(this.transactionId, this.amount);
}

class ScoreEngine {
  ScoreEngine._internal();
  static final ScoreEngine instance = ScoreEngine._internal();

  final ValueNotifier<double> todayScore = ValueNotifier<double>(0.0);
  final ValueNotifier<double> totalScore = ValueNotifier<double>(0.0);
  
  // Public event bus for Gamification and other systems
  final _eventController = StreamController<ScoreEvent>.broadcast();
  Stream<ScoreEvent> get eventStream => _eventController.stream;
  
  // To ensure idempotent updates during a day
  final Set<String> _processedTransactions = {};
  
  ScoreRepository get _repository => sl<ScoreRepository>();

  Future<void> initialize() async {
    AppLogger.info('Initializing ScoreEngine...', tag: 'ScoreEngine');
    
    // Load persisted state
    totalScore.value = await _repository.loadTotalScore();
    todayScore.value = await _repository.loadTodayScore();
    
    final txList = await _repository.loadProcessedTransactions();
    _processedTransactions.clear();
    _processedTransactions.addAll(txList);

    // Legacy Migration: If lastResetDate is not today, yesterday's score was not yet aggregated.
    final lastResetDate = await _repository.loadLastResetDate();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (lastResetDate != null && lastResetDate != todayKey) {
      totalScore.value += todayScore.value;
      if (totalScore.value < 0.0) totalScore.value = 0.0;
      await _repository.saveScoreState(
        todayScore: todayScore.value,
        totalScore: totalScore.value,
        processedTransactions: _processedTransactions.toList(),
      );
    }
  }

  void clearStateForTesting() {
    todayScore.value = 0.0;
    totalScore.value = 0.0;
    _processedTransactions.clear();
  }

  Future<bool> addScore(String transactionId, double amount) async {
    if (_processedTransactions.contains(transactionId)) {
      AppLogger.warning('Transaction $transactionId already processed. Skipping.', tag: 'ScoreEngine');
      return false; // Already processed
    }

    _processedTransactions.add(transactionId);
    todayScore.value += amount;
    totalScore.value += amount;
    if (totalScore.value < 0.0) totalScore.value = 0.0;
    
    // Broadcast explicit event
    _eventController.add(ScoreEvent(transactionId, amount));
    AppLogger.info('Score updated: +$amount (Tx: $transactionId). Today: ${todayScore.value}', tag: 'ScoreEngine');
    
    // Save to disk atomically
    await _repository.saveScoreState(
      todayScore: todayScore.value,
      totalScore: totalScore.value,
      processedTransactions: _processedTransactions.toList(),
    );
    
    return true;
  }

  Future<void> checkMidnightReset() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final lastResetDate = await _repository.loadLastResetDate();
    if (lastResetDate != todayKey) {
      AppLogger.info('Midnight reset needed. Last reset: $lastResetDate, Today: $todayKey', tag: 'ScoreEngine');
      await handleMidnightRollover(todayKey);
    }
  }

  Future<void> handleMidnightRollover(String todayKey) async {
    final now = DateTime.now();
    // Save under yesterday's date since this runs right after midnight
    final yesterday = now.subtract(const Duration(days: 1));
    final dateKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    
    // Clamp check
    if (totalScore.value < 0.0) totalScore.value = 0.0;
    
    // Add to history
    final history = await _repository.loadScoreHistory();
    history.add('$dateKey:${todayScore.value}');
    
    // Reset today's score and transactions
    todayScore.value = 0.0;
    _processedTransactions.clear();
    
    // Save new states atomically
    await _repository.saveScoreState(
      todayScore: 0.0,
      totalScore: totalScore.value,
      processedTransactions: [],
      lastResetDate: todayKey,
      history: history,
    );
    
    AppLogger.info('Midnight reset completed successfully for date: $dateKey. Total score: ${totalScore.value}', tag: 'ScoreEngine');
  }
}
