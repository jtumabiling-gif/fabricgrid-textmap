import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/image_upload_service.dart';
import '../services/product_service.dart';
import '../widgets/edit_pin_dialog.dart';

class ListItemScreen extends StatefulWidget {
  const ListItemScreen({super.key});

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _sizeController;
  late TextEditingController _stockQuantityController;
  late MapController mapController;

  String _selectedCategory = 'Uniform';
  String _selectedLocation = 'Select location on map';
  double _selectedLat = 7.3014;
  double _selectedLng = 125.6810;
  bool _isLoading = false;
  bool _boostListing = false;

  // Image handling
  final ImageUploadService _imageUploadService = ImageUploadService();
  XFile? _selectedImage;
  bool _isUploadingImage = false;

  final List<String> _categories = [
    'Uniform',
    'Eventwear',
  ];

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _productNameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _sizeController = TextEditingController();
    _stockQuantityController = TextEditingController();
  }

  @override
  void dispose() {
    mapController.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  void _openLocationPicker() async {
    await showDialog<Map<String, dynamic>>(
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
            // Move map to the new location
            mapController.move(LatLng(lat, lng), 14);
          });
        },
      ),
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _productService.initialize();

      var price = double.tryParse(_priceController.text) ?? 0.0;
      
      // Apply 3% discount if boost listing is selected
      if (_boostListing) {
        price = price * 0.97; // 3% discount (multiply by 0.97)
      }

      // Upload image if selected
      List<String> imageUrls = [];
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        try {
          final imageUrl = await _imageUploadService.uploadImage(
            imageFile: _selectedImage!,
            folder: 'products',
            userId: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          imageUrls.add(imageUrl);
        } catch (e) {
          Get.snackbar(
            'Warning',
            'Image upload failed, publishing without image',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
        setState(() => _isUploadingImage = false);
      }

      // Add product to Firestore
      await _productService.addProduct(
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory,
        status: 'AVAILABLE',
        stockQuantity: int.tryParse(_stockQuantityController.text) ?? 1,
        sku: _sizeController.text.trim(),
        latitude: _selectedLat,
        longitude: _selectedLng,
        location: _selectedLocation,
        imageUrls: imageUrls,
        isBoost: _boostListing,
        size: _sizeController.text.trim(),
      );

      Get.snackbar(
        'Success',
        'Listing published successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1EDDAC),
        colorText: Colors.black87,
        duration: const Duration(seconds: 2),
      );

      // Reset form
      _formKey.currentState!.reset();
      _productNameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _sizeController.clear();
      _stockQuantityController.clear();
      setState(() {
        _selectedCategory = 'Uniform';
        _selectedLocation = 'Select location on map';
        _selectedLat = 7.3014;
        _selectedLng = 125.6810;
        _boostListing = false;
        _selectedImage = null;
      });

      // Navigate back to marketplace
      Get.toNamed('/marketplace');
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            'List a New Item',
            style: TextStyle(
              color: Color(0xFF1EDDAC),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                const Text(
                  'ITEM SPECIFICATIONS',
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
                    hintText: 'e.g. Organic Indigo Cotton Fabric',
                    hintStyle: const TextStyle(color: Colors.white38),
                    labelText: 'ITEM NAME',
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
                      return 'Item name is required';
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
                              items: _categories
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'Fabrics';
                                });
                              },
                              dropdownColor: const Color(0xFF1A2B3F),
                              isExpanded: true,
                              underline: const SizedBox(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                            'PRICE (Peso)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle:
                                  const TextStyle(color: Colors.white38),
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
                                return 'Invalid price';
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

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'DESCRIPTION',
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText:
                        'Describe the texture, material, and condition of your item...',
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
                const SizedBox(height: 16),

                // Size and Stock Quantity
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIZE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _sizeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. M, L, XL',
                              hintStyle:
                                  const TextStyle(color: Colors.white38),
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
                            controller: _stockQuantityController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '1',
                              hintStyle:
                                  const TextStyle(color: Colors.white38),
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
                                return 'Quantity is required';
                              }
                              if (int.tryParse(value!) == null) {
                                return 'Invalid quantity';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Image Upload Section
                _buildImageUploadSection(),
                const SizedBox(height: 24),

                // Boost Listing Section
                _buildBoostListingSection(),
                const SizedBox(height: 24),

                // Location Section
                _buildPickupLocationSection(),
                const SizedBox(height: 32),

                // Publish Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black87),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Publishing...',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch,
                                  color: Colors.black87, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Publish Listing',
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

  Widget _buildBoostListingSection() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.3)),
          color: const Color(0xFF1A2B3F),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rocket_launch, color: Color(0xFF1EDDAC), size: 20),
                SizedBox(width: 8),
                Text(
                  'BOOST YOUR LISTING',
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Boost Your Listing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get 3% discount on your listing price',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: _boostListing,
                    onChanged: (value) {
                      setState(() {
                        _boostListing = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF1EDDAC),
                    checkColor: Colors.black87,
                    side: const BorderSide(
                      color: Color(0xFF1EDDAC),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
            if (_boostListing) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF1EDDAC).withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF1EDDAC),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your listing will be boosted and get 3% discount on the listing price!',
                        style: TextStyle(
                          color: const Color(0xFF1EDDAC).withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                'SET ITEM LOCATION',
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
                  key: ValueKey<String>(
                      'map_${_selectedLat}_$_selectedLng'),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF1EDDAC),
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Map Controls
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openLocationPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B3F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF1EDDAC)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_location, color: Color(0xFF1EDDAC)),
                  SizedBox(width: 8),
                  Text(
                    'Pick Location on Map',
                    style: TextStyle(
                      color: Color(0xFF1EDDAC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _pickImage() async {
    try {
      final image = await _imageUploadService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildImageUploadSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image, color: Color(0xFF1EDDAC), size: 20),
              SizedBox(width: 8),
              Text(
                'ITEM IMAGE (1 MAX)',
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
          if (_selectedImage != null)
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1EDDAC), width: 2),
                    image: DecorationImage(
                      image: FileImage(File(_selectedImage!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1EDDAC),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  color: const Color(0xFF1A2B3F),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF1EDDAC),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Recommended: Clear product photo',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
