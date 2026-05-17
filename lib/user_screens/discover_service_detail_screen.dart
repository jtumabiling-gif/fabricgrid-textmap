import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/service_model.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/shop_owner_service.dart';
import '../utils/responsive_helper.dart';

class DiscoverServiceDetailScreen extends StatefulWidget {
  const DiscoverServiceDetailScreen({super.key});

  @override
  State<DiscoverServiceDetailScreen> createState() =>
      _DiscoverServiceDetailScreenState();
}

class _DiscoverServiceDetailScreenState
    extends State<DiscoverServiceDetailScreen> {
  late Service _service;
  late ReviewService _reviewService;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  late PageController _imagePageController;
  List<String> _categoryImages = [];
  StreamSubscription<DocumentSnapshot>? _serviceListener;

  @override
  void initState() {
    super.initState();
    // Get the service from navigation arguments
    try {
      _service = Get.arguments as Service;
      _reviewService = ReviewService();
      _isLoading = false;
      _imagePageController = PageController();
      _loadCategoryImages();
      _initializeReviewService();
      
      // Fetch seller tier from subscription
      _fetchSellerTier();
      
      // Set up real-time listener for service status updates
      _setupServiceListener();
    } catch (e) {
      print('Error getting service from arguments: $e');
      _error = 'Failed to load service details';
      _isLoading = false;
    }
  }

  void _setupServiceListener() {
    try {
      final serviceId = _service.id;
      if (serviceId.isEmpty) return;

      _serviceListener = FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              final data = snapshot.data();
              if (data != null) {
                // Reconstruct service with updated data
                _service = Service.fromMap(data, serviceId);
                setState(() {});
                // Fetch seller tier when service is updated
                _fetchSellerTier();
              }
            }
          });
    } catch (e) {
      print('Error setting up service listener: $e');
    }
  }

  Future<void> _fetchSellerTier() async {
    try {
      final shopOwnerId = _service.shopOwnerId;
      if (shopOwnerId.isEmpty) return;

      // Query for active subscription
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isNotEmpty) {
        final planName = subscriptionQuery.docs.first['planName'] as String?;
        
        // Map planName to tier (Premium, Standard, or null)
        String? tier;
        if (planName == 'Premium') {
          tier = 'Premium';
        } else if (planName == 'Standard') {
          tier = 'Standard';
        }

        // Update service with seller tier
        if (tier != null) {
          setState(() {
            _service = Service(
              id: _service.id,
              shopOwnerId: _service.shopOwnerId,
              serviceName: _service.serviceName,
              category: _service.category,
              price: _service.price,
              description: _service.description,
              estimatedTime: _service.estimatedTime,
              expressDelivery: _service.expressDelivery,
              homePickup: _service.homePickup,
              materialIncluded: _service.materialIncluded,
              status: _service.status,
              imageUrl: _service.imageUrl,
              imageUrls: _service.imageUrls,
              location: _service.location,
              createdAt: _service.createdAt,
              updatedAt: _service.updatedAt,
              shopOwnerName: _service.shopOwnerName,
              isPremium: _service.isPremium,
              sellerTier: tier,
              shopOwnerRating: _service.shopOwnerRating,
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching seller tier: $e');
    }
  }

  Future<void> _initializeReviewService() async {
    try {
      await _reviewService.initialize();
    } catch (e) {
      print('Error initializing ReviewService: $e');
    }
  }

  Future<void> _loadCategoryImages() async {
    try {
      final productService = ProductService();
      await productService.initialize();
      
      final products = await productService.getProductsByCategory(_service.category);
      final images = <String>[];
      
      for (final product in products) {
        final imageUrls = product['imageUrls'] as List<dynamic>? ?? [];
        if (imageUrls.isNotEmpty) {
          images.addAll(imageUrls.cast<String>());
        }
      }
      
      if (mounted && images.isNotEmpty) {
        setState(() {
          _categoryImages = images;
        });
      }
    } catch (e) {
      print('Error loading category images: $e');
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _serviceListener?.cancel();
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
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: Get.back,
            ),
          ),
        ),
        title: const Text(
          'Service Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
      body: _buildBody(),
      bottomNavigationBar: _error == null
          ? Container(
              color: const Color(0xFF0F1F2F),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.toNamed('/book-service', arguments: _service);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EDDAC),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book Service',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1EDDAC),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image Carousel
          Stack(
            children: [
              Container(
                height: 280,
                width: double.infinity,
                color: Colors.white12,
                child: _buildImageCarousel(),
              ),
              // Image indicators
              if (_service.imageUrls.isNotEmpty && _service.imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _service.imageUrls.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? const Color(0xFF1EDDAC)
                                : Colors.white30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name
                Text(
                  _service.serviceName,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, small: 20, medium: 24, large: 28),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 3),
                // Rating and Stock Status
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    StreamBuilder<double>(
                      stream: _reviewService.getShopOwnerAverageRatingStream(_service.shopOwnerId),
                      builder: (context, ratingSnapshot) {
                        final rating = ratingSnapshot.data ?? 0.0;
                        return Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<int>(
                      stream: _reviewService.getShopOwnerReviewCountStream(_service.shopOwnerId),
                      builder: (context, countSnapshot) {
                        final count = countSnapshot.data ?? 0;
                        return Text(
                          '($count reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _service.status == 'ACTIVE'
                            ? const Color(0xFF1EDDAC).withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _service.status == 'ACTIVE' ? 'IN STOCK' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _service.status == 'ACTIVE'
                              ? const Color(0xFF1EDDAC)
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price
                Text(
                  '₱${_service.price.toStringAsFixed(2)} per service',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1EDDAC),
                  ),
                ),
                const SizedBox(height: 24),
                // Description
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _service.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                // Provider Info
                const Text(
                  'SERVICE PROVIDER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1EDDAC),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _service.shopOwnerName ?? 'Shop Owner',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            if (_service.shopOwnerId.isNotEmpty) {
                              _showServiceProviderModal(
                                context,
                                _service.shopOwnerId,
                                _service.shopOwnerName ?? 'Service Provider',
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Service provider information not available',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1EDDAC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Additional Details
                const Text(
                  'SERVICE DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1F2F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Estimated Time', _service.estimatedTime),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Category',
                        _service.category,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Express Delivery',
                        _service.expressDelivery ? 'Available' : 'Not Available',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Home Pickup',
                        _service.homePickup ? 'Available' : 'Not Available',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Material Included',
                        _service.materialIncluded ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );

  Widget _buildImageCarousel() {
    // Use imageUrls if available, otherwise fall back to single imageUrl
    var images = _service.imageUrls.isNotEmpty
        ? _service.imageUrls
        : (_service.imageUrl != null && _service.imageUrl!.isNotEmpty
            ? [_service.imageUrl!]
            : []);

    // If no service images, use category images
    if (images.isEmpty && _categoryImages.isNotEmpty) {
      images = _categoryImages;
    }

    // Use a default image if still no images
    final imagesToDisplay = images.isNotEmpty
        ? images
        : ['https://via.placeholder.com/400x600?text=Service'];

    if (imagesToDisplay.length == 1) {
      // Single image, no carousel needed
      return CachedNetworkImage(
        imageUrl: imagesToDisplay[0],
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1EDDAC),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1EDDAC).withOpacity(0.2),
          child: const Center(
            child: Icon(
              Icons.local_laundry_service,
              size: 80,
              color: Color(0xFF1EDDAC),
            ),
          ),
        ),
      );
    }

    // Multiple images, show carousel
    return PageView.builder(
      controller: _imagePageController,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemCount: imagesToDisplay.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: imagesToDisplay[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1EDDAC),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF1EDDAC).withOpacity(0.2),
            child: const Center(
              child: Icon(
                Icons.local_laundry_service,
                size: 80,
                color: Color(0xFF1EDDAC),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showServiceProviderModal(
    BuildContext context,
    String shopOwnerId,
    String shopOwnerName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ServiceProviderModal(
          shopOwnerId: shopOwnerId,
          shopOwnerName: shopOwnerName,
        ),
    );
  }
}

class ServiceProviderModal extends StatefulWidget {

  const ServiceProviderModal({
    required this.shopOwnerId,
    required this.shopOwnerName,
    super.key,
  });
  final String shopOwnerId;
  final String shopOwnerName;

  @override
  State<ServiceProviderModal> createState() => _ServiceProviderModalState();
}

class _ServiceProviderModalState extends State<ServiceProviderModal> {
  late ShopOwnerService _shopOwnerService;
  late ReviewService _reviewService;
  bool _isLoading = true;
  Map<String, dynamic> _providerData = {};
  double _providerRating = 0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _shopOwnerService = ShopOwnerService();
    _reviewService = ReviewService();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      await _shopOwnerService.initialize();
      await _reviewService.initialize();

      // Get ratings
      final rating = await _reviewService.getAverageRating(widget.shopOwnerId);
      final reviewCount = await _reviewService.getReviewCount(widget.shopOwnerId);

      // Get service and booking counts
      var serviceCount = 0;
      var bookingCount = 0;

      try {
        final serviceSnapshot = await FirebaseFirestore.instance
            .collection('services')
            .where('shopOwnerId', isEqualTo: widget.shopOwnerId)
            .count()
            .get();
        serviceCount = serviceSnapshot.count ?? 0;

        final bookingSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: widget.shopOwnerId)
            .count()
            .get();
        bookingCount = bookingSnapshot.count ?? 0;
      } catch (e) {
        print('Error fetching counts: $e');
      }

      if (mounted) {
        setState(() {
          _providerData = {
            'name': widget.shopOwnerName,
            'serviceCount': serviceCount,
            'bookingCount': bookingCount,
          };
          _providerRating = rating;
          _reviewCount = reviewCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading provider data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatarWithInitials(String name, {double size = 80}) {
    final initials = name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1EDDAC).withOpacity(0.7),
            const Color(0xFF0F4C75).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF1EDDAC),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Avatar
                  _buildAvatarWithInitials(_providerData['name'] ?? 'Provider'),
                  const SizedBox(height: 16),

                  // Provider Name
                  Text(
                    _providerData['name'] ?? 'Service Provider',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _providerRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1EDDAC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 14,
                            color: index < _providerRating.toInt()
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($_reviewCount reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1EDDAC).withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_providerData['serviceCount'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_providerData['bookingCount'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Bookings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message Provider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1EDDAC),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.white,
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
  }

