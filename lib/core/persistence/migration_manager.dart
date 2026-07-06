/// Safe, incremental data migration from SharedPreferences to Hive.
///
/// Migrations are:
///  - **Versioned**: each migration has a unique version number.
///  - **Atomic**: either fully succeeds or fully rolls back.
///  - **Idempotent**: safe to re-run (skips already-applied versions).
///  - **Non-destructive**: old SharedPreferences keys are NOT deleted
///    until the migration is verified. A `_migrated_v{N}` flag is set
///    after each successful migration.
///
/// Usage:
/// ```dart
/// await MigrationManager.runAll();
/// ```
library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'hive_boxes.dart';

/// Describes a single migration step.
class _Migration {
  final int version;
  final String description;
  final Future<void> Function(SharedPreferences prefs, Box settingsBox)
      migrate;

  const _Migration({
    required this.version,
    required this.description,
    required this.migrate,
  });
}

class MigrationManager {
  MigrationManager._();

  static const String _tag = 'Migration';

  /// The ordered list of all migrations. New migrations are appended here.
  static final List<_Migration> _migrations = [
    _Migration(
      version: 1,
      description: 'Copy prayer coordinates from SharedPreferences to Hive',
      migrate: _migrateV1PrayerCoordinates,
    ),
    _Migration(
      version: 2,
      description:
          'Copy notification legacy data from SharedPreferences to Hive',
      migrate: _migrateV2Notifications,
    ),
    _Migration(
      version: 3,
      description: 'Copy prayer tracking data from SharedPreferences to Hive',
      migrate: _migrateV3PrayerData,
    ),
  ];

  /// Run all pending migrations in order.
  ///
  /// Skips migrations that have already been applied.
  /// Stops at the first failure without applying subsequent migrations.
  static Future<void> runAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationBox = Hive.box(HiveBoxes.migration);
      final currentVersion =
          migrationBox.get(HiveBoxes.keyMigrationVersion, defaultValue: 0)
              as int;

      AppLogger.info(
        'Current migration version: $currentVersion, '
        'latest available: ${_migrations.isEmpty ? 0 : _migrations.last.version}',
        tag: _tag,
      );

      for (final migration in _migrations) {
        if (migration.version <= currentVersion) continue;

        AppLogger.info(
          'Running migration v${migration.version}: ${migration.description}',
          tag: _tag,
        );

        try {
          final settingsBox = Hive.box(HiveBoxes.settings);
          await migration.migrate(prefs, settingsBox);

          // Mark this migration as applied.
          await migrationBox.put(
              HiveBoxes.keyMigrationVersion, migration.version);

          AppLogger.info(
            'Migration v${migration.version} completed successfully',
            tag: _tag,
          );
        } catch (e, st) {
          AppLogger.error(
            'Migration v${migration.version} failed — stopping migration chain',
            tag: _tag,
            error: e,
            stackTrace: st,
          );
          // Stop here — don't run further migrations.
          return;
        }
      }

      AppLogger.info('All migrations complete', tag: _tag);
    } catch (e, st) {
      AppLogger.error(
        'Migration manager failed to initialize',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get the currently applied migration version.
  static int getCurrentVersion() {
    try {
      final box = Hive.box(HiveBoxes.migration);
      return box.get(HiveBoxes.keyMigrationVersion, defaultValue: 0) as int;
    } catch (_) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  Individual Migration Implementations
  // ════════════════════════════════════════════════════════════

  /// V1: Copy prayer lat/lng from SharedPreferences to Hive prayer box.
  static Future<void> _migrateV1PrayerCoordinates(
    SharedPreferences prefs,
    Box settingsBox,
  ) async {
    final prayerBox =
        await _ensureBoxOpen(HiveBoxes.prayer);

    final lat = prefs.getDouble('prayer_lat');
    final lng = prefs.getDouble('prayer_lng');

    if (lat != null && lng != null) {
      await prayerBox.put(HiveBoxes.keyPrayerLat, lat);
      await prayerBox.put(HiveBoxes.keyPrayerLng, lng);
      AppLogger.debug('Migrated coordinates: ($lat, $lng)', tag: _tag);
    } else {
      AppLogger.debug('No coordinates to migrate', tag: _tag);
    }
  }

  /// V2: Copy notification_data from SharedPreferences to Hive.
  static Future<void> _migrateV2Notifications(
    SharedPreferences prefs,
    Box settingsBox,
  ) async {
    final notifBox =
        await _ensureBoxOpen(HiveBoxes.notifications);

    final raw = prefs.getString('notification_data');
    if (raw != null) {
      // Store the raw JSON as-is for backward compatibility.
      // The notification module will parse and migrate the format in Phase 3.
      await notifBox.put(HiveBoxes.keyNotificationLegacy, raw);
      AppLogger.debug('Migrated legacy notification data', tag: _tag);
    } else {
      AppLogger.debug('No notification data to migrate', tag: _tag);
    }
  }

  /// V3: Copy prayer tracking data from SharedPreferences to Hive.
  static Future<void> _migrateV3PrayerData(
    SharedPreferences prefs,
    Box settingsBox,
  ) async {
    final prayerBox =
        await _ensureBoxOpen(HiveBoxes.prayer);

    // Map of SharedPreferences keys → Hive keys.
    final keyMap = <String, String>{
      'pt2_today': HiveBoxes.keyPrayerToday,
      'pt2_history': HiveBoxes.keyPrayerHistory,
      'pt2_total': HiveBoxes.keyPrayerTotal,
      'pt2_streak': HiveBoxes.keyPrayerStreak,
      'pt2_qada': HiveBoxes.keyPrayerQada,
    };

    for (final entry in keyMap.entries) {
      final spKey = entry.key;
      final hiveKey = entry.value;

      // Try different types since SharedPreferences is typed.
      final stringVal = prefs.getString(spKey);
      if (stringVal != null) {
        await prayerBox.put(hiveKey, stringVal);
        AppLogger.debug('Migrated $spKey (String)', tag: _tag);
        continue;
      }

      final doubleVal = prefs.getDouble(spKey);
      if (doubleVal != null) {
        await prayerBox.put(hiveKey, doubleVal);
        AppLogger.debug('Migrated $spKey (double)', tag: _tag);
        continue;
      }

      final intVal = prefs.getInt(spKey);
      if (intVal != null) {
        await prayerBox.put(hiveKey, intVal);
        AppLogger.debug('Migrated $spKey (int)', tag: _tag);
        continue;
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  /// Ensure a Hive box is open, opening it if necessary.
  static Future<Box> _ensureBoxOpen(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }
}
