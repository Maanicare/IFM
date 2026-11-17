import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` for the one place this app needs a
/// device location: technician check-in (Section 11). Returns null on
/// any failure (permission denied, service disabled, timeout) rather
/// than throwing - the caller treats "no location" as "fall back to
/// manual override with reason", not as an app error.
class DeviceLocationService {
  const DeviceLocationService._();

  static Future<({double latitude, double longitude})?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
