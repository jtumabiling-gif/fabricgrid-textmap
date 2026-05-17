import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/edit_pin_dialog.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  late MapController mapController;
  late TextEditingController _searchController;
  double _mapLat = 7.3014;
  double _mapLng = 125.6810;
  String _mapLocation = 'Panabo City, Davao del Norte, Philippines';
  bool _showSearchSection = false;

  // Sample markers for textile services in Panabo
  final List<MapMarker> markers = [
    MapMarker(
      name: 'Stitch Master',
      type: 'Professional Tailor',
      lat: 7.3014,
      lng: 125.6810,
      icon: '✂️',
    ),
    MapMarker(
      name: 'Quick Laundry',
      type: 'Laundry Service',
      lat: 7.3108,
      lng: 125.6889,
      icon: '🧺',
    ),
    MapMarker(
      name: 'Fabric Rental',
      type: 'Uniform Rental',
      lat: 7.2933,
      lng: 125.6739,
      icon: '👕',
    ),
    MapMarker(
      name: 'Textile Hub',
      type: 'Fabric Store',
      lat: 7.3063,
      lng: 125.6839,
      icon: '🧵',
    ),
    MapMarker(
      name: 'Express Alteration',
      type: 'Alterations',
      lat: 7.2983,
      lng: 125.6789,
      icon: '✂️',
    ),
  ];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
        title: const Text(
          'Live Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () => Get.toNamed('/notifications'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Leaflet Map
          FlutterMap(
            key: ValueKey<String>('map_${_mapLat}_$_mapLng'),
            mapController: mapController,
            options: MapOptions(
              center: LatLng(_mapLat, _mapLng),
              zoom: 14,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: markers.map((marker) => Marker(
                    point: LatLng(marker.lat, marker.lng),
                    width: 80,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showMarkerDetails(marker),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1EDDAC),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                marker.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
              ),
            ],
          ),
          // Top Search Bar with Location Info - Collapsible
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              constraints: BoxConstraints(
                maxHeight: _showSearchSection ? 300 : 56,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1F2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: _showSearchSection 
                ? _buildSearchSection()
                : GestureDetector(
                    onTap: () => setState(() => _showSearchSection = true),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Color(0xFF1EDDAC), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mapLocation.length > 30
                                ? '${_mapLocation.substring(0, 30)}...'
                                : _mapLocation,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showEditPinDialog,
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF1EDDAC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
            ),
          ),
          // Zoom Controls on the Right
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B3F),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        mapController.move(
                          mapController.center,
                          mapController.zoom + 1,
                        );
                      },
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add,
                            color: Color(0xFF1EDDAC),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white12,
                  ),
                  // Zoom Out Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        mapController.move(
                          mapController.center,
                          mapController.zoom - 1,
                        );
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.remove,
                            color: Color(0xFF1EDDAC),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Current Location Button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1A2B3F),
              onPressed: () {
                mapController.move(
                  const LatLng(7.3014, 125.6810),
                  14,
                );
              },
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF1EDDAC),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A2B3F),
        elevation: 8,
        selectedItemColor: const Color(0xFF1EDDAC),
        unselectedItemColor: Colors.white54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 2, // Map tab
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Get.toNamed('/home');
              break;
            case 1:
              Get.toNamed('/discover');
              break;
            case 2:
              // Already on map
              break;
            case 3:
              Get.toNamed('/marketplace');
              break;
            case 4:
              Get.toNamed('/profile');
              break;
          }
        },
      ),
    );

  /// Build the expanded search section
  Widget _buildSearchSection() => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1EDDAC), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'SEARCH & EDIT LOCATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showSearchSection = false),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF1EDDAC),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search input field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search location or enter coordinates...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1EDDAC), size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.clear, color: Color(0xFF1EDDAC), size: 18),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A2B3F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _showEditPinDialog();
                }
              },
            ),
            const SizedBox(height: 12),
            // Current location display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B3F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mapLocation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lat: $_mapLat, Lng: $_mapLng',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditPinDialog,
                icon: const Icon(Icons.edit_location, size: 18),
                label: const Text('Edit Pin on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EDDAC),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  /// Show edit pin dialog with search functionality
  void _showEditPinDialog() {
    showDialog(
      context: context,
      builder: (context) => EditPinDialog(
          initialLat: _mapLat,
          initialLng: _mapLng,
          initialLocation: _mapLocation,
          onSave: (lat, lng, location) {
            setState(() {
              _mapLat = lat;
              _mapLng = lng;
              _mapLocation = location;
              _showSearchSection = false;
              _searchController.clear();
            });
            // Move map to the new location
            mapController.move(LatLng(lat, lng), 14);
          },
        ),
    );
  }

  void _showMarkerDetails(MapMarker marker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2B3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        marker.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marker.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          marker.type,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed('/shop-detail');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed('/booking');
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF1EDDAC),
                      side: const BorderSide(color: Color(0xFF1EDDAC)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class MapMarker {

  MapMarker({
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.icon,
  });
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String icon;
}
