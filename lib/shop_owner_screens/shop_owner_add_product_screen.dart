import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../services/product_service.dart';
import '../services/service_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/edit_pin_dialog.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _estimatedTimeController;
  late MapController mapController;

  String _selectedCategory = 'Uniform';
  String _selectedStatus = 'AVAILABLE';
  String _selectedLocation = 'Panabo City, Davao del Norte, Philippines';
  double _selectedLat = 7.7333;
  double _selectedLng = 125.7667;

  // Image handling
  final ImageUploadService _imageUploadService = ImageUploadService();
  final List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  // Service-specific fields
  bool _expressDelivery = false;
  bool _homePickup = false;
  bool _materialIncluded = false;

  final List<String> _categories = [
    'Uniform',
    'Eventwear',
    'Laundermats',
    'Alteration Shop',
    'Tailor'
  ];

  final List<String> _statuses = ['AVAILABLE', 'OUT_OF_STOCK', 'DISCONTINUED'];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _productNameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _skuController = TextEditingController();
    _stockController = TextEditingController();
    _estimatedTimeController = TextEditingController();
  }

  @override
  void dispose() {
    mapController.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF1EDDAC)),
          ),
        ),
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Color(0xFF1EDDAC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRODUCT SPECIFICATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Product Name
              TextFormField(
                controller: _productNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Organic Indigo Cotton Roll',
                  hintStyle: const TextStyle(color: Colors.white38),
                  labelText: 'PRODUCT NAME',
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A2B3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category and Price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2B3F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            items: _categories.map((category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value ?? 'Uniform';
                              });
                            },
                            dropdownColor: const Color(0xFF1A2B3F),
                            isExpanded: true,
                            underline: const SizedBox(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRICE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixText: r'₱ ',
                            prefixStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A2B3F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Price is required';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status and Stock (only for products, not services and not laundermats)
              if (_selectedCategory != 'Services' && _selectedCategory != 'Laundermats' && _selectedCategory != 'Alteration Shop' && _selectedCategory != 'Tailor') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2B3F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              items: _statuses.map((status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value ?? 'AVAILABLE';
                                });
                              },
                              dropdownColor: const Color(0xFF1A2B3F),
                              isExpanded: true,
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STOCK QUANTITY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF1A2B3F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Stock is required';
                              }
                              if (int.tryParse(value!) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // SKU
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Size',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _skuController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. S, M, L, XL, 2XL',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1A2B3F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              // Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Describe the texture, weave, and origin of your product...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A2B3F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Set Pickup Location with Map UI
              _buildPickupLocationSection(),
              const SizedBox(height: 24),
              // Upload Product Imagery
              _buildImageUploadSection(),
              const SizedBox(height: 24),
              // Service-Specific Fields (shown only when Services or Laundermats category is selected)
              if (_selectedCategory == 'Services' || _selectedCategory == 'Laundermats' || _selectedCategory == 'Alteration Shop' || _selectedCategory == 'Tailor') ...[
                const Text(
                  'SERVICE DETAILS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATED TIME',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _estimatedTimeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., 2 hours, 1 day',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1A2B3F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if ((_selectedCategory == 'Services' || _selectedCategory == 'Laundermats' || _selectedCategory == 'Alteration Shop' || _selectedCategory == 'Tailor') && (value?.isEmpty ?? true)) {
                          return 'Estimated time is required for services';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Service Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2B3F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERVICE OPTIONS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Express Delivery',
                            style: TextStyle(color: Colors.white)),
                        value: _expressDelivery,
                        onChanged: (value) {
                          setState(() => _expressDelivery = value ?? false);
                        },
                        checkColor: Colors.black87,
                        activeColor: const Color(0xFF1EDDAC),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Home Pickup Available',
                            style: TextStyle(color: Colors.white)),
                        value: _homePickup,
                        onChanged: (value) {
                          setState(() => _homePickup = value ?? false);
                        },
                        checkColor: Colors.black87,
                        activeColor: const Color(0xFF1EDDAC),
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('Material Included',
                            style: TextStyle(color: Colors.white)),
                        value: _materialIncluded,
                        onChanged: (value) {
                          setState(() => _materialIncluded = value ?? false);
                        },
                        checkColor: Colors.black87,
                        activeColor: const Color(0xFF1EDDAC),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Publish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _publishProduct();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch,
                          color: Colors.black87, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Publish Product',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

  Widget _buildPickupLocationSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF1EDDAC), size: 20),
            SizedBox(width: 8),
            Text(
              'SET PICKUP LOCATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          height: 300,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Map
              FlutterMap(
                key: ValueKey<String>('map_${_selectedLat}_$_selectedLng'),
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(_selectedLat, _selectedLng),
                  zoom: 14,
                  minZoom: 10,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.fabricgrid.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_selectedLat, _selectedLng),
                        width: 120,
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1EDDAC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedLocation.length > 20
                                    ? '${_selectedLocation.substring(0, 20)}...'
                                    : _selectedLocation,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                              child: const Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                        offset: const Offset(0, 2),
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
                      Container(
                        height: 1,
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
              // Center Location Button
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF1A2B3F),
                  onPressed: () {
                    mapController.move(
                      const LatLng(35.6595, 139.7004),
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
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on,
                  color: Color(0xFF1EDDAC), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _showEditPinDialog,
                child: const Text(
                  'Edit Pin',
                  style: TextStyle(
                    color: Color(0xFF1EDDAC),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

  /// Show edit pin dialog
  void _showEditPinDialog() {
    showDialog(
      context: context,
      builder: (context) => EditPinDialog(
          initialLat: _selectedLat,
          initialLng: _selectedLng,
          initialLocation: _selectedLocation,
          onSave: (lat, lng, location) {
            setState(() {
              _selectedLat = lat;
              _selectedLng = lng;
              _selectedLocation = location;
            });
            // Move map to the new location
            mapController.move(LatLng(lat, lng), 14);
          },
        ),
    );
  }

  /// Publish product or service to Firebase
  Future<void> _publishProduct() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      
      final isService = _selectedCategory == 'Services' || _selectedCategory == 'Laundermats' || _selectedCategory == 'Alteration Shop' || _selectedCategory == 'Tailor';
      final loadingMessage = isService ? 'Publishing service...' : 'Publishing product...';
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
            backgroundColor: const Color(0xFF0F1F2F),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loadingMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      );

      // Upload images if any are selected
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          uploadedImageUrls = await _imageUploadService.uploadMultipleImages(
            imageFiles: _selectedImages,
            folder: isService ? 'services' : 'products',
            userId: _getCurrentUserId(),
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading images: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      if (isService) {
        // Create service
        final serviceService = ServiceService();
        await serviceService.initialize();

        await serviceService.createService(
          serviceName: _productNameController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim(),
          estimatedTime: _estimatedTimeController.text.trim(),
          expressDelivery: _expressDelivery,
          homePickup: _homePickup,
          materialIncluded: _materialIncluded,
          latitude: _selectedLat,
          longitude: _selectedLng,
          location: _selectedLocation,
          imageUrls: uploadedImageUrls,
        );
      } else {
        // Create product
        final productService = ProductService();
        await productService.initialize();

        await productService.addProduct(
          productName: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          status: _selectedStatus,
          stockQuantity: int.parse(_stockController.text.trim()),
          sku: _skuController.text.trim(),
          latitude: _selectedLat,
          longitude: _selectedLng,
          location: _selectedLocation,
          imageUrls: uploadedImageUrls,
          size: _skuController.text.trim(),
        );
      }

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      final successTitle = isService ? 'Success!' : 'Success!';
      final successMessage = isService
          ? 'Service published successfully!'
          : 'Product published successfully!';
      
      Get.snackbar(
        successTitle,
        successMessage,
        backgroundColor: const Color(0xFF1EDDAC),
        colorText: Colors.black87,
        duration: const Duration(seconds: 2),
      );

      // Navigate back after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Build image upload section with preview
  Widget _buildImageUploadSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'UPLOAD PRODUCT IMAGERY',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      // Image preview grid
      if (_selectedImages.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImages[index].path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
      // Upload button (show only if less than 1 image selected)
      if (_selectedImages.length < 1)
        GestureDetector(
          onTap: _isUploadingImages ? null : _pickImages,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                if (_isUploadingImages)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1EDDAC),
                    ),
                  )
                else
                  const Icon(Icons.image_outlined,
                      size: 48, color: Colors.white38),
                const SizedBox(height: 16),
                Text(
                  _selectedImages.isEmpty ? 'Upload Product Imagery' : 'Add More Images',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select high-resolution textures or product shots (Max 1 image)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EDDAC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedImages.isEmpty ? 'Choose Files' : 'Add Files (${_selectedImages.length}/2)',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Center(
            child: Text(
              'Maximum 1 image reached',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ),
        ),
    ],
  );

  /// Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final remainingSlots = 1 - _selectedImages.length;
      
      // Don't allow picking if max images reached
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 1 image reached'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final images = await _imageUploadService.pickMultipleImages(
        maxImages: remainingSlots,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get current user ID
  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'unknown_user';
  }
}
