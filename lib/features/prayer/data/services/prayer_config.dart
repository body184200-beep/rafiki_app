import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إحداثيات وطريقة الحساب المستخدمة في كل التطبيق
class PrayerConfig {
  // الإحداثيات الافتراضية (دمياط - مصر)
  static const double defaultLatitude = 31.4165;
  static const double defaultLongitude = 31.8133;

  static CalculationParameters get params =>
      CalculationMethod.egyptian.getParameters();

  static Future<Coordinates> getCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('prayer_lat') ?? defaultLatitude;
      final lng = prefs.getDouble('prayer_lng') ?? defaultLongitude;
      return Coordinates(lat, lng);
    } catch (_) {
      return Coordinates(defaultLatitude, defaultLongitude);
    }
  }

  static Future<void> saveCoordinates(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prayer_lat', lat);
      await prefs.setDouble('prayer_lng', lng);
    } catch (_) {}
  }
}