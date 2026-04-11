import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FloatingButtonsWidget extends StatelessWidget {
  final LatLng? userLocation;
  final MapController controller;
  final VoidCallback openLayerMenu;
  final VoidCallback getLocation;

  const FloatingButtonsWidget({
    super.key,
    required this.userLocation,
    required this.controller,
    required this.openLayerMenu,
    required this.getLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "layers",
          onPressed: openLayerMenu,
          backgroundColor: const Color(0xFF1C130E),
          foregroundColor: Colors.white, // Forces the ripple and icon to be white
          child: const Icon(Icons.layers, color: Colors.white), // Explicitly makes the icon white
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "location",
          onPressed: () {
            if (userLocation != null) {
              controller.move(userLocation!, 10);
            } else {
              getLocation();
            }
          },
          backgroundColor: const Color(0xFF1C130E),
          foregroundColor: Colors.white, // Forces the ripple and icon to be white
          child: const Icon(Icons.my_location, color: Colors.white), // Explicitly makes the icon white
        ),
      ],
    );
  }
}