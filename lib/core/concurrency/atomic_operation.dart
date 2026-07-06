/// Async mutex / lock for preventing concurrent state mutations.
///
/// Dart is single-threaded but async operations can interleave.
/// This provides a simple lock mechanism to ensure atomic execution
/// of critical sections (database writes, reward claims, etc.).
///
/// Usage:
/// ```dart
/// final lock = AtomicLock();
///
/// Future<void> claimReward() => lock.guard(() async {
///   // Only one caller can be inside here at a time.
///   final current = await db.read();
///   current.claimed = true;
///   await db.write(current);
/// });
/// ```
library;

import 'dart:async';

import '../logging/app_logger.dart';

/// A simple async mutex that serialises access to a critical section.
class AtomicLock {
  Completer<void>? _completer;

  /// Whether the lock is currently held.
  bool get isLocked => _completer != null && !_completer!.isCompleted;

  /// Execute [action] while holding the lock.
  ///
  /// If the lock is already held, this waits until it is released
  /// before executing [action]. Returns the result of [action].
  Future<T> guard<T>(Future<T> Function() action) async {
    // Wait for any existing lock to release.
    while (_completer != null && !_completer!.isCompleted) {
      await _completer!.future;
    }

    // Acquire the lock.
    _completer = Completer<void>();

    try {
      return await action();
    } finally {
      // Release the lock.
      _completer!.complete();
    }
  }
}

/// Ensures an operation is idempotent by tracking completed operation IDs.
///
/// Prevents double-execution of the same logical operation (e.g. claiming
/// a reward, counting a prayer, incrementing a streak).
///
/// Usage:
/// ```dart
/// final guard = IdempotencyGuard();
///
/// void onPrayerCompleted(String prayerName) {
///   final opId = 'prayer_${dateKey}_$prayerName';
///   if (!guard.tryExecute(opId)) return; // Already executed
///   // ... safe to proceed
/// }
/// ```
class IdempotencyGuard {
  final Set<String> _executedOps = {};
  final int _maxEntries;

  IdempotencyGuard({int maxEntries = 500}) : _maxEntries = maxEntries;

  /// Returns `true` if this is the first call with [operationId],
  /// marking it as executed. Returns `false` if already executed.
  bool tryExecute(String operationId) {
    if (_executedOps.contains(operationId)) return false;

    // Prevent unbounded growth — evict oldest entries.
    if (_executedOps.length >= _maxEntries) {
      final oldest = _executedOps.first;
      _executedOps.remove(oldest);
    }

    _executedOps.add(operationId);
    return true;
  }

  /// Check if an operation has already been executed.
  bool wasExecuted(String operationId) => _executedOps.contains(operationId);

  /// Remove an operation from the executed set (for undo/retry).
  void reset(String operationId) => _executedOps.remove(operationId);

  /// Clear all tracked operations (e.g. on day rollover).
  void clearAll() => _executedOps.clear();
}

/// Wraps a future-returning function to ensure it executes atomically
/// with error logging and optional retry.
///
/// Usage:
/// ```dart
/// await atomicWrite(
///   operation: () => hiveBox.put('key', value),
///   tag: 'PrayerRepo',
///   description: 'Save prayer record',
/// );
/// ```
Future<T?> atomicWrite<T>({
  required Future<T> Function() operation,
  required String tag,
  required String description,
  int maxRetries = 1,
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final result = await operation();
      AppLogger.debug('$description succeeded', tag: tag);
      return result;
    } catch (e, st) {
      if (attempt == maxRetries) {
        AppLogger.error(
          '$description failed after $maxRetries attempt(s)',
          tag: tag,
          error: e,
          stackTrace: st,
        );
        return null;
      }
      AppLogger.warning(
        '$description attempt $attempt failed, retrying...',
        tag: tag,
        error: e,
      );
      // Brief delay before retry.
      await Future.delayed(
          Duration(milliseconds: 50 * attempt));
    }
  }
  return null;
}
