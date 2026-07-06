/// Hive initialisation and lifecycle management.
///
/// Call [HiveConfig.initialize] once at app startup (before runApp).
/// This opens all required boxes and prepares the persistence layer.
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../logging/app_logger.dart';
import 'hive_boxes.dart';

class HiveConfig {
  HiveConfig._();

  static bool _initialized = false;

  /// Whether Hive has been successfully initialised.
  static bool get isInitialized => _initialized;

  /// Initialise Hive and open all required boxes.
  ///
  /// Must be called once before any Hive operations.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing Hive...', tag: 'HiveConfig');

      // Initialize Hive with default Flutter path.
      await Hive.initFlutter();

      // Register type adapters here as they are created in later phases.
      // _registerAdapters();

      // Open all boxes.
      await _openBoxes();

      _initialized = true;
      AppLogger.info('Hive initialized successfully', tag: 'HiveConfig');
    } catch (e, st) {
      AppLogger.fatal(
        'Failed to initialize Hive',
        tag: 'HiveConfig',
        error: e,
        stackTrace: st,
      );
      // Re-throw so the app can handle the fatal error.
      rethrow;
    }
  }

  /// Open all application boxes.
  static Future<void> _openBoxes() async {
    // Open boxes that are needed immediately.
    // Other boxes can be opened lazily when their features are accessed.
    final immediateBoxes = [
      HiveBoxes.settings,
      HiveBoxes.migration,
    ];

    for (final boxName in immediateBoxes) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
          AppLogger.debug('Opened box: $boxName', tag: 'HiveConfig');
        }
      } catch (e, st) {
        AppLogger.error(
          'Failed to open box: $boxName',
          tag: 'HiveConfig',
          error: e,
          stackTrace: st,
        );
        // Try to delete the corrupted box and re-open.
        try {
          await Hive.deleteBoxFromDisk(boxName);
          await Hive.openBox(boxName);
          AppLogger.warning(
            'Recovered box $boxName by deleting and re-creating',
            tag: 'HiveConfig',
          );
        } catch (e2, st2) {
          AppLogger.fatal(
            'Cannot recover box: $boxName',
            tag: 'HiveConfig',
            error: e2,
            stackTrace: st2,
          );
        }
      }
    }
  }

  /// Open a specific box lazily (for features loaded on demand).
  ///
  /// Returns the opened box, or null if it cannot be opened.
  static Future<Box?> openBoxLazy(String boxName) async {
    if (!_initialized) {
      AppLogger.error(
        'Cannot open box $boxName — Hive not initialized',
        tag: 'HiveConfig',
      );
      return null;
    }

    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    try {
      final box = await Hive.openBox(boxName);
      AppLogger.debug('Lazily opened box: $boxName', tag: 'HiveConfig');
      return box;
    } catch (e, st) {
      AppLogger.error(
        'Failed to lazily open box: $boxName',
        tag: 'HiveConfig',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Get an already-opened box by name.
  ///
  /// Returns null if the box is not open.
  static Box? getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) return null;
    return Hive.box(boxName);
  }

  /// Close all open boxes. Call on app shutdown.
  static Future<void> closeAll() async {
    try {
      await Hive.close();
      _initialized = false;
      AppLogger.info('All Hive boxes closed', tag: 'HiveConfig');
    } catch (e, st) {
      AppLogger.error(
        'Error closing Hive boxes',
        tag: 'HiveConfig',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Compact all open boxes to reclaim disk space.
  static Future<void> compactAll() async {
    for (final boxName in HiveBoxes.allBoxes) {
      if (Hive.isBoxOpen(boxName)) {
        try {
          final box = Hive.box(boxName);
          await box.compact();
        } catch (e) {
          AppLogger.warning(
            'Failed to compact box: $boxName',
            tag: 'HiveConfig',
            error: e,
          );
        }
      }
    }
  }
}
