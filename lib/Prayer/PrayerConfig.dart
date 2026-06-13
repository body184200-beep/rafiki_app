import 'package:adhan/adhan.dart';

/// إحداثيات وطريقة الحساب المستخدمة في كل التطبيق
/// (دمياط - نفس المدينة المستخدمة في Aladhan API للعرض)
class PrayerConfig {
  static final Coordinates coordinates = Coordinates(31.4165, 31.8133);

  static CalculationParameters get params =>
      CalculationMethod.egyptian.getParameters();

  /// اسم المدينة المستخدم في Aladhan API (للعرض فقط)
  static const String apiCity = 'Damietta';
  static const String apiCountry = 'Egypt';
  static const int apiMethod = 5;
}