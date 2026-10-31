import 'package:flutter/material.dart';

class CustomNotification {
  final String id;
  final String title;
  final String body;
  final TimeOfDay time;
  final List<String> days;
  final bool enabled;
  final int? repeatIntervalHours; // e.g. null for once daily at [time], or 1, 2, 3, 4, 6

  CustomNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.days,
    this.enabled = true,
    this.repeatIntervalHours,
  });

  CustomNotification copyWith({
    String? id,
    String? title,
    String? body,
    TimeOfDay? time,
    List<String>? days,
    bool? enabled,
    int? repeatIntervalHours,
  }) {
    return CustomNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      repeatIntervalHours: repeatIntervalHours ?? this.repeatIntervalHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'hour': time.hour,
      'minute': time.minute,
      'days': days,
      'enabled': enabled,
      'repeatIntervalHours': repeatIntervalHours,
    };
  }

  factory CustomNotification.fromJson(Map<String, dynamic> json) {
    return CustomNotification(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? '🤍 ذكر لطيف ليومك',
      body: json['body'] as String? ?? json['zekr'] as String? ?? '',
      time: TimeOfDay(
        hour: (json['hour'] as num?)?.toInt() ?? 8,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
      ),
      days: List<String>.from(json['days'] as List? ?? []),
      enabled: json['enabled'] as bool? ?? true,
      repeatIntervalHours: (json['repeatIntervalHours'] as num?)?.toInt(),
    );
  }
}
