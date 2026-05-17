import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/subscription_limits.dart';
import '../services/product_service.dart';
import '../services/service_service.dart';
import 'shop_owner_add_product_screen.dart' show AddProductScreen;
import 'shop_owner_edit_product_screen.dart';
import 'shop_owner_subscription_screen.dart';

class ShopOwnerProductsScreen extends StatefulWidget {
  const ShopOwnerProductsScreen({super.key});

  @override
  State<ShopOwnerProductsScreen> createState() =>
      _ShopOwnerProductsScreenState();
}

class _ShopOwnerProductsScreenState extends State<ShopOwnerProductsScreen> {
  late ProductService _productService;
  late ServiceService _serviceService;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _totalItems = 0;
  int _publishedItemsCount = 0;
  Stream<QuerySnapshot>? _itemsStream;
  String _subscriptionTier = SubscriptionLimits.tierOrdinary;
  int _productLimit = SubscriptionLimits.ordinaryLimit;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _serviceService = ServiceService();
    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _initializeRealTimeUpdates();
  }

  Future<void> _initializeRealTimeUpdates() async {
    try {
      await _productService.initialize();
      await _serviceService.initialize();

      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Fetch subscription info FIRST before setting up streams
      await _fetchSubscriptionInfo();
      print('✅ Subscription info fetched during init');

      // Set up real-time stream for products
      _itemsStream = _firestore
          .collection('products')
          .where('shopOwnerId', isEqualTo: userId)
          .snapshots();

      // Listen to real-time updates
      _itemsStream!.listen((snapshot) {
        _updateItemsList();
      });

      // Initial load
      _updateItemsList();
    } catch (e) {
      print('Error in _initializeRealTimeUpdates: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing inventory: $e')),
        );
      }
    }
  }

  Future<void> _fetchSubscriptionInfo() async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        print('❌ No user ID found');
        return;
      }

      print('🔍 Fetching subscription for userId: $userId');

      // First, check ALL subscriptions for this user (without status filter, without orderBy to avoid needing index)
      final allSubscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('uid', isEqualTo: userId)
          .get();

      print('📊 Total subscriptions found: ${allSubscriptionsQuery.docs.length}');
      
      for (final doc in allSubscriptionsQuery.docs) {
        print('📄 Subscription doc: ${doc.data()}');
      }

      // Now check for active subscription (without orderBy to avoid index requirement)
      final subscriptionsQuery = await _firestore
          .collection('subscriptions')
          .where('uid', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      print('📊 Active subscriptions count: ${subscriptionsQuery.docs.length}');

      if (subscriptionsQuery.docs.isNotEmpty) {
        final subscription = subscriptionsQuery.docs.first.data();
        print('✅ Subscription found: ${subscription.toString()}');
        
        final planName = subscription['planName'] as String?;
        print('📋 Plan Name: $planName');
        
        final tier = SubscriptionLimits.getTierFromPlanName(planName);
        print('⭐ Tier: $tier');
        
        final limit = SubscriptionLimits.getLimitForTier(tier);
        print('🎯 Product Limit: $limit');
        
        if (mounted) {
          setState(() {
            _subscriptionTier = tier;
            _productLimit = limit;
          });
        }
        print('✅ Shop owner subscription tier: $tier, limit: $_productLimit');
      } else {
        print('⚠️ No active subscription found - using Ordinary tier');
        // No active subscription, use ordinary tier
        if (mounted) {
          setState(() {
            _subscriptionTier = SubscriptionLimits.tierOrdinary;
            _productLimit = SubscriptionLimits.ordinaryLimit;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching subscription info: $e');
      // Default to ordinary tier on error
      if (mounted) {
        setState(() {
          _subscriptionTier = SubscriptionLimits.tierOrdinary;
          _productLimit = SubscriptionLimits.ordinaryLimit;
        });
      }
    }
  }

  void _handleAddProduct() {
    // Check if limit is reached (for non-unlimited tiers)
    if (_productLimit != -1 && _totalItems >= _productLimit) {
      _showLimitReachedDialog();
      return;
    }

    // Limit not reached, proceed to add product
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    ).then((result) {
      // Refresh inventory if product was added
      if (result == true) {
        _updateItemsList();
      }
    });
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Listing Limit Reached',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have reached the maximum number of listings ($_totalItems/$_productLimit) for your $_subscriptionTier tier subscription.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to add more listings:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildUpgradeTierInfo(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF1EDDAC)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopOwnerSubscriptionScreen(),
                ),
              ).then((_) {
                // Refresh subscription info and inventory when returning
                _fetchSubscriptionInfo();
                _updateItemsList();
              });
            },
            child: const Text(
              'Upgrade Now',
              style: TextStyle(
                color: Color(0xFF1EDDAC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeTierInfo() {
    final String upgradeSuggestion;
    
    if (_subscriptionTier == SubscriptionLimits.tierOrdinary) {
      upgradeSuggestion = 'Standard: 15 listings (₱99/month)';
    } else if (_subscriptionTier == SubscriptionLimits.tierStandard) {
      upgradeSuggestion = 'Premium: Unlimited listings (₱199/month)';
    } else {
      upgradeSuggestion = 'You have unlimited listings';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1EDDAC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.3)),
      ),
      child: Text(
        upgradeSuggestion,
        style: const TextStyle(
          color: Color(0xFF1EDDAC),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> item) {
    final itemName = item['productName'] ?? 'Unknown Item';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Item',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$itemName"?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'This action will delete:\n• The product/service\n• All associated bookings\n• All ratings and reviews\n\nThis cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF1EDDAC)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
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
      final itemId = item['id'];
      final isService = item.containsKey('estimatedTime');

      if (isService) {
        // Delete service
        final serviceService = ServiceService();
        await serviceService.initialize();
        await serviceService.deleteService(itemId);
      } else {
        // Delete product with all associated data
        await _productService.deleteProduct(itemId);
      }

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      final successTitle = 'Success!';
      final successMessage = isService
          ? 'Service deleted successfully!'
          : 'Product and all associated data deleted successfully!';
      
      Get.snackbar(
        successTitle,
        successMessage,
        backgroundColor: const Color(0xFF1EDDAC),
        colorText: Colors.black87,
        duration: const Duration(seconds: 2),
      );

      // Refresh inventory
      _updateItemsList();
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

  Future<void> _updateItemsList() async {
    try {
      final products = await _productService.getShopOwnerProducts();
      final services = await _serviceService.getShopOwnerServices();

      print('=== Shop Owner Inventory ===');
      print('Fetched ${products.length} products');
      print('Fetched ${services.length} services');

      // Convert services to map format
      final servicesAsMap = services.map((service) => {
          'id': service.id,
          'productName': service.serviceName,
          'category': service.category,
          'price': service.price,
          'description': service.description,
          'status': service.status,
          'type': 'SERVICE',
          'estimatedTime': service.estimatedTime,
          'expressDelivery': service.expressDelivery,
          'homePickup': service.homePickup,
          'materialIncluded': service.materialIncluded,
          'imageUrls': service.imageUrls,
        }).toList();

      // Add type identifier to products
      final productsWithType = products.map((product) => {
          ...product,
          'type': _getCategoryType(product['category'] ?? 'Other'),
        }).toList();

      // Combine and sort
      final allItems = [...productsWithType, ...servicesAsMap];
      allItems.sort((a, b) {
        final nameA = (a['productName'] as String?)?.toLowerCase() ?? '';
        final nameB = (b['productName'] as String?)?.toLowerCase() ?? '';
        return nameA.compareTo(nameB);
      });

      // Count published items (status = AVAILABLE or ACTIVE)
      final publishedCount = allItems
          .where((item) {
            final status = (item['status'] as String?)?.toUpperCase() ?? '';
            return status == 'AVAILABLE' || status == 'ACTIVE';
          })
          .length;

      if (mounted) {
        setState(() {
          _allItems = allItems;
          _totalItems = allItems.length;
          _publishedItemsCount = publishedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _updateItemsList: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2B3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildAddOption(
              icon: Icons.shopping_bag,
              title: 'Add Product',
              subtitle: 'Add fabrics and items to inventory',
              onTap: () {
                Navigator.pop(context);
                _handleAddProduct();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1F2F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1EDDAC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1EDDAC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF1EDDAC),
                size: 16,
              ),
            ],
          ),
        ),
      );

  String _getCategoryType(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('fabric') || categoryLower.contains('textile')) {
      return 'FABRIC';
    } else if (categoryLower.contains('accessory') ||
        categoryLower.contains('accessories')) {
      return '👜 ACCESSORIES';
    } else if (categoryLower.contains('service')) {
      return '🔧 SERVICE';
    } else if (categoryLower.contains('product')) {
      return ' PRODUCT';
    }
    return '📌 OTHER';
  }

  Widget _buildPublishedItemsCard() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ITEMS PUBLISHED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_publishedItemsCount / $_totalItems',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _totalItems > 0 ? _publishedItemsCount / _totalItems : 0,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1EDDAC)),
            ),
          ),
        ],
      ),
    );

  List<Map<String, dynamic>> _getFilteredItems() {
    if (_searchQuery.isEmpty) {
      return _allItems;
    }
    return _allItems
        .where((item) =>
            (item['productName'] as String?)
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false)
        .toList();
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final title = item['productName'] ?? 'Unknown Item';
    final status = item['status'] ?? 'AVAILABLE';
    final price = item['price']?.toString() ?? '0';
    final category = item['category'] ?? 'General';
    final stock = item['stockQuantity']?.toString() ?? 'N/A';
    final isService = item.containsKey('estimatedTime');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(item),
            ),
          ),
          const SizedBox(height: 8),
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1EDDAC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1EDDAC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱$price',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (!isService)
                          Text(
                            '$stock units',
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
            ),
          ),
          const SizedBox(height: 6),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(product: item),
                      ),
                    ).then((result) {
                      // Refresh inventory if product was edited
                      if (result == true) {
                        _updateItemsList();
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1EDDAC),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size.fromHeight(28),
                  ),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog(item);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size.fromHeight(28),
                  ),
                  child: const Icon(Icons.delete, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MANAGEMENT PORTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'My Inventory',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildPublishedItemsCard(),
              const SizedBox(height: 24),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search name or category',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: const Icon(Icons.tune, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A2B3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  ),
                )
              else if (_allItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first product or service',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _getFilteredItems().length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(_getFilteredItems()[index]);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddOptions(context);
          },
          backgroundColor: const Color(0xFF1EDDAC),
          child: const Icon(Icons.add, color: Colors.black87, size: 28),
        ),
      );
  }

  /// Build product image widget with gallery support
  Widget _buildProductImage(Map<String, dynamic> item) {
    final imageUrls = item['imageUrls'] as List<dynamic>? ?? [];
    
    if (imageUrls.isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 60, color: Colors.white54),
      );
    }

    // If only one image, just display it
    if (imageUrls.length == 1) {
      final imageUrl = imageUrls[0] as String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1EDDAC),
            ),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.image, size: 60, color: Colors.white54),
          ),
        ),
      );
    }

    // Multiple images - show as carousel with indicator
    return StatefulBuilder(
      builder: (context, setState) {
        int currentImageIndex = 0;
        
        return Stack(
          children: [
            // Image carousel
            PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index] as String;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1EDDAC),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.white54),
                    ),
                  ),
                );
              },
            ),
            // Image counter
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${currentImageIndex + 1}/${imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

