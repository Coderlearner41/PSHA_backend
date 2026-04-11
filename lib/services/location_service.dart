import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<LatLng?> getUserLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return null;

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      Position position =
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

      return LatLng(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}