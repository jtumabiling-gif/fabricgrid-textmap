import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../models/service_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_debug_service.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/service_service.dart';
import '../services/subscription_service.dart';
import '../utils/responsive_helper.dart';
import '../widgets/premium_badge_widget.dart';

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

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  int _selectedTabIndex = 0;
  late MapController mapController;
  String _selectedCategory = 'All';
  String _sortBy = 'Popular';
  double _mapLat = 7.3014;
  double _mapLng = 125.6810;
  bool _mapInitialized = false;
  final List<String> categories = [
    'All',
    'Cleaning',
    'Repair',
    'Tailoring',
    'Dyeing'
  ];

  // Settings
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool locationSharing = false;
  bool darkMode = false;

  // Products state
  late ProductService _productService;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoadingProducts = true;
  String _searchQuery = '';

  // Services state
  late ServiceService _serviceService;
  late ReviewService _reviewService;
  late SubscriptionService _subscriptionService;
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  bool _isLoadingServices = true;
  
  // Recommended shops state (Premium and Standard subscribers)
  List<Map<String, dynamic>> _recommendedShops = [];
  bool _isLoadingRecommendedShops = true;
  
  // Trending products state (most booked)
  List<Map<String, dynamic>> _trendingProducts = [];
  bool _isLoadingTrendingProducts = true;
  
  // User reviews state
  List<Map<String, dynamic>> _userReviews = [];
  bool _isLoadingUserReviews = true;
  double _userAverageRating = 0.0;
  
  // Cache for seller tier by shop name to avoid repeated queries
  final Map<String, String?> _sellerTierCache = {};

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
      lat: 7.0825,
      lng: 125.6200,
      icon: '🧺',
    ),
    MapMarker(
      name: 'Fabric Rental',
      type: 'Uniform Rental',
      lat: 7.0650,
      lng: 125.6050,
      icon: '👕',
    ),
    MapMarker(
      name: 'Textile Hub',
      type: 'Fabric Store',
      lat: 7.0780,
      lng: 125.6150,
      icon: '🧵',
    ),
    MapMarker(
      name: 'Express Alteration',
      type: 'Alterations',
      lat: 7.0700,
      lng: 125.6100,
      icon: '✂️',
    ),
  ];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _productService = ProductService();
    _serviceService = ServiceService();
    _reviewService = ReviewService();
    _subscriptionService = SubscriptionService();
    _initializeReviewService();
    _initializeProducts();
    _initializeServices();
    _loadTrendingProducts();
    _loadUserReviews();
    
    // Initialize Firebase debug service
    final debugService = FirebaseDebugService();
    debugService.initialize();
    debugService.listAllCollections();
  }
  
  Future<void> _initializeReviewService() async {
    try {
      await _reviewService.initialize();
    } catch (e) {
      print('=== Error initializing ReviewService: $e ===');
    }
  }
  
  void _initializeMapToDefaultLocation() {
    // Move map to default Panabo City location after a small delay to ensure map is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        mapController.move(
          const LatLng(7.3014, 125.6810),
          14,
        );
      }
    });
  }

  void _initializeServices() async {
    try {
      print('=== Initializing ServiceService ===');
      await _serviceService.initialize();
      await _loadServices();
    } catch (e) {
      print('=== Error initializing services: $e ===');
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _loadServices() async {
    try {
      final services = await _serviceService.getAllServices();
      
      // Fetch laundromat products to use their images for laundromat services
      Map<String, List<String>> categoryImageMap = {};
      try {
        final laundromats = await _productService.getProductsByCategory('Laundermats');
        final laundromatsImages = <String>[];
        for (final product in laundromats) {
          final imageUrls = product['imageUrls'] as List<dynamic>? ?? [];
          if (imageUrls.isNotEmpty) {
            laundromatsImages.addAll(imageUrls.cast<String>());
          }
        }
        if (laundromatsImages.isNotEmpty) {
          categoryImageMap['Laundermats'] = laundromatsImages;
        }
      } catch (e) {
        print('Error loading laundromat images: $e');
      }
      
      if (mounted) {
        // Fetch seller tier for each service by shop name
        final updatedServices = <Service>[];
        for (final service in services) {
          final shopName = service.shopOwnerName ?? '';
          final sellerTier = await _checkShopOwnerSellerTier(shopName);
          final isPremium = sellerTier == 'Premium'; // Set isPremium for backward compatibility
          
          // Use product images for services if available
          List<String> serviceImages = service.imageUrls;
          if (serviceImages.isEmpty && categoryImageMap.containsKey(service.category)) {
            serviceImages = categoryImageMap[service.category]!;
          }
          
          updatedServices.add(
            Service(
              id: service.id,
              shopOwnerId: service.shopOwnerId,
              serviceName: service.serviceName,
              category: service.category,
              price: service.price,
              description: service.description,
              estimatedTime: service.estimatedTime,
              expressDelivery: service.expressDelivery,
              homePickup: service.homePickup,
              materialIncluded: service.materialIncluded,
              status: service.status,
              createdAt: service.createdAt,
              location: service.location,
              imageUrl: service.imageUrl,
              imageUrls: serviceImages,
              updatedAt: service.updatedAt,
              shopOwnerName: service.shopOwnerName,
              isPremium: isPremium,
              sellerTier: sellerTier,
              shopOwnerRating: service.shopOwnerRating,
            ),
          );
        }
        
        setState(() {
          _services = updatedServices;
          _filteredServices = updatedServices;
          _isLoadingServices = false;
        });
      }
      print('=== Loaded ${services.length} services ===');
    } catch (e) {
      print('=== Error loading services: $e ===');
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  /// Get seller tier based on subscription plan name
  /// Returns 'Premium', 'Standard', or null
  Future<String?> _checkShopOwnerSellerTier(String shopName) async {
    // Return null if shop name is empty
    if (shopName.isEmpty) return null;
    
    // Check cache first
    if (_sellerTierCache.containsKey(shopName)) {
      return _sellerTierCache[shopName];
    }

    try {
      await _subscriptionService.initialize();
    _loadRecommendedShops();
      
      // Query subscriptions by shop name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('shopName', isEqualTo: shopName)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _sellerTierCache[shopName] = null;
        return null;
      }

      // Get the planName from subscription document
      final planName = querySnapshot.docs.first['planName'] as String?;
      print('=== Seller Tier for "$shopName": $planName ===');
      
      // Map planName to tier
      String? tier;
      if (planName != null) {
        final lowerPlan = planName.toLowerCase();
        if (lowerPlan.contains('premium')) {
          tier = 'Premium';
        } else if (lowerPlan.contains('standard')) {
          tier = 'Standard';
        }
      }
      
      _sellerTierCache[shopName] = tier;
      return tier;
    } catch (e) {
      print('Error checking seller tier for "$shopName": $e');
      _sellerTierCache[shopName] = null;
      return null;
    }
  }

  void _initializeProducts() async {
    try {
      print('=== Initializing ProductService ===');
      await _productService.initialize();
      print('=== ProductService initialized successfully ===');
      if (mounted) {
        _loadProducts();
      }
    } catch (e) {
      print('Error initializing ProductService: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing ProductService: $e')),
        );
      }
      
      // Show debug info
      final debugService = FirebaseDebugService();
      debugService.initialize();
      await debugService.listAllCollections();
    }
  }

  void _loadProducts() async {
    if (!mounted) return;
    print('=== Starting to load products ===');
    setState(() => _isLoadingProducts = true);
    try {
      var sortBy = 'createdAt';
      if (_sortBy == 'Price: Low to High') {
        sortBy = 'price_low_to_high';
      } else if (_sortBy == 'Price: High to Low') {
        sortBy = 'price_high_to_low';
      } else if (_sortBy == 'Popular') {
        sortBy = 'rating';
      }

      print('Loading products with sortBy=$sortBy');

      final products = await _productService.getAllProducts(
        sortBy: sortBy,
        limit: 100,
      );

      print('=== Successfully loaded ${products.length} products ===');
      
      // Fetch seller tier for each product by shop name
      final updatedProducts = <Map<String, dynamic>>[];
      for (final product in products) {
        print('Product: ${product['productName']} - \$${product['price']}');
        
        final shopName = product['shopOwnerName'] as String? ?? '';
        final sellerTier = shopName.isNotEmpty 
          ? await _checkShopOwnerSellerTier(shopName)
          : null;
        final isPremium = sellerTier == 'Premium'; // Set isPremium for backward compatibility
        
        final updatedProduct = {...product};
        updatedProduct['isPremium'] = isPremium;
        updatedProduct['sellerTier'] = sellerTier;
        updatedProducts.add(updatedProduct);
      }

      if (mounted) {
        setState(() {
          _products = _sortProductsWithBoosted(updatedProducts);
          _filterProducts();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('=== ERROR loading products: $e ===');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  /// Sort products with seller tier priority: Premium first, Standard second, Boosted third
  /// Display priority: Premium sellers > Standard sellers > Boosted items (isBoost: true) > Other items (isBoost: false)
  List<Map<String, dynamic>> _sortProductsWithBoosted(
    List<Map<String, dynamic>> products,
  ) {
    final premiumSellerProducts = <Map<String, dynamic>>[];
    final standardSellerProducts = <Map<String, dynamic>>[];
    final boostedProducts = <Map<String, dynamic>>[];
    final otherProducts = <Map<String, dynamic>>[];

    for (final product in products) {
      final sellerTier = product['sellerTier'] as String?;
      final isBoost = product['isBoost'] as bool? ?? false;

      if (sellerTier == 'Premium') {
        // Premium sellers come first
        premiumSellerProducts.add(product);
      } else if (sellerTier == 'Standard') {
        // Standard sellers come second
        standardSellerProducts.add(product);
      } else if (isBoost == true) {
        // Boosted items (isBoost: true) come third
        boostedProducts.add(product);
      } else {
        // Non-boosted items (isBoost: false) come last
        otherProducts.add(product);
      }
    }

    // Combine all lists: Premium first, then Standard, then Boosted, then others
    return [...premiumSellerProducts, ...standardSellerProducts, ...boostedProducts, ...otherProducts];
  }

  Future<void> _loadRecommendedShops() async {
    try {
      setState(() => _isLoadingRecommendedShops = true);

      // Get all active subscriptions to show as recommended shops
      final subscriptions = await _subscriptionService.getAllSubscriptions();
      final recommendedShops = <Map<String, dynamic>>[];

      // Include all active subscriptions (Premium, Standard, and any other active plans)
      for (final subscription in subscriptions) {
        final data = subscription.data()! as Map<String, dynamic>;
        final isActive = data['isActive'] as bool? ?? false;

        if (isActive) {
          final planName = data['planName'] as String? ?? 'Standard';
          recommendedShops.add({
            'id': subscription.id,
            'shopName': data['shopName'] ?? 'Unknown Shop',
            'shopDescription': data['shopDescription'] ?? '',
            'rating': (data['rating'] as num?)?.toDouble() ?? 4.5,
            'location': data['address'] ?? 'Panabo City, Davao del Norte',
            'planName': planName,
            'address': data['address'] ?? '',
            'shopOwnerId': data['shopOwnerId'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _recommendedShops = recommendedShops.take(6).toList(); // Show top 6
          _isLoadingRecommendedShops = false;
        });
      }
    } catch (e) {
      print('Error loading recommended shops: $e');
      if (mounted) {
        setState(() => _isLoadingRecommendedShops = false);
      }
    }
  }

  Future<void> _loadTrendingProducts() async {
    try {
      setState(() => _isLoadingTrendingProducts = true);

      // Get top 2 most booked products
      final trendingProducts = await _productService.getTopMostBookedProducts(limit: 2);

      if (mounted) {
        setState(() {
          _trendingProducts = trendingProducts;
          _isLoadingTrendingProducts = false;
        });
      }
    } catch (e) {
      print('Error loading trending products: $e');
      if (mounted) {
        setState(() => _isLoadingTrendingProducts = false);
      }
    }
  }

  Future<void> _loadUserReviews() async {
    try {
      setState(() => _isLoadingUserReviews = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          setState(() => _isLoadingUserReviews = false);
        }
        return;
      }

      // Get all reviews for the current user
      final reviews = await _reviewService.getUserReviews(userId);

      if (reviews.isNotEmpty) {
        // Calculate average rating
        final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / reviews.length;

        // Convert reviews to maps for display
        final reviewMaps = reviews.map((review) => {
          'id': review.id,
          'rating': review.rating,
          'reviewText': review.reviewText,
          'productName': review.productName,
          'shopOwnerName': review.shopOwnerName,
          'createdAt': review.createdAt,
          'tags': review.tags,
        }).toList();

        if (mounted) {
          setState(() {
            _userReviews = reviewMaps;
            _userAverageRating = averageRating;
            _isLoadingUserReviews = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userReviews = [];
            _userAverageRating = 0.0;
            _isLoadingUserReviews = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user reviews: $e');
      if (mounted) {
        setState(() => _isLoadingUserReviews = false);
      }
    }
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) => (product['productName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    // Apply sorting after filtering
    _filteredProducts = _sortMarketProducts(_filteredProducts);
  }

  /// Sort marketplace products based on the current sort preference
  List<Map<String, dynamic>> _sortMarketProducts(
      List<Map<String, dynamic>> products) {
    final sorted = List<Map<String, dynamic>>.from(products);
    
    switch (_sortBy) {
      case 'Popular':
        // Sort by rating (highest first)
        sorted.sort((a, b) {
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Newest':
        // Sort by creation date (newest first)
        sorted.sort((a, b) {
          final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'Price: Low to High':
        sorted.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      default:
        break;
    }
    
    return sorted;
  }

  void _filterDiscoverItems() {
    // Filter services and laundromat products based on search query and category
    var filteredServices = _services;
    var filteredProducts = _getLaundermatsProducts();

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredServices = filteredServices
          .where((service) => service.category == _selectedCategory)
          .toList();
      filteredProducts = filteredProducts
          .where((product) => (product['category'] ?? '') == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredServices = filteredServices
          .where((service) => service.serviceName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
      filteredProducts = filteredProducts
          .where((product) => (product['productName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sorting
    filteredServices = _sortServices(filteredServices);
    filteredProducts = _sortDiscoverProducts(filteredProducts);
    
    // Sort by seller tier: Premium > Standard > Others
    filteredServices = _sortServicesBySellerTier(filteredServices);
    filteredProducts = _sortDiscoverProductsBySellerTier(filteredProducts);

    setState(() {
      _filteredServices = filteredServices;
    });
  }

  /// Sort services based on the current sort preference
  List<Service> _sortServices(List<Service> services) {
    final sorted = List<Service>.from(services);
    
    switch (_sortBy) {
      case 'Popular':
        // Sort by rating (highest first)
        sorted.sort((a, b) => b.shopOwnerRating.compareTo(a.shopOwnerRating));
        break;
      case 'Newest':
        // Sort by creation date (newest first)
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Price: Low to High':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    
    return sorted;
  }

  /// Sort services by seller tier: Premium > Standard > Others
  List<Service> _sortServicesBySellerTier(List<Service> services) {
    final premiumServices = <Service>[];
    final standardServices = <Service>[];
    final otherServices = <Service>[];

    for (final service in services) {
      final sellerTier = service.sellerTier;
      if (sellerTier == 'Premium') {
        premiumServices.add(service);
      } else if (sellerTier == 'Standard') {
        standardServices.add(service);
      } else {
        otherServices.add(service);
      }
    }

    return [...premiumServices, ...standardServices, ...otherServices];
  }

  /// Sort discover products by seller tier: Premium > Standard > Others
  List<Map<String, dynamic>> _sortDiscoverProductsBySellerTier(
      List<Map<String, dynamic>> products) {
    final premiumProducts = <Map<String, dynamic>>[];
    final standardProducts = <Map<String, dynamic>>[];
    final otherProducts = <Map<String, dynamic>>[];

    for (final product in products) {
      final sellerTier = product['sellerTier'] as String?;
      if (sellerTier == 'Premium') {
        premiumProducts.add(product);
      } else if (sellerTier == 'Standard') {
        standardProducts.add(product);
      } else {
        otherProducts.add(product);
      }
    }

    return [...premiumProducts, ...standardProducts, ...otherProducts];
  }

  /// Sort discover products (laundermats) based on the current sort preference
  List<Map<String, dynamic>> _sortDiscoverProducts(
      List<Map<String, dynamic>> products) {
    final sorted = List<Map<String, dynamic>>.from(products);
    
    switch (_sortBy) {
      case 'Popular':
        // Sort by rating (highest first)
        sorted.sort((a, b) {
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Newest':
        // Sort by creation date (newest first)
        sorted.sort((a, b) {
          final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'Price: Low to High':
        sorted.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      default:
        break;
    }
    
    return sorted;
  }

  /// Get laundromat products from all products list
  List<Map<String, dynamic>> _getLaundermatsProducts() {
    return _products
        .where((product) => (product['category'] ?? '').toString() == 'Laundermats')
        .toList();
  }

  /// Build the discover items list (both services and laundromat products)
  Widget _buildDiscoverItemsList() {
    final laundermatsProducts = _getLaundermatsProducts();
    
    // Filter laundromat products based on search
    var filteredLaundermats = laundermatsProducts;
    if (_searchQuery.isNotEmpty) {
      filteredLaundermats = laundermatsProducts
          .where((product) => (product['productName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Sort laundromat products by seller tier
    filteredLaundermats = _sortDiscoverProductsBySellerTier(filteredLaundermats);
    
    // Also filter services by search
    var filteredServices = _filteredServices;
    if (_searchQuery.isNotEmpty) {
      filteredServices = _services
          .where((service) => service.serviceName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Sort services by seller tier
    filteredServices = _sortServicesBySellerTier(filteredServices);

    // Combine both lists
    final combinedCount = filteredServices.length + filteredLaundermats.length;

    if (combinedCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white30,
            ),
            SizedBox(height: 16),
            Text(
              'No services or laundermats found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getResponsiveGridCrossAxisCount(context),
        crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context),
        mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context),
        childAspectRatio: ResponsiveHelper.getResponsiveAspectRatio(context),
      ),
      itemCount: combinedCount,
      itemBuilder: (context, index) {
        // First show laundromat products, then services
        if (index < filteredLaundermats.length) {
          final product = filteredLaundermats[index];
          final productName = product['productName'] ?? 'Product';
          final price = product['price'] ?? 0.0;
          final isPremium = product['isPremium'] ?? false;

          return GestureDetector(
            onTap: () {
              // Convert laundromat product to Service for navigation
              final laundermatsService = Service(
                id: product['id'] ?? '',
                shopOwnerId: product['shopOwnerId'] ?? '',
                serviceName: product['productName'] ?? '',
                category: product['category'] ?? 'Laundermats',
                price: (product['price'] ?? 0.0).toDouble(),
                description: product['description'] ?? '',
                estimatedTime: '',
                expressDelivery: false,
                homePickup: false,
                materialIncluded: false,
                status: 'ACTIVE',
                createdAt: DateTime.now(),
                location: product['location'] ?? {},
                imageUrl: (product['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
                    ? (product['imageUrls'] as List<dynamic>).first as String
                    : null,
                imageUrls: (product['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
                shopOwnerName: product['shopOwnerName'],
                isPremium: isPremium,
              );
              Get.toNamed('/discover-service-detail', arguments: laundermatsService);
            },
            child: PremiumBorderWidget(
              isPremium: isPremium,
              child: Card(
                color: const Color(0xFF1A2B3F),
                elevation: 4,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: const Color(0xFF1EDDAC).withOpacity(0.2),
                            child: _buildMarketProductImage(product),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1EDDAC),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (product['stockQuantity'] != null)
                                    Text(
                                      '${product['stockQuantity']} Units',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Premium badge on top-right
                    if (isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1EDDAC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Show services
          final serviceIndex = index - filteredLaundermats.length;
          final service = filteredServices[serviceIndex];
          return GestureDetector(
            onTap: () => Get.toNamed(
              '/discover-service-detail',
              arguments: service,
            ),
            child: PremiumBorderWidget(
              isPremium: service.isPremium,
              child: Card(
                color: const Color(0xFF1A2B3F),
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: const Color(0xFF1EDDAC).withOpacity(0.2),
                            child: _buildServiceImage(service),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.serviceName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.category,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StreamBuilder<double>(
                                    stream: _reviewService.getShopOwnerAverageRatingStream(service.shopOwnerId),
                                    builder: (context, ratingSnapshot) {
                                      final rating = ratingSnapshot.data ?? 0.0;
                                      return StreamBuilder<int>(
                                        stream: _reviewService.getShopOwnerReviewCountStream(service.shopOwnerId),
                                        builder: (context, countSnapshot) {
                                          final reviewCount = countSnapshot.data ?? 0;
                                          return Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '($reviewCount)',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Text(
                                    '₱${service.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1EDDAC),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Premium/Standard badge on top-right
                    if (service.sellerTier != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: PremiumBadgeWidget(
                          sellerTier: service.sellerTier,
                          showDetails: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  String _getTabTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Discover';
      case 2:
        return 'Map';
      case 3:
        return 'Market';
      case 4:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(
            child: Icon(
              Icons.shopping_bag,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          _getTabTitle(),
          style: const TextStyle(
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
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A2B3F),
        elevation: 8,
        selectedItemColor: const Color(0xFF1EDDAC),
        unselectedItemColor: Colors.white54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedTabIndex,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
        },
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
      ),
    );

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildDiscoverTab();
      case 2:
        return _buildMapTab();
      case 3:
        return _buildMarketplaceTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ==================== HOME TAB ====================
  Widget _buildHomeTab() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final fullName = currentUser?.displayName ?? 'User';
    // Extract first name from full name
    final firstName = fullName.split(' ').first;

    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Text(
                  'Good morning, $firstName ',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      small: 20,
                      medium: 22,
                      large: 24,
                    ),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Text(
              'Ready to weave your day together?',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  small: 12,
                  medium: 13,
                  large: 14,
                ),
                color: Colors.white70,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
            // Featured Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1EDDAC), Color(0xFF16C896)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context).top),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.black87),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                      Text(
                        'NEARBY GIS MAP',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            small: 9,
                            medium: 10,
                            large: 11,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
                  Text(
                    'Find Textile Services\nNear You',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        small: 16,
                        medium: 18,
                        large: 20,
                      ),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                  Text(
                    'Discover products and laundries\nwithin of your current location.',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        small: 11,
                        medium: 12,
                        large: 13,
                      ),
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 1.5),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedTabIndex = 2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              small: 12,
                              medium: 13,
                              large: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                        const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 2),
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  small: 16,
                  medium: 17,
                  large: 18,
                ),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context),
              mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  icon: '🎛️',
                  title: 'FIND LAUNDERMATS',
                  onTap: () {
                    setState(() => _selectedTabIndex = 1);
                  },
                ),
                _buildActionCard(
                  icon: '👕',
                  title: 'RENT UNIFORM',
                  onTap: () {
                    setState(() => _selectedTabIndex = 3);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Recommended Shops Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended Shops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedTabIndex = 3);
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF1EDDAC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingRecommendedShops)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1EDDAC),
                ),
              )
            else if (_recommendedShops.isEmpty)
              const Text(
                'No recommended shops available',
                style: TextStyle(color: Colors.white70),
              )
            else
              ..._recommendedShops.take(2).map((shop) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecommendedShopCard(
                    name: shop['shopName'] as String,
                    type: shop['shopDescription'] as String? ?? 'Service Provider',
                    location: shop['location'] as String? ?? 'Panabo City, Davao del Norte',
                    rating: shop['rating'] as double,
                    planName: shop['planName'] as String,
                    onTap: () {
                      // Navigate to marketplace and let user explore shop's products
                      setState(() => _selectedTabIndex = 3);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 32),
            // Trending Section
            const Text(
              'Trending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingTrendingProducts)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1EDDAC),
                ),
              )
            else if (_trendingProducts.isEmpty)
              const Text(
                'No trending products available',
                style: TextStyle(color: Colors.white70),
              )
            else
              ..._trendingProducts.take(2).map((product) {
                final productName = product['productName'] as String? ?? 'Product';
                final shopOwnerName = product['shopOwnerName'] as String? ?? 'Shop Owner';
                final bookingCount = product['bookingCount'] as int? ?? 0;
                final price = product['price'] as num? ?? 0;
                final views = bookingCount * 5; // Approximate views based on bookings
                final imageUrl = (product['imageUrls'] as List<dynamic>?)?.firstOrNull as String?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to product details
                      Get.toNamed('/product-detail', arguments: product);
                    },
                    child: _buildTrendingCard(
                      title: productName,
                      subtitle: 'by $shopOwnerName',
                      likes: bookingCount,
                      views: views,
                      badge: 'MOST BOOKED',
                      price: '\₱${price.toStringAsFixed(2)}',
                      imageUrl: imageUrl,
                    ),
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==================== DISCOVER TAB ====================
  Widget _buildDiscoverTab() => Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterDiscoverItems();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search services & laundermats',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A2B3F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getLaundermatsProducts().length + _filteredServices.length} Items',
                style: const TextStyle(color: Colors.white70),
              ),
              DropdownButton<String>(
                value: _sortBy,
                dropdownColor: const Color(0xFF1A2B3F),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                      _filterDiscoverItems();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Popular', child: Text('Popular')),
                  DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                  DropdownMenuItem(
                      value: 'Price: Low to High',
                      child: Text('Price: Low to High')),
                  DropdownMenuItem(
                      value: 'Price: High to Low',
                      child: Text('Price: High to Low')),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
        Expanded(
          child: _isLoadingServices || _isLoadingProducts
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  ),
                )
              : _buildDiscoverItemsList(),
        ),
      ],
    );

  // ==================== MAP TAB ====================
  
  /// Get icon data based on category for map markers
  IconData _getIconForCategory(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('uniform')) {
      return Icons.checkroom; // Icon for uniform
    } else if (categoryLower.contains('eventwear')) {
      return Icons.style; // Icon for eventwear
    } else if (categoryLower.contains('launderm')) {
      return Icons.local_laundry_service; // Icon for laundermats
    }
    return Icons.shopping_bag; // Default icon
  }

  Widget _buildMapTab() {
    // Initialize map to default location when tab is first built
    if (!_mapInitialized) {
      _mapInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeMapToDefaultLocation();
      });
    }
    
    // Build markers from products and services
    final dynamicMarkers = <Marker>[];

    // Add product markers
    for (final product in _products) {
      try {
        final location = product['location'] as Map<String, dynamic>?;
        if (location != null) {
          final lat = location['latitude'] as double?;
          final lng = location['longitude'] as double?;

          if (lat != null && lng != null) {
            final category = (product['category'] as String?) ?? 'Other';
            final iconData = _getIconForCategory(category);
            
            dynamicMarkers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 80,
                height: 60,
                child: GestureDetector(
                  onTap: () => _showProductMarkerDetails(product),
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
                          child: Icon(
                            iconData,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing product location: $e');
      }
    }

    // Add service markers
    for (final service in _services) {
      try {
        final lat = service.location['latitude'] as double?;
        final lng = service.location['longitude'] as double?;

        if (lat != null && lng != null) {
          final iconData = _getIconForCategory(service.category);
          
          dynamicMarkers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 80,
              height: 60,
              child: GestureDetector(
                onTap: () => _showServiceMarkerDetails(service),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
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
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing service location: $e');
      }
    }

    return Stack(
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
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: dynamicMarkers.isNotEmpty ? dynamicMarkers : markers.map((marker) => Marker(
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
        // Marker Count Badge
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1F2F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '${dynamicMarkers.length} ${_products.isEmpty && _services.isEmpty ? 'markers' : 'locations'} found',
              style: const TextStyle(
                color: Color(0xFF1EDDAC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Map Controls (Zoom In/Out and Location)
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
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
                      color: Color(0xFF1A2B3F),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                width: 48,
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
                      color: Color(0xFF1A2B3F),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
              // Spacing between zoom and location button
              const SizedBox(height: 12),
              // Current Location Button
              FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF1A2B3F),
                onPressed: () {
                  mapController.move(
                    LatLng(_mapLat, _mapLng),
                    14,
                  );
                },
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MARKETPLACE TAB ====================
  Widget _buildMarketplaceTab() => Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterProducts();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A2B3F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredProducts.length} Products',
                style: const TextStyle(color: Colors.white70),
              ),
              DropdownButton<String>(
                value: _sortBy,
                dropdownColor: const Color(0xFF1A2B3F),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                      _filterProducts();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Popular', child: Text('Popular')),
                  DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                  DropdownMenuItem(
                      value: 'Price: Low to High',
                      child: Text('Price: Low to High')),
                  DropdownMenuItem(
                      value: 'Price: High to Low',
                      child: Text('Price: High to Low')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed('/list-item'),
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1EDDAC),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingProducts
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  ),
                )
              : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.white30,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _loadProducts,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1EDDAC),
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final debugService = FirebaseDebugService();
                                  debugService.initialize();
                                  await debugService.listAllCollections();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Debug info logged to console'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bug_report),
                                label: const Text('Debug'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: ResponsiveHelper.getResponsivePadding(context),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            ResponsiveHelper.getResponsiveGridCrossAxisCount(
                                context),
                        crossAxisSpacing:
                            ResponsiveHelper.getResponsiveGridSpacing(context),
                        mainAxisSpacing:
                            ResponsiveHelper.getResponsiveGridSpacing(context),
                        childAspectRatio:
                            ResponsiveHelper.getResponsiveAspectRatio(
                          context,
                          defaultRatio: 0.75,
                        ),
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final productName =
                            product['productName'] ?? 'Product';
                        final price = product['price'] ?? 0.0;
                        final isUserListing = product['isUserListing'] ?? false;
                        final isPremium = product['isPremium'] ?? false;
                        final sellerTier = product['sellerTier'] as String?;

                        return GestureDetector(
                          onTap: () =>
                              Get.toNamed('/product-detail', arguments: product),
                          child: PremiumBorderWidget(
                            isPremium: isPremium,
                            child: sellerTier == 'Standard'
                                ? Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF2196F3),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Card(
                                      color: const Color(0xFF1A2B3F),
                                      elevation: 4,
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 100,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          color: const Color(0xFF1EDDAC)
                                              .withOpacity(0.2),
                                        ),
                                        child: _buildMarketProductImage(product),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '₱${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1EDDAC),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Real-time rating and review count
                                            StreamBuilder<double>(
                                              stream: _reviewService
                                                  .getProductRatingByNameStream(
                                                      productName),
                                              initialData: 0,
                                              builder: (context, ratingSnapshot) => StreamBuilder<int>(
                                                  stream: _reviewService
                                                      .getProductReviewCountByNameStream(
                                                          productName),
                                                  initialData: 0,
                                                  builder:
                                                      (context, countSnapshot) {
                                                    final rating = ratingSnapshot
                                                            .data ??
                                                        0.0;
                                                    final reviewCount =
                                                        countSnapshot.data ?? 0;

                                                    return Row(
                                                      children: [
                                                        const Icon(Icons.star,
                                                            size: 12,
                                                            color:
                                                                Colors.amber),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                                                          style: const TextStyle(
                                                            color: Colors
                                                                .white70,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (product['stockQuantity'] != null)
                                              Text(
                                                '${product['stockQuantity']} Units',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Premium/Standard Badge (top-right)
                                  if (sellerTier != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: PremiumBadgeWidget(
                                        sellerTier: sellerTier,
                                        showDetails: false,
                                      ),
                                    )
                                  // User Listing Badge
                                  else if (isUserListing)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1EDDAC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Community',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                                    )
                                : Card(
                                    color: const Color(0xFF1A2B3F),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 100,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                                color: const Color(0xFF1EDDAC)
                                                    .withOpacity(0.2),
                                              ),
                                              child: _buildMarketProductImage(product),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    productName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '₱${price.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          color: Color(0xFF1EDDAC),
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Real-time rating and review count
                                                  StreamBuilder<double>(
                                                    stream: _reviewService
                                                        .getProductRatingByNameStream(
                                                            productName),
                                                    initialData: 0,
                                                    builder: (context, ratingSnapshot) => StreamBuilder<int>(
                                                        stream: _reviewService
                                                            .getProductReviewCountByNameStream(
                                                                productName),
                                                        initialData: 0,
                                                        builder:
                                                            (context, countSnapshot) {
                                                          final rating = ratingSnapshot
                                                                  .data ??
                                                              0.0;
                                                          final reviewCount =
                                                              countSnapshot.data ?? 0;

                                                          return Row(
                                                            children: [
                                                              const Icon(Icons.star,
                                                                  size: 12,
                                                                  color:
                                                                      Colors.amber),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                '${rating.toStringAsFixed(1)} ($reviewCount)',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (product['stockQuantity'] != null)
                                                    Text(
                                                      '${product['stockQuantity']} Units',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Premium/Standard Badge (top-right)
                                        if (sellerTier != null)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: PremiumBadgeWidget(
                                              sellerTier: sellerTier,
                                              showDetails: false,
                                            ),
                                          )
                                        // User Listing Badge
                                        else if (isUserListing)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1EDDAC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Community',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

  // ==================== PROFILE TAB ====================
  Widget _buildProfileTab() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final userName = currentUser?.displayName ?? 'User';
    final firstName = userName.split(' ').first;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1EDDAC).withOpacity(0.1),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1EDDAC),
                  ),
                  child: Center(
                    child: Text(
                      firstName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingUserReviews)
                  const CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  )
                else if (_userReviews.isEmpty)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_userAverageRating.toStringAsFixed(1)} (${_userReviews.length} ${_userReviews.length == 1 ? 'review' : 'reviews'})',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileListTile(
                  leading: const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFF1EDDAC)),
                  title: 'My Bookings',
                  onTap: () => Get.toNamed('/my-bookings'),
                ),
                _buildProfileListTile(
                  leading: const Icon(Icons.account_balance_wallet,
                      color: Color(0xFF1EDDAC)),
                  title: 'My Balance',
                  onTap: () => Get.toNamed('/user-balance'),
                ),
                _buildProfileListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Color(0xFF1EDDAC)),
                  title: 'User Profile Details',
                  onTap: () => Get.toNamed('/user-details'),
                ),
                _buildProfileListTile(
                  leading:
                      const Icon(Icons.help_outline, color: Color(0xFF1EDDAC)),
                  title: 'Help & Support',
                  onTap: _showComingSoonDialog,
                ),
                _buildProfileListTile(
                  leading: const Icon(Icons.settings_outlined,
                      color: Color(0xFF1EDDAC)),
                  title: 'Settings',
                  onTap: () => Get.toNamed('/settings-full'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildActionCard({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  small: 28,
                  medium: 30,
                  large: 32,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) / 2),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context) / 2,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    small: 9,
                    medium: 10,
                    large: 11,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildRecommendedShopCard({
    required String name,
    required String type,
    required String location,
    required double rating,
    required String planName,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1EDDAC), width: 1),
        ),
        padding: ResponsiveHelper.getResponsiveCardPadding(context),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(context,
                  small: 50, medium: 55, large: 60),
              height: ResponsiveHelper.getResponsiveIconSize(context,
                  small: 50, medium: 55, large: 60),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Colors.white30),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              small: 12,
                              medium: 13,
                              large: 14,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveSpacing(
                                  context) /
                              2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: planName == 'Premium'
                              ? Colors.amber.withOpacity(0.2)
                              : const Color(0xFF1EDDAC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          planName,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              small: 8,
                              medium: 9,
                              large: 10,
                            ),
                            fontWeight: FontWeight.w600,
                            color: planName == 'Premium'
                                ? Colors.amber
                                : const Color(0xFF1EDDAC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context) / 4,
                  ),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );

  Widget _buildTrendingCard({
    required String title,
    required String subtitle,
    required int likes,
    required int views,
    required String badge,
    String? price,
    String? imageUrl,
  }) => Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: Colors.white12,
            child: Stack(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1EDDAC),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.white12,
                      child: const Icon(Icons.image, color: Colors.white30, size: 60),
                    ),
                  )
                else
                  const Icon(Icons.image, color: Colors.white30, size: 60),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price != null)
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1EDDAC),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      '$likes Bookings',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.visibility,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      '$views Views',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildProfileListTile({
    required Widget leading,
    required String title,
    required VoidCallback onTap,
  }) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
      onTap: onTap,
    );

  /// Format location to show only up to province level, removing region
  String _formatLocationForDisplay(String address) {
    if (address.isEmpty) return 'Unknown Location';
    
    // Split address by commas
    final parts = address.split(',').map((e) => e.trim()).toList();
    
    // Find and remove region-level names (like "Davao Region", "Metro Manila Region", etc.)
    parts.removeWhere((part) => part.contains('Region'));
    
    // Return the remaining parts (up to province level)
    return parts.isNotEmpty ? parts.join(', ') : address;
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

  void _showProductMarkerDetails(Map<String, dynamic> product) {
    final productName = product['productName'] as String? ?? 'Product';
    final price = product['price'] as num? ?? 0;
    final category = product['category'] as String? ?? 'General';
    final shopOwnerName = product['shopOwnerName'] as String? ?? 'Shop Owner';
    final location = product['location'] as Map<String, dynamic>?;
    final address = location?['address'] as String? ?? 'Unknown Location';
    final formattedAddress = _formatLocationForDisplay(address);
    final iconData = _getIconForCategory(category);

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
                    child: Icon(
                      iconData,
                      size: 28,
                      color: const Color(0xFF1EDDAC),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1F2F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₱${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shop Owner:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        shopOwnerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formattedAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF1EDDAC),
                      side: const BorderSide(color: Color(0xFF1EDDAC)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed('/product-detail', arguments: product);
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceMarkerDetails(Service service) {
    final address = service.location['address'] as String? ?? 'Unknown Location';
    final iconData = _getIconForCategory(service.category);

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
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 28,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.category,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1F2F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₱${service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Est. Time:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        service.estimatedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shop Owner:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        service.shopOwnerName ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF1EDDAC),
                      side: const BorderSide(color: Color(0xFF1EDDAC)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to discover service detail screen with service data
                      Get.toNamed(
                        '/discover-service-detail',
                        arguments: service,
                      );
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature may be implemented in the future.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF1EDDAC)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketProductImage(Map<String, dynamic> product) {
    final imageUrls = product['imageUrls'] as List<dynamic>? ?? [];
    print('=== _buildMarketProductImage DEBUG ===');
    print('Product: ${product['productName']}');
    print('imageUrls raw: $imageUrls');
    print('imageUrls length: ${imageUrls.length}');
    if (imageUrls.isNotEmpty) {
      print('First URL: ${imageUrls[0]}');
    }
    
    if (imageUrls.isEmpty) {
      print('No images found, showing placeholder icon');
      return const Center(
        child: Icon(Icons.checkroom, size: 40, color: Color(0xFF1EDDAC)),
      );
    }

    final imageUrl = imageUrls[0] as String;
    print('Loading image from URL: $imageUrl');
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1EDDAC),
        ),
      ),
      errorWidget: (context, url, error) {
        print('Error loading image: $error');
        return const Center(
          child: Icon(Icons.checkroom, size: 40, color: Color(0xFF1EDDAC)),
        );
      },
    );
  }

  Widget _buildServiceImage(Service service) {
    // Try imageUrls first, then fall back to imageUrl
    final imageUrls = service.imageUrls.isNotEmpty
        ? service.imageUrls
        : (service.imageUrl != null && service.imageUrl!.isNotEmpty
            ? [service.imageUrl!]
            : []);

    if (imageUrls.isEmpty) {
      return Container(
        color: const Color(0xFF1EDDAC).withOpacity(0.2),
        child: const Center(
          child: Icon(
            Icons.local_laundry_service,
            size: 40,
            color: Color(0xFF1EDDAC),
          ),
        ),
      );
    }

    final imageUrl = imageUrls[0];

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
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
            size: 40,
            color: Color(0xFF1EDDAC),
          ),
        ),
      ),
    );
  }
}
