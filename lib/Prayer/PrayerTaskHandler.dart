import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';

import 'PrayerConfig.dart';


class PrayerTaskHandler extends TaskHandler {
  Timer? timer;

  // نخزن آخر صلاة + تاريخها عشان نتجنب تكرار التنبيه ونتعامل مع تغيير اليوم
  Prayer? lastAlertPrayer;
  DateTime? lastAlertDay;

  Prayer? lastPrayerNow;
  DateTime? lastPrayerNowDay;

  final AudioPlayer player = AudioPlayer();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkPrayer();
    });
    // فحص فوري عند البدء بدون انتظار أول 30 ثانية
    checkPrayer();
  }

  void checkPrayer() {
    final coordinates = PrayerConfig.coordinates;
    final params = PrayerConfig.params;

    final times = PrayerTimes.today(coordinates, params);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<Prayer, DateTime> prayers = {
      Prayer.fajr: times.fajr,
      Prayer.dhuhr: times.dhuhr,
      Prayer.asr: times.asr,
      Prayer.maghrib: times.maghrib,
      Prayer.isha: times.isha,
    };

    prayers.forEach((prayer, time) async {
      final diff = time.difference(now);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds;

      // 🔔 قبل الصلاة بـ 10 دقائق (نطاق 9:31 - 10:00 دقيقة قبل الموعد)
      final isTenMinutesBefore = seconds > 0 && seconds <= 600 && seconds > 570;

      if (isTenMinutesBefore) {
        final alreadyAlerted =
            lastAlertPrayer == prayer && lastAlertDay == today;
        if (!alreadyAlerted) {
          lastAlertPrayer = prayer;
          lastAlertDay = today;

          final name = _getName(prayer);

          FlutterForegroundTask.updateService(
            notificationTitle: "⏳ قرب أذان $name",
            notificationText: "باقي 10 دقائق على صلاة $name",
          );

          try {
            await player.play(AssetSource('adhan.mp3'));
          } catch (_) {}
        }
      }

      // 🕌 وقت الصلاة (نطاق ±30 ثانية حول الموعد، ومش متأخر كتير)
      final isPrayerTimeNow = seconds.abs() < 30;

      if (isPrayerTimeNow) {
        final alreadyNotified =
            lastPrayerNow == prayer && lastPrayerNowDay == today;
        if (!alreadyNotified) {
          lastPrayerNow = prayer;
          lastPrayerNowDay = today;

          final name = _getName(prayer);

          FlutterForegroundTask.updateService(
            notificationTitle: "🕌 حان وقت الصلاة",
            notificationText: "موعد صلاة $name الآن",
          );

          try {
            await player.play(AssetSource('adhan.mp3'));
          } catch (_) {}
        }
      }
    });
  }

  String _getName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return "الفجر";
      case Prayer.dhuhr:
        return "الظهر";
      case Prayer.asr:
        return "العصر";
      case Prayer.maghrib:
        return "المغرب";
      case Prayer.isha:
        return "العشاء";
      case Prayer.none:
      case Prayer.sunrise:
        return "";
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) {
    timer?.cancel();
    player.stop();
    player.dispose();
    return Future.value();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}
}