import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationPermission;
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/core/constants/app_constants.dart';
import 'package:rafiki_app/core/utils/time_format.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';

class PrayerTaskHandler extends TaskHandler {
  // Caching
  Coordinates? _cachedCoordinates;
  DateTime? _lastCoordsFetch;
  PrayerTimes? _cachedTodayTimes;
  PrayerTimes? _cachedTomorrowTimes;
  DateTime? _cachedDate;

  // Custom Azkar caching
  List<CustomNotification>? _cachedCustomNotifications;
  DateTime? _lastCustomNotifFetch;

  // Diagnostic logging tracker
  Prayer? _lastLoggedPrayer;
  String? _lastLoggedSource;

  // ── Live-fire tracking ──────────────────────────────────────────────
  //
  // This service ticks every 1 second while running, which is exactly
  // what lets it act as its own "exact alarm": it doesn't need Android's
  // SCHEDULE_EXACT_ALARM permission at all, because it isn't scheduling
  // anything for the future — it notices the right second arriving in
  // real time and fires immediately. `_firedKeys` guards against firing
  // the same prayer/type more than once per day (reset on date change).
  final Set<String> _firedKeys = {};

  static const Map<Prayer, String> _prayerNamesAr = {
    Prayer.fajr: 'الفجر',
    Prayer.dhuhr: 'الظهر',
    Prayer.asr: 'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha: 'العشاء',
  };

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

        // New calendar day → reset the live-fire guards so today's
        // BEFORE/AT notifications can fire again.
        _firedKeys.clear();
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

      // ── Live fire: BEFORE (10 min) & AT (prayer time) ─────────────────
      //
      // Checked every tick (every 1s) against every one of today's five
      // prayers — independent of which one is "next" for the countdown
      // display below. Each combination fires at most once/day.
      for (final entry in todayPrayers) {
        final prayer = entry.key;
        final prayerTime = entry.value;
        final beforeTime = prayerTime.subtract(const Duration(minutes: 10));
        final dateKey = '${today.year}-${today.month}-${today.day}-${prayer.name}';

        final beforeKey = '${dateKey}_before';
        if (!_firedKeys.contains(beforeKey) &&
            now.isAfter(beforeTime) &&
            now.isBefore(prayerTime)) {
          _firedKeys.add(beforeKey);
          await _fireLiveNotification(
            id: AppConstants.prayerBeforeIdToday[prayer]!,
            prayer: prayer,
            isAthanTime: false,
          );
        }

        final atKey = '${dateKey}_at';
        // Grace window (10 min) so a service that was briefly
        // suspended during doze still catches the moment and fires.
        if (!_firedKeys.contains(atKey) &&
            now.isAfter(prayerTime) &&
            now.difference(prayerTime) < const Duration(minutes: 10)) {
          _firedKeys.add(atKey);
          await _fireLiveNotification(
            id: AppConstants.prayerAtIdToday[prayer]!,
            prayer: prayer,
            isAthanTime: true,
          );
        }
      }

      // ── Live fire: Custom Azkar Reminders ────────────────────────────
      await _checkLiveCustomAzkar(now, today);

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

  /// Fires a real notification RIGHT NOW (no `schedule:` block at all) —
  /// this is what makes it independent of the exact-alarm permission.
  /// Uses the exact same notification ID that [NotificationEngine] uses
  /// for its OS-scheduled backup, so if that one *is* also pending (e.g.
  /// exact alarm was granted), it gets silently replaced instead of
  /// duplicated.
  Future<void> _fireLiveNotification({
    required int id,
    required Prayer prayer,
    required bool isAthanTime,
  }) async {
    final name = _prayerNamesAr[prayer] ?? '';
    try {
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        debugPrint('🕌 [PrayerTaskHandler] ⛔ Live-fire skipped ($name, athan=$isAthanTime) — notifications not allowed');
        return;
      }

      // Mutual exclusion: cancel the OS-scheduled backup alarm for this ID
      // so it cannot fire a second time (prevents duplicate audio/chime).
      try {
        await AwesomeNotifications().cancelSchedule(id);
        debugPrint('🕌 [PrayerTaskHandler] 🛑 Cancelled OS backup schedule for id=$id (Live fire taking over)');
      } catch (e) {
        debugPrint('🕌 [PrayerTaskHandler] Note on cancelSchedule($id): $e');
      }

      final ok = await AwesomeNotifications().createNotification(
        content: isAthanTime
            ? NotificationContent(
                id: id,
                channelKey: AppConstants.notificationChannelPrayer,
                title: '🕌 حان الآن وقت صلاة $name',
                body: 'الله أكبر، حان موعد أذان $name — أقم الصلاة يرحمك الله',
                notificationLayout: NotificationLayout.BigText,
                category: NotificationCategory.Reminder,
                largeIcon: 'resource://mipmap/ic_launcher',
                roundedLargeIcon: true,
                color: AppColors.gold,
                wakeUpScreen: true,
                customSound: 'resource://raw/res_abdul_hakam',
                autoDismissible: true,
                groupKey: 'prayer_alerts',
                summary: 'مواقيت الصلاة',
              )
            : NotificationContent(
                id: id,
                channelKey: AppConstants.notificationChannelPrayerReminder,
                title: '⏳ متبقي 10 دقائق على صلاة $name',
                body: 'استعد للوضوء والصلاة يرحمك الله',
                notificationLayout: NotificationLayout.BigText,
                category: NotificationCategory.Reminder,
                largeIcon: 'resource://mipmap/ic_launcher',
                roundedLargeIcon: true,
                color: AppColors.accent,
                wakeUpScreen: true,
                autoDismissible: true,
                groupKey: 'prayer_alerts',
                summary: 'مواقيت الصلاة',
              ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'تم',
            actionType: ActionType.DismissAction,
          ),
        ],
        // No `schedule:` — this fires immediately, this exact second.
      );
      debugPrint(
        '🕌 [PrayerTaskHandler] ${ok ? '✅ LIVE-FIRED' : '⚠️ LIVE-FIRE FAILED'} | $name | '
        '${isAthanTime ? 'AT' : 'BEFORE'} | id=$id',
      );
    } catch (e, st) {
      debugPrint('🕌 [PrayerTaskHandler] ❌ Live-fire ERROR ($name, athan=$isAthanTime): $e\n$st');
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

  static const Map<int, List<String>> _weekdayTokens = {
    DateTime.monday: [
      'الاثنين', 'الإثنين', 'إثنين', 'اثنين', 'إثن', 'اثن',
      'Monday', 'Mon',
    ],
    DateTime.tuesday: [
      'الثلاثاء', 'ثلاثاء', 'ثلا',
      'Tuesday', 'Tue',
    ],
    DateTime.wednesday: [
      'الأربعاء', 'الاربعاء', 'أربعاء', 'اربعاء', 'أرب', 'ارب',
      'Wednesday', 'Wed',
    ],
    DateTime.thursday: [
      'الخميس', 'خميس', 'خمس',
      'Thursday', 'Thu',
    ],
    DateTime.friday: [
      'الجمعة', 'جمعة', 'جمع',
      'Friday', 'Fri',
    ],
    DateTime.saturday: [
      'السبت', 'سبت',
      'Saturday', 'Sat',
    ],
    DateTime.sunday: [
      'الأحد', 'الاحد', 'أحد', 'احد',
      'Sunday', 'Sun',
    ],
  };

  Future<void> _checkLiveCustomAzkar(DateTime now, DateTime today) async {
    // Refresh custom notifications from SharedPreferences every 20 seconds
    if (_lastCustomNotifFetch == null ||
        now.difference(_lastCustomNotifFetch!).inSeconds >= 20) {
      _lastCustomNotifFetch = now;
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('notifications_list_v2');
        if (raw != null && raw.isNotEmpty) {
          final List dynamicList = jsonDecode(raw);
          _cachedCustomNotifications =
              dynamicList.map((e) => CustomNotification.fromJson(e)).toList();
        } else {
          _cachedCustomNotifications = [];
        }
      } catch (e) {
        debugPrint('⚠️ [PrayerTaskHandler] Error loading custom azkar: $e');
      }
    }

    final azkarList = _cachedCustomNotifications;
    if (azkarList == null || azkarList.isEmpty) return;

    final todayTokens = _weekdayTokens[now.weekday] ?? [];

    for (final notif in azkarList) {
      if (!notif.enabled) continue;

      // Check if notif includes today
      final matchesToday = notif.days.any((d) {
        final trimmed = d.trim();
        return todayTokens.contains(trimmed);
      });

      if (!matchesToday) continue;

      // Check hour and minute
      if (now.hour == notif.time.hour && now.minute == notif.time.minute) {
        final fireKey = 'zikr_${notif.id}_${today.year}_${today.month}_${today.day}_${now.hour}_${now.minute}';
        if (_firedKeys.contains(fireKey)) continue;

        _firedKeys.add(fireKey);

        final baseBlock = 10000 + ((notif.id.hashCode.abs() % 6900) * 10);
        final scheduleId = baseBlock + now.weekday;

        try {
          final ok = await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: scheduleId,
              channelKey: AppConstants.notificationChannelAzkar,
              title: notif.title.isNotEmpty ? notif.title : 'تذكير بذكر الله',
              body: notif.body,
              notificationLayout: NotificationLayout.BigText,
              category: NotificationCategory.Reminder,
              largeIcon: 'resource://mipmap/ic_launcher',
              roundedLargeIcon: true,
              color: AppColors.accent,
              wakeUpScreen: true,
              autoDismissible: true,
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'DISMISS',
                label: 'تم',
                actionType: ActionType.DismissAction,
              ),
            ],
          );
          debugPrint('📿 [PrayerTaskHandler] ${ok ? "✅ LIVE-FIRED" : "⚠️ LIVE-FIRE FAILED"} Azkar "${notif.title}" (id=$scheduleId)');
        } catch (e, st) {
          debugPrint('📿 [PrayerTaskHandler] ❌ Error firing live custom azkar: $e\n$st');
        }
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}