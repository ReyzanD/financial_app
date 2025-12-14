import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:financial_app/services/logger_service.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      LoggerService.error('Error getting current position', error: e);
      return null;
    }
  }

  // Helper method for backward compatibility
  static Future<Position?> getCurrentLatLng() async {
    return await getCurrentPosition();
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static String getAddressFromCoordinates(double lat, double lng) {
    // Note: Reverse geocoding requires additional setup
    // For now, return coordinates as string
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
}
