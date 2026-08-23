import 'package:adhan/adhan.dart';

import 'package:rafiki_app/core/l10n/app_localizations.dart';

/// Localized labels for the five daily prayers (+ sunrise).
abstract final class PrayerNames {
  static Map<Prayer, String> map(AppLocalizations loc) => {
        Prayer.fajr: loc.prayer_fajr,
        Prayer.sunrise: loc.prayer_sunrise,
        Prayer.dhuhr: loc.prayer_dhuhr,
        Prayer.asr: loc.prayer_asr,
        Prayer.maghrib: loc.prayer_maghrib,
        Prayer.isha: loc.prayer_isha,
      };

  static String of(AppLocalizations loc, Prayer prayer) =>
      map(loc)[prayer] ?? loc.tooltip_next_prayer;

  static Map<Prayer, String> alerts(AppLocalizations loc) => {
        Prayer.fajr: loc.alert_fajr,
        Prayer.dhuhr: loc.alert_dhuhr,
        Prayer.asr: loc.alert_asr,
        Prayer.maghrib: loc.alert_maghrib,
        Prayer.isha: loc.alert_isha,
      };
}
