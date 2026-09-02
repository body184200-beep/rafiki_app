import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';

class PrayerTaskHandler extends TaskHandler {
  // Caching
  Coordinates? _cachedCoordinates;
  DateTime? _lastCoordsFetch;
  PrayerTimes? _cachedTodayTimes;
  PrayerTimes? _cachedTomorrowTimes;
  DateTime? _cachedDate;

  // Diagnostic logging tracker
  Prayer? _lastLoggedPrayer;
  String? _lastLoggedSource;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🚀 [PrayerTaskHandler] onStart called at $timestamp (starter: $starter)');
    try {
      // Immediate synchronous initial calculation
      await _updatePrayerCountdown(timestamp);
    } catch (e, st) {
      debugPrint('❌ [PrayerTaskHandler] FATAL in onStart: $e\n$st');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    try {
      _updatePrayerCountdown(timestamp);
    } catch (e, st) {
      debugPrint('❌ [PrayerTaskHandler] FATAL in onRepeatEvent: $e\n$st');
    }
  }

  Future<void> _updatePrayerCountdown(DateTime now) async {
    try {
      final today = DateTime(now.year, now.month, now.day);

      // 1. Coordinates: immediate fallback default, never hang
      _cachedCoordinates ??= Coordinates(
        PrayerConfig.defaultLatitude,
        PrayerConfig.defaultLongitude,
      );

      if (_lastCoordsFetch == null ||
          now.difference(_lastCoordsFetch!).inMinutes >= 5) {
        try {
          final freshCoords = await PrayerConfig.getCoordinates().timeout(
            const Duration(seconds: 2),
            onTimeout: () => _cachedCoordinates!,
          );
          if (freshCoords.latitude != _cachedCoordinates!.latitude ||
              freshCoords.longitude != _cachedCoordinates!.longitude) {
            _cachedCoordinates = freshCoords;
            _cachedDate = null;
          }
        } catch (e) {
          debugPrint('⚠️ [PrayerTaskHandler] Failed fetching fresh coordinates (using cached): $e');
        }
        _lastCoordsFetch = now;
      }

      final coords = _cachedCoordinates!;
      final params = PrayerConfig.params;

      // Recompute prayer times when date changes or on first run
      if (_cachedTodayTimes == null ||
          _cachedDate == null ||
          _cachedDate != today) {
        final todayComponents = DateComponents.from(now);
        _cachedTodayTimes = PrayerTimes(coords, todayComponents, params);

        final tomorrowComponents = DateComponents.from(now.add(const Duration(days: 1)));
        _cachedTomorrowTimes = PrayerTimes(coords, tomorrowComponents, params);
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

      // Find the next upcoming prayer for today
      Prayer nextPrayer = Prayer.none;
      DateTime? nextPrayerTime;
      String source = 'today';

      for (final entry in todayPrayers) {
        if (entry.value.isAfter(now)) {
          nextPrayer = entry.key;
          nextPrayerTime = entry.value;
          source = 'today';
          break;
        }
      }

      // If all today's prayers have passed (after Isha), next prayer is tomorrow's Fajr
      if (nextPrayer == Prayer.none || nextPrayerTime == null) {
        nextPrayer = Prayer.fajr;
        nextPrayerTime = tomorrowTimes.fajr;
        source = 'tomorrow';
      }

      final diff = nextPrayerTime.difference(now);
      final safeDiff = diff.isNegative ? Duration.zero : diff;

      // 📝 Safe diagnostic log (logs every 10s or when target changes)
      if (now.second % 10 == 0 ||
          _lastLoggedPrayer != nextPrayer ||
          _lastLoggedSource != source) {
        _lastLoggedPrayer = nextPrayer;
        _lastLoggedSource = source;
        debugPrint(
          '⏱ [PrayerTaskHandler] id: 1000 | now: $now | Next: ${_getName(nextPrayer)} at: $nextPrayerTime (source: $source) | remaining: $safeDiff',
        );
      }

      final prayerName = _getName(nextPrayer);
      final prayerTimeStr = TimeFormat.format12h(nextPrayerTime);
      final countdownStr = TimeFormat.hhmmss(safeDiff);
      final isTomorrow = source == 'tomorrow';

      final title = isTomorrow
          ? 'الصلاة القادمة: $prayerName (غداً)'
          : 'الصلاة القادمة: $prayerName';
      final text = '$prayerTimeStr   •   $countdownStr';

      // Live update foreground notification with brand accent color and clear typography
      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.pravera.flutter_foreground_task.notification_icon',
          backgroundColor: Color(0xFF4ECCA3),
        ),
      );
    } catch (e, st) {
      debugPrint('⏱ [PrayerTaskHandler] Error updating countdown: $e\n$st');
    }
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
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}