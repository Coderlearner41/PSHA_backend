import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HazardData {
  final List<double> periods;
  final List<double> psa;
  final List<double> rsHorizontal;
  final List<double> rsVertical;

  HazardData({
    required this.periods,
    required this.psa,
    required this.rsHorizontal,
    required this.rsVertical,
  });
}

class LocalHazardService {
  static Database? _database;
  static List<double> _periods = [];
  static List<double> _intG = [];

  // =========================================================================
  // NEW HELPER: Safely converts unaligned SQLite byte buffers to Float32Lists
  // =========================================================================
  static Float32List _getAlignedFloats(Uint8List unalignedBlob) {
    // By creating a fresh copy, we guarantee the memory offset starts at 0 (which is a multiple of 4)
    // This permanently prevents the "Offset must be a multiple of 4" crash.
    final alignedCopy = Uint8List.fromList(unalignedBlob);
    return Float32List.view(alignedCopy.buffer);
  }

  /// Copies the DB from assets to the device file system and opens it
  static Future<void> initDB() async {
    if (_database != null) return;

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "hazard_data.db");

    var exists = await databaseExists(path);
    if (!exists) {
      try {
        ByteData data = await rootBundle.load(join("assets", "hazard_data.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception("Error copying database: $e");
      }
    }

    _database = await openDatabase(path);

    // Load Meta variables (Periods and IntG)
    final List<Map<String, dynamic>> metaData = await _database!.query('meta');
    for (var row in metaData) {
      Uint8List blob = row['data_blob'] as Uint8List;
      
      // FIX: Use our new aligned memory helper
      Float32List floats = _getAlignedFloats(blob); 
      
      if (row['key'] == 'periods') _periods = floats.toList();
      if (row['key'] == 'int_g') _intG = floats.toList();
    }
  }

  /// Calculates hazard data locally
  static Future<HazardData?> computeUHS(double lat, double lon, String siteClass, int returnPeriod) async {
    if (_database == null) await initDB();

    if (lon < 60.0 || lon > 100.0 || lat < 2.0 || lat > 40.0) {
      throw Exception("Location outside of supported Indian seismic data range.");
    }

    final int nPeriods = _periods.length; 

    // Find Nearest Grid Point in SQLite
    final List<Map<String, dynamic>> nearest = await _database!.rawQuery('''
      SELECT lat, lon, data_blob 
      FROM grid 
      WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?
      ORDER BY ((lat - ?) * (lat - ?) + (lon - ?) * (lon - ?)) ASC 
      LIMIT 1
    ''', [lat - 0.5, lat + 0.5, lon - 0.5, lon + 0.5, lat, lat, lon, lon]);

    if (nearest.isEmpty) return null;

    Uint8List rawBlob = nearest.first['data_blob'] as Uint8List;
    
    // FIX: Use our new aligned memory helper here too!
    Float32List z4Flat = _getAlignedFloats(rawBlob);
    
    double n1 = 1.0 / returnPeriod;
    List<double> psaRp = List.filled(nPeriods, 0.0); 

    for (int i = 0; i < nPeriods; i++) {
      List<double> bCol = [];
      for (int j = 0; j < 15; j++) {
        bCol.add(z4Flat[j * nPeriods + i]);
      }

      List<double> aboveN1 = bCol.where((val) => val > n1).toList()..sort((a, b) => b.compareTo(a)); 
      List<double> belowN1 = bCol.where((val) => val < n1).toList()..sort(); 

      if (aboveN1.isEmpty || belowN1.isEmpty) {
        psaRp[i] = 0.0;
        continue;
      }

      double j1 = aboveN1.last;
      double k1 = belowN1.last; 
      
      double l1 = _intG[bCol.indexOf(j1)];
      double m1 = _intG[bCol.indexOf(k1)];

      if (k1 - j1 != 0) {
        psaRp[i] = l1 + (n1 - j1) * (m1 - l1) / (k1 - j1);
      } else {
        psaRp[i] = l1; 
      }
    }

    List<double> rsH = _getRSSpectra(_periods, siteClass, 'H');
    List<double> rsV = _getRSSpectra(_periods, siteClass, 'V');

    return HazardData(
      periods: _periods,
      psa: psaRp,
      rsHorizontal: rsH,
      rsVertical: rsV,
    );
  }

  /// Replicates get_RS_spectra from Python
  static List<double> _getRSSpectra(List<double> tArr, String siteClass, String direction) {
    List<double> aArr = List.filled(tArr.length, 0.0);
    siteClass = siteClass.toUpperCase();
    direction = direction.toUpperCase();

    for (int i = 0; i < tArr.length; i++) {
      double t = tArr[i];
      double a = 0.0;

      if (direction == 'H') {
        if (siteClass == 'A' || siteClass == 'B') {
          if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.4) a = 2.5;
          else if (t > 0.4 && t <= 6.0) a = 1.0 / t;
          else if (t > 6.0 && t <= 10.0) a = 6.0 / math.pow(t, 2);
        } else if (siteClass == 'C') {
          if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.6) a = 2.5;
          else if (t > 0.6 && t <= 6.0) a = 1.5 / t;
          else if (t > 6.0 && t <= 10.0) a = 9.0 / math.pow(t, 2);
        } else if (siteClass == 'D') {
          if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.8) a = 2.5;
          else if (t > 0.8 && t <= 6.0) a = 2.0 / t;
          else if (t > 6.0 && t <= 10.0) a = 12.0 / math.pow(t, 2);
        }
      } else if (direction == 'V') {
        double deltaV = 0.0;
        if (siteClass == 'A' || siteClass == 'B') {
          if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.4) a = 2.5;
          else if (t > 0.4 && t <= 6.0) a = 1.0 / t;
          else if (t > 6.0 && t <= 10.0) a = 6.0 / math.pow(t, 2);

          if (t >= 0 && t <= 0.01) deltaV = 0.80;
          else if (t > 0.01 && t <= 0.10) deltaV = 0.80 - (200.0 / 135.0) * (t - 0.01);
          else deltaV = 0.67;
        } else if (siteClass == 'C') {
           if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.6) a = 2.5;
          else if (t > 0.6 && t <= 6.0) a = 1.5 / t;
          else if (t > 6.0 && t <= 10.0) a = 9.0 / math.pow(t, 2);

          if (t >= 0 && t <= 0.01) deltaV = 0.82;
          else if (t > 0.01 && t <= 0.10) deltaV = 0.82 - (213.0 / 125.0) * (t - 0.01);
          else deltaV = 0.67;
        } else if (siteClass == 'D') {
          if (t >= 0 && t <= 0.01) a = 1.0;
          else if (t > 0.01 && t <= 0.1) a = 1.0 + (50.0 / 3.0) * (t - 0.01);
          else if (t > 0.1 && t <= 0.8) a = 2.5;
          else if (t > 0.8 && t <= 6.0) a = 2.0 / t;
          else if (t > 6.0 && t <= 10.0) a = 12.0 / math.pow(t, 2);

          if (t >= 0 && t <= 0.01) deltaV = 0.85;
          else if (t > 0.01 && t <= 0.10) deltaV = 0.85 - (200.0 / 100.0) * (t - 0.01);
          else deltaV = 0.67;
        }
        a = a * deltaV;
      }
      aArr[i] = a;
    }
    return aArr;
  }
}