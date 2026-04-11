import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

class SoilService {
  // Stores [latitude, longitude, soilMark]
  static final List<List<double>> _soilData = [];

  static Future<void> loadSoilData() async {
    try {
      final data = await rootBundle.loadString('assets/SoilData.csv');
      final lines = data.split('\n');
      
      // Start at i = 1 to skip the header row (Long,Lat,SoilMark)
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final parts = lines[i].split(',');
        if (parts.length >= 3) {
          double? lng = double.tryParse(parts[0]);
          double? lat = double.tryParse(parts[1]);
          double? mark = double.tryParse(parts[2]);
          
          if (lng != null && lat != null && mark != null) {
            _soilData.add([lat, lng, mark]);
          }
        }
      }
    } catch (e) {
      print("Error loading soil data: $e");
    }
  }

  /// Finds the closest coordinate in the CSV and returns its SoilMark
  static double getNearestSoilMark(LatLng point) {
    if (_soilData.isEmpty) return 1.0; // Default fallback

    double minDistance = double.infinity;
    double nearestMark = 1.0;

    for (var row in _soilData) {
      // Simple Pythagorean distance is fast enough for this grid matching
      double dLat = row[0] - point.latitude;
      double dLng = row[1] - point.longitude;
      double distSq = (dLat * dLat) + (dLng * dLng);
      
      if (distSq < minDistance) {
        minDistance = distSq;
        nearestMark = row[2];
      }
    }
    return nearestMark;
  }
}