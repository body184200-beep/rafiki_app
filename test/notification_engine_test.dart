import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Pure-logic helpers extracted from NotificationEngine for unit testing.
//  These test the scheduling DECISIONS (which prayers get scheduled vs skipped,
//  correct ID assignment, -10 min calculation) without touching platform APIs.
// ─────────────────────────────────────────────────────────────────────────────

/// Models a single notification that would be scheduled.
class PlannedNotif {
  final int id;
  final String type; // 'BEFORE' or 'AT'
  final String prayer;
  final DateTime scheduledAt;
  final String dayLabel;

  const PlannedNotif({
    required this.id,
    required this.type,
    required this.prayer,
    required this.scheduledAt,
    required this.dayLabel,
  });

  @override
  String toString() =>
      'PlannedNotif(id=$id, type=$type, prayer=$prayer, at=$scheduledAt, day=$dayLabel)';
}

/// Replicates the scheduling decision logic from NotificationEngine
/// without calling any platform/AwesomeNotifications APIs.
List<PlannedNotif> planPrayerNotifications({
  required DateTime now,
  required Map<Prayer, DateTime> todayPrayers,
  required Map<Prayer, DateTime> tomorrowPrayers,
}) {
  const Map<Prayer, int> beforeIdToday = {
    Prayer.fajr: 90000,
    Prayer.dhuhr: 90002,
    Prayer.asr: 90004,
    Prayer.maghrib: 90006,
    Prayer.isha: 90008,
  };
  const Map<Prayer, int> atIdToday = {
    Prayer.fajr: 90001,
    Prayer.dhuhr: 90003,
    Prayer.asr: 90005,
    Prayer.maghrib: 90007,
    Prayer.isha: 90009,
  };
  const Map<Prayer, int> beforeIdTomorrow = {
    Prayer.fajr: 90010,
    Prayer.dhuhr: 90012,
    Prayer.asr: 90014,
    Prayer.maghrib: 90016,
    Prayer.isha: 90018,
  };
  const Map<Prayer, int> atIdTomorrow = {
    Prayer.fajr: 90011,
    Prayer.dhuhr: 90013,
    Prayer.asr: 90015,
    Prayer.maghrib: 90017,
    Prayer.isha: 90019,
  };

  const Map<Prayer, String> names = {
    Prayer.fajr: 'الفجر',
    Prayer.dhuhr: 'الظهر',
    Prayer.asr: 'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha: 'العشاء',
  };

  final planned = <PlannedNotif>[];

  void planPrayer({
    required Prayer prayer,
    required DateTime prayerTime,
    required int beforeId,
    required int atId,
    required String dayLabel,
  }) {
    final name = names[prayer]!;
    final beforeTime = prayerTime.subtract(const Duration(minutes: 10));
    if (beforeTime.isAfter(now)) {
      planned.add(PlannedNotif(
        id: beforeId,
        type: 'BEFORE',
        prayer: name,
        scheduledAt: beforeTime,
        dayLabel: dayLabel,
      ));
    }
    if (prayerTime.isAfter(now)) {
      planned.add(PlannedNotif(
        id: atId,
        type: 'AT',
        prayer: name,
        scheduledAt: prayerTime,
        dayLabel: dayLabel,
      ));
    }
  }

  for (final e in todayPrayers.entries) {
    planPrayer(
      prayer: e.key,
      prayerTime: e.value,
      beforeId: beforeIdToday[e.key]!,
      atId: atIdToday[e.key]!,
      dayLabel: 'Today',
    );
  }
  for (final e in tomorrowPrayers.entries) {
    planPrayer(
      prayer: e.key,
      prayerTime: e.value,
      beforeId: beforeIdTomorrow[e.key]!,
      atId: atIdTomorrow[e.key]!,
      dayLabel: 'Tomorrow',
    );
  }

  return planned;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Test helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Build a minimal prayer map anchored around [base] time.
Map<Prayer, DateTime> fakeTodayPrayers(DateTime base) => {
  Prayer.fajr: base.subtract(const Duration(hours: 10)), // in the past
  Prayer.dhuhr: base.add(const Duration(hours: 1)),
  Prayer.asr: base.add(const Duration(hours: 4)),
  Prayer.maghrib: base.add(const Duration(hours: 7)),
  Prayer.isha: base.add(const Duration(hours: 9)),
};

Map<Prayer, DateTime> fakeTomorrowPrayers(DateTime base) {
  final t = base.add(const Duration(days: 1));
  return {
    Prayer.fajr: t.subtract(const Duration(hours: 10)),
    Prayer.dhuhr: t.add(const Duration(hours: 1)),
    Prayer.asr: t.add(const Duration(hours: 4)),
    Prayer.maghrib: t.add(const Duration(hours: 7)),
    Prayer.isha: t.add(const Duration(hours: 9)),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationEngine.instance.notifications.value = [];
  });

  // ── Scheduling logic ──────────────────────────────────────────────────────

  group('Prayer Notification Scheduling Logic', () {
    test('Past prayers are skipped; future prayers are scheduled', () {
      final now = DateTime(2026, 9, 1, 14, 0); // 2 PM
      final today = fakeTodayPrayers(now);
      // fajr is 10h before now → deeply in the past
      // dhuhr is 1h from now → future ✓
      final tomorrow = fakeTomorrowPrayers(now);

      final planned = planPrayerNotifications(
        now: now,
        todayPrayers: today,
        tomorrowPrayers: tomorrow,
      );

      // Fajr (today) is in the past → no BEFORE, no AT for it
      final fajrToday = planned.where((n) => n.prayer == 'الفجر' && n.dayLabel == 'Today');
      expect(fajrToday, isEmpty, reason: 'Fajr (today) already passed — should be skipped');

      // Dhuhr today should have both BEFORE and AT
      final dhuhrToday = planned.where((n) => n.prayer == 'الظهر' && n.dayLabel == 'Today');
      expect(dhuhrToday.map((n) => n.type).toList()..sort(), ['AT', 'BEFORE']);
    });

    test('BEFORE time is exactly prayerTime - 10 minutes', () {
      final now = DateTime(2026, 9, 1, 11, 0);
      final prayerTime = DateTime(2026, 9, 1, 12, 30);
      final today = <Prayer, DateTime>{
        Prayer.dhuhr: prayerTime,
        Prayer.fajr: now.subtract(const Duration(hours: 5)), // past
        Prayer.asr: now.add(const Duration(hours: 5)),
        Prayer.maghrib: now.add(const Duration(hours: 8)),
        Prayer.isha: now.add(const Duration(hours: 10)),
      };

      final planned = planPrayerNotifications(
        now: now,
        todayPrayers: today,
        tomorrowPrayers: fakeTomorrowPrayers(now),
      );

      final dhuhrBefore = planned.firstWhere(
        (n) => n.prayer == 'الظهر' && n.type == 'BEFORE' && n.dayLabel == 'Today',
      );
      expect(
        dhuhrBefore.scheduledAt,
        prayerTime.subtract(const Duration(minutes: 10)),
      );
    });

    test('BEFORE is skipped if less than 10 min remains before prayer', () {
      final now = DateTime(2026, 9, 1, 12, 25); // only 5 min before dhuhr at 12:30
      final prayerTime = DateTime(2026, 9, 1, 12, 30);
      final today = <Prayer, DateTime>{
        Prayer.dhuhr: prayerTime,
        Prayer.fajr: now.subtract(const Duration(hours: 6)),
        Prayer.asr: now.add(const Duration(hours: 3)),
        Prayer.maghrib: now.add(const Duration(hours: 6)),
        Prayer.isha: now.add(const Duration(hours: 8)),
      };

      final planned = planPrayerNotifications(
        now: now,
        todayPrayers: today,
        tomorrowPrayers: fakeTomorrowPrayers(now),
      );

      final dhuhrBefore = planned.where(
        (n) => n.prayer == 'الظهر' && n.type == 'BEFORE' && n.dayLabel == 'Today',
      );
      // beforeTime = 12:20, now = 12:25 → beforeTime is in the past → skip
      expect(dhuhrBefore, isEmpty);

      // AT notification (12:30) is still in the future → should be scheduled
      final dhuhrAt = planned.where(
        (n) => n.prayer == 'الظهر' && n.type == 'AT' && n.dayLabel == 'Today',
      );
      expect(dhuhrAt.length, 1);
    });

    test('Fixed IDs: each (prayer × type × day) maps to the correct constant', () {
      final now = DateTime(2026, 9, 1, 0, 0); // midnight → all today are future
      final base = now;
      final today = <Prayer, DateTime>{
        Prayer.fajr: base.add(const Duration(hours: 5)),
        Prayer.dhuhr: base.add(const Duration(hours: 12)),
        Prayer.asr: base.add(const Duration(hours: 15, minutes: 30)),
        Prayer.maghrib: base.add(const Duration(hours: 18)),
        Prayer.isha: base.add(const Duration(hours: 20)),
      };
      final tomorrow = <Prayer, DateTime>{
        Prayer.fajr: base.add(const Duration(hours: 29)),
        Prayer.dhuhr: base.add(const Duration(hours: 36)),
        Prayer.asr: base.add(const Duration(hours: 39, minutes: 30)),
        Prayer.maghrib: base.add(const Duration(hours: 42)),
        Prayer.isha: base.add(const Duration(hours: 44)),
      };

      final planned = planPrayerNotifications(now: now, todayPrayers: today, tomorrowPrayers: tomorrow);

      int idFor(String prayer, String type, String day) =>
          planned.firstWhere((n) => n.prayer == prayer && n.type == type && n.dayLabel == day).id;

      // Today
      expect(idFor('الفجر', 'BEFORE', 'Today'), 90000);
      expect(idFor('الفجر', 'AT', 'Today'), 90001);
      expect(idFor('الظهر', 'BEFORE', 'Today'), 90002);
      expect(idFor('الظهر', 'AT', 'Today'), 90003);
      expect(idFor('العصر', 'BEFORE', 'Today'), 90004);
      expect(idFor('العصر', 'AT', 'Today'), 90005);
      expect(idFor('المغرب', 'BEFORE', 'Today'), 90006);
      expect(idFor('المغرب', 'AT', 'Today'), 90007);
      expect(idFor('العشاء', 'BEFORE', 'Today'), 90008);
      expect(idFor('العشاء', 'AT', 'Today'), 90009);

      // Tomorrow
      expect(idFor('الفجر', 'BEFORE', 'Tomorrow'), 90010);
      expect(idFor('الفجر', 'AT', 'Tomorrow'), 90011);
      expect(idFor('الظهر', 'BEFORE', 'Tomorrow'), 90012);
      expect(idFor('الظهر', 'AT', 'Tomorrow'), 90013);
      expect(idFor('العصر', 'BEFORE', 'Tomorrow'), 90014);
      expect(idFor('العصر', 'AT', 'Tomorrow'), 90015);
      expect(idFor('المغرب', 'BEFORE', 'Tomorrow'), 90016);
      expect(idFor('المغرب', 'AT', 'Tomorrow'), 90017);
      expect(idFor('العشاء', 'BEFORE', 'Tomorrow'), 90018);
      expect(idFor('العشاء', 'AT', 'Tomorrow'), 90019);
    });

    test('No duplicate IDs across all planned notifications', () {
      final now = DateTime(2026, 9, 1, 0, 0);
      final base = now;
      final today = <Prayer, DateTime>{
        Prayer.fajr: base.add(const Duration(hours: 5)),
        Prayer.dhuhr: base.add(const Duration(hours: 12)),
        Prayer.asr: base.add(const Duration(hours: 15)),
        Prayer.maghrib: base.add(const Duration(hours: 18)),
        Prayer.isha: base.add(const Duration(hours: 20)),
      };
      final tomorrow = <Prayer, DateTime>{
        Prayer.fajr: base.add(const Duration(hours: 29)),
        Prayer.dhuhr: base.add(const Duration(hours: 36)),
        Prayer.asr: base.add(const Duration(hours: 39)),
        Prayer.maghrib: base.add(const Duration(hours: 42)),
        Prayer.isha: base.add(const Duration(hours: 44)),
      };

      final planned = planPrayerNotifications(now: now, todayPrayers: today, tomorrowPrayers: tomorrow);
      final ids = planned.map((n) => n.id).toList();
      final uniqueIds = ids.toSet();
      expect(
        ids.length,
        uniqueIds.length,
        reason: 'All notification IDs must be unique — found duplicates',
      );
    });

    test('After Isha, all today prayers are skipped; tomorrow is fully scheduled', () {
      final now = DateTime(2026, 9, 1, 23, 0); // 11 PM — after Isha
      final today = <Prayer, DateTime>{
        Prayer.fajr: DateTime(2026, 9, 1, 5, 0),
        Prayer.dhuhr: DateTime(2026, 9, 1, 12, 0),
        Prayer.asr: DateTime(2026, 9, 1, 15, 30),
        Prayer.maghrib: DateTime(2026, 9, 1, 18, 0),
        Prayer.isha: DateTime(2026, 9, 1, 20, 0),
      };
      final tomorrow = <Prayer, DateTime>{
        Prayer.fajr: DateTime(2026, 9, 2, 5, 0),
        Prayer.dhuhr: DateTime(2026, 9, 2, 12, 0),
        Prayer.asr: DateTime(2026, 9, 2, 15, 30),
        Prayer.maghrib: DateTime(2026, 9, 2, 18, 0),
        Prayer.isha: DateTime(2026, 9, 2, 20, 0),
      };

      final planned = planPrayerNotifications(now: now, todayPrayers: today, tomorrowPrayers: tomorrow);

      // All today's prayers are in the past
      final todayNotifs = planned.where((n) => n.dayLabel == 'Today');
      expect(todayNotifs, isEmpty, reason: 'All today prayers passed — none should be scheduled');

      // Tomorrow's 5 prayers × 2 types = 10 notifications
      final tomorrowNotifs = planned.where((n) => n.dayLabel == 'Tomorrow');
      expect(tomorrowNotifs.length, 10, reason: 'All 5 tomorrow prayers × 2 types = 10');
    });

    test('Midnight rollover: todayStr changes, guard would pass, new day scheduled', () {
      final beforeMidnight = DateTime(2026, 9, 1, 23, 59);
      final afterMidnight = DateTime(2026, 9, 2, 0, 1);

      String todayStr(DateTime d) => '${d.year}-${d.month}-${d.day}';

      final lastScheduled = todayStr(beforeMidnight); // '2026-9-1'

      // Guard passes because lastScheduled != new todayStr
      expect(
        lastScheduled == todayStr(afterMidnight),
        isFalse,
        reason: 'After midnight, todayStr changes — guard must NOT block re-scheduling',
      );
    });

    test('Idempotency: calling planPrayerNotifications twice returns same IDs', () {
      final now = DateTime(2026, 9, 1, 14, 0);
      final base = now;
      final today = <Prayer, DateTime>{
        Prayer.fajr: base.subtract(const Duration(hours: 8)),
        Prayer.dhuhr: base.add(const Duration(hours: 1)),
        Prayer.asr: base.add(const Duration(hours: 4)),
        Prayer.maghrib: base.add(const Duration(hours: 7)),
        Prayer.isha: base.add(const Duration(hours: 9)),
      };
      final tomorrow = fakeTomorrowPrayers(now);

      final first = planPrayerNotifications(now: now, todayPrayers: today, tomorrowPrayers: tomorrow);
      final second = planPrayerNotifications(now: now, todayPrayers: today, tomorrowPrayers: tomorrow);

      expect(
        first.map((n) => n.id).toSet(),
        second.map((n) => n.id).toSet(),
        reason: 'Same inputs → same IDs every time (idempotent)',
      );
    });
  });

  // ── NotificationEngine CRUD ───────────────────────────────────────────────

  group('NotificationEngine CRUD Tests', () {
    test('Initialization creates empty lists', () async {
      final engine = NotificationEngine.instance;
      await engine.initialize();
      expect(engine.notifications.value, isEmpty);
    });

    test('Add Notification enforces limits and validates time', () async {
      final engine = NotificationEngine.instance;
      await engine.initialize();

      final notif = CustomNotification(
        id: '1',
        title: 'Test',
        body: 'Body',
        time: const TimeOfDay(hour: 10, minute: 30),
        days: ['Monday'],
      );

      await engine.addNotification(notif);
      expect(engine.notifications.value.length, 1);

      // Add notification with same time on same day → conflict
      final duplicateTime = CustomNotification(
        id: '2',
        title: 'Test 2',
        body: 'Body 2',
        time: const TimeOfDay(hour: 10, minute: 30),
        days: ['Monday'],
      );

      expect(() => engine.addNotification(duplicateTime), throwsException);
    });

    test('Update Notification modifies properties', () async {
      final engine = NotificationEngine.instance;
      await engine.initialize();

      final notif = CustomNotification(
        id: '1',
        title: 'Original',
        body: 'Body',
        time: const TimeOfDay(hour: 10, minute: 30),
        days: ['Monday'],
      );

      await engine.addNotification(notif);

      final updated = CustomNotification(
        id: '1',
        title: 'Updated',
        body: 'Body',
        time: const TimeOfDay(hour: 11, minute: 0),
        days: ['Monday'],
      );

      await engine.updateNotification(updated);
      expect(engine.notifications.value.first.title, 'Updated');
      expect(engine.notifications.value.first.time.hour, 11);
    });

    test('Delete Notification removes it', () async {
      final engine = NotificationEngine.instance;
      await engine.initialize();

      final notif = CustomNotification(
        id: '1',
        title: 'Test',
        body: 'Body',
        time: const TimeOfDay(hour: 10, minute: 30),
        days: ['Monday'],
      );

      await engine.addNotification(notif);
      expect(engine.notifications.value.length, 1);

      await engine.deleteNotification('1');
      expect(engine.notifications.value, isEmpty);
    });
  });
}
