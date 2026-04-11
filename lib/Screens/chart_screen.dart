import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_saver/file_saver.dart';
import 'map_picker_screen.dart'; // Make sure the path matches where you saved it
import '../services/local_hazard_service.dart';

class ChartScreen extends StatefulWidget {
  final String chartType; // "UHS" or "Spectra"
  final LatLng? initialPoint;

  const ChartScreen({super.key, required this.chartType, this.initialPoint});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _rpController = TextEditingController(text: "2475");
  
  bool _isLoading = false;
  bool _showTable = false;
  HazardData? _hazardData;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    if (widget.initialPoint != null) {
      _latController.text = widget.initialPoint!.latitude.toStringAsFixed(4);
      _lonController.text = widget.initialPoint!.longitude.toStringAsFixed(4);
      _fetchData(); 
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _latController.dispose();
    _lonController.dispose();
    _rpController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationFromMap() async {
    // Default to center of India if fields are empty
    LatLng currentPos = const LatLng(22.0, 78.0); 
    
    if (_latController.text.isNotEmpty && _lonController.text.isNotEmpty) {
      final lat = double.tryParse(_latController.text);
      final lon = double.tryParse(_lonController.text);
      if (lat != null && lon != null) currentPos = LatLng(lat, lon);
    }

    // Launch the new full-screen picker
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialPosition: currentPos),
      ),
    );

    // Update text fields if a location was confirmed
    if (picked != null) {
      setState(() {
        _latController.text = picked.latitude.toStringAsFixed(4);
        _lonController.text = picked.longitude.toStringAsFixed(4);
      });
    }
  }

  Future<void> _fetchData() async {
    FocusScope.of(context).unfocus(); 

    final double? lat = double.tryParse(_latController.text);
    final double? lon = double.tryParse(_lonController.text);
    final int? rp = int.tryParse(_rpController.text);

    if (lat == null || lon == null || rp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numeric values."))
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final data = await LocalHazardService.computeUHS(lat, lon, 'C', rp);
      
      if (mounted) {
        setState(() {
          _hazardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  Future<void> _downloadCsv() async {
    if (_hazardData == null) return;
    
    // 1. Generate CSV String
    StringBuffer csv = StringBuffer("Period(s),PSA(g),RS_Horizontal(g),RS_Vertical(g)\n");
    for (int i = 0; i < _hazardData!.periods.length; i++) {
      csv.write("${_hazardData!.periods[i]},${_hazardData!.psa[i]},${_hazardData!.rsHorizontal[i]},${_hazardData!.rsVertical[i]}\n");
    }

    // 2. Convert to Bytes
    final bytes = Uint8List.fromList(utf8.encode(csv.toString()));

    try {
      // 3. Save directly to the device (Downloads folder / Files app)
      await FileSaver.instance.saveFile(
        name: '${widget.chartType}_Data',
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      // 4. Show success message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.chartType} CSV downloaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle any permission or saving errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Deeper, more modern background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Dynamically calculate sidebar width based on screen size
            double sidebarWidth = constraints.maxWidth * 0.32;
            if (sidebarWidth < 280) sidebarWidth = 280; // Min width to prevent squishing
            if (sidebarWidth > 350) sidebarWidth = 350; // Max width to preserve chart space

            return Row(
              children: [
                // ==============================
                // LEFT SIDEBAR: Controls
                // ==============================
                Container(
                  width: sidebarWidth,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16161D),
                    border: Border(right: BorderSide(color: Colors.white10, width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Header inside the sidebar to save top-bar space
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.chartType} Analysis",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      
                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Group Lat/Lon horizontally to save vertical space
                              Row(
                                children: [
                                  Expanded(child: _buildCompactTextField("Lat", _latController)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildCompactTextField("Lon", _lonController)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Map Picker & RP Row
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildCompactTextField("Return Pd (Yrs)", _rpController, icon: Icons.update),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: AspectRatio(
                                      aspectRatio: 1, // Make it a square button
                                      child: OutlinedButton(
                                        onPressed: _pickLocationFromMap,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          side: const BorderSide(color: Colors.blueAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Icon(Icons.map_rounded, color: Colors.blueAccent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Generate Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent, 
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _fetchData,
                                child: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Text("Generate Graph", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ==============================
                // RIGHT SIDE: Chart View
                // ==============================
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Header & Legend Area
                        // Dynamic Header & Legend Area
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_hazardData != null && widget.chartType == "Spectra" && !_showTable)
                              Row(
                                children: [
                                  _buildLegendItem("Horizontal", Colors.blueAccent),
                                  const SizedBox(width: 16),
                                  _buildLegendItem("Vertical", Colors.redAccent),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                              
                            if (_hazardData != null)
                              Row(
                                children: [
                                  // NEW TABLE TOGGLE BUTTON
                                  IconButton(
                                    tooltip: _showTable ? "Show Graph" : "Show Table",
                                    onPressed: () => setState(() => _showTable = !_showTable),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF16161D),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: Icon(_showTable ? Icons.auto_graph_rounded : Icons.table_chart_rounded, color: Colors.blueAccent, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  // EXISTING EXPORT BUTTON
                                  IconButton(
                                    tooltip: "Export CSV",
                                    onPressed: _downloadCsv,
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF16161D),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.download_rounded, color: Colors.greenAccent, size: 20),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // The Graph
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161D),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10, width: 1),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                            child: _hazardData == null 
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_graph_rounded, size: 48, color: Colors.white12),
                                      SizedBox(height: 12),
                                      Text("Enter parameters to generate chart", style: TextStyle(color: Colors.white38, fontSize: 14)),
                                    ],
                                  ),
                                )
                              : _showTable ? _buildDataTable() : _buildChart(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
  Widget _buildDataTable() {
    if (_hazardData == null) return const SizedBox();
    
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          dividerThickness: 0.5,
          columns: [
            const DataColumn(label: Text('Period (T)')),
            if (widget.chartType == "UHS") const DataColumn(label: Text('Sa (g)')),
            if (widget.chartType == "Spectra") const DataColumn(label: Text('RS Horizontal (g)')),
            if (widget.chartType == "Spectra") const DataColumn(label: Text('RS Vertical (g)')),
          ],
          rows: List.generate(_hazardData!.periods.length, (index) {
            return DataRow(cells: [
              DataCell(Text(_hazardData!.periods[index].toStringAsFixed(3))),
              if (widget.chartType == "UHS") DataCell(Text(_hazardData!.psa[index].toStringAsFixed(4))),
              if (widget.chartType == "Spectra") DataCell(Text(_hazardData!.rsHorizontal[index].toStringAsFixed(4))),
              if (widget.chartType == "Spectra") DataCell(Text(_hazardData!.rsVertical[index].toStringAsFixed(4))),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Refactored to be much more compact
  Widget _buildCompactTextField(String label, TextEditingController controller, {IconData? icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        isDense: true, // Crucial for saving vertical height
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white24, size: 18) : null,
        prefixIconConstraints: icon != null ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
        filled: true,
        fillColor: const Color(0xFF22222A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent, width: 1)),
      ),
    );
  }

  Widget _buildChart() {
    if (_hazardData == null) return const SizedBox();
    List<FlSpot> spots1 = [];
    List<FlSpot> spots2 = [];

    double maxY = 0;
    final int count = [
      _hazardData!.periods.length,
      _hazardData!.psa.length,
      _hazardData!.rsHorizontal.length,
      _hazardData!.rsVertical.length
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < count; i++) {
      double x = _hazardData!.periods[i];
      double val1 = widget.chartType == "UHS" ? _hazardData!.psa[i] : _hazardData!.rsHorizontal[i];
      spots1.add(FlSpot(x, val1));
      if (val1 > maxY) maxY = val1;

      if (widget.chartType == "Spectra") {
        double val2 = _hazardData!.rsVertical[i];
        spots2.add(FlSpot(x, val2));
        if (val2 > maxY) maxY = val2;
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        minY: 0,
        maxY: maxY + (maxY * 0.15), 
        backgroundColor: Colors.transparent,
        
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [4, 4]),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [4, 4]),
        ),
        
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF22222A),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(3)} g\n${spot.x.toStringAsFixed(2)} s',
                  TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("Period (s)", style: TextStyle(color: Colors.white54, fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text("Accel (g)", style: TextStyle(color: Colors.white54, fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        
        borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.white24, width: 1.5), left: BorderSide(color: Colors.white24, width: 1.5))),
        
        lineBarsData: [
          LineChartBarData(
            spots: spots1,
            isCurved: true,
            curveSmoothness: 0.2,
            color: Colors.blueAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // Hide dots by default for a cleaner modern look
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blueAccent.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (widget.chartType == "Spectra")
            LineChartBarData(
              spots: spots2,
              isCurved: true,
              curveSmoothness: 0.2,
              color: Colors.redAccent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.redAccent.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
        ],
      ),
    );
  }
}