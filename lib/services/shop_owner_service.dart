import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop_owner_profile_model.dart';

class ShopOwnerService {

  factory ShopOwnerService() => _instance;

  ShopOwnerService._internal();
  static final ShopOwnerService _instance = ShopOwnerService._internal();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

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

  /// Create shop owner profile
  Future<void> createShopOwnerProfile({
    required String email,
    required String shopName,
    required String? shopDescription,
    required String? phone,
    required String? address,
    required double latitude,
    required double longitude,
  }) async {
    await _ensureInitialized();

    try {
      final user = _firebaseAuth.currentUser;
      final shopOwnerId = user?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final shopOwnerProfile = ShopOwnerProfile(
        uid: shopOwnerId,
        email: email,
        shopName: shopName,
        shopDescription: shopDescription,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        ownerFullName: user?.displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('shop_owners')
          .doc(shopOwnerId)
          .set(shopOwnerProfile.toMap());
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to create shop owner profile: $e';
    }
  }

  /// Get shop owner profile
  Future<ShopOwnerProfile?> getShopOwnerProfile(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final doc =
          await _firestore.collection('shop_owners').doc(shopOwnerId).get();

      if (doc.exists) {
        return ShopOwnerProfile.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve shop owner profile: $e';
    }
  }

  /// Get current shop owner profile
  Future<ShopOwnerProfile?> getCurrentShopOwnerProfile() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      return getShopOwnerProfile(shopOwnerId);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve current shop owner profile: $e';
    }
  }

  /// Update shop owner profile
  Future<void> updateShopOwnerProfile({
    String? shopName,
    String? shopDescription,
    String? phone,
    String? address,
    String? shopImageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (shopName != null) updateData['shopName'] = shopName;
      if (shopDescription != null) updateData['shopDescription'] = shopDescription;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (shopImageUrl != null) updateData['shopImageUrl'] = shopImageUrl;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;

      await _firestore
          .collection('shop_owners')
          .doc(shopOwnerId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update shop owner profile: $e';
    }
  }

  /// Increment shop owner product counter
  Future<void> incrementProductCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalProducts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update product count: $e';
    }
  }

  /// Recalculate shop owner product count from products collection
  Future<void> recalculateProductCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Count all products for this shop owner
      final productSnapshot = await _firestore
          .collection('products')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .count()
          .get();

      final productCount = productSnapshot.count ?? 0;

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalProducts': productCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Updated product count to: $productCount');
    } on FirebaseException catch (e) {
      print('Firebase error updating product count: ${e.code} - ${e.message}');
      // Continue without throwing - this is non-critical
    } catch (e) {
      print('Error recalculating product count: $e');
      // Continue without throwing - this is non-critical
    }
  }

  /// Increment shop owner booking counter
  Future<void> incrementBookingCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalBookings': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update booking count: $e';
    }
  }

  /// Recalculate shop owner booking count from bookings collection
  Future<void> recalculateBookingCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Count all bookings (BOOK type) for this shop owner
      final bookingSnapshot = await _firestore
          .collection('bookings')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('bookingType', isEqualTo: 'BOOK')
          .count()
          .get();

      final bookingCount = bookingSnapshot.count ?? 0;

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalBookings': bookingCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Updated booking count to: $bookingCount');
    } on FirebaseException catch (e) {
      print('Firebase error updating booking count: ${e.code} - ${e.message}');
      // Continue without throwing - this is non-critical
    } catch (e) {
      print('Error recalculating booking count: $e');
      // Continue without throwing - this is non-critical
    }
  }

  /// Increment shop owner reservation counter
  Future<void> incrementReservationCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalReservations': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update reservation count: $e';
    }
  }

  /// Increment shop owner rental counter
  Future<void> incrementRentalCount() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalRentals': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update rental count: $e';
    }
  }

  /// Update active inventory items count
  Future<void> updateActiveInventoryCount(int count) async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'activeInventoryItems': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update inventory count: $e';
    }
  }

  /// Update total revenue
  Future<void> addRevenue(double amount) async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('shop_owners').doc(shopOwnerId).update({
        'totalRevenue': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update revenue: $e';
    }
  }

  /// Stream of shop owner profile (real-time updates)
  Stream<ShopOwnerProfile?> getShopOwnerProfileStream(String shopOwnerId) => _firestore
        .collection('shop_owners')
        .doc(shopOwnerId)
        .snapshots()
        .map(
      (doc) {
        if (doc.exists) {
          return ShopOwnerProfile.fromMap(doc.data()!);
        }
        return null;
      },
    );
}
