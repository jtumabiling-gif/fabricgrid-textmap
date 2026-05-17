import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/subscription_limits.dart';
import '../services/review_service.dart';
import '../services/shop_owner_service.dart';
import '../utils/responsive_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic> _product = {};
  bool _isAvailable = true;
  double _shopOwnerRating = 0;
  int _reviewCount = 0;
  late ReviewService _reviewService;
  String _shopOwnerSubscriptionTier = 'Ordinary';
  double _commissionFee = 0;
  int _currentImageIndex = 0;
  late PageController _imagePageController;
  StreamSubscription<DocumentSnapshot>? _productListener;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService();
    _imagePageController = PageController();
    // Get product data from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _product = args;
    } else {
      // Fallback to default product data if none provided
      _product = {
        'productName': 'Product',
        'description': 'No description available',
        'price': 0.0,
        'category': 'General',
        'status': 'AVAILABLE',
        'stockQuantity': 0,
        'sku': 'N/A',
        'rating': 0.0,
        'reviewCount': 0,
      };
    }
    _isAvailable = (_product['status'] ?? 'AVAILABLE').toString().toUpperCase() == 'AVAILABLE';
    _fetchShopOwnerRating();
    
    // Set up real-time listener for product stock updates
    if (_product['id'] != null && _product['id'].toString().isNotEmpty) {
      _setupProductListener();
    }
  }

  void _setupProductListener() {
    try {
      final productId = _product['id'] as String?;
      if (productId == null || productId.isEmpty) return;

      _productListener = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              setState(() {
                final data = snapshot.data() as Map<String, dynamic>? ?? {};
                _product['stockQuantity'] = data['stockQuantity'] ?? 0;
                _product['status'] = data['status'] ?? 'AVAILABLE';
                _isAvailable = (_product['status'] ?? 'AVAILABLE').toString().toUpperCase() == 'AVAILABLE';
              });
            }
          });
    } catch (e) {
      print('Error setting up product listener: $e');
    }
  }

  Future<void> _fetchShopOwnerSubscriptionTier() async {
    try {
      final shopOwnerId = _product['shopOwnerId'] ?? '';
      if (shopOwnerId.isEmpty) return;

      final subscription = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      var tier = SubscriptionLimits.tierOrdinary;
      if (subscription.docs.isNotEmpty) {
        final planName = subscription.docs.first['planName'] as String?;
        tier = SubscriptionLimits.getTierFromPlanName(planName);
      }

      if (mounted) {
        setState(() {
          _shopOwnerSubscriptionTier = tier;
          _updateCommissionFee();
        });
      }
    } catch (e) {
      print('Error fetching subscription tier: $e');
    }
  }

  void _updateCommissionFee() {
    final basePrice = (_product['price'] ?? 0.0) as num;
    final totalPrice = basePrice.toDouble();
    _commissionFee = SubscriptionLimits.calculateCommissionFee(_shopOwnerSubscriptionTier, totalPrice);
  }

  Future<void> _fetchShopOwnerRating() async {
    try {
      await _reviewService.initialize();
      final shopOwnerId = _product['shopOwnerId'] ?? '';
      if (shopOwnerId.isNotEmpty) {
        final rating = await _reviewService.getAverageRating(shopOwnerId);
        final reviewCount = await _reviewService.getReviewCount(shopOwnerId);
        if (mounted) {
          setState(() {
            _shopOwnerRating = rating;
            _reviewCount = reviewCount;
          });
        }
      }
      // Fetch subscription tier after rating
      await _fetchShopOwnerSubscriptionTier();
    } catch (e) {
      print('Error fetching shop owner rating: $e');
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _productListener?.cancel();
    super.dispose();
  }

  Widget _buildProductImage() {
    // Try imageUrls first (from market screen), then fall back to imageUrl
    final imageUrls = _product['imageUrls'] as List<dynamic>? ?? [];
    final imageUrl = _product['imageUrl'] as String?;

    List<String> imagesToDisplay = [];
    if (imageUrls.isNotEmpty) {
      imagesToDisplay = imageUrls.cast<String>();
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imagesToDisplay = [imageUrl];
    }

    if (imagesToDisplay.isEmpty) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF1EDDAC).withOpacity(0.1),
        child: const Icon(
          Icons.checkroom,
          size: 80,
          color: Color(0xFF1EDDAC),
        ),
      );
    }

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
              Icons.checkroom,
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
                Icons.checkroom,
                size: 80,
                color: Color(0xFF1EDDAC),
              ),
            ),
          ),
        );
      },
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: IconButton(
                icon: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_outline,
                  color: _isFavorited ? Colors.red : const Color(0xFF1EDDAC),
                ),
                onPressed: () {
                  setState(() {
                    _isFavorited = !_isFavorited;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Status Badge
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.white12,
                  child: _buildProductImage(),
                ),
                // Image indicators
                if ((_product['imageUrls'] as List<dynamic>? ?? []).isNotEmpty && (_product['imageUrls'] as List<dynamic>).length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        (_product['imageUrls'] as List<dynamic>).length,
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
                // Status Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_product['status'] ?? 'AVAILABLE').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Size Badge
                if (_isAvailable)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1EDDAC).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF1EDDAC)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Size: ${_product['size'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
                  // Title
                  Text(
                    _product['productName'] ?? 'Product',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, small: 20, medium: 24, large: 28),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),

                  // Price and Status
                  Row(
                    children: [
                      Text(
                        '₱${(_product['price'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, small: 20, medium: 24, large: 28),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1EDDAC),
                        ),
                      ),
                      Text(
                        ' /day',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF1EDDAC), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        (_product['status'] ?? 'AVAILABLE').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1EDDAC).withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Commission Fee Info (if applicable)
                  if (_commissionFee > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1EDDAC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1EDDAC).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF1EDDAC), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Platform fee ($_shopOwnerSubscriptionTier): ₱${_commissionFee.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1EDDAC),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product['description'] ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seller/Shop Owner Info with Overall Rating
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1EDDAC).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF1EDDAC),
                              ),
                              child: const Icon(Icons.store,
                                  color: Colors.black87, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seller',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _product['shopOwnerName'] ?? 'Shop Owner',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1EDDAC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final shopOwnerId = _product['shopOwnerId'];
                                final isUserListing = _product['isUserListing'] ?? false;
                                
                                if (shopOwnerId != null && shopOwnerId.isNotEmpty) {
                                  _showSellerProfileModal(context, shopOwnerId, isUserListing);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Seller information not available'),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'VIEW PROFILE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1EDDAC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Rating',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      _shopOwnerRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1EDDAC),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRatingStars(_shopOwnerRating, size: 14),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '$_reviewCount review${_reviewCount != 1 ? 's' : ''}',
                              style: const TextStyle(
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

                  // Category and Stock Info
                  const Text(
                    'PRODUCT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1EDDAC),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF1EDDAC).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Category:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _product['category'] ?? 'General',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stock Quantity:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${_product['stockQuantity'] ?? 0} units',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                          ],
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
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0F1F2F),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAvailable 
                    ? () {
                        // Pass product to booking screen
                        Get.toNamed('/booking', arguments: {
                          ..._product,
                          'commissionFee': _commissionFee,
                          'subscriptionTier': _shopOwnerSubscriptionTier,
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EDDAC),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isAvailable ? 'Buy Now' : 'Not Available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildRatingStars(double rating, {double size = 16}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,
          size: size,
          color: index < rating.toInt() ? Colors.amber : Colors.grey[300],
        ),
      ),
    );

  void _showSellerProfileModal(BuildContext context, String shopOwnerId, bool isUserListing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SellerProfileModal(
          shopOwnerId: shopOwnerId,
          shopOwnerName: _product['shopOwnerName'] ?? 'Seller',
          isUserListing: isUserListing,
        ),
    );
  }
}

class SellerProfileModal extends StatefulWidget {

  const SellerProfileModal({
    required this.shopOwnerId,
    required this.shopOwnerName,
    required this.isUserListing,
    super.key,
  });
  final String shopOwnerId;
  final String shopOwnerName;
  final bool isUserListing;

  @override
  State<SellerProfileModal> createState() => _SellerProfileModalState();
}

class _SellerProfileModalState extends State<SellerProfileModal> {
  late ShopOwnerService _shopOwnerService;
  late ReviewService _reviewService;
  bool _isLoading = true;
  Map<String, dynamic> _sellerData = {};
  double _shopOwnerRating = 0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _shopOwnerService = ShopOwnerService();
    _reviewService = ReviewService();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    try {
      await _shopOwnerService.initialize();
      await _reviewService.initialize();

      // Get seller basic info
      final shopOwnerProfile = await _shopOwnerService.getShopOwnerProfile(widget.shopOwnerId);
      
      // Get ratings
      final rating = await _reviewService.getAverageRating(widget.shopOwnerId);
      final reviewCount = await _reviewService.getReviewCount(widget.shopOwnerId);

      // Get product and booking counts
      var productCount = 0;
      var bookingCount = 0;
      
      try {
        final productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('shopOwnerId', isEqualTo: widget.shopOwnerId)
            .count()
            .get();
        productCount = productSnapshot.count ?? 0;

        final bookingSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: widget.shopOwnerId)
            .count()
            .get();
        bookingCount = bookingSnapshot.count ?? 0;
      } catch (e) {
        print('Error fetching counts: $e');
      }

      // Get seller name from the product data passed
      var sellerName = widget.shopOwnerName;
      
      // Try to get from Firestore users collection for additional info if needed
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.shopOwnerId)
            .get();
        if (userDoc.exists) {
          final fetchedName = userDoc.data()?['displayName'] ?? userDoc.data()?['email'];
          if (fetchedName != null && fetchedName.isNotEmpty) {
            sellerName = fetchedName;
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }

      if (mounted) {
        setState(() {
          _sellerData = {
            'name': sellerName,
            'productCount': productCount,
            'bookingCount': bookingCount,
            'profile': shopOwnerProfile,
          };
          _shopOwnerRating = rating;
          _reviewCount = reviewCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading seller data: $e');
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
                  _buildAvatarWithInitials(_sellerData['name'] ?? 'Seller'),
                  const SizedBox(height: 16),

                  // Seller Name
                  Text(
                    _sellerData['name'] ?? 'Seller',
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
                        _shopOwnerRating.toStringAsFixed(1),
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
                            color: index < _shopOwnerRating.toInt()
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
                              '${_sellerData['productCount'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Products',
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
                              '${_sellerData['bookingCount'] ?? 0}',
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
