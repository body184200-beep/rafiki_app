/// Hive box name constants and type adapter IDs.
///
/// Centralises all Hive box names to prevent typos and make
/// schema changes traceable. Type adapter IDs are reserved in
/// sequential blocks per feature.
library;

class HiveBoxes {
  HiveBoxes._();

  // ── Box Names ──────────────────────────────────────────────

  /// General app settings and flags.
  static const String settings = 'settings_box';

  /// Prayer records, scores, and streaks.
  static const String prayer = 'prayer_box';

  /// Custom notification configurations.
  static const String notifications = 'notifications_box';

  /// Azkar progress and scores.
  static const String azkar = 'azkar_box';

  /// Score history (daily / total).
  static const String scoreHistory = 'score_history_box';

  /// Backup metadata.
  static const String backup = 'backup_box';

  /// Migration tracking.
  static const String migration = 'migration_box';

  /// All box names for batch operations.
  static const List<String> allBoxes = [
    settings,
    prayer,
    notifications,
    azkar,
    scoreHistory,
    backup,
    migration,
  ];

  // ── Type Adapter IDs (reserved ranges per feature) ─────────
  // Each feature gets a block of 10 IDs for future expansion.
  //
  // 0-9:   Core / Settings
  // 10-19: Prayer
  // 20-29: Notifications
  // 30-39: Azkar
  // 40-49: Gamification
  // 50-59: Score / History
  // 60-69: Backup
  // 70-79: Collections

  // Reserved — actual TypeAdapters will be registered in Phase 2+
  // when models are migrated to Hive-native types.

  // ── Key Constants within Boxes ─────────────────────────────

  /// Keys inside the [settings] box.
  static const String keyAppVersion = 'app_version';
  static const String keyMigrationVersion = 'migration_version';
  static const String keyRadioFirstLaunch = 'radio_first_launch_done';
  static const String keyUserGender = 'user_gender';
  static const String keyUserName = 'user_name';

  /// Keys inside the [prayer] box.
  static const String keyPrayerToday = 'prayer_today';
  static const String keyPrayerHistory = 'prayer_history';
  static const String keyPrayerTotal = 'prayer_total';
  static const String keyPrayerStreak = 'prayer_streak';
  static const String keyPrayerQada = 'prayer_qada';
  static const String keyPrayerLat = 'prayer_lat';
  static const String keyPrayerLng = 'prayer_lng';

  /// Keys inside the [notifications] box.
  static const String keyNotificationList = 'notification_list';
  static const String keyNotificationLegacy = 'notification_legacy_data';

  /// Keys inside the [azkar] box.
  static const String keyAzkarTotalScore = 'azkar_total_score';
  static const String keyAzkarDailyScore = 'azkar_daily_score';
  static const String keyAzkarProgress = 'azkar_progress';
  static const String keyAzkarLastDate = 'azkar_last_date';
}
