import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../services/soil_service.dart'; // <-- ADD THIS

import '../models/earthquake_event.dart';
import '../services/location_service.dart';
import '../services/fault_service.dart';
import '../services/earthquake_service.dart';
import '../services/seismogenic_service.dart';
import '../services/seismic_zone_service.dart';
import '../utils/geo_utils.dart'; 

import '../widgets/pulsing_blue_dot.dart';
import '../widgets/layer_menu_popup.dart';
import '../widgets/floating_buttons_widget.dart';
import '../widgets/analysis_bottom_sheet.dart'; 
import '../widgets/earthquake_details_popup.dart'; 

import './chart_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng? selectedPoint;
  LatLng? userLocation;

  bool showCracks = false;
  bool showEpicenters = false;
  bool showRecentEpicenters = false; 
  Set<MapLayer> selectedLayers = {}; 

  bool _isAnalysisVisible = false;
  double _currentFaultDist = 0;
  double _currentMaxMag = 0;
  
  String _currentIsSeismicZone = "Zone Unknown";
  String _currentSeismogenicZone = "Zone Unknown";
  double _currentSoilMark = 1.0;

  List<EarthquakeEvent> earthquakes = [];
  List<CircleMarker> epicenterMarkers = [];
  List<EarthquakeEvent> recentEarthquakes = []; 
  List<CircleMarker> recentEpicenterMarkers = [];
  List<Polygon> _prebuiltSeismicPolygons = [];
  
 
  List<FaultFeature> faultFeatures = [];
  
  List<Polyline> seismogenicLines = [];
  List<SeismicZone> seismicZonesData = [];

  List<CircleMarker> rangeCircles = [];
  List<Marker> rangeLabels = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadFaults(),
      _loadEarthquakes(),
      _getUserLocation(),
      _loadSeismogenicMap(), 
      _loadRecentEarthquakes(),
      _loadSeismicZones(), 
      SoilService.loadSoilData(),
    ]);
  }

  Future<void> _loadRecentEarthquakes() async {
    final eq = await EarthquakeService.fetchRecentEarthquakes();
    final markers = EarthquakeService.buildMarkers(eq);
    if (mounted) {
      setState(() {
        recentEarthquakes = eq;
        recentEpicenterMarkers = markers;
      });
    }
  }

  Future<void> _loadSeismicZones() async {
    final zones = await SeismicZoneService.loadZones();
    
    // Build the map polygons ONCE in memory
    List<Polygon> builtPolygons = [];
    for (var zone in zones) {
      for (var polyCoords in zone.polygons) {
        builtPolygons.add(Polygon(
          points: polyCoords,
          color: zone.color,
          // No borders to save extreme amount of GPU processing
        ));
      }
    }

    if (mounted) {
      setState(() {
        seismicZonesData = zones;
        _prebuiltSeismicPolygons = builtPolygons; // Store the finished polygons
      });
    }
  }

  Future<void> _loadFaults() async {
    final features = await FaultService.loadFaultData();
    if (mounted) {
      setState(() {
        faultFeatures = features;
      });
    }
  }

  String _identifySeismicZone(LatLng point) {
    return SeismicZoneService.getNearestZone(point);
  }

  String _identifySeismogenicZone(LatLng point) {
    return SeismogenicService.getZoneForLocation(point); 
  }

  Future<void> _loadEarthquakes() async {
    final eq = await EarthquakeService.loadEarthquakes(); 
    final markers = EarthquakeService.buildMarkers(eq);
    if (mounted) {
      setState(() {
        earthquakes = eq;
        epicenterMarkers = markers;
      });
    }
  }

  Future<void> _loadSeismogenicMap() async {
    final lines = await SeismogenicService.loadSeismogenicLines();
    if (mounted) {
      setState(() {
        seismogenicLines = lines;
      });
    }
  }

  Future<void> _getUserLocation() async {
    final location = await LocationService.getUserLocation(); 
    if (location != null && mounted) {
      setState(() => userLocation = location);
      _mapController.move(location, 8.0);
    }
  }

  // UPDATED: Now uses faultFeatures.points
  double _calculateDistanceToNearestFault(LatLng point) {
    double minDistance = double.infinity;
    for (var fault in faultFeatures) {
      for (int i = 0; i < fault.points.length - 1; i++) {
        double d = GeoUtils.distanceToSegment(point, fault.points[i], fault.points[i + 1]); 
        if (d < minDistance) minDistance = d;
      }
    }
    return minDistance == double.infinity ? -1 : minDistance;
  }

  double _calculateMaxMagnitude(LatLng point, double radiusKm) {
    double maxMag = -1;
    const distance = Distance();
    for (var eq in earthquakes) {
      double d = distance.as(LengthUnit.Kilometer, point, eq.location);
      if (d <= radiusKm && eq.magnitude > maxMag) {
        maxMag = eq.magnitude;
      }
    }
    return maxMag;
  }

  Marker _buildRangeLabel(LatLng pos, String distanceText, double maxMag, Color color) {
    return Marker(
      point: pos,
      width: 100,
      height: 48,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE181818),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(distanceText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, height: 1.1)),
            Text(maxMag > 0 ? "Max: ${maxMag.toStringAsFixed(1)}M" : "No EQ", style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.1)),
          ],
        ),
      ),
    );
  }

  void _drawRangeCircles(LatLng point) {
    double maxMag100 = _calculateMaxMagnitude(point, 100.0);
    double maxMag200 = _calculateMaxMagnitude(point, 200.0);
    double maxMag300 = _calculateMaxMagnitude(point, 300.0);

    const Distance dist = Distance();
    LatLng pos100 = dist.offset(point, 100000, 45);
    LatLng pos200 = dist.offset(point, 200000, 45);
    LatLng pos300 = dist.offset(point, 300000, 45);

    setState(() {
      rangeCircles = [
        CircleMarker(point: point, radius: 100000, useRadiusInMeter: true, color: Colors.blue.withOpacity(0.1), borderStrokeWidth: 1, borderColor: Colors.blueAccent),
        CircleMarker(point: point, radius: 200000, useRadiusInMeter: true, color: Colors.orange.withOpacity(0.05), borderStrokeWidth: 1, borderColor: Colors.orangeAccent),
        CircleMarker(point: point, radius: 300000, useRadiusInMeter: true, color: Colors.red.withOpacity(0.03), borderStrokeWidth: 1, borderColor: Colors.redAccent),
      ];

      rangeLabels = [
        _buildRangeLabel(pos100, "100 km", maxMag100, Colors.blueAccent),
        _buildRangeLabel(pos200, "200 km", maxMag200, Colors.orangeAccent),
        _buildRangeLabel(pos300, "300 km", maxMag300, Colors.redAccent),
      ];
    });
  }

  // NEW: UI Popup for when a fault line is tapped
  void _showFaultPopup(FaultFeature fault) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C130E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: fault.color, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.timeline, color: Colors.white),
            SizedBox(width: 10),
            Text("Fault Detected", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          fault.name, 
          style: TextStyle(color: fault.color, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Dismiss", style: TextStyle(color: Colors.grey))
          )
        ],
      )
    );
  }

  void _onTap(TapPosition _, LatLng latlng) {
    // 1. Check Epicenters Tap
    if (showEpicenters || showRecentEpicenters) {
      EarthquakeEvent? tappedEq;
      const distance = Distance();
      double minTapDist = 25.0; 

      List<EarthquakeEvent> activeEvents = [];
      if (showEpicenters) activeEvents.addAll(earthquakes);
      if (showRecentEpicenters) activeEvents.addAll(recentEarthquakes);
      
      for (var eq in activeEvents.where((e) => e.magnitude >= 4.0)) {
        double d = distance.as(LengthUnit.Kilometer, latlng, eq.location);
        if (d < minTapDist) {
          tappedEq = eq;
          minTapDist = d; 
        }
      }

      if (tappedEq != null) {
        showEarthquakeDetailsPopup(context, tappedEq); 
        return; 
      }
    }

    // 2. NEW: Check Fault Line Tap
    if (showCracks) {
      FaultFeature? tappedFault;
      double minLineDist = 15.0; // Must tap within 15km of the line

      for (var fault in faultFeatures) {
        for (int i = 0; i < fault.points.length - 1; i++) {
          double d = GeoUtils.distanceToSegment(latlng, fault.points[i], fault.points[i + 1]); 
          if (d < minLineDist) {
            minLineDist = d;
            tappedFault = fault;
          }
        }
      }

      if (tappedFault != null) {
        _showFaultPopup(tappedFault);
        return; // Stop here so it doesn't open the bottom sheet
      }
    }

    // 3. Normal Location Analysis Tap
    setState(() {
      selectedPoint = latlng;
      _isAnalysisVisible = true;
      
      _drawRangeCircles(latlng);
      _currentFaultDist = _calculateDistanceToNearestFault(latlng);
      _currentMaxMag = _calculateMaxMagnitude(latlng, 300.0);
      
      _currentIsSeismicZone = _identifySeismicZone(latlng);
      _currentSeismogenicZone = _identifySeismogenicZone(latlng);
      _currentSoilMark = SoilService.getNearestSoilMark(latlng);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digiquake Dashboard"),
        backgroundColor: const Color(0xFF1C130E),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF181818),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1C130E)),
              child: Text('Analysis Tools', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.show_chart, color: Colors.blueAccent),
              title: const Text('UHS Graph', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen(chartType: "UHS", initialPoint: selectedPoint ?? userLocation)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.multiline_chart, color: Colors.redAccent),
              title: const Text('Spectra Graph', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen(chartType: "Spectra", initialPoint: selectedPoint ?? userLocation)));
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(22.0, 79.0),
              initialZoom: 4.8,
              minZoom: 2,
              maxZoom: 25.0,
              // ADDED: Locking camera bounds to India
              // cameraConstraint: CameraConstraint.contain(
              //   bounds: LatLngBounds(
              //     const LatLng(6.5, 68.0),   // South-West corner
              //     const LatLng(37.5, 97.5),  // North-East corner
              //   ),
              // ),
              
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&gl=IN",
                userAgentPackageName: 'com.example.slopesafe',
              ),
              
              // UPDATED: Now maps dynamically from faultFeatures with a thicker stroke
              if (showCracks) 
                PolylineLayer(
                  polylines: faultFeatures.map((f) => Polyline(
                    points: f.points,
                    color: f.color,
                    strokeWidth: 2.0, // Thick and visible
                  )).toList(),
                ),
                
              if (selectedLayers.contains(MapLayer.seismogenic)) PolylineLayer(polylines: seismogenicLines),
              if (selectedLayers.contains(MapLayer.seismic))
                PolygonLayer(
                  polygonCulling: true,
                  polygons: _prebuiltSeismicPolygons,
                ),
              if (showEpicenters) CircleLayer(circles: epicenterMarkers),
              if (showRecentEpicenters) CircleLayer(circles: recentEpicenterMarkers), 
              if (rangeCircles.isNotEmpty) CircleLayer(circles: rangeCircles),
              
              MarkerLayer(
                markers: [
                  if (selectedPoint != null)
                    Marker(point: selectedPoint!, width: 60, height: 60, child: const Icon(Icons.location_on, color: Colors.red, size: 50)),
                  if (userLocation != null)
                    Marker(point: userLocation!, width: 60, height: 60, child: const PulsingBlueDot()),
                  ...rangeLabels,
                ],
              ),
            ],
          ),

          if (_isAnalysisVisible && selectedPoint != null)
            AnalysisResultView( 
              latlng: selectedPoint!,
              faultDistance: _currentFaultDist,
              maxMagnitude: _currentMaxMag,
              isSeismicZone: _currentIsSeismicZone,
              soilMark: _currentSoilMark,
              seismogenicZone: _currentSeismogenicZone, 
              onClose: () {
                setState(() {
                  _isAnalysisVisible = false;
                  selectedPoint = null;
                  rangeCircles.clear();
                  rangeLabels.clear();
                });
              },
            ),
          
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // Resets the rotation to True North
                _mapController.rotate(0.0); 
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25), 
                      blurRadius: 6, 
                      offset: const Offset(0, 3),
                    )
                  ]
                ),
                child: Center(
                  // Sizing the compass needle
                  child: SizedBox(
                    width: 14,
                    height: 30,
                    child: CustomPaint(
                      painter: CompassPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _isAnalysisVisible ? 60 : 0),
        child: FloatingButtonsWidget( 
          userLocation: userLocation,
          controller: _mapController,
          openLayerMenu: () => showLayerMenu( 
            context: context,
            showCracks: showCracks,
            showEpicenters: showEpicenters,
            showRecentEpicenters: showRecentEpicenters,
            selectedLayers: selectedLayers,
            onCracksChanged: (val) => setState(() => showCracks = val),
            onEpicentersChanged: (val) => setState(() => showEpicenters = val),
            onRecentEpicentersChanged: (val) => setState(() => showRecentEpicenters = val), 
            onLayersChanged: (val) => setState(() => selectedLayers = val),
          ),
          getLocation: _getUserLocation,
        ),
      ),
    );
  }
}

// --- CUSTOM COMPASS NEEDLE PAINTER ---
// --- CUSTOM COMPASS NEEDLE PAINTER ---
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 3D Shading colors matching the Google Maps style
    final Paint redLeft = Paint()..color = const Color(0xFFEA4335);  // Lighter Red
    final Paint redRight = Paint()..color = const Color(0xFFC5221F); // Darker Red
    final Paint whiteLeft = Paint()..color = const Color(0xFFFFFFFF); // Pure White
    final Paint whiteRight = Paint()..color = const Color(0xFFE0E0E0); // Light Grey for shadow

    // Top Left (Lighter Red)
    Path topLeft = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(0, h / 2)
      ..lineTo(w / 2, h / 2)
      ..close();
    canvas.drawPath(topLeft, redLeft);

    // Top Right (Darker Red)
    Path topRight = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h / 2)
      ..close();
    canvas.drawPath(topRight, redRight);

    // Bottom Left (Pure White)
    Path bottomLeft = Path()
      ..moveTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..lineTo(w / 2, h / 2)
      ..close();
    canvas.drawPath(bottomLeft, whiteLeft);

    // Bottom Right (Grey Shadow)
    Path bottomRight = Path()
      ..moveTo(w / 2, h)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h / 2)
      ..close();
    canvas.drawPath(bottomRight, whiteRight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}