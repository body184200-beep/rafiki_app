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
import 'package:rafiki_app/core/constants/app_constants.dart';

class NotificationEngine {
  static final NotificationEngine instance = NotificationEngine._internal();
  NotificationEngine._internal();

  final ValueNotifier<List<CustomNotification>> notifications = ValueNotifier([]);
  
  static const String _kNotificationsKey = 'notifications_list_v2';
  static const String _kLegacyKey = 'notification_data'; // from AppConstants.prefNotificationData

  static const Map<String, int> _dayMap = {
    'السبت': DateTime.saturday,
    'الأحد': DateTime.sunday,
    'الاثنين': DateTime.monday,
    'الثلاثاء': DateTime.tuesday,
    'الأربعاء': DateTime.wednesday,
    'الخميس': DateTime.thursday,
    'الجمعة': DateTime.friday,
  };

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Migration from legacy key
    final legacyRaw = prefs.getString(_kLegacyKey);
    if (legacyRaw != null) {
      try {
        final m = jsonDecode(legacyRaw) as Map<String, dynamic>;
        final legacyNotif = CustomNotification.fromJson(m);
        // Save to new list
        final list = [legacyNotif];
        await prefs.setString(_kNotificationsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
        // Delete legacy
        await prefs.remove(_kLegacyKey);
      } catch (_) {}
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

    // 3. Initialize AwesomeNotifications if not already done
    debugPrint('🔔 [NotifEngine] Calling AwesomeNotifications().initialize()...');
    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelKey: AppConstants.notificationChannelAzkar,
          channelName: 'Azkar Notifications',
          channelDescription: 'Notifications for daily Azkar',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultColor: AppColors.accent,
          ledColor: AppColors.accent,
        ),
        NotificationChannel(
          channelKey: AppConstants.notificationChannelPrayer,
          channelName: 'Prayer Notifications',
          channelDescription: 'تنبيهات مواقيت الصلاة والأذان',
          importance: NotificationImportance.Max,
          defaultColor: AppColors.gold,
          ledColor: AppColors.gold,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          criticalAlerts: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        )
      ],
    );
    debugPrint('🔔 [NotifEngine] AwesomeNotifications().initialize() DONE');

    // 4. Check permissions
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    debugPrint('🔔 [NotifEngine] isNotificationAllowed = $allowed');

    // 4b. Detailed permission check
    try {
      final permList = await AwesomeNotifications().checkPermissionList();
      debugPrint('🔔 [NotifEngine] checkPermissionList = $permList');
    } catch (e) {
      debugPrint('🔔 [NotifEngine] checkPermissionList ERROR: $e');
    }

    if (allowed) {
      await syncSchedules();
      debugPrint('🔔 [NotifEngine] syncSchedules() DONE, now calling schedulePrayerNotifications()...');
      // Schedule today's prayer alert notifications (10-min-before + at-time)
      await schedulePrayerNotifications();
      debugPrint('🔔 [NotifEngine] schedulePrayerNotifications() DONE');
    } else {
      debugPrint('🔔 [NotifEngine] ⚠️ Notifications NOT allowed — skipping all scheduling');
    }
  }

  // ── Validation ────────────────────────────────────────────────────────

  bool _hasConflict(CustomNotification newNotif) {
    for (final existing in notifications.value) {
      if (existing.id == newNotif.id) continue; // skip self
      if (existing.time.hour == newNotif.time.hour && existing.time.minute == newNotif.time.minute) {
        // Check if any days overlap
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

  static const String _kMiuiGuideShownKey = 'miui_battery_guide_shown_v1';

  /// Unified sequential permission request to avoid Android permission cancellation race conditions.
  /// 1. AwesomeNotifications permissions (Alert, Sound, Badge, Vibration, PreciseAlarms, CriticalAlert)
  /// 2. FlutterForegroundTask permission
  /// 3. Precise Alarms check (Android 12+)
  /// 4. Sync & Schedule
  /// 5. Show MIUI / Battery optimization hint dialog if first time on Android
  Future<bool> requestAllNotificationPermissions({BuildContext? context}) async {
    debugPrint('🔔 [NotifEngine] ▶ requestAllNotificationPermissions() started...');
    
    try {
      // 1. AwesomeNotifications permission check & request (Sequential Step 1)
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
            NotificationPermission.PreciseAlarms,
            NotificationPermission.CriticalAlert,
          ],
        );
        debugPrint('🔔 [NotifEngine] AwesomeNotifications after request = $awesomeAllowed');
      }

      // 2. FlutterForegroundTask permission request (Sequential Step 2)
      debugPrint('🔔 [NotifEngine] Requesting FlutterForegroundTask permission...');
      final fgStatus = await FlutterForegroundTask.requestNotificationPermission();
      debugPrint('🔔 [NotifEngine] FlutterForegroundTask permission status = $fgStatus');

      // 3. Exact Alarm check on Android 12+ (SCHEDULE_EXACT_ALARM)
      try {
        final permList = await AwesomeNotifications().checkPermissionList();
        debugPrint('🔔 [NotifEngine] Granted permissions: $permList');
        if (!permList.contains(NotificationPermission.PreciseAlarms)) {
          debugPrint('🔔 [NotifEngine] Requesting PreciseAlarms explicitly...');
          await AwesomeNotifications().requestPermissionToSendNotifications(
            permissions: [NotificationPermission.PreciseAlarms],
          );
        }
      } catch (e) {
        debugPrint('🔔 [NotifEngine] PreciseAlarms check error: $e');
      }

      // 4. Sync all schedules & schedule prayer times if allowed
      final isFinalAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isFinalAllowed) {
        await syncSchedules();
        await schedulePrayerNotifications(force: true);
        debugPrint('🔔 [NotifEngine] ✅ All schedules synced & prayer notifications scheduled successfully.');
      } else {
        debugPrint('🔔 [NotifEngine] ⚠️ Notification permissions not fully granted.');
      }

      // 5. Check and show MIUI/Xiaomi/Battery Optimization guide dialog
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
    } catch (_) {}
  }

  Future<bool> checkAndRequestPermission({BuildContext? context}) async {
    return requestAllNotificationPermissions(context: context);
  }

  Future<void> _atomicSave(List<CustomNotification> newList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(newList.map((e) => e.toJson()).toList());
    
    // Atomic write
    final success = await prefs.setString(_kNotificationsKey, jsonStr);
    if (!success) {
      throw Exception('فشل في حفظ البيانات');
    }

    // Update in-memory state
    notifications.value = newList;

    // Resync schedules
    await syncSchedules();
  }

  Future<void> syncSchedules() async {
    // 1. Cancel all azkar_channel schedules
    await AwesomeNotifications().cancelNotificationsByChannelKey(AppConstants.notificationChannelAzkar);

    // 2. Re-schedule enabled notifications
    for (final notif in notifications.value) {
      if (!notif.enabled) continue;

      // Base ID generated securely using string hashcode offset
      final baseId = notif.id.hashCode.abs() % 100000;

      for (var i = 0; i < notif.days.length; i++) {
        final weekday = _dayMap[notif.days[i]] ?? DateTime.monday;
        final scheduleId = baseId + i;

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: scheduleId,
            channelKey: AppConstants.notificationChannelAzkar,
            title: notif.title,
            body: notif.body,
            notificationLayout: NotificationLayout.BigText,
          ),
          schedule: NotificationCalendar(
            weekday: weekday,
            hour: notif.time.hour,
            minute: notif.time.minute,
            second: 0,
            repeats: true,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  // ── Prayer Alert Notifications ──────────────────────────────────────

  /// Stable notification IDs for prayer alerts (range 90000–90009).
  /// Each prayer gets 2 IDs: one for 10-min-before, one for at-time.
  /// Fajr=0, Dhuhr=1, Asr=2, Maghrib=3, Isha=4
  static const int _prayerNotifBaseId = 90000;

  static const String _kPrayerScheduleDateKey = 'prayer_notif_scheduled_date';

  static const Map<Prayer, String> _prayerNames = {
    Prayer.fajr: 'الفجر',
    Prayer.dhuhr: 'الظهر',
    Prayer.asr: 'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha: 'العشاء',
  };

  /// Schedules push notifications for each of the 5 daily prayers:
  ///   - 10 minutes before prayer time  →  "⏳ اقتربت صلاة {name}"
  ///   - At prayer time                 →  "🕌 حان وقت صلاة {name}"
  ///
  /// This method is **idempotent per day**: it stores the date of the last
  /// scheduling run and skips if already done today (unless [force] is true).
  /// It cancels all previous prayer_channel notifications before re-scheduling.
  ///
  /// Call this:
  ///   1. At app startup (via [initialize])
  ///   2. From [PrayerTaskHandler] when the date rolls over at midnight
  Future<void> schedulePrayerNotifications({bool force = false}) async {
    debugPrint('🕌 [PrayerNotif] ▶ schedulePrayerNotifications() CALLED (force=$force)');
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    debugPrint('🕌 [PrayerNotif] now=$now, todayStr=$todayStr');

    // Guard: don't reschedule if already done today (unless forced)
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastScheduled = prefs.getString(_kPrayerScheduleDateKey);
      debugPrint('🕌 [PrayerNotif] lastScheduled=$lastScheduled');
      if (lastScheduled == todayStr) {
        debugPrint('🕌 [PrayerNotif] ⏭ SKIPPING — already scheduled today');
        return;
      }
    }

    try {
      // 1. Compute today's prayer times
      final coords = await PrayerConfig.getCoordinates();
      debugPrint('🕌 [PrayerNotif] coords=(${coords.latitude}, ${coords.longitude})');
      final params = PrayerConfig.params;
      final prayerTimes = PrayerTimes.today(coords, params);

      final prayers = <Prayer, DateTime>{
        Prayer.fajr: prayerTimes.fajr,
        Prayer.dhuhr: prayerTimes.dhuhr,
        Prayer.asr: prayerTimes.asr,
        Prayer.maghrib: prayerTimes.maghrib,
        Prayer.isha: prayerTimes.isha,
      };

      debugPrint('🕌 [PrayerNotif] Prayer times for today:');
      for (final e in prayers.entries) {
        debugPrint('   ${_prayerNames[e.key]}: ${e.value}');
      }

      // 2. Cancel all existing prayer_channel notifications
      await AwesomeNotifications().cancelNotificationsByChannelKey(
        AppConstants.notificationChannelPrayer,
      );
      debugPrint('🕌 [PrayerNotif] Cancelled old prayer_channel notifications');

      // 3. Schedule 2 notifications per prayer (10 total)
      var index = 0;
      var scheduledCount = 0;
      var skippedCount = 0;
      for (final entry in prayers.entries) {
        final prayer = entry.key;
        final time = entry.value;
        final name = _prayerNames[prayer] ?? '';

        // ── 10 minutes before ──────────────────────────────────
        final beforeTime = time.subtract(const Duration(minutes: 10));
        final beforeId = _prayerNotifBaseId + (index * 2);
        if (beforeTime.isAfter(now)) {
          debugPrint('🕌 [PrayerNotif] 📋 Scheduling BEFORE-$name (id=$beforeId) at $beforeTime');
          try {
            final result = await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: beforeId,
                channelKey: AppConstants.notificationChannelPrayer,
                title: '⏳ اقتربت صلاة $name',
                body: 'باقي 10 دقائق على موعد أذان $name — استعد للصلاة',
                notificationLayout: NotificationLayout.BigText,
                category: NotificationCategory.Reminder,
                largeIcon: 'resource://mipmap/ic_launcher',
                roundedLargeIcon: true,
                color: AppColors.accent,
                wakeUpScreen: true,
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
                repeats: false,
                allowWhileIdle: true,
                preciseAlarm: true,
              ),
            );
            debugPrint('🕌 [PrayerNotif] ✅ BEFORE-$name result=$result');
            scheduledCount++;
          } catch (e) {
            debugPrint('🕌 [PrayerNotif] ❌ BEFORE-$name ERROR: $e');
          }
        } else {
          debugPrint('🕌 [PrayerNotif] ⏭ SKIP BEFORE-$name — already past ($beforeTime <= $now)');
          skippedCount++;
        }

        // ── At prayer time (Athan) ─────────────────────────────
        final atId = _prayerNotifBaseId + (index * 2) + 1;
        if (time.isAfter(now)) {
          debugPrint('🕌 [PrayerNotif] 📋 Scheduling AT-$name (id=$atId) at $time');
          try {
            final result = await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: atId,
                channelKey: AppConstants.notificationChannelPrayer,
                title: '🕌 حان وقت صلاة $name',
                body: 'الله أكبر، حان الآن موعد أذان $name — أقم الصلاة يرحمك الله',
                notificationLayout: NotificationLayout.BigText,
                category: NotificationCategory.Alarm,
                criticalAlert: true,
                largeIcon: 'resource://mipmap/ic_launcher',
                roundedLargeIcon: true,
                color: AppColors.gold,
                wakeUpScreen: true,
              ),
              actionButtons: [
                NotificationActionButton(
                  key: 'DISMISS',
                  label: 'تم',
                  actionType: ActionType.DismissAction,
                ),
              ],
              schedule: NotificationCalendar(
                year: time.year,
                month: time.month,
                day: time.day,
                hour: time.hour,
                minute: time.minute,
                second: 0,
                millisecond: 0,
                repeats: false,
                allowWhileIdle: true,
                preciseAlarm: true,
              ),
            );
            debugPrint('🕌 [PrayerNotif] ✅ AT-$name result=$result');
            scheduledCount++;
          } catch (e) {
            debugPrint('🕌 [PrayerNotif] ❌ AT-$name ERROR: $e');
          }
        } else {
          debugPrint('🕌 [PrayerNotif] ⏭ SKIP AT-$name — already past ($time <= $now)');
          skippedCount++;
        }

        index++;
      }

      // 4. Mark today as scheduled
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrayerScheduleDateKey, todayStr);

      debugPrint('🕌 [PrayerNotif] ✅ DONE — scheduled=$scheduledCount, skipped=$skippedCount');

      // 5. Verify: list all pending scheduled notifications
      try {
        final pending = await AwesomeNotifications().listScheduledNotifications();
        debugPrint('🕌 [PrayerNotif] 📊 Total pending scheduled notifications: ${pending.length}');
        for (final n in pending) {
          debugPrint('   id=${n.content?.id}, title=${n.content?.title}, schedule=${n.schedule}');
        }
      } catch (e) {
        debugPrint('🕌 [PrayerNotif] listScheduledNotifications ERROR: $e');
      }
    } catch (e, st) {
      debugPrint('🕌 [PrayerNotif] ❌ FATAL ERROR: $e');
      debugPrint('🕌 [PrayerNotif] StackTrace: $st');
    }
  }

  // ── DEBUG: Test Notification ────────────────────────────────────────

  /// Fires a single test notification immediately + one scheduled 30s from now.
  /// Call via: NotificationEngine.instance.debugFireTestNotification()
  Future<void> debugFireTestNotification() async {
    debugPrint('🧪 [DEBUG] debugFireTestNotification() CALLED');
    final now = DateTime.now();
    final fireAt = now.add(const Duration(seconds: 30));
    debugPrint('🧪 [DEBUG] now=$now, will fire scheduled at=$fireAt');

    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('🧪 [DEBUG] isNotificationAllowed=$isAllowed');

      if (!isAllowed) {
        debugPrint('🧪 [DEBUG] ⚠️ Notifications not allowed — aborting test notification.');
        return;
      }

      // Fire immediately (no schedule) to test basic delivery
      debugPrint('🧪 [DEBUG] Firing IMMEDIATE test notification (id=99999)...');
      final immediateResult = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 99999,
          channelKey: AppConstants.notificationChannelPrayer,
          title: '🧪 اختبار فوري',
          body: 'هذا إشعار تجريبي فوري — لو ظهر يبقى القناة شغالة',
          notificationLayout: NotificationLayout.Default,
        ),
      );
      debugPrint('🧪 [DEBUG] Immediate result=$immediateResult');

      // Also fire a scheduled one in 30 seconds
      debugPrint('🧪 [DEBUG] Scheduling test notification (id=99998) for 30s from now...');
      final scheduledResult = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 99998,
          channelKey: AppConstants.notificationChannelPrayer,
          title: '🧪 اختبار مجدول',
          body: 'هذا إشعار تجريبي بعد 30 ثانية — لو ظهر يبقى الجدولة شغالة',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          year: fireAt.year,
          month: fireAt.month,
          day: fireAt.day,
          hour: fireAt.hour,
          minute: fireAt.minute,
          second: fireAt.second,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      debugPrint('🧪 [DEBUG] Scheduled result=$scheduledResult');

      // List all pending
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
}
