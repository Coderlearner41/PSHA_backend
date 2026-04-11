import 'package:flutter/material.dart';

// --- FIXED: 'seismogenic' added to the enum here ---
enum MapLayer { seismogenic, seismic, soil }

void showLayerMenu({
  required BuildContext context,
  required bool showCracks,
  required bool showEpicenters,
  required bool showRecentEpicenters,
  required Set<MapLayer> selectedLayers,
  required ValueChanged<bool> onCracksChanged,
  required ValueChanged<bool> onEpicentersChanged,
  required ValueChanged<bool> onRecentEpicentersChanged,
  required ValueChanged<Set<MapLayer>> onLayersChanged,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.1),
    builder: (BuildContext context) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: kToolbarHeight + 16, right: 16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setPopupState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Text(
                            "Map Overlays",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        _buildToggle("Faults", showCracks, (val) {
                          setPopupState(() => showCracks = val);
                          onCracksChanged(val);
                        }),

                        _buildToggle("Epicenters", showEpicenters, (val) {
                          setPopupState(() => showEpicenters = val);
                          onEpicentersChanged(val);
                        }),

                        _buildToggle("Last 7 Days (USGS)", showRecentEpicenters, (val) {
                          setPopupState(() => showRecentEpicenters = val);
                          onRecentEpicentersChanged(val);
                        }),

                        const Divider(color: Colors.white24, height: 1),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            "Base Map (Multiple)",
                            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),

                        _buildModernCheckbox("Seismogenic Zone", MapLayer.seismogenic, Colors.blueAccent, selectedLayers, (layers) {
                          setPopupState(() => selectedLayers = layers);
                          onLayersChanged(layers);
                        }),
                        _buildModernCheckbox("Seismic Zone", MapLayer.seismic, Colors.orangeAccent, selectedLayers, (layers) {
                          setPopupState(() => selectedLayers = layers);
                          onLayersChanged(layers);
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, 
            style: TextStyle(color: value ? Colors.white : Colors.white70, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 48, height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: value ? Colors.redAccent : Colors.white10,
              border: Border.all(color: value ? Colors.redAccent : Colors.white24, width: 1.5),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildModernCheckbox(String title, MapLayer layer, Color activeColor, Set<MapLayer> currentSelected, ValueChanged<Set<MapLayer>> onChanged) {
  bool isSelected = currentSelected.contains(layer);
  return InkWell(
    onTap: () {
      final newSet = Set<MapLayer>.from(currentSelected);
      isSelected ? newSet.remove(layer) : newSet.add(layer);
      onChanged(newSet);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: isSelected ? activeColor : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
          ),
          Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? activeColor : Colors.white24, size: 20),
        ],
      ),
    ),
  );
}