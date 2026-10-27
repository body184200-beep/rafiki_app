import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';

/// رسائل التحديث المخصصة لتطبيق رفيقي باللغة العربية.
class RafikiUpgraderMessages extends UpgraderMessages {
  RafikiUpgraderMessages({super.code = 'ar'});

  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.title:
        return 'تحديث جديد متاح';
      case UpgraderMessage.body:
        return 'يتوفر إصدار أحدث من تطبيق رفيقي، يُرجى التحديث للحصول على أحدث التحسينات والميزات.';
      case UpgraderMessage.prompt:
        return '';
      case UpgraderMessage.buttonTitleUpdate:
        return 'تحديث الآن';
      case UpgraderMessage.buttonTitleLater:
        return 'لاحقًا';
      case UpgraderMessage.buttonTitleIgnore:
        return 'تجاهل';
      case UpgraderMessage.releaseNotes:
        return 'سجل التغييرات';
    }
  }
}

/// خدمة فحص تحديثات تطبيق رفيقي عبر متجر Google Play.
class AppUpgraderService {
  AppUpgraderService._();

  /// نسخة مهيأة مسبقاً من [Upgrader] مع الرسائل العربية وإعدادات عدم الإزعاج.
  static final Upgrader instance = Upgrader(
    messages: RafikiUpgraderMessages(),
    checkOnResume: false,
    durationUntilAlertAgain: const Duration(days: 3),
    debugLogging: kDebugMode,
  );
}
