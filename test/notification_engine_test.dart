import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiki_app/features/notification/data/services/notification_engine.dart';
import 'package:rafiki_app/features/notification/data/models/notification_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationEngine.instance.notifications.value = [];
  });

  group('NotificationEngine Tests', () {
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

      // Add duplicate time
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
