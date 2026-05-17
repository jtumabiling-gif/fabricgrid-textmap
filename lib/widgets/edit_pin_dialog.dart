import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class EditPinDialog extends StatefulWidget {
  const EditPinDialog({
    required this.initialLat,
    required this.initialLng,
    required this.initialLocation,
    required this.onSave,
    super.key,
  });

  final double initialLat;
  final double initialLng;
  final String initialLocation;
  final Function(double lat, double lng, String location) onSave;

  @override
  State<EditPinDialog> createState() => _EditPinDialogState();
}

class _EditPinDialogState extends State<EditPinDialog> {
  late MapController mapController;
  late double selectedLat;
  late double selectedLng;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    selectedLat = widget.initialLat;
    selectedLng = widget.initialLng;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    mapController.dispose();
    super.dispose();
  }

  void _resetToDefault() {
    setState(() {
      selectedLat = widget.initialLat;
      selectedLng = widget.initialLng;
    });
    mapController.move(
      LatLng(widget.initialLat, widget.initialLng),
      14,
    );
  }

  Future<String> _getReverseGeocoding(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FabricGrid-App',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['display_name'] ?? 'Unknown Location';
      }
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
    }
    return 'Unknown Location';
  }

  void _saveChanges() async {
    // Show loading dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Color(0xFF0F1F2F),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1EDDAC),
              ),
              SizedBox(height: 16),
              Text(
                'Saving location...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Get location name from coordinates
    final locationName = await _getReverseGeocoding(selectedLat, selectedLng);
    
    if (!mounted) return;
    
    // Close loading dialog
    Navigator.of(context).pop();
    
    // Call the callback with coordinates and location name
    widget.onSave(selectedLat, selectedLng, locationName);
    
    // Close the dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EDIT PICKUP LOCATION',
                    style: TextStyle(
                      color: Color(0xFF1EDDAC),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF1EDDAC),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Map with centered pin
            Expanded(
              child: Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(selectedLat, selectedLng),
                      initialZoom: 14,
                      minZoom: 10,
                      maxZoom: 19,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture) {
                          setState(() {
                            final center = mapController.center;
                            selectedLat = center.latitude;
                            selectedLng = center.longitude;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.fabricgrid.app',
                        maxZoom: 19,
                      ),
                    ],
                  ),
                  // Centered Pin Icon with shadow effect
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1EDDAC).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 56,
                            color: Color(0xFF1EDDAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Zoom Controls
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2B3F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                mapController.move(
                                  mapController.center,
                                  mapController.zoom + 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xFF1EDDAC),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 44,
                            color: Colors.white12,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                mapController.move(
                                  mapController.center,
                                  mapController.zoom - 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Icon(
                                    Icons.remove,
                                    color: Color(0xFF1EDDAC),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Coordinates Display (Top-Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1F2F).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lat: ${selectedLat.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Color(0xFF1EDDAC),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lon: ${selectedLng.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Color(0xFF1EDDAC),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons at Bottom
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white12),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetToDefault,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2B3F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF1EDDAC)),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EDDAC),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Location',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
