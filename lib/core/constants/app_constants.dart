/// App-wide constants and configuration values.
///
/// Centralises magic numbers & keys to prevent duplication and
/// make future changes safe. Every subsystem should reference
/// these instead of scattering literal values.
library;

class AppConstants {
  AppConstants._(); // prevent instantiation

  // ── App Info ────────────────────────────────────────────────
  static const String appName = 'رفيقي';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ── Prayer ─────────────────────────────────────────────────
  static const int totalDailyPrayers = 5;
  static const int totalSunnahPrayers = 5;
  static const int prayerAlertDurationSeconds = 180;
  static const int prayerCheckIntervalSeconds = 30;

  // ── Prayer Scoring ─────────────────────────────────────────
  static const double scoreCongregation = 2.7;
  static const double scoreIndividual = 1.0;
  static const double scoreQada = 0.5;
  static const double scoreSunnah = 0.75;

  // ── Notification ───────────────────────────────────────────
  static const int maxCustomNotifications = 25;
  static const String notificationChannelAzkar = 'azkar_channel';
  static const String notificationChannelPrayer = 'prayer_channel_v2';

  // ── Gamification ───────────────────────────────────────────
  static const int keysPerChest = 5;
  static const int streakBonusThreshold = 3; // consecutive days
  static const int congregationBonusThresholdSmall = 7;
  static const int congregationBonusThresholdLarge = 15;
  static const int congregationBonusDaysWindow = 3;

  // ── Rarity Weights (out of 100) ────────────────────────────
  static const int rarityCommon = 60;
  static const int rarityRare = 25;
  static const int rarityEpic = 10;
  static const int rarityLegendary = 4;
  static const int rarityMythic = 1;

  // ── Persistence Keys (SharedPreferences — legacy) ──────────
  static const String prefPrayerLat = 'prayer_lat';
  static const String prefPrayerLng = 'prayer_lng';
  static const String prefNotificationData = 'notification_data';
  static const String prefPrayerToday = 'pt2_today';
  static const String prefPrayerHistory = 'pt2_history';
  static const String prefPrayerTotal = 'pt2_total';
  static const String prefPrayerStreak = 'pt2_streak';
  static const String prefPrayerQada = 'pt2_qada';
  static const String prefRadioFirstLaunch = 'radio_first_launch_done';

  // ── Default Coordinates (Damietta, Egypt) ──────────────────
  static const double defaultLatitude = 31.4165;
  static const double defaultLongitude = 31.8133;

  // ── Performance Tuning ─────────────────────────────────────
  static const int debounceMs = 300;
  static const int saveDebounceMs = 500;
  static const int maxHistoryDays = 7;

  // ── Backup ─────────────────────────────────────────────────
  static const String backupFileExtension = '.rafiki_backup';
  static const int backupVersion = 1;
}
