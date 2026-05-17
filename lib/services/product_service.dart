import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  static const String _imageFolder = 'products';

  factory ProductService() => _instance;

  ProductService._internal();
  static final ProductService _instance = ProductService._internal();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firestore
  Future<void> initialize() async {
    if (_isInitialized) {
      await _initCompleter.future;
      return;
    }

    try {
      _firestore = FirebaseFirestore.instance;
      _firebaseAuth = FirebaseAuth.instance;
      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Ensure Firestore is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Add a new product with location data to Firestore
  /// Returns the document ID of the newly created product
  Future<String> addProduct({
    required String productName,
    required String description,
    required double price,
    required String category,
    required String status,
    required int stockQuantity,
    required String sku,
    required double latitude,
    required double longitude,
    required String location,
    List<String> imageUrls = const [],
    bool isBoost = false,
    String? size,
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Get shop owner name from Firebase Auth displayName
      var shopOwnerName = _firebaseAuth.currentUser?.displayName ?? 'User';
      var shopOwnerRating = 0.0;
      var isUserListing = true; // Default to user listing
      
      print('Using seller name: $shopOwnerName');

      // Check if this is a shop owner by looking at user profile
      try {
        final userProfileDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        
        if (userProfileDoc.exists) {
          final userData = userProfileDoc.data();
          final userType = userData?['userType'] ?? 'USER';
          
          // If user is a SHOP_OWNER, try to get shop details
          if (userType == 'SHOP_OWNER') {
            isUserListing = false;
            
            // Try to get shop owner specific details
            try {
              final shopOwnerDoc = await _firestore
                  .collection('shop_owners')
                  .doc(userId)
                  .get();
              
              if (shopOwnerDoc.exists) {
                final shopOwnerData = shopOwnerDoc.data();
                final firebaseShopName = shopOwnerData?['shopName'];
                if (firebaseShopName != null && firebaseShopName.isNotEmpty) {
                  shopOwnerName = firebaseShopName;
                }
                shopOwnerRating = (shopOwnerData?['rating'] ?? 0.0).toDouble();
                print('Fetched shop owner details: $shopOwnerName, Rating: $shopOwnerRating');
              }
            } catch (e) {
              print('Warning: Could not fetch shop owner details: $e');
            }
          } else {
            // Regular user listing
            isUserListing = true;
            print('User type is $userType - marking as user listing');
          }
        } else {
          print('User profile not found, defaulting to user listing');
          isUserListing = true;
        }
      } catch (e) {
        print('Warning: Could not fetch user profile: $e - defaulting to user listing');
        isUserListing = true;
      }

      // Create the product data map
      final productData = {
        'productName': productName,
        'description': description,
        'price': price,
        'category': category,
        'status': status.toUpperCase(),
        'stockQuantity': stockQuantity,
        'sku': sku,
        'size': size,
        'imageUrls': imageUrls,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': location,
        },
        'shopOwnerId': userId,
        'shopOwnerName': shopOwnerName,
        'shopOwnerRating': shopOwnerRating,
        'isUserListing': isUserListing,
        'isBoost': isBoost,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Creating product with data: $productData (isUserListing: $isUserListing)');

      // Add product to Firestore under products collection
      final docRef =
          await _firestore.collection('products').add(productData);

      print('Product created successfully with ID: ${docRef.id}');
      
      // Update shop owner product count if not a user listing
      if (!isUserListing) {
        try {
          await _firestore
              .collection('shop_owners')
              .doc(userId)
              .update({
                'totalProducts': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          print('Warning: Could not update shop owner product count: $e');
        }
      }
      
      return docRef.id;
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      print('Exception: $e');
      throw 'Failed to add product: $e';
    }
  }

  /// Get all products for the current shop owner
  Future<List<Map<String, dynamic>>> getShopOwnerProducts() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      print('=== Fetching products for shop owner: $userId ===');

      // Fetch all products and filter in-memory (avoids composite index requirement)
      final snapshot = await _firestore
          .collection('products')
          .get();

      print('Total products in collection: ${snapshot.docs.length}');

      final products = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Filter for current shop owner's products
      final shopOwnerProducts = products
          .where((product) {
            final productShopOwnerId = product['shopOwnerId'];
            final matches = productShopOwnerId == userId;
            print('Product ${product['productName']} - shopOwnerId: $productShopOwnerId - matches: $matches');
            return matches;
          })
          .toList();

      print('Filtered products for current owner: ${shopOwnerProducts.length}');

      // Sort by createdAt descending
      shopOwnerProducts.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      return shopOwnerProducts;
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.message}');
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      print('Error fetching products: $e');
      throw 'Failed to retrieve products: $e';
    }
  }

  /// Update an existing product
  Future<void> updateProduct({
    required String productId,
    required String productName,
    required String description,
    required double price,
    required String category,
    required String status,
    required int stockQuantity,
    required String sku,
    required double latitude,
    required double longitude,
    required String location,
    List<String> imageUrls = const [],
  }) async {
    await _ensureInitialized();

    try {
      final updateData = {
        'productName': productName,
        'description': description,
        'price': price,
        'category': category,
        'status': status,
        'stockQuantity': stockQuantity,
        'sku': sku,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': location,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update imageUrls if provided
      if (imageUrls.isNotEmpty) {
        updateData['imageUrls'] = imageUrls;
      }

      await _firestore.collection('products').doc(productId).update(updateData);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update product: $e';
    }
  }

  /// Delete a product and all associated bookings and ratings
  Future<void> deleteProduct(String productId) async {
    await _ensureInitialized();

    try {
      // Delete all bookings associated with this product
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('productId', isEqualTo: productId)
          .get();
      
      for (final bookingDoc in bookingsQuery.docs) {
        await bookingDoc.reference.delete();
      }

      // Delete all ratings associated with this product
      final ratingsQuery = await _firestore
          .collection('ratings')
          .where('productId', isEqualTo: productId)
          .get();
      
      for (final ratingDoc in ratingsQuery.docs) {
        await ratingDoc.reference.delete();
      }

      // Delete the product itself
      await _firestore.collection('products').doc(productId).delete();
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to delete product: $e';
    }
  }

  /// Get a single product by ID
  Future<Map<String, dynamic>> getProduct(String productId) async {
    await _ensureInitialized();

    try {
      final doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw 'Product not found';
      }

      return {...doc.data()!, 'id': doc.id};
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve product: $e';
    }
  }

  /// Get ALL products without filtering (for debugging)
  Future<List<Map<String, dynamic>>> getAllProductsRaw({
    String? sortBy = 'createdAt',
    bool descending = true,
    int limit = 100,
  }) async {
    await _ensureInitialized();

    try {
      // Fetch all products without any filters
      var query = _firestore.collection('products') as Query<Map<String, dynamic>>;

      // Apply sorting
      try {
        if (sortBy == 'price_low_to_high') {
          query = query.orderBy('price', descending: false);
        } else if (sortBy == 'price_high_to_low') {
          query = query.orderBy('price', descending: true);
        } else if (sortBy == 'rating') {
          query = query.orderBy('rating', descending: true);
        } else {
          query = query.orderBy('createdAt', descending: descending);
        }
      } catch (e) {
        // If orderBy fails, just continue without ordering
        print('Error applying order: $e');
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      print('Found ${snapshot.docs.length} total products in Firestore');

      final products = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {...data, 'id': doc.id};
          })
          .toList();

      return products;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve products: $e';
    }
  }

  /// Get all available products (for marketplace)
  Future<List<Map<String, dynamic>>> getAllProducts({
    String? sortBy = 'createdAt',
    bool descending = true,
    int limit = 100,
  }) async {
    await _ensureInitialized();

    try {
      print('=== ProductService.getAllProducts called with sortBy=$sortBy ===');
      
      // Fetch all products without any filtering
      // This will include both shop owner products and user listings
      final query = _firestore.collection('products').limit(limit);
      
      print('Executing Firestore query...');
      final snapshot = await query.get();
      
      print('Query returned ${snapshot.docs.length} documents');

      // Convert to list with logging
      final allProducts = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        allProducts.add({...data, 'id': doc.id});
        final isUserListing = data['isUserListing'] ?? false;
        final productType = isUserListing ? 'USER LISTING' : 'SHOP PRODUCT';
        print('Raw document: ${data['productName']} - type: $productType - status: ${data['status']} - stock: ${data['stockQuantity']}');
      }

      // Filter locally to get only available products with stock
      // This includes both shop owner products AND user listings
      final products = allProducts.where((product) {
        final status = (product['status'] ?? 'available').toString().toUpperCase();
        final stockQuantity = product['stockQuantity'] ?? 1;
        final isAvailable = status == 'AVAILABLE' && stockQuantity > 0;
        
        if (!isAvailable) {
          final isUserListing = product['isUserListing'] ?? false;
          final productType = isUserListing ? 'USER LISTING' : 'SHOP PRODUCT';
          print('Filtering out: ${product['productName']} - type: $productType (status: $status, stock: $stockQuantity)');
        }
        return isAvailable;
      }).toList();

      print('After filtering: ${products.length} products available (includes user listings and shop products)');

      // Now apply sorting on filtered results
      try {
        if (sortBy == 'price_low_to_high') {
          products.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        } else if (sortBy == 'price_high_to_low') {
          products.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        } else if (sortBy == 'rating') {
          products.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        } else {
          // Sort by createdAt
          products.sort((a, b) {
            final aDate = a['createdAt'] as dynamic;
            final bDate = b['createdAt'] as dynamic;
            if (aDate == null || bDate == null) return 0;
            return descending ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
          });
        }
        print('Applied sorting: $sortBy');
      } catch (e) {
        print('Warning: Could not apply sort $sortBy: $e');
      }

      print('=== Returning ${products.length} products (user listings + shop products) ===');
      return products;
    } on FirebaseException catch (e) {
      print('Firebase Error: ${e.message} (code: ${e.code})');
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      print('General Error in getAllProducts: $e');
      throw 'Failed to retrieve products: $e';
    }
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
      String category) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter locally
      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((product) {
            final status = product['status'] ?? 'AVAILABLE';
            final stockQuantity = product['stockQuantity'] ?? 0;
            return status == 'AVAILABLE' && stockQuantity > 0;
          })
          .toList();
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve products: $e';
    }
  }

  /// Search products by name or description
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    await _ensureInitialized();

    try {
      final queryLower = query.toLowerCase();

      // Get all products first
      final snapshot = await _firestore
          .collection('products')
          .get();

      // Filter locally by name, description, and availability
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status'] ?? 'AVAILABLE';
            final stockQuantity = data['stockQuantity'] ?? 0;
            
            return status == 'AVAILABLE' && stockQuantity > 0;
          })
          .where((doc) {
            final data = doc.data();
            final productName = (data['productName'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            return productName.contains(queryLower) || description.contains(queryLower);
          })
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to search products: $e';
    }
  }

  /// Get the count of active products for a shop owner
  /// Only counts products with status 'AVAILABLE'
  Future<int> getActiveProductCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('status', isEqualTo: 'AVAILABLE')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Firebase error counting products: ${e.message}');
      return 0;
    } catch (e) {
      print('Error counting products: $e');
      return 0;
    }
  }

  /// Get the total count of all products (including inactive) for a shop owner
  Future<int> getTotalProductCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Firebase error counting products: ${e.message}');
      return 0;
    } catch (e) {
      print('Error counting products: $e');
      return 0;
    }
  }

  /// Get the count of active services for a shop owner (from services collection)
  /// Only counts services with status 'ACTIVE'
  Future<int> getActiveServiceCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('services')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('status', isEqualTo: 'ACTIVE')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Firebase error counting services: ${e.message}');
      return 0;
    } catch (e) {
      print('Error counting services: $e');
      return 0;
    }
  }

  /// Get the total count of all services for a shop owner
  Future<int> getTotalServiceCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('services')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Firebase error counting services: ${e.message}');
      return 0;
    } catch (e) {
      print('Error counting services: $e');
      return 0;
    }
  }

  /// Get the combined count of active products and services for a shop owner
  /// This is the count used for subscription limits
  Future<int> getCombinedActiveListingCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final productCount = await getActiveProductCount(shopOwnerId);
      final serviceCount = await getActiveServiceCount(shopOwnerId);
      return productCount + serviceCount;
    } catch (e) {
      print('Error getting combined listing count: $e');
      return 0;
    }
  }

  /// Get the top N most booked products based on booking collection
  Future<List<Map<String, dynamic>>> getTopMostBookedProducts({int limit = 2}) async {
    await _ensureInitialized();

    try {
      print('=== Fetching top $limit most booked products ===');

      // Get all bookings grouped by product
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .get();

      // Count bookings by productId
      final bookingCounts = <String, int>{};
      for (final bookingDoc in bookingsSnapshot.docs) {
        final productId = bookingDoc['productId'] as String?;
        if (productId != null && productId.isNotEmpty) {
          bookingCounts[productId] = (bookingCounts[productId] ?? 0) + 1;
        }
      }

      // Sort product IDs by booking count (descending)
      final sortedProductIds = bookingCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      // Fetch top products
      final topProducts = <Map<String, dynamic>>[];
      for (int i = 0; i < sortedProductIds.length && i < limit; i++) {
        final productId = sortedProductIds[i].key;
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            final data = productDoc.data() as Map<String, dynamic>;
            final bookingCount = bookingCounts[productId] ?? 0;
            data['id'] = productDoc.id;
            data['bookingCount'] = bookingCount;
            topProducts.add(data);
          }
        } catch (e) {
          print('Error fetching product $productId: $e');
        }
      }

      print('=== Found ${topProducts.length} top booked products ===');
      return topProducts;
    } catch (e) {
      print('Error fetching top booked products: $e');
      return [];
    }
  }
}
