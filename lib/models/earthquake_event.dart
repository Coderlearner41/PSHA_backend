import 'package:latlong2/latlong.dart';

class EarthquakeEvent {
  final LatLng location;
  final double magnitude;
  final String date; // Added date field

  // Date is optional and defaults to "Unknown" so it doesn't break your existing parsing logic
  EarthquakeEvent(this.location, this.magnitude, {this.date = "Unknown Date"});

  // Getters to easily access coordinates for the popup
  double get latitude => location.latitude;
  double get longitude => location.longitude;
}