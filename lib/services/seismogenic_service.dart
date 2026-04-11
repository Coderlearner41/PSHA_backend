import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shapefile/shapefile.dart';
import 'dart:math';

class SeismogenicService {
  static List<Map<String, dynamic>> _seismogenicFeatures = [];

  // Load Shapefile AND its associated DBF data
  static Future<List<Polyline>> loadSeismogenicLines() async {
    final ByteData shpBytes = await rootBundle.load('assets/Seismogenic_Map.shp');
    final ByteData dbfBytes = await rootBundle.load('assets/Seismogenic_Map.dbf'); 
    
    final shpStream = Stream.value(shpBytes.buffer.asUint8List());
    final dbfStream = Stream.value(dbfBytes.buffer.asUint8List());
    
    final parsedData = await featureCollection(shpStream, dbf: dbfStream);

    List<Polyline> lines = [];
    _seismogenicFeatures = [];

    if (parsedData['features'] != null) {
      for (var feature in parsedData['features']) {
        _seismogenicFeatures.add(feature);
        final geometry = feature['geometry'];
        final type = geometry['type'];
        final coords = geometry['coordinates'];

        if (type == 'LineString') {
          List<LatLng> points = (coords as List).map((c) => LatLng(c[1], c[0])).toList();
          lines.add(Polyline(points: points, color: Colors.blueAccent, strokeWidth: 2));
        } 
        else if (type == 'Polygon') {
          for (var ring in coords) {
            List<LatLng> points = (ring as List).map((c) => LatLng(c[1], c[0])).toList();
            lines.add(Polyline(points: points, color: Colors.blueAccent, strokeWidth: 2));
          }
        } 
        else if (type == 'MultiLineString') {
          for (var line in coords) {
            List<LatLng> points = (line as List).map((c) => LatLng(c[1], c[0])).toList();
            lines.add(Polyline(points: points, color: Colors.blueAccent, strokeWidth: 2));
          }
        } 
        else if (type == 'MultiPolygon') {
          for (var poly in coords) {
            for (var ring in poly) {
              List<LatLng> points = (ring as List).map((c) => LatLng(c[1], c[0])).toList();
              lines.add(Polyline(points: points, color: Colors.blueAccent, strokeWidth: 2));
            }
          }
        }
      }
    }
    return lines;
  }

  // Find the zone based on Point-In-Polygon or Nearest Line
  static String getZoneForLocation(LatLng point) {
    if (_seismogenicFeatures.isEmpty) {
      return "Data Loading...";
    }

    double minDistance = double.infinity;
    String? closestZone;

    for (var feature in _seismogenicFeatures) {
      final geometry = feature['geometry'];
      final properties = feature['properties'] ?? {};
      
      // Expanded checks for common DBF column names used by GIS analysts
      final zoneValue = properties['ZONE'] ?? properties['Zone'] ?? properties['NAME'] ?? properties['Name'] ?? properties['FID'] ?? properties['Id'] ?? "Unknown";

      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (type == 'Polygon') {
        for (var ring in coords) {
          List<LatLng> polyPoints = (ring as List).map((c) => LatLng(c[1], c[0])).toList();
          if (_isPointInPolygon(point, polyPoints)) return "Zone $zoneValue";
        }
      } 
      else if (type == 'MultiPolygon') {
        for (var poly in coords) {
          for (var ring in poly) {
            List<LatLng> polyPoints = (ring as List).map((c) => LatLng(c[1], c[0])).toList();
            if (_isPointInPolygon(point, polyPoints)) return "Zone $zoneValue";
          }
        }
      } 
      else if (type == 'LineString') {
        List<LatLng> linePoints = (coords as List).map((c) => LatLng(c[1], c[0])).toList();
        double dist = _distanceToLine(point, linePoints);
        if (dist < minDistance) {
          minDistance = dist;
          closestZone = zoneValue.toString();
        }
      } 
      else if (type == 'MultiLineString') {
        for (var line in coords) {
          List<LatLng> linePoints = (line as List).map((c) => LatLng(c[1], c[0])).toList();
          double dist = _distanceToLine(point, linePoints);
          if (dist < minDistance) {
            minDistance = dist;
            closestZone = zoneValue.toString();
          }
        }
      }
    }

    // If it's a map made of lines, return the closest one we found
    if (closestZone != null) { 
      return "Zone $closestZone";
    }

    // If it still reaches here, uncomment this to debug what the DBF actually contains
    // print("Available DBF keys for first feature: ${_seismogenicFeatures.first['properties'].keys}");

    return "Zone Unknown";
  }

  // Standard Horizontal Ray-casting algorithm for Point-in-Polygon
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      double xi = polygon[i].longitude, yi = polygon[i].latitude;
      double xj = polygon[j].longitude, yj = polygon[j].latitude;

      bool intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      if (intersect) isInside = !isInside;
      j = i;
    }
    return isInside;
  }

  // Proximity check for LineStrings
  static double _distanceToLine(LatLng point, List<LatLng> line) {
    double minDst = double.infinity;
    for (int i = 0; i < line.length - 1; i++) {
      double d = _pointToSegmentDistance(point, line[i], line[i + 1]);
      if (d < minDst) minDst = d;
    }
    return minDst;
  }

  static double _pointToSegmentDistance(LatLng p, LatLng v, LatLng w) {
    double l2 = pow(v.latitude - w.latitude, 2) + pow(v.longitude - w.longitude, 2).toDouble();
    if (l2 == 0) return sqrt(pow(p.latitude - v.latitude, 2) + pow(p.longitude - v.longitude, 2));
    double t = ((p.latitude - v.latitude) * (w.latitude - v.latitude) + (p.longitude - v.longitude) * (w.longitude - v.longitude)) / l2;
    t = max(0, min(1, t));
    LatLng proj = LatLng(v.latitude + t * (w.latitude - v.latitude), v.longitude + t * (w.longitude - v.longitude));
    return sqrt(pow(p.latitude - proj.latitude, 2) + pow(p.longitude - proj.longitude, 2));
  }
}