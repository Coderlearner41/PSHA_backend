import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AnalysisResultView extends StatelessWidget {
  final LatLng latlng;
  final double faultDistance;
  final double maxMagnitude;
  final String isSeismicZone; 
  final String seismogenicZone;
  final double soilMark; // <-- CHANGED to double to accept the numeric value (1.0, 1.15, etc.)
  final VoidCallback onClose;

  const AnalysisResultView({
    super.key,
    required this.latlng,
    required this.faultDistance,
    required this.maxMagnitude,
    required this.isSeismicZone,
    required this.seismogenicZone,
    required this.soilMark, // <-- CHANGED
    required this.onClose,
  });

  /// Helper method to convert the numeric soil mark from the CSV into a readable string
  String getSoilTypeName(double soilMarkValue) {
    // Use a slight tolerance for float comparisons (e.g., 1.15000000001)
    if ((soilMarkValue - 1.0).abs() < 0.01) {
      return 'Metamorphic';
    } else if ((soilMarkValue - 1.15).abs() < 0.01) {
      return 'Sediment';
    } else if ((soilMarkValue - 1.35).abs() < 0.01) {
      return 'Laterite';
    } else if ((soilMarkValue - 1.5).abs() < 0.01) {
      return 'Alluvium';
    } else {
      return 'Unknown'; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.40, 
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF181818),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              // Pull Handle
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location Analysis",
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}",
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    // First Row of Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            "Max Earthquake", 
                            maxMagnitude < 0 ? "No Data" : "${maxMagnitude.toStringAsFixed(1)} M", 
                            Icons.waves
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            "Nearest Fault", 
                            faultDistance < 0 ? "No Data" : "${faultDistance.toStringAsFixed(2)} km", 
                            Icons.straighten
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Second Row of Cards (Zone & Soil)
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard("Seismic Zone", isSeismicZone, Icons.map)), 
                        const SizedBox(width: 16),
                        // <-- UPDATED: Call the helper method and pass the numeric soilMark
                        Expanded(child: _buildInfoCard("Soil Type", getSoilTypeName(soilMark), Icons.terrain)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Full-width Seismogenic Zone Card
                    _buildInfoCard("Seismogenic Zone", seismogenicZone, Icons.layers_outlined),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: onClose,
                        child: const Text("Close Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}