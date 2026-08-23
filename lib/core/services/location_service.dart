import 'package:geolocator/geolocator.dart';

import 'package:rafiki_app/core/logging/app_logger.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Wraps Geolocator so UI/controllers never talk to the plugin directly.
class LocationService {
  Future<GeoPoint?> current({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (e, st) {
      AppLogger.debug('Location unavailable: $e', tag: 'Location');
      AppLogger.debug('$st', tag: 'Location');
      return null;
    }
  }

  double distanceMeters(GeoPoint a, GeoPoint b) => Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
}
