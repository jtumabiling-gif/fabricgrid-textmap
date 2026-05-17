import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/product_service.dart';
import '../services/service_service.dart';
import '../services/image_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProductScreen extends StatefulWidget {

  const EditProductScreen({
    super.key,
    required this.product,
  });
  final Map<String, dynamic> product;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _estimatedTimeController;

  String _selectedCategory = 'Uniform';
  String _selectedStatus = 'AVAILABLE';

  // Service-specific fields
  bool _expressDelivery = false;
  bool _homePickup = false;
  bool _materialIncluded = false;

  // Image handling
  final ImageUploadService _imageUploadService = ImageUploadService();
  final List<XFile> _selectedNewImages = [];
  late List<String> _existingImageUrls;
  bool _isUploadingImages = false;

  final List<String> _categories = [
    'Uniform',
    'Eventwear',
    'Laundermats'
  ];

  final List<String> _statuses = ['AVAILABLE', 'OUT_OF_STOCK', 'DISCONTINUED'];

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _skuController = TextEditingController();
    _stockController = TextEditingController();
    _estimatedTimeController = TextEditingController();

    _initializeFromProduct();
  }

  void _initializeFromProduct() {
    final product = widget.product;
    
    _productNameController.text = product['productName'] ?? '';
    _priceController.text = (product['price'] ?? 0).toString();
    _descriptionController.text = product['description'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _stockController.text = (product['stockQuantity'] ?? 0).toString();
    _estimatedTimeController.text = product['estimatedTime'] ?? '';

    _selectedCategory = product['category'] ?? 'Uniform';
    _selectedStatus = product['status'] ?? 'AVAILABLE';

    // Service-specific fields
    _expressDelivery = product['expressDelivery'] ?? false;
    _homePickup = product['homePickup'] ?? false;
    _materialIncluded = product['materialIncluded'] ?? false;

    // Initialize existing images
    _existingImageUrls = List<String>.from(product['imageUrls'] ?? []);
  }

  @override
  void dispose() {
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
          'Edit Product',
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
              if (_selectedCategory != 'Services' && _selectedCategory != 'Laundermats') ...[
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
              
              // Image Upload Section
              _buildImageUploadSection(),
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
                      hintText: 'Describe your product or service in detail...',
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
              const SizedBox(height: 32),
              // Service-Specific Fields (shown only when Services or Laundermats category is selected)
              if (_selectedCategory == 'Services' || _selectedCategory == 'Laundermats') ...[
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
                        if ((_selectedCategory == 'Services' || _selectedCategory == 'Laundermats') && (value?.isEmpty ?? true)) {
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
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

  /// Build image upload section with preview
  Widget _buildImageUploadSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'PRODUCT IMAGERY',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      
      // Show existing images
      if (_existingImageUrls.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existing Images',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _existingImageUrls.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _existingImageUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1EDDAC),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image_not_supported, size: 32, color: Colors.white54),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _existingImageUrls.removeAt(index);
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
            const SizedBox(height: 12),
          ],
        ),
      
      // Show new images
      if (_selectedNewImages.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Images',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedNewImages.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedNewImages[index].path),
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
                          _selectedNewImages.removeAt(index);
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
            const SizedBox(height: 12),
          ],
        ),
      
      // Upload button (show only if total images < 1)
      if (_existingImageUrls.length + _selectedNewImages.length < 1)
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
                  _existingImageUrls.isEmpty && _selectedNewImages.isEmpty 
                      ? 'Upload Product Imagery' 
                      : 'Add More Images',
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
                    'Add Files (${_existingImageUrls.length + _selectedNewImages.length}/1)',
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
          child: Center(
            child: Text(
              'Maximum 1 image reached (${_existingImageUrls.length + _selectedNewImages.length}/1)',
              style: const TextStyle(
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
      final remainingSlots = 1 - (_existingImageUrls.length + _selectedNewImages.length);
      
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
          _selectedNewImages.addAll(images);
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1EDDAC),
        ),
      ),
    );

    try {
      final isService = _selectedCategory == 'Services' || _selectedCategory == 'Laundermats';
      final productId = widget.product['id'];

      // Prepare final image URLs list
      List<String> finalImageUrls = List<String>.from(_existingImageUrls);

      // Upload new images if any are selected
      if (_selectedNewImages.isNotEmpty) {
        try {
          final uploadedImageUrls = await _imageUploadService.uploadMultipleImages(
            imageFiles: _selectedNewImages,
            folder: isService ? 'services' : 'products',
            userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
          );
          finalImageUrls.addAll(uploadedImageUrls);
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
        // Update service
        final serviceService = ServiceService();
        await serviceService.initialize();

        await serviceService.updateService(
          serviceId: productId,
          serviceName: _productNameController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim(),
          estimatedTime: _estimatedTimeController.text.trim(),
          expressDelivery: _expressDelivery,
          homePickup: _homePickup,
          materialIncluded: _materialIncluded,
          imageUrls: finalImageUrls,
        );
      } else {
        // Update product
        final productService = ProductService();
        await productService.initialize();

        await productService.updateProduct(
          productId: productId,
          productName: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          status: _selectedStatus,
          stockQuantity: int.parse(_stockController.text.trim()),
          sku: _skuController.text.trim(),
          latitude: 7.7333, // Default location - could be enhanced later
          longitude: 125.7667,
          location: 'Panabo City, Davao del Norte, Philippines',
          imageUrls: finalImageUrls,
        );
      }

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      final successTitle = 'Success!';
      final successMessage = isService
          ? 'Service updated successfully!'
          : 'Product updated successfully!';
      
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
          Navigator.pop(context, true); // Return true to indicate data was updated
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
}
