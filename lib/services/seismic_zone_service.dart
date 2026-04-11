import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class SeismicZone {
  final String name;
  final Color color;
  final List<List<LatLng>> polygons;

  SeismicZone(this.name, this.color, this.polygons);
}

class SeismicZonePoint {
  final LatLng point;
  final String zoneName;
  final int zoneValue;

  SeismicZonePoint(this.point, this.zoneName, this.zoneValue);
}

// Wrapper to pass data back from the background Isolate
class _ParsedZoneData {
  final List<SeismicZone> zones;
  final List<SeismicZonePoint> lookupPoints;
  _ParsedZoneData(this.zones, this.lookupPoints);
}

class SeismicZoneService {
  static List<SeismicZonePoint> _zonePoints = [];

  static Future<List<SeismicZone>> loadZones() async {
    try {
      // 1. Load the text string on the main thread (rootBundle isn't available in Isolates)
      final String csvString = await rootBundle.loadString('assets/ZoneTable.csv');

      // 2. Fire up a SEPARATE INSTANCE (Isolate) to do the heavy math and parsing
      final parsedData = await Isolate.run(() => _parseZonesInBackground(csvString));

      // 3. Save the fast-lookup points to the main memory and return the zones
      _zonePoints = parsedData.lookupPoints;
      
      debugPrint("✅ Seismic Zones parsed in background isolate successfully.");
      return parsedData.zones;

    } catch (e) {
      debugPrint("🚨 ERROR: Failed to load ZoneTable.csv: $e");
      return [];
    }
  }

  // --- BACKGROUND THREAD LOGIC ---
  static _ParsedZoneData _parseZonesInBackground(String csvString) {
    final Map<String, Color> zoneColors = {
      // Increased opacity across the board to compensate for the missing borders
      "Zone II": const Color(0x80FFFF00),       // Yellow with 50% opacity (was 30%)
      "Zone III": const Color(0x8CFFAB40),      // OrangeAccent with 55% opacity (was 35%)
      "Zone IV": const Color(0x99FF5722),       // DeepOrange with 60% opacity (was 40%)
      "Zone V": const Color(0xA6F44336),        // Red with 65% opacity (was 45%)
      "Zone VI": const Color(0xA69C27B0),       // Purple with 65% opacity
    };

    final Map<String, List<List<LatLng>>> zonePolygons = {
      "Zone II": [], "Zone III": [], "Zone IV": [], "Zone V": [], "Zone VI": [],
    };

    List<SeismicZonePoint> isolatedZonePoints = [];
    final List<String> lines = const LineSplitter().convert(csvString);

    bool isHeader = true;
    for (String line in lines) {
      if (isHeader) { isHeader = false; continue; }
      if (line.trim().isEmpty) continue;

      List<String> parts = line.split(',');
      if (parts.length >= 4) {
        double lon = double.parse(parts[0]);
        double lat = double.parse(parts[1]);
        String zoneRoman = parts[2].trim();
        int zoneValue = int.tryParse(parts[3]) ?? 2;

        String fullZoneName = "Zone $zoneRoman";
        isolatedZonePoints.add(SeismicZonePoint(LatLng(lat, lon), fullZoneName, zoneValue));

        // 2% overlap to prevent visual gaps without needing heavy borders
        double halfStep = 0.052; 
        List<LatLng> square = [
          LatLng(lat - halfStep, lon - halfStep),
          LatLng(lat + halfStep, lon - halfStep),
          LatLng(lat + halfStep, lon + halfStep),
          LatLng(lat - halfStep, lon + halfStep),
        ];

        if (zonePolygons.containsKey(fullZoneName)) {
          zonePolygons[fullZoneName]!.add(square);
        }
      }
    }

    List<SeismicZone> loadedZones = [];
    zonePolygons.forEach((key, value) {
      if (value.isNotEmpty) {
        loadedZones.add(SeismicZone(key, zoneColors[key] ?? const Color(0x4D9E9E9E), value));
      }
    });

    return _ParsedZoneData(loadedZones, isolatedZonePoints);
  }

  // Fast grid lookup for the UI tap
  static String getNearestZone(LatLng point) {
    if (_zonePoints.isEmpty) return "Zone II (IS 1893)";

    double minDistance = double.infinity;
    String nearestZone = "Zone II (IS 1893)";

    for (var zp in _zonePoints) {
      double dLat = zp.point.latitude - point.latitude;
      double dLon = zp.point.longitude - point.longitude;
      double distSq = (dLat * dLat) + (dLon * dLon);

      if (distSq < minDistance) {
        minDistance = distSq;
        nearestZone = zp.zoneName;
      }
    }
    return nearestZone;
  }
}