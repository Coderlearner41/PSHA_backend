import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shapefile/shapefile.dart';

// --- NEW DATA MODEL ---
class FaultFeature {
  final List<LatLng> points;
  final String name;
  final Color color;

  FaultFeature({
    required this.points,
    required this.name,
    required this.color,
  });
}

class _FaultMeta {
  final LatLng point;
  final String? name;
  final Color? color;

  _FaultMeta({required this.point, this.name, this.color});
}

class FaultService {
  static Future<List<FaultFeature>> loadFaultData() async {
    List<List<LatLng>> rawLines = await _loadShapefile();
    List<_FaultMeta> names = await _loadNames();
    List<_FaultMeta> colors = await _loadColorsFromCSV();

    List<FaultFeature> features = [];

    for (var line in rawLines) {
      if (line.isEmpty) continue;
      
      LatLng startPoint = line.first;
      LatLng endPoint = line.last; // <--- FIX: We now check both ends!

      // --- Match Color ---
      Color faultColor = Colors.grey;
      double minColorDist = double.infinity;
      
      for (var c in colors) {
        // Check distance to both ends to fix reverse-drawn shapefiles
        double dist1 = _sqDist(startPoint, c.point);
        double dist2 = _sqDist(endPoint, c.point);
        double dist = min(dist1, dist2);
        
        // Increased threshold to 2.5 to catch slight digitizing errors
        if (dist < minColorDist && dist < 2.5) { 
          minColorDist = dist;
          faultColor = c.color ?? Colors.grey;
        }
      }

      // --- Match Name ---
      String faultName = "Unnamed Fault Line";
      double minNameDist = double.infinity;
      
      for (var n in names) {
        double dist1 = _sqDist(startPoint, n.point);
        double dist2 = _sqDist(endPoint, n.point);
        double dist = min(dist1, dist2);
        
        if (dist < minNameDist && dist < 2.5) {
          minNameDist = dist;
          faultName = n.name ?? "Unnamed Fault Line";
        }
      }

      // Save the bundled data
      features.add(
        FaultFeature(
          points: line,
          name: faultName,
          color: faultColor,
        ),
      );
    }

    return features;
  }

  // --- 1. SHAPEFILE PARSER ---
  static Future<List<List<LatLng>>> _loadShapefile() async {
    try {
      final ByteData shpBytes = await rootBundle.load('assets/Final_Fault_Map_2020.shp');
      final shpStream = Stream.value(shpBytes.buffer.asUint8List());
      final parsedData = await featureCollection(shpStream);

      List<List<LatLng>> lines = [];
      if (parsedData['features'] != null) {
        for (var feature in parsedData['features']) {
          final geometry = feature['geometry'];
          if (geometry['type'] == 'LineString') {
            List<LatLng> points = [];
            for (var coord in geometry['coordinates']) {
              points.add(LatLng(coord[1], coord[0]));
            }
            lines.add(points);
          }
        }
      }
      return lines;
    } catch (e) {
      return [];
    }
  }

  // --- 2. NAMES PARSER ---
  static Future<List<_FaultMeta>> _loadNames() async {
    List<_FaultMeta> result = [];
    try {
      final String content = await rootBundle.loadString('assets/faultnames.txt');
      final List<String> lines = const LineSplitter().convert(content);

      for (String line in lines) {
        if (line.trim().isEmpty || line.toLowerCase().contains('sheet')) continue;
        String cleanLine = line.replaceAll('lat=', '').replaceAll('lon=', '').trim();
        List<String> parts = cleanLine.split(RegExp(r'\s+'));

        if (parts.length >= 3) {
          double? val1 = double.tryParse(parts[0]);
          double? val2 = double.tryParse(parts[1]);

          if (val1 != null && val2 != null) {
            double lat = val1 < 45 ? val1 : val2;
            double lon = val1 > 45 ? val1 : val2;
            String name = parts.sublist(2).join(' ').replaceAll(RegExp(r'\s+\d+$'), ''); 
            result.add(_FaultMeta(point: LatLng(lat, lon), name: name));
          }
        }
      }
    } catch (e) {}
    return result;
  }

  // --- 3. MATLAB TXT PARSER ---
  static Future<List<_FaultMeta>> _loadColorsFromCSV() async {
    List<_FaultMeta> result = [];
    try {
      final String content = await rootBundle.loadString('assets/fault_colors.csv');
      final List<String> lines = const LineSplitter().convert(content);

      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        List<String> row = lines[i].split(','); // Assuming standard comma separation
        if (row.length >= 4) {
          String colorCode = row[1];
          double lon = double.tryParse(row[2]) ?? 0.0;
          double lat = double.tryParse(row[3]) ?? 0.0;

          result.add(_FaultMeta(
            point: LatLng(lat, lon), 
            color: _getFlutterColor(colorCode)
          ));
        }
      }
    } catch (e) {
      debugPrint("❌ CSV PARSE ERROR: $e");
    }
    return result;
  }

  static Color _getFlutterColor(String matlabColorCode) {
    switch (matlabColorCode) {
      case 'r': return Colors.red;
      case 'g': return Colors.green.shade700; 
      case 'b': return Colors.blue.shade700;
      case 'c': return Colors.teal; 
      case 'm': return Colors.purpleAccent; 
      case 'y': return Colors.yellow; 
      case 'k': return Colors.black87;
      default: return Colors.pinkAccent;
    }
  }

  static double _sqDist(LatLng p1, LatLng p2) {
    return pow(p1.latitude - p2.latitude, 2) + pow(p1.longitude - p2.longitude, 2).toDouble();
  }
}