import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/review_model.dart';
import '../models/shop_owner_profile_model.dart';
import '../services/review_service.dart';
import '../services/shop_owner_service.dart';

class ShopOwnerDetailsScreen extends StatefulWidget {
  const ShopOwnerDetailsScreen({super.key});

  @override
  State<ShopOwnerDetailsScreen> createState() => _ShopOwnerDetailsScreenState();
}

class _ShopOwnerDetailsScreenState extends State<ShopOwnerDetailsScreen> {
  late ShopOwnerService _shopOwnerService;
  late ReviewService _reviewService;
  ShopOwnerProfile? _shopProfile;
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _ownerEmail;
  int _totalProducts = 0;
  int _totalBookings = 0;

  @override
  void initState() {
    super.initState();
    _shopOwnerService = ShopOwnerService();
    _reviewService = ReviewService();
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    try {
      await _shopOwnerService.initialize();
      await _reviewService.initialize();
      
      // Get shopOwnerId from arguments
      String shopOwnerId;
      final args = Get.arguments;
      if (args != null && args is Map<String, dynamic> && args.containsKey('shopOwnerId')) {
        shopOwnerId = args['shopOwnerId'] as String;
      } else {
        // Fallback to current user if no arguments provided
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw 'User not authenticated';
        }
        shopOwnerId = currentUser.uid;
      }

      // Get shop profile and reviews
      var profile = await _shopOwnerService.getShopOwnerProfile(shopOwnerId);
      
      // If profile doesn't exist, create it from auth data
      if (profile == null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _shopOwnerService.createShopOwnerProfile(
            email: currentUser.email ?? 'unknown@email.com',
            shopName: currentUser.displayName ?? 'My Shop',
            shopDescription: null,
            phone: null,
            address: null,
            latitude: 0,
            longitude: 0,
          );
          // Retry fetching the profile
          profile = await _shopOwnerService.getShopOwnerProfile(shopOwnerId);
        }
      }
      
      final reviews = await _reviewService.getShopOwnerReviews(shopOwnerId);
      
      // Get owner email from Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      final ownerEmail = currentUser?.email ?? 'N/A';
      
      // Fetch actual counts from Firestore collections
      final productCount = await _getProductCount(shopOwnerId);
      final bookingCount = await _getBookingCount(shopOwnerId);
      
      if (mounted) {
        setState(() {
          _shopProfile = profile;
          _reviews = reviews;
          _ownerEmail = ownerEmail;
          _totalProducts = productCount;
          _totalBookings = bookingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching shop details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shop details: $e')),
        );
      }
    }
  }

  Future<int> _getProductCount(String shopOwnerId) async {
    try {
      // Get product count
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();
      
      // Get service count
      final serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();
      
      final productCount = productSnapshot.count ?? 0;
      final serviceCount = serviceSnapshot.count ?? 0;
      
      return productCount + serviceCount;
    } catch (e) {
      print('Error fetching product count: $e');
      return 0;
    }
  }

  Future<int> _getBookingCount(String shopOwnerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error fetching booking count: $e');
      return 0;
    }
  }

  double _calculateAverageRating() {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (prev, review) => prev + review.rating);
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        title: const Text(
          'Shop Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchShopDetails,
            tooltip: 'Refresh statistics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShopHeader(),
                  const SizedBox(height: 24),
                  _buildShopInfoSection(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );

  Widget _buildShopHeader() {
    final avgRating = _calculateAverageRating();
    
    return Column(
      children: [
        if (_shopProfile?.shopImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _shopProfile!.shopImageUrl!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1EDDAC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (_shopProfile?.shopName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _shopProfile?.shopName ?? 'Unknown Shop',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _ownerEmail ?? 'N/A',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 18, color: Color(0xFFFFB84D)),
            const SizedBox(width: 4),
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_reviews.length} reviews)',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
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
      ],
    );
  }

  Widget _buildShopInfoSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Shop Name', _shopProfile?.shopName ?? 'N/A'),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow(
                'Email',
                _ownerEmail ?? 'N/A',
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow(
                'Member Since',
                _formatDate(_shopProfile?.createdAt),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildContactSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.email, size: 18, color: Color(0xFF1EDDAC)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _shopProfile?.email ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Color(0xFF1EDDAC)),
                  const SizedBox(width: 12),
                  Text(
                    _shopProfile?.phone ?? 'Not provided',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildStatsSection() {
    final avgRating = _calculateAverageRating();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Total Products',
              _totalProducts.toString(),
              Icons.shopping_bag,
            ),
            _buildStatCard(
              'Total Bookings',
              _totalBookings.toString(),
              Icons.calendar_today,
            ),
            _buildStatCard(
              'Rating',
              avgRating.toStringAsFixed(1),
              Icons.star,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

  Widget _buildInfoRow(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildReviewsSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.star_outline,
                  size: 48,
                  color: Colors.white30,
                ),
                SizedBox(height: 8),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewCard(review);
            },
          ),
      ],
    );

  Widget _buildReviewCard(Review review) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_outline,
                    size: 14,
                    color: const Color(0xFFFFB84D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.reviewText,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(review.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );

  void _showEditProfileDialog() {
    final shopNameController = TextEditingController(
      text: _shopProfile?.shopName ?? '',
    );
    final emailController = TextEditingController(
      text: _shopProfile?.email ?? '',
    );
    final phoneController = TextEditingController(
      text: _shopProfile?.phone ?? '',
    );
    var isLoading = false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: shopNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Shop Name',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1F2F),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1EDDAC),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1F2F),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1EDDAC),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: phoneController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF0F1F2F),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1EDDAC),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      final shopOwnerId =
                                          FirebaseAuth.instance.currentUser?.uid ?? '';

                                      // Update Firestore
                                      await FirebaseFirestore.instance
                                          .collection('shop_owners')
                                          .doc(shopOwnerId)
                                          .update({
                                        'shopName': shopNameController.text,
                                        'email': emailController.text,
                                        'phone': phoneController.text,
                                        'updatedAt': DateTime.now(),
                                      });

                                      // Update local state
                                      if (mounted) {
                                        setState(() {
                                          _shopProfile = ShopOwnerProfile(
                                            uid: shopOwnerId,
                                            shopName: shopNameController.text,
                                            email: emailController.text,
                                            phone: phoneController.text,
                                            shopDescription: _shopProfile?.shopDescription,
                                            shopImageUrl: _shopProfile?.shopImageUrl,
                                            address: _shopProfile?.address,
                                            latitude: _shopProfile?.latitude ?? 0,
                                            longitude: _shopProfile?.longitude ?? 0,
                                            createdAt: _shopProfile?.createdAt ?? DateTime.now(),
                                            updatedAt: DateTime.now(),
                                          );
                                        });

                                        Navigator.of(context).pop();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Profile updated successfully!',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error updating profile: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error updating profile: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    setDialogState(() {
                                      isLoading = false;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1EDDAC),
                              foregroundColor: Colors.black87,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black87,
                                      ),
                                    ),
                                  )
                                : const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
