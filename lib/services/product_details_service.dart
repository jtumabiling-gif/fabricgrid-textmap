import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/shop_owner_profile_model.dart';
import '../models/user_profile_model.dart';

class ProductDetailsService {
  factory ProductDetailsService() => _instance;

  ProductDetailsService._internal();
  static final ProductDetailsService _instance =
      ProductDetailsService._internal();
  late FirebaseFirestore _firestore;
  bool _isInitialized = false;

  /// Initialize Firestore
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Ensure Firestore is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get product with seller details (shop owner or user)
  /// Returns a map containing product, shop owner (if seller is shop owner), and user details
  Future<Map<String, dynamic>> getProductWithSellerDetails({
    required String productId,
  }) async {
    await _ensureInitialized();

    try {
      // Fetch product
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw 'Product not found';
      }

      final productData = productDoc.data();
      if (productData == null) {
        throw 'Product data is empty';
      }
      final product = Product.fromMap(productData, productId);
      final shopOwnerId = product.shopOwnerId;

      // Fetch seller's user profile
      final userProfileDoc =
          await _firestore.collection('users').doc(shopOwnerId).get();

      UserProfile? userProfile;
      if (userProfileDoc.exists) {
        userProfile = UserProfile.fromMap(userProfileDoc.data()!);
      }

      // If seller is a shop owner, fetch shop owner profile
      ShopOwnerProfile? shopOwnerProfile;
      if (userProfile?.userType == 'SHOP_OWNER') {
        final shopOwnerDoc =
            await _firestore.collection('shop_owners').doc(shopOwnerId).get();

        if (shopOwnerDoc.exists) {
          shopOwnerProfile = ShopOwnerProfile.fromMap(shopOwnerDoc.data()!);
        }
      }

      return {
        'product': product,
        'userProfile': userProfile,
        'shopOwnerProfile': shopOwnerProfile,
        'isShopOwner': userProfile?.userType == 'SHOP_OWNER',
      };
    } catch (e) {
      throw 'Error fetching product details: $e';
    }
  }

  /// Get product by name and shop owner name
  /// Returns a map containing product, shop owner, and user details
  Future<Map<String, dynamic>> getProductByNameAndShopOwnerName({
    required String productName,
    required String shopOwnerName,
  }) async {
    await _ensureInitialized();

    try {
      // First, find the shop owner by name
      final shopOwnersQuery = await _firestore
          .collection('shop_owners')
          .where('shopName', isEqualTo: shopOwnerName)
          .limit(1)
          .get();

      if (shopOwnersQuery.docs.isEmpty) {
        throw 'Shop owner with name "$shopOwnerName" not found';
      }

      final shopOwnerId = shopOwnersQuery.docs.first.id;
      final shopOwnerData = shopOwnersQuery.docs.first.data();
      final shopOwnerProfile = ShopOwnerProfile.fromMap(shopOwnerData);

      // Now find the product by name and shop owner ID
      final productsQuery = await _firestore
          .collection('products')
          .where('productName', isEqualTo: productName)
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .limit(1)
          .get();

      if (productsQuery.docs.isEmpty) {
        throw 'Product with name "$productName" from shop owner "$shopOwnerName" not found';
      }

      final productDoc = productsQuery.docs.first;
      final product = Product.fromMap(productDoc.data(), productDoc.id);

      // Fetch user profile
      final userProfileDoc =
          await _firestore.collection('users').doc(shopOwnerId).get();

      UserProfile? userProfile;
      if (userProfileDoc.exists) {
        userProfile = UserProfile.fromMap(userProfileDoc.data()!);
      }

      return {
        'product': product,
        'userProfile': userProfile,
        'shopOwnerProfile': shopOwnerProfile,
        'isShopOwner': true,
      };
    } catch (e) {
      throw 'Error fetching product by name and shop owner: $e';
    }
  }

  /// Get products by shop owner name
  /// Returns a list of products from a specific shop owner
  Future<List<Map<String, dynamic>>> getProductsByShopOwnerName({
    required String shopOwnerName,
  }) async {
    await _ensureInitialized();

    try {
      // First, find the shop owner by name
      final shopOwnersQuery = await _firestore
          .collection('shop_owners')
          .where('shopName', isEqualTo: shopOwnerName)
          .limit(1)
          .get();

      if (shopOwnersQuery.docs.isEmpty) {
        throw 'Shop owner with name "$shopOwnerName" not found';
      }

      final shopOwnerId = shopOwnersQuery.docs.first.id;
      final shopOwnerData = shopOwnersQuery.docs.first.data();
      final shopOwnerProfile = ShopOwnerProfile.fromMap(shopOwnerData);

      // Fetch user profile
      final userProfileDoc =
          await _firestore.collection('users').doc(shopOwnerId).get();

      UserProfile? userProfile;
      if (userProfileDoc.exists) {
        userProfile = UserProfile.fromMap(userProfileDoc.data()!);
      }

      // Fetch all products from this shop owner
      final productsQuery = await _firestore
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .get();

      final products = <Map<String, dynamic>>[];
      for (final productDoc in productsQuery.docs) {
        final product = Product.fromMap(productDoc.data(), productDoc.id);
        products.add({
          'product': product,
          'userProfile': userProfile,
          'shopOwnerProfile': shopOwnerProfile,
          'isShopOwner': true,
        });
      }

      return products;
    } catch (e) {
      throw 'Error fetching products by shop owner: $e';
    }
  }

  /// Search products by shop owner name and product name (fuzzy search)
  /// Returns a list of matching products
  Future<List<Map<String, dynamic>>> searchProductsByShopOwnerAndProductName({
    required String shopOwnerName,
    required String productName,
  }) async {
    await _ensureInitialized();

    try {
      // First, find the shop owner by name (case-insensitive)
      final shopOwnersQuery =
          await _firestore.collection('shop_owners').get();

      final matchingShopOwners = shopOwnersQuery.docs
          .where((doc) => (doc['shopName'] as String)
              .toLowerCase()
              .contains(shopOwnerName.toLowerCase()))
          .toList();

      if (matchingShopOwners.isEmpty) {
        return [];
      }

      final results = <Map<String, dynamic>>[];

      for (final shopOwnerDoc in matchingShopOwners) {
        final shopOwnerId = shopOwnerDoc.id;
        final shopOwnerProfile = ShopOwnerProfile.fromMap(shopOwnerDoc.data());

        // Fetch user profile
        final userProfileDoc =
            await _firestore.collection('users').doc(shopOwnerId).get();

        UserProfile? userProfile;
        if (userProfileDoc.exists) {
          userProfile = UserProfile.fromMap(userProfileDoc.data()!);
        }

        // Fetch products from this shop owner
        final productsQuery = await _firestore
            .collection('products')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .get();

        // Filter by product name (case-insensitive)
        final matchingProducts = productsQuery.docs
            .where((doc) => (doc['productName'] as String)
                .toLowerCase()
                .contains(productName.toLowerCase()))
            .toList();

        for (final productDoc in matchingProducts) {
          final product = Product.fromMap(productDoc.data(), productDoc.id);
          results.add({
            'product': product,
            'userProfile': userProfile,
            'shopOwnerProfile': shopOwnerProfile,
            'isShopOwner': true,
          });
        }
      }

      return results;
    } catch (e) {
      throw 'Error searching products: $e';
    }
  }
}
