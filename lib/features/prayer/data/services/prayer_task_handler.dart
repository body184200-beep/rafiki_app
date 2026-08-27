import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';

class PrayerTaskHandler extends TaskHandler {
  // Caching
  Coordinates? _cachedCoordinates;
  DateTime? _lastCoordsFetch;
  PrayerTimes? _cachedTodayTimes;
  PrayerTimes? _cachedTomorrowTimes;
  DateTime? _cachedDate;

  // Alerts tracking to avoid duplicate audio alerts
  Prayer? _lastAlertPrayer;
  DateTime? _lastAlertDay;

  Prayer? _lastPrayerNow;
  DateTime? _lastPrayerNowDay;

  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initial immediate update when foreground service starts
    await _updatePrayerCountdown(timestamp);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called every second (1000ms) by ForegroundTaskEventAction.repeat(1000)
    _updatePrayerCountdown(timestamp);
  }

  Future<void> _updatePrayerCountdown(DateTime now) async {
    try {
      final today = DateTime(now.year, now.month, now.day);

      // Refresh coordinates if needed (initial load or every 5 minutes)
      if (_cachedCoordinates == null ||
          _lastCoordsFetch == null ||
          now.difference(_lastCoordsFetch!).inMinutes >= 5) {
        _cachedCoordinates = await PrayerConfig.getCoordinates();
        _lastCoordsFetch = now;
        // Invalidate cached times so they recalculate with new coordinates
        _cachedDate = null;
      }

      final coords = _cachedCoordinates!;
      final params = PrayerConfig.params;

      // Recompute prayer times when date changes or on first run
      if (_cachedTodayTimes == null ||
          _cachedDate == null ||
          _cachedDate != today) {
        _cachedTodayTimes = PrayerTimes.today(coords, params);
        final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
        _cachedTomorrowTimes = PrayerTimes(coords, tomorrow, params);
        _cachedDate = today;
      }

      final todayTimes = _cachedTodayTimes!;
      final tomorrowTimes = _cachedTomorrowTimes!;

      final todayPrayers = [
        MapEntry(Prayer.fajr, todayTimes.fajr),
        MapEntry(Prayer.dhuhr, todayTimes.dhuhr),
        MapEntry(Prayer.asr, todayTimes.asr),
        MapEntry(Prayer.maghrib, todayTimes.maghrib),
        MapEntry(Prayer.isha, todayTimes.isha),
      ];

      // Check audio alerts (10 minutes before and at prayer time)
      _checkAudioAlerts(todayPrayers, now, today);

      // Find the next upcoming prayer
      Prayer nextPrayer = Prayer.none;
      DateTime? nextPrayerTime;

      for (final entry in todayPrayers) {
        if (entry.value.isAfter(now)) {
          nextPrayer = entry.key;
          nextPrayerTime = entry.value;
          break;
        }
      }

      // If all today's prayers have passed (after Isha), next prayer is tomorrow's Fajr
      if (nextPrayer == Prayer.none || nextPrayerTime == null) {
        nextPrayer = Prayer.fajr;
        nextPrayerTime = tomorrowTimes.fajr;
      }

      final diff = nextPrayerTime.difference(now);
      final safeDiff = diff.isNegative ? Duration.zero : diff;

      final prayerName = _getName(nextPrayer);
      final prayerTimeStr = TimeFormat.format12h(nextPrayerTime);
      final countdownStr = TimeFormat.hhmmss(safeDiff);

      // Live update foreground notification
      FlutterForegroundTask.updateService(
        notificationTitle: '🕌 الصلاة القادمة: $prayerName',
        notificationText: '🕐 $prayerTimeStr   ⏳ متبقي: $countdownStr',
      );
    } catch (_) {}
  }

  void _checkAudioAlerts(
    List<MapEntry<Prayer, DateTime>> prayers,
    DateTime now,
    DateTime today,
  ) {
    for (final entry in prayers) {
      final diff = entry.value.difference(now);
      final seconds = diff.inSeconds;

      // 🔔 10 minutes before prayer (diff is ~600 seconds)
      if (seconds > 0 && seconds <= 600 && seconds >= 595) {
        final alreadyAlerted =
            _lastAlertPrayer == entry.key && _lastAlertDay == today;
        if (!alreadyAlerted) {
          _lastAlertPrayer = entry.key;
          _lastAlertDay = today;
          _playAdhan();
        }
      }

      // 🕌 Prayer time has entered (diff is <= 0 and within 2 seconds)
      if (seconds <= 0 && seconds >= -2) {
        final alreadyNotified =
            _lastPrayerNow == entry.key && _lastPrayerNowDay == today;
        if (!alreadyNotified) {
          _lastPrayerNow = entry.key;
          _lastPrayerNowDay = today;
          _playAdhan();
        }
      }
    }
  }

  Future<void> _playAdhan() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('adhan.mp3'));
    } catch (_) {}
  }

  String _getName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
      case Prayer.sunrise:
        return '';
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    try {
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
  }
}