import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationPermission;
import 'package:adhan/adhan.dart';

import 'package:rafiki_app/core/theme/app_colors.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_config.dart';
import 'package:rafiki_app/features/prayer/data/services/prayer_engine.dart';
import 'package:rafiki_app/core/constants/app_constants.dart';

class NotificationEngine {
  static final NotificationEngine instance = NotificationEngine._internal();
  NotificationEngine._internal();

  final ValueNotifier<List<CustomNotification>> notifications = ValueNotifier([]);

  /// Callback to ensure FlutterForegroundTask is running when notifications are allowed
  Future<void> Function()? onEnsureForegroundService;

  /// Reactive flag: true when general notification permission is granted.
  /// Single source of truth for the entire app (Azkar, Prayers, etc.).
  final ValueNotifier<bool> isGlobalAllowed = ValueNotifier(false);

  /// Reactive flag: true when SCHEDULE_EXACT_ALARM permission is granted.
  /// UI widgets can listen to this to show a persistent warning when inexact.
  final ValueNotifier<bool> exactAlarmGranted = ValueNotifier(false);

  static const String _kNotificationsKey = 'notifications_list_v2';
  static const String _kLegacyKey = 'notification_data'; // from AppConstants.prefNotificationData

  static const Map<String, int> _dayMap = {
    // Arabic Full
    'السبت': DateTime.saturday,
    'الأحد': DateTime.sunday,
    'الاثنين': DateTime.monday,
    'الإثنين': DateTime.monday,
    'الثلاثاء': DateTime.tuesday,
    'الأربعاء': DateTime.wednesday,
    'الخميس': DateTime.thursday,
    'الجمعة': DateTime.friday,
    // Arabic Short
    'سبت': DateTime.saturday,
    'أحد': DateTime.sunday,
    'إثن': DateTime.monday,
    'اثن': DateTime.monday,
    'ثلا': DateTime.tuesday,
    'أرب': DateTime.wednesday,
    'ارب': DateTime.wednesday,
    'خمس': DateTime.thursday,
    'جمع': DateTime.friday,
    // English Full
    'Saturday': DateTime.saturday,
    'Sunday': DateTime.sunday,
    'Monday': DateTime.monday,
    'Tuesday': DateTime.tuesday,
    'Wednesday': DateTime.wednesday,
    'Thursday': DateTime.thursday,
    'Friday': DateTime.friday,
    // English Short
    'Sat': DateTime.saturday,
    'Sun': DateTime.sunday,
    'Mon': DateTime.monday,
    'Tue': DateTime.tuesday,
    'Wed': DateTime.wednesday,
    'Thu': DateTime.thursday,
    'Fri': DateTime.friday,
  };

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('🔔 [NotifEngine] Notification Action: id=${receivedAction.id}, key=${receivedAction.buttonKeyPressed}');
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Migration from legacy key
    final legacyRaw = prefs.getString(_kLegacyKey);
    if (legacyRaw != null) {
      try {
        final m = jsonDecode(legacyRaw) as Map<String, dynamic>;
        final legacyNotif = CustomNotification.fromJson(m);
        final list = [legacyNotif];
        await prefs.setString(_kNotificationsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
        await prefs.remove(_kLegacyKey);
      } catch (e) {
        debugPrint('[NotifEngine] Failed to migrate legacy notifications: $e');
      }
    }

    // 2. Load notifications
    final raw = prefs.getString(_kNotificationsKey);
    if (raw != null) {
      try {
        final List dynamicList = jsonDecode(raw);
        final loadedList = dynamicList.map((e) => CustomNotification.fromJson(e)).toList();
        notifications.value = loadedList;
      } catch (e) {
        debugPrint('Error loading notifications: $e');
        notifications.value = [];
      }
    }

    // Cleanup old legacy channels BEFORE initialize to avoid conflict
    try {
      await AwesomeNotifications().removeChannel('azkar_channel');
      await AwesomeNotifications().removeChannel('prayer_channel');
      await AwesomeNotifications().removeChannel('prayer_channel_v2');
      await AwesomeNotifications().removeChannel('prayer_channel_v3');
      await AwesomeNotifications().removeChannel('prayer_reminder_channel');
    } catch (e) {
      debugPrint('Legacy channel removal note: $e');
    }

    // 3. Initialize AwesomeNotifications if not already done
    debugPrint('🔔 [NotifEngine] Calling AwesomeNotifications().initialize()...');
    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: AppConstants.notificationChannelAzkar,
          channelName: 'Azkar Notifications',
          channelDescription: 'إشعارات التذكير اليومي بالأذكار والأدعية',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultColor: AppColors.accent,
          ledColor: AppColors.accent,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          onlyAlertOnce: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
        NotificationChannel(
          channelKey: AppConstants.notificationChannelPrayer,
          channelName: 'Prayer Notifications',
          channelDescription: 'تنبيهات مواقيت الصلاة وصوت الأذان',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultColor: AppColors.gold,
          ledColor: AppColors.gold,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          soundSource: 'resource://raw/res_abdul_hakam',
          onlyAlertOnce: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
        NotificationChannel(
          channelKey: AppConstants.notificationChannelPrayerReminder,
          channelName: 'Prayer Reminders',
          channelDescription: 'تنبيه اقتراب موعد الصلاة قبلها بـ 10 دقائق',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultColor: AppColors.accent,
          ledColor: AppColors.accent,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          onlyAlertOnce: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
    );
    debugPrint('🔔 [NotifEngine] AwesomeNotifications().initialize() DONE');

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    // 4. Check permissions
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    isGlobalAllowed.value = allowed;
    debugPrint('🔔 [NotifEngine] isNotificationAllowed = $allowed');

    try {
      final permList = await AwesomeNotifications().checkPermissionList();
      debugPrint('🔔 [NotifEngine] checkPermissionList = $permList');
    } catch (e) {
      debugPrint('🔔 [NotifEngine] checkPermissionList ERROR: $e');
    }

    if (allowed) {
      await syncSchedules();
      debugPrint('🔔 [NotifEngine] syncSchedules() DONE, now calling schedulePrayerNotifications()...');
      await schedulePrayerNotifications();
      debugPrint('🔔 [NotifEngine] schedulePrayerNotifications() DONE');
    } else {
      debugPrint('🔔 [NotifEngine] ⚠️ Notifications NOT allowed — skipping all scheduling');
    }

    // 5. Subscribe to PrayerEngine midnight events so notifications are
    //    re-scheduled for the new day even when the app stays open overnight.
    _listenToMidnightEvent();
  }

  // ── Validation ────────────────────────────────────────────────────────

  bool _hasConflict(CustomNotification newNotif) {
    for (final existing in notifications.value) {
      if (existing.id == newNotif.id) continue;
      if (existing.time.hour == newNotif.time.hour && existing.time.minute == newNotif.time.minute) {
        final overlap = existing.days.any((d) => newNotif.days.contains(d));
        if (overlap) return true;
      }
    }
    return false;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────

  Future<void> addNotification(CustomNotification notif) async {
    if (notifications.value.length >= AppConstants.maxCustomNotifications) {
      throw Exception('لقد وصلت للحد الأقصى للإشعارات (${AppConstants.maxCustomNotifications})');
    }
    if (_hasConflict(notif)) {
      throw Exception('يوجد إشعار آخر في نفس الوقت ونفس اليوم.');
    }

    final newList = List<CustomNotification>.from(notifications.value)..add(notif);
    await _atomicSave(newList);
  }

  Future<void> updateNotification(CustomNotification notif) async {
    if (_hasConflict(notif)) {
      throw Exception('يوجد إشعار آخر في نفس الوقت ونفس اليوم.');
    }

    final newList = List<CustomNotification>.from(notifications.value);
    final idx = newList.indexWhere((e) => e.id == notif.id);
    if (idx != -1) {
      newList[idx] = notif;
      await _atomicSave(newList);
    }
  }

  Future<void> deleteNotification(String id) async {
    final newList = List<CustomNotification>.from(notifications.value)
      ..removeWhere((e) => e.id == id);
    await _atomicSave(newList);
  }

  Future<void> toggleNotification(String id, bool enabled) async {
    final newList = List<CustomNotification>.from(notifications.value);
    final idx = newList.indexWhere((e) => e.id == id);
    if (idx != -1) {
      newList[idx] = newList[idx].copyWith(enabled: enabled);
      await _atomicSave(newList);
    }
  }

  bool _isResuming = false;
  DateTime? _lastResumeCheck;

  Future<bool> checkAndHandleAppResume({BuildContext? context}) async {
    final now = DateTime.now();

    if (_isResuming) {
      debugPrint('🔔 [NotifEngine] ⏭ Skipping checkAndHandleAppResume — already running');
      return false;
    }

    if (_lastResumeCheck != null && now.difference(_lastResumeCheck!).inSeconds < 30) {
      debugPrint('🔔 [NotifEngine] ⏭ Skipping checkAndHandleAppResume — throttled (<30s since last run)');
      return false;
    }

    _isResuming = true;
    _lastResumeCheck = now;

    try {
      final isGlobalAllowedVal = await AwesomeNotifications().isNotificationAllowed();
      isGlobalAllowed.value = isGlobalAllowedVal;
      final globalPerms = await AwesomeNotifications().checkPermissionList();
      final prayerPerms = await AwesomeNotifications().checkPermissionList(
        channelKey: AppConstants.notificationChannelPrayer,
      );

      debugPrint('🔔 [NotifEngine] 📊 Resumed status:');
      debugPrint('   • isNotificationAllowed: $isGlobalAllowedVal');
      debugPrint('   • Global permissions: $globalPerms');
      debugPrint('   • Prayer channel permissions: $prayerPerms');

      if (isGlobalAllowedVal) {
        debugPrint('🔔 [NotifEngine] ✅ Permissions are ACTIVE — syncing schedules...');
        await syncSchedules();
        await schedulePrayerNotifications();
        await onEnsureForegroundService?.call();

        return true;
      } else {
        debugPrint('🔔 [NotifEngine] ⚠️ Notifications are currently NOT allowed.');
        return false;
      }
    } catch (e, st) {
      debugPrint('🔔 [NotifEngine] ❌ Error in checkAndHandleAppResume: $e\n$st');
      return false;
    } finally {
      _isResuming = false;
    }
  }

  static const String _kMiuiGuideShownKey = 'miui_battery_guide_shown_v1';

  /// Exact alarms are not required — the app uses standard notifications +
  /// live Foreground Service countdown to fire on time.
  Future<bool> checkAndRequestExactAlarmPermission({
    BuildContext? context,
    bool forcePrompt = false,
  }) async {
    exactAlarmGranted.value = true;
    return true;
  }

  Future<bool> requestAllNotificationPermissions({BuildContext? context}) async {
    debugPrint('🔔 [NotifEngine] ▶ requestAllNotificationPermissions() (User Gesture) started...');

    try {
      bool awesomeAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('🔔 [NotifEngine] AwesomeNotifications initial isNotificationAllowed = $awesomeAllowed');

      if (!awesomeAllowed) {
        debugPrint('🔔 [NotifEngine] Requesting AwesomeNotifications permissions...');
        awesomeAllowed = await AwesomeNotifications().requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
          ],
        );
        debugPrint('🔔 [NotifEngine] AwesomeNotifications after request = $awesomeAllowed');
      }

      debugPrint('🔔 [NotifEngine] Requesting FlutterForegroundTask permission...');
      final fgStatus = await FlutterForegroundTask.requestNotificationPermission();
      debugPrint('🔔 [NotifEngine] FlutterForegroundTask permission status = $fgStatus');

      // Runtime verification and redirection for SCHEDULE_EXACT_ALARM on Android 12+
      if (context != null && context.mounted) {
        await checkAndRequestExactAlarmPermission(context: context);
      } else {
        await checkAndRequestExactAlarmPermission();
      }

      final isFinalAllowed = await AwesomeNotifications().isNotificationAllowed();
      isGlobalAllowed.value = isFinalAllowed;
      final prayerPerms = await AwesomeNotifications().checkPermissionList(
        channelKey: AppConstants.notificationChannelPrayer,
      );
      debugPrint('🔔 [NotifEngine] Final isNotificationAllowed = $isFinalAllowed, prayer channel perms = $prayerPerms');

      if (isFinalAllowed) {
        await syncSchedules();
        await schedulePrayerNotifications();
        await onEnsureForegroundService?.call();
        debugPrint('🔔 [NotifEngine] ✅ All schedules synced & prayer notifications scheduled successfully.');
      } else {
        debugPrint('🔔 [NotifEngine] ⚠️ Notification permissions not fully granted.');
      }

      if (context != null && context.mounted) {
        await _showBatteryOptimizationGuideIfNeeded(context);
      }

      return isFinalAllowed;
    } catch (e, st) {
      debugPrint('🔔 [NotifEngine] ❌ Error in requestAllNotificationPermissions: $e');
      debugPrint('🔔 [NotifEngine] StackTrace: $st');
      return false;
    }
  }

  Future<void> _showBatteryOptimizationGuideIfNeeded(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_kMiuiGuideShownKey) ?? false;
      if (shown || !context.mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'لضمان عمل الأذان في الخلفية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'بعض الأجهزة (مثل Xiaomi / MIUI و Huawei و Samsung) تقوم بإيقاف التطبيقات في الخلفية لتوفير البطارية.\n\n'
                'لضمان وصول إشعارات الأذان والعداد المباشر في موعدها:\n'
                '1. تفعيل «التشغيل التلقائي» (Autostart).\n'
                '2. ضبط توفير البطارية على «لا توجد قيود» (No restrictions).',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('حسناً، فهمت', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      await prefs.setBool(_kMiuiGuideShownKey, true);
    } catch (e) {
      debugPrint('[NotifEngine] Could not show MIUI guide dialog: $e');
    }
  }

  Future<bool> checkAndRequestPermission({BuildContext? context}) async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    isGlobalAllowed.value = allowed;
    if (!allowed) {
      if (context != null && !context.mounted) return false;
      return requestAllNotificationPermissions(context: context);
    }
    return allowed;
  }

  Future<void> _atomicSave(List<CustomNotification> newList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(newList.map((e) => e.toJson()).toList());

    final success = await prefs.setString(_kNotificationsKey, jsonStr);
    if (!success) {
      throw Exception('فشل في حفظ البيانات');
    }

    notifications.value = newList;
    await syncSchedules();
  }

  Future<void> syncSchedules() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      debugPrint('🔔 [NotifEngine] Azkar scheduling skipped — notifications not allowed');
      return;
    }

    try {
      await AwesomeNotifications().cancelNotificationsByChannelKey(AppConstants.notificationChannelAzkar);
      await AwesomeNotifications().cancelNotificationsByChannelKey('azkar_channel');
    } catch (e) {
      debugPrint('🔔 [NotifEngine] Error cancelling azkar channel schedules: $e');
    }

    final localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

    for (final notif in notifications.value) {
      if (!notif.enabled) continue;

      // Unique hash block in 10000..79000 range (strictly disjoint from prayer IDs 90000..90019)
      final baseBlock = 10000 + ((notif.id.hashCode.abs() % 6900) * 10);

      for (var i = 0; i < notif.days.length; i++) {
        final weekday = _dayMap[notif.days[i].trim()] ?? DateTime.monday;
        final scheduleId = baseBlock + weekday;

        try {
          await AwesomeNotifications().createNotification(
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
            schedule: NotificationCalendar(
              weekday: weekday,
              hour: notif.time.hour,
              minute: notif.time.minute,
              second: 0,
              timeZone: localTimeZone,
              repeats: true,
              allowWhileIdle: true,
              preciseAlarm: false,
            ),
          );
        } catch (e) {
          debugPrint('🔔 [NotifEngine] Azkar schedule error for ID $scheduleId: $e');
        }
      }
    }
  }

  // ── Prayer Alert Notification IDs ──────────────────────────
  //
  // Fixed, permanent mapping — never change these unless the old IDs
  // are explicitly cancelled first (otherwise ghost notifications linger).
  //
  // Layout: Prayer × Type × Day → unique int ID
  //   Today:    BEFORE (10-min) = 90000/02/04/06/08
  //             AT (prayer time) = 90001/03/05/07/09
  //   Tomorrow: BEFORE           = 90010/12/14/16/18
  //             AT               = 90011/13/15/17/19

  static const Map<Prayer, int> _beforeIdToday = {
    Prayer.fajr:    90000,
    Prayer.dhuhr:   90002,
    Prayer.asr:     90004,
    Prayer.maghrib: 90006,
    Prayer.isha:    90008,
  };

  static const Map<Prayer, int> _atIdToday = {
    Prayer.fajr:    90001,
    Prayer.dhuhr:   90003,
    Prayer.asr:     90005,
    Prayer.maghrib: 90007,
    Prayer.isha:    90009,
  };

  static const Map<Prayer, int> _beforeIdTomorrow = {
    Prayer.fajr:    90010,
    Prayer.dhuhr:   90012,
    Prayer.asr:     90014,
    Prayer.maghrib: 90016,
    Prayer.isha:    90018,
  };

  static const Map<Prayer, int> _atIdTomorrow = {
    Prayer.fajr:    90011,
    Prayer.dhuhr:   90013,
    Prayer.asr:     90015,
    Prayer.maghrib: 90017,
    Prayer.isha:    90019,
  };

  static const String _kPrayerScheduleDateKey = 'prayer_notif_scheduled_date';

  static const Map<Prayer, String> _prayerNames = {
    Prayer.fajr:    'الفجر',
    Prayer.dhuhr:   'الظهر',
    Prayer.asr:     'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha:    'العشاء',
  };

  bool _isSchedulingPrayer = false;
  DateTime? _lastPrayerScheduleRun;

  /// Subscription to PrayerEngine midnight events — triggers re-scheduling
  /// for the new day without requiring the user to open the app.
  StreamSubscription<PrayerEvent>? _midnightSubscription;

  Future<void> schedulePrayerNotifications({bool force = false}) async {
    final now = DateTime.now();

    if (_isSchedulingPrayer) {
      debugPrint('🕌 [PrayerNotification] ⚠️ SKIPPED — scheduling already in progress');
      return;
    }

    if (!force && _lastPrayerScheduleRun != null &&
        now.difference(_lastPrayerScheduleRun!).inSeconds < 10) {
      debugPrint('🕌 [PrayerNotification] ⏭ Throttled (<10s) — skip');
      return;
    }

    _isSchedulingPrayer = true;
    _lastPrayerScheduleRun = now;

    debugPrint('🕌 [PrayerNotification] ▶ schedulePrayerNotifications() CALLED (force=$force)');
    final todayStr = '${now.year}-${now.month}-${now.day}';
    debugPrint('🕌 [PrayerNotification] now=$now, todayStr=$todayStr');

    // Guard: skip if already scheduled today AND notifications are still pending
    // in the OS queue — handles battery-optimization wipes by verifying actual
    // pending count, not just the saved date.
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastScheduled = prefs.getString(_kPrayerScheduleDateKey);
      debugPrint('🕌 [PrayerNotification] lastScheduled=$lastScheduled');

      bool hasPendingPrayerNotifs = false;
      try {
        final pending = await AwesomeNotifications().listScheduledNotifications();
        hasPendingPrayerNotifs = pending.any(
          (n) => n.content?.channelKey == AppConstants.notificationChannelPrayer ||
                 n.content?.channelKey == AppConstants.notificationChannelPrayerReminder,
        );
        debugPrint(
          '🕌 [PrayerNotification] hasPendingPrayerNotifs=$hasPendingPrayerNotifs '
          '(total pending=${pending.length})',
        );
      } catch (e) {
        debugPrint('🕌 [PrayerNotification] listScheduledNotifications ERROR during guard: $e');
      }

      if (lastScheduled == todayStr && hasPendingPrayerNotifs) {
        debugPrint('🕌 [PrayerNotification] ⏭ SKIP — already scheduled today & notifications pending');
        _isSchedulingPrayer = false;
        return;
      }
    }

    try {
      final coords = await PrayerConfig.getCoordinates();
      debugPrint('🕌 [PrayerNotification] coords=(${coords.latitude}, ${coords.longitude})');
      final params = PrayerConfig.params;

      final todayComponents = DateComponents.from(now);
      final todayTimes = PrayerTimes(coords, todayComponents, params);

      final tomorrowComponents = DateComponents.from(now.add(const Duration(days: 1)));
      final tomorrowTimes = PrayerTimes(coords, tomorrowComponents, params);

      // Cancel ALL existing prayer notifications before re-scheduling.
      // IDs are fixed constants so no orphan notifications are left behind.
      await AwesomeNotifications().cancelNotificationsByChannelKey(
        AppConstants.notificationChannelPrayer,
      );
      await AwesomeNotifications().cancelNotificationsByChannelKey(
        AppConstants.notificationChannelPrayerReminder,
      );
      await AwesomeNotifications().cancelNotificationsByChannelKey('prayer_channel_v3');
      await AwesomeNotifications().cancelNotificationsByChannelKey('prayer_reminder_channel');
      debugPrint('🕌 [PrayerNotification] 🗑 Cancelled all prayer channels notifications');

      final localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

      var scheduledCount = 0;
      var skippedCount = 0;

      // ── Inner helper ────────────────────────────────────────────────────
      Future<void> _schedulePrayer({
        required Prayer prayer,
        required DateTime prayerTime,
        required int beforeId,
        required int atId,
        required String dayLabel,
      }) async {
        final name = _prayerNames[prayer] ?? '';
        final beforeTime = prayerTime.subtract(const Duration(minutes: 10));

        // ── BEFORE notification (10 min early) ──────────────────────────
        if (beforeTime.isAfter(now)) {
          debugPrint(
            '🕌 [PrayerNotification] 📋 Scheduling | $name [$dayLabel] | Type=BEFORE | '
            'Prayer Time=$prayerTime | 10-Min Time=$beforeTime | ID=$beforeId',
          );
          try {
            final ok = await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: beforeId,
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
              schedule: NotificationCalendar(
                year: beforeTime.year,
                month: beforeTime.month,
                day: beforeTime.day,
                hour: beforeTime.hour,
                minute: beforeTime.minute,
                second: 0,
                millisecond: 0,
                timeZone: localTimeZone,
                repeats: false,
                allowWhileIdle: true,
                preciseAlarm: false,
              ),
            );
            debugPrint(
              '🕌 [PrayerNotification] ${ok ? '✅ SCHEDULED' : '⚠️ SCHEDULED (inexact fallback)'} | $name [$dayLabel] | Type=BEFORE | '
              'ID=$beforeId | createNotification=$ok',
            );
            scheduledCount++;
          } catch (e) {
            debugPrint('🕌 [PrayerNotification] ❌ $name [$dayLabel] BEFORE ERROR: $e');
          }
        } else {
          debugPrint(
            '🕌 [PrayerNotification] ⏭ SKIP | $name [$dayLabel] | Type=BEFORE | '
            'already past ($beforeTime <= $now)',
          );
          skippedCount++;
        }

        // ── AT notification (prayer time) ────────────────────────────────
        if (prayerTime.isAfter(now)) {
          debugPrint(
            '🕌 [PrayerNotification] 📋 Scheduling | $name [$dayLabel] | Type=AT | '
            'Prayer Time=$prayerTime | ID=$atId',
          );
          try {
            final ok = await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: atId,
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
              ),
              actionButtons: [
                NotificationActionButton(
                  key: 'DISMISS',
                  label: 'تم',
                  actionType: ActionType.DismissAction,
                ),
              ],
              schedule: NotificationCalendar(
                year: prayerTime.year,
                month: prayerTime.month,
                day: prayerTime.day,
                hour: prayerTime.hour,
                minute: prayerTime.minute,
                second: 0,
                millisecond: 0,
                timeZone: localTimeZone,
                repeats: false,
                allowWhileIdle: true,
                preciseAlarm: false,
              ),
            );
            debugPrint(
              '🕌 [PrayerNotification] ${ok ? '✅ SCHEDULED' : '⚠️ SCHEDULED (inexact fallback)'} | $name [$dayLabel] | Type=AT | '
              'ID=$atId | createNotification=$ok',
            );
            scheduledCount++;
          } catch (e) {
            debugPrint('🕌 [PrayerNotification] ❌ $name [$dayLabel] AT ERROR: $e');
          }
        } else {
          debugPrint(
            '🕌 [PrayerNotification] ⏭ SKIP | $name [$dayLabel] | Type=AT | '
            'already past ($prayerTime <= $now)',
          );
          skippedCount++;
        }
      }

      // ── Schedule today's prayers (fixed IDs: 90000–90009) ───────────────
      final todayPrayers = <Prayer, DateTime>{
        Prayer.fajr:    todayTimes.fajr,
        Prayer.dhuhr:   todayTimes.dhuhr,
        Prayer.asr:     todayTimes.asr,
        Prayer.maghrib: todayTimes.maghrib,
        Prayer.isha:    todayTimes.isha,
      };

      for (final entry in todayPrayers.entries) {
        await _schedulePrayer(
          prayer:     entry.key,
          prayerTime: entry.value,
          beforeId:   _beforeIdToday[entry.key]!,
          atId:       _atIdToday[entry.key]!,
          dayLabel:   'Today',
        );
      }

      // ── Schedule tomorrow's prayers (fixed IDs: 90010–90019) ────────────
      final tomorrowPrayers = <Prayer, DateTime>{
        Prayer.fajr:    tomorrowTimes.fajr,
        Prayer.dhuhr:   tomorrowTimes.dhuhr,
        Prayer.asr:     tomorrowTimes.asr,
        Prayer.maghrib: tomorrowTimes.maghrib,
        Prayer.isha:    tomorrowTimes.isha,
      };

      for (final entry in tomorrowPrayers.entries) {
        await _schedulePrayer(
          prayer:     entry.key,
          prayerTime: entry.value,
          beforeId:   _beforeIdTomorrow[entry.key]!,
          atId:       _atIdTomorrow[entry.key]!,
          dayLabel:   'Tomorrow',
        );
      }

      // Persist the date so the guard can skip unnecessary re-scheduling
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrayerScheduleDateKey, todayStr);

      debugPrint(
        '🕌 [PrayerNotification] ✅ DONE | scheduled=$scheduledCount | skipped=$skippedCount',
      );

      // Diagnostic: list all pending notifications
      try {
        final pending = await AwesomeNotifications().listScheduledNotifications();
        debugPrint('🕌 [PrayerNotification] 📊 Total pending: ${pending.length}');
        for (final n in pending) {
          debugPrint('   id=${n.content?.id} | title=${n.content?.title} | schedule=${n.schedule}');
        }
      } catch (e) {
        debugPrint('🕌 [PrayerNotification] listScheduledNotifications ERROR: $e');
      }
    } catch (e, st) {
      debugPrint('🕌 [PrayerNotification] ❌ FATAL ERROR: $e');
      debugPrint('🕌 [PrayerNotification] StackTrace: $st');
    } finally {
      _isSchedulingPrayer = false;
    }
  }

  // ── Midnight Re-Scheduling ───────────────────────────────────────────
  //
  // When the app remains open past midnight, PrayerEngine emits a
  // [PrayerEvent.midnight] event.  Without this listener, tomorrow's prayers
  // (already scheduled) would fire correctly, but the **new tomorrow** would
  // never get scheduled — only a fresh app open would trigger re-scheduling.
  //
  // This listener closes that gap: on midnight, we force a full re-schedule
  // so the current "today" window always has 10+10 notifications queued.

  void _listenToMidnightEvent() {
    _midnightSubscription?.cancel();
    _midnightSubscription = PrayerEngine.instance.eventStream
        .where((event) => event == PrayerEvent.midnight)
        .listen((_) async {
      debugPrint('🕌 [PrayerNotification] 🌙 Midnight event received — forcing re-schedule for new day');
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (allowed) {
        await schedulePrayerNotifications(force: true);
        await syncSchedules();
      } else {
        debugPrint('🕌 [PrayerNotification] ⚠️ Midnight re-schedule skipped — notifications not allowed');
      }
    });
    debugPrint('🕌 [PrayerNotification] 👂 Listening to PrayerEngine midnight events');
  }

  // ── DEBUG: Test Notification ────────────────────────────────────────

  Future<void> debugFireTestNotification() async {
    debugPrint('🧪 [DEBUG] debugFireTestNotification() CALLED');
    final now = DateTime.now();
    final fireAt = now.add(const Duration(minutes: 2));
    debugPrint('🧪 [DEBUG] now=$now, will fire scheduled at=$fireAt');

    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('🧪 [DEBUG] isNotificationAllowed=$isAllowed');

      if (!isAllowed) {
        debugPrint('🧪 [DEBUG] ⚠️ Notifications not allowed — aborting test notification.');
        return;
      }

      final localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      debugPrint('🧪 [DEBUG] Scheduling test notification (id=99998) for 2 minutes from now ($fireAt, tz=$localTimeZone)...');
      final scheduledResult = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 99998,
          channelKey: AppConstants.notificationChannelPrayerReminder,
          title: '🧪 اختبار التذكير (بعد دقيقتين)',
          body: 'هذا إشعار تذكير عادي يثبت وصول التنبيه بدقة',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
        ),
        schedule: NotificationCalendar(
          year: fireAt.year,
          month: fireAt.month,
          day: fireAt.day,
          hour: fireAt.hour,
          minute: fireAt.minute,
          second: fireAt.second,
          millisecond: 0,
          timeZone: localTimeZone,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: false,
        ),
      );
      debugPrint('🧪 [DEBUG] Scheduled result=$scheduledResult');

      final pending = await AwesomeNotifications().listScheduledNotifications();
      debugPrint('🧪 [DEBUG] Total pending after test: ${pending.length}');
      for (final n in pending) {
        debugPrint('   id=${n.content?.id}, title=${n.content?.title}');
      }
    } catch (e, st) {
      debugPrint('🧪 [DEBUG] ❌ ERROR: $e');
      debugPrint('🧪 [DEBUG] StackTrace: $st');
    }
  }

  // ── IN-APP DIAGNOSTICS ──────────────────────────────────────────────
  //
  // Collects all notification permission states and pending schedule info,
  // schedules a 1-minute test notification, and returns a human-readable
  // report string to display directly in the UI (no adb needed).

  Future<NotificationDiagnosticsReport> runInAppDiagnostics() async {
    final now = DateTime.now();
    final buf = StringBuffer();
    bool testScheduled = false;
    bool testCreateResult = false;
    String testError = '';
    int pendingTotal = 0;
    bool hasPrayerPending = false;

    try {
      // ── 1. Permission states ──────────────────────────────────────────
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      final globalPerms = await AwesomeNotifications().checkPermissionList();
      final prayerPerms = await AwesomeNotifications().checkPermissionList(
        channelKey: AppConstants.notificationChannelPrayer,
      );
      final precisePerms = await AwesomeNotifications().checkPermissionList(
        permissions: [NotificationPermission.PreciseAlarms],
      );
      final hasPrecise = precisePerms.contains(NotificationPermission.PreciseAlarms);

      buf.writeln('📋 حالة الأذونات:');
      buf.writeln('• isNotificationAllowed: $isAllowed');
      buf.writeln('• isGlobalAllowed (cached): ${isGlobalAllowed.value}');
      buf.writeln('• PreciseAlarms: $hasPrecise (cached: ${exactAlarmGranted.value})');
      buf.writeln('• Global perms: ${globalPerms.map((e) => e.name).join(', ')}');
      buf.writeln('• Prayer ch perms: ${prayerPerms.map((e) => e.name).join(', ')}');
      buf.writeln('');

      // ── 2. Pending notifications ──────────────────────────────────────
      final pending = await AwesomeNotifications().listScheduledNotifications();
      pendingTotal = pending.length;
      final prayerPending = pending.where(
        (n) => n.content?.channelKey == AppConstants.notificationChannelPrayer,
      ).toList();
      hasPrayerPending = prayerPending.isNotEmpty;

      buf.writeln('📊 الإشعارات المعلّقة: $pendingTotal إجمالي');
      buf.writeln('• قناة الصلاة: ${prayerPending.length} معلّق');
      for (final n in pending) {
        buf.writeln('  - ID=${n.content?.id} | ${n.content?.title ?? "—"}');
      }
      buf.writeln('');

      // ── 3. Schedule 1-minute test notification ────────────────────────
      final fireAt = now.add(const Duration(minutes: 1));
      buf.writeln('🧪 إشعار تجريبي مجدول بعد دقيقة:');
      buf.writeln('• سيُطلق في: ${fireAt.hour.toString().padLeft(2, "0")}:${fireAt.minute.toString().padLeft(2, "0")}:${fireAt.second.toString().padLeft(2, "0")}');

      if (isAllowed) {
        try {
          final immediateOk = await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 99996,
              channelKey: AppConstants.notificationChannelPrayer,
              title: '🕌 تجربة الأذان الفورية',
              body: 'صوت الأذان والتنبيه يعمل الآن كإشعار عادي بنجاح ✅',
              notificationLayout: NotificationLayout.BigText,
              category: NotificationCategory.Reminder,
              wakeUpScreen: true,
              autoDismissible: true,
              color: AppColors.gold,
              customSound: 'resource://raw/res_abdul_hakam',
            ),
          );
          buf.writeln('• إشعار فوري بصوت الأذان: ${immediateOk ? "نجح ✅" : "فشل ❌"}');
        } catch (e) {
          buf.writeln('• ❌ الإشعار الفوري: $e');
        }

        try {
          final diagTz = await AwesomeNotifications().getLocalTimeZoneIdentifier();
          testCreateResult = await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 99997,
              channelKey: AppConstants.notificationChannelPrayerReminder,
              title: '🧪 اختبار: إشعار بعد دقيقة',
              body: 'نجحت الجدولة ✅  |  الوقت: ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
              notificationLayout: NotificationLayout.BigText,
              category: NotificationCategory.Reminder,
              wakeUpScreen: true,
              autoDismissible: true,
            ),
            schedule: NotificationCalendar(
              year: fireAt.year,
              month: fireAt.month,
              day: fireAt.day,
              hour: fireAt.hour,
              minute: fireAt.minute,
              second: fireAt.second,
              millisecond: 0,
              timeZone: diagTz,
              repeats: false,
              allowWhileIdle: true,
              preciseAlarm: false,
            ),
          );
          testScheduled = true;
          buf.writeln('• createNotification() رجعت: $testCreateResult');
        } catch (e) {
          testError = e.toString();
          buf.writeln('• ❌ createNotification() رمى exception: $e');
        }
      } else {
        buf.writeln('• ⛔ الإشعارات غير مسموح بها — لم يتم الجدولة');
      }
    } catch (e) {
      buf.writeln('\n❌ خطأ عام في التشخيص: $e');
    }

    return NotificationDiagnosticsReport(
      report: buf.toString(),
      testScheduled: testScheduled,
      testCreateResult: testCreateResult,
      testError: testError,
      pendingTotal: pendingTotal,
      hasPrayerPending: hasPrayerPending,
    );
  }
}

// ── Diagnostics result model ────────────────────────────────────────────────
class NotificationDiagnosticsReport {
  final String report;
  final bool testScheduled;
  final bool testCreateResult;
  final String testError;
  final int pendingTotal;
  final bool hasPrayerPending;

  const NotificationDiagnosticsReport({
    required this.report,
    required this.testScheduled,
    required this.testCreateResult,
    required this.testError,
    required this.pendingTotal,
    required this.hasPrayerPending,
  });
}
