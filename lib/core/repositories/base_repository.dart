/// Abstract base repository providing common persistence patterns.
///
/// Subclasses choose their backing store (Hive box, SharedPreferences,
/// or both during migration) and inherit safe read/write helpers,
/// debounced saving, and error logging.
///
/// Usage:
/// ```dart
/// class PrayerRepository extends BaseRepository {
///   PrayerRepository() : super(boxName: HiveBoxes.prayer, tag: 'PrayerRepo');
///
///   Future<DayRecord?> getToday() =>
///       readFromBox<String>(HiveBoxes.keyPrayerToday)
///           .then((json) => json != null ? DayRecord.fromJson(...) : null);
/// }
/// ```
library;

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../concurrency/atomic_operation.dart';
import '../logging/app_logger.dart';
import '../persistence/hive_config.dart';

/// Base class for all repositories in the application.
abstract class BaseRepository {
  /// The Hive box name this repository operates on.
  final String boxName;

  /// Tag for log messages.
  final String tag;

  /// Lock for serialising writes to this repository.
  final AtomicLock _writeLock = AtomicLock();

  /// Debounce timer for batched saves.
  Timer? _debounceTimer;

  BaseRepository({required this.boxName, required this.tag});

  // ── Box Access ─────────────────────────────────────────────

  /// Get the Hive box, opening it lazily if needed.
  Future<Box?> _getBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return HiveConfig.openBoxLazy(boxName);
  }

  // ── Read Operations ────────────────────────────────────────

  /// Read a value from the Hive box.
  ///
  /// Returns [defaultValue] if the key doesn't exist or the box
  /// cannot be opened.
  Future<T?> readFromBox<T>(String key, {T? defaultValue}) async {
    try {
      final box = await _getBox();
      if (box == null) return defaultValue;
      final value = box.get(key, defaultValue: defaultValue);
      return value as T?;
    } catch (e, st) {
      AppLogger.error(
        'Failed to read key "$key" from box "$boxName"',
        tag: tag,
        error: e,
        stackTrace: st,
      );
      return defaultValue;
    }
  }

  /// Check if a key exists in the box.
  Future<bool> containsKey(String key) async {
    try {
      final box = await _getBox();
      return box?.containsKey(key) ?? false;
    } catch (e) {
      AppLogger.warning('containsKey check failed for "$key"',
          tag: tag, error: e);
      return false;
    }
  }

  // ── Write Operations ───────────────────────────────────────

  /// Write a value to the Hive box atomically (with lock).
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> writeToBox<T>(String key, T value) async {
    return _writeLock.guard(() async {
      try {
        final box = await _getBox();
        if (box == null) {
          AppLogger.error(
            'Cannot write — box "$boxName" unavailable',
            tag: tag,
          );
          return false;
        }
        await box.put(key, value);
        return true;
      } catch (e, st) {
        AppLogger.error(
          'Failed to write key "$key" to box "$boxName"',
          tag: tag,
          error: e,
          stackTrace: st,
        );
        return false;
      }
    });
  }

  /// Write multiple key-value pairs atomically.
  ///
  /// Either all writes succeed or none are applied (on failure
  /// the box may be in a partial state — Hive doesn't support
  /// true transactions, but the lock prevents interleaving).
  Future<bool> writeBatch(Map<String, dynamic> entries) async {
    return _writeLock.guard(() async {
      try {
        final box = await _getBox();
        if (box == null) {
          AppLogger.error(
            'Cannot write batch — box "$boxName" unavailable',
            tag: tag,
          );
          return false;
        }
        await box.putAll(entries);
        return true;
      } catch (e, st) {
        AppLogger.error(
          'Batch write failed for box "$boxName"',
          tag: tag,
          error: e,
          stackTrace: st,
        );
        return false;
      }
    });
  }

  /// Delete a key from the box.
  Future<bool> deleteFromBox(String key) async {
    return _writeLock.guard(() async {
      try {
        final box = await _getBox();
        if (box == null) return false;
        await box.delete(key);
        return true;
      } catch (e, st) {
        AppLogger.error(
          'Failed to delete key "$key" from box "$boxName"',
          tag: tag,
          error: e,
          stackTrace: st,
        );
        return false;
      }
    });
  }

  // ── Debounced Save ─────────────────────────────────────────

  /// Schedule a debounced save. Multiple rapid calls within
  /// [debounceMs] will be collapsed into a single save.
  ///
  /// Subclasses should override [performSave] to define what
  /// gets persisted.
  void scheduleSave({int debounceMs = 300}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: debounceMs),
      () async {
        try {
          await performSave();
        } catch (e, st) {
          AppLogger.error(
            'Debounced save failed',
            tag: tag,
            error: e,
            stackTrace: st,
          );
        }
      },
    );
  }

  /// Override this in subclasses to define the actual save logic.
  Future<void> performSave() async {}

  // ── Cleanup ────────────────────────────────────────────────

  /// Cancel any pending debounced saves. Call when the feature
  /// is disposed (e.g. in a State.dispose).
  void cancelPendingSave() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Flush any pending saves immediately. Useful before app shutdown.
  Future<void> flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await performSave();
  }
}
