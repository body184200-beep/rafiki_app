import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:rafiki_app/features/notification/data/models/notification_model.dart';
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
    AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelKey: AppConstants.notificationChannelAzkar,
          channelName: 'Azkar Notifications',
          channelDescription: 'Notifications for daily Azkar',
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: AppConstants.notificationChannelPrayer,
          channelName: 'Prayer Notifications',
          channelDescription: 'Notifications for prayer times',
          importance: NotificationImportance.High,
        )
      ],
    );

    // 4. Ensure permissions and resync schedules (important for reboot recovery)
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (allowed) {
      await syncSchedules();
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

  // ── Persistence & Scheduling ──────────────────────────────────────────

  Future<bool> checkAndRequestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      final requested = await AwesomeNotifications().requestPermissionToSendNotifications();
      if (requested) {
        await syncSchedules();
      }
      return requested;
    }
    return true;
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
}
