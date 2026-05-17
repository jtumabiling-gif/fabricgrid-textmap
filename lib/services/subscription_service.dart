import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop_owner_profile_model.dart';

class SubscriptionService {
  factory SubscriptionService() => _instance;

  SubscriptionService._internal();
  static final SubscriptionService _instance = SubscriptionService._internal();
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

  /// Save subscription to Firestore
  Future<String> saveSubscription({
    required String planName,
    required String price,
    required double commission,
    required String paymentMethod,
    required ShopOwnerProfile shopOwnerProfile,
  }) async {
    await _ensureInitialized();

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final subscriptionData = {
        'uid': currentUser.uid,
        'shopOwnerId': shopOwnerProfile.uid,
        'email': shopOwnerProfile.email,
        'shopName': shopOwnerProfile.shopName,
        'shopDescription': shopOwnerProfile.shopDescription,
        'phone': shopOwnerProfile.phone,
        'address': shopOwnerProfile.address,
        'shopImageUrl': shopOwnerProfile.shopImageUrl,
        'latitude': shopOwnerProfile.latitude,
        'longitude': shopOwnerProfile.longitude,
        'planName': planName,
        'price': price,
        'commission': commission,
        'paymentMethod': paymentMethod,
        'subscriptionStartDate': DateTime.now(),
        'subscriptionEndDate': DateTime.now().add(const Duration(days: 30)),
        'isActive': true,
        'status': 'active',
        'totalRevenue': shopOwnerProfile.totalRevenue,
        'totalCommission': shopOwnerProfile.totalCommission,
        'totalProducts': shopOwnerProfile.totalProducts,
        'rating': shopOwnerProfile.rating,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Save to subscriptions collection
      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscriptionData);

      // Update shop owner profile with subscription details
      await _firestore
          .collection('shop_owners')
          .doc(shopOwnerProfile.uid)
          .update({
        'currentPlan': planName,
        'commissionRate': commission,
        'subscriptionStatus': 'active',
        'subscriptionStartDate': DateTime.now(),
        'subscriptionEndDate': DateTime.now().add(const Duration(days: 30)),
        'lastSubscriptionUpdate': DateTime.now(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get active subscription for a shop owner
  Future<DocumentSnapshot?> getActiveSubscription(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      // First try: Get with isActive = true filter
      try {
        final query = await _firestore
            .collection('subscriptions')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          return query.docs.first;
        }
      } catch (e) {
        // If the query fails (e.g., missing index), try without isActive filter
        print('First query attempt failed, trying without isActive filter: $e');
      }

      // Fallback: Get the most recent subscription without isActive filter
      final query = await _firestore
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        
        // Check if subscription is still valid (not cancelled and not expired)
        final endDate = data['subscriptionEndDate'] as Timestamp?;
        final status = data['status'] as String?;
        
        if (status != 'cancelled' && (endDate == null || endDate.toDate().isAfter(DateTime.now()))) {
          return doc;
        }
      }
      
      return null;
    } catch (e) {
      print('Error in getActiveSubscription: $e');
      rethrow;
    }
  }

  /// Get all subscriptions for a shop owner
  Future<List<DocumentSnapshot>> getShopOwnerSubscriptions(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final query = await _firestore
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all subscriptions (admin view)
  Future<List<DocumentSnapshot>> getAllSubscriptions() async {
    await _ensureInitialized();

    try {
      final query = await _firestore
          .collection('subscriptions')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    await _ensureInitialized();

    try {
      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'isActive': false,
        'status': 'cancelled',
        'cancelledAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update subscription
  Future<void> updateSubscription({
    required String subscriptionId,
    required String planName,
    required String price,
    required double commission,
  }) async {
    await _ensureInitialized();

    try {
      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'planName': planName,
        'price': price,
        'commission': commission,
        'subscriptionEndDate': DateTime.now().add(const Duration(days: 30)),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get current subscription tier for a shop owner
  /// Returns the plan name (Premium, Standard, Ordinary)
  Future<String?> getCurrentSubscriptionTier(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      print('getCurrentSubscriptionTier: Querying for shopOwnerId=$shopOwnerId');
      final subscription = await getActiveSubscription(shopOwnerId);
      
      if (subscription != null) {
        final planName = subscription.get('planName') as String?;
        print('getCurrentSubscriptionTier: Found planName=$planName');
        return planName;
      }
      
      print('getCurrentSubscriptionTier: No active subscription found');
      // If no active subscription, return null (Ordinary tier)
      return null;
    } catch (e) {
      print('Error fetching subscription tier: $e');
      return null;
    }
  }

  /// Get subscription by shop name
  /// Returns the active subscription document for a given shop name
  Future<DocumentSnapshot?> getSubscriptionByShopName(String shopName) async {
    await _ensureInitialized();

    try {
      final query = await _firestore
          .collection('subscriptions')
          .where('shopName', isEqualTo: shopName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }
      return null;
    } catch (e) {
      print('Error fetching subscription by shop name: $e');
      return null;
    }
  }

  /// Get product listing limit based on actual subscription
  /// Queries the subscriptions collection to get real-time limits
  Future<int> getProductLimitByShopName(String shopName) async {
    await _ensureInitialized();

    try {
      final subscription = await getSubscriptionByShopName(shopName);
      
      if (subscription != null) {
        final planName = subscription.get('planName') as String?;
        // Import SubscriptionLimits to get the limit for the plan
        // For now, determine limit based on planName
        if (planName != null) {
          final lowerPlan = planName.toLowerCase();
          if (lowerPlan.contains('premium')) {
            return -1; // Unlimited
          } else if (lowerPlan.contains('standard')) {
            return 15;
          }
        }
      }
      
      // Default to Ordinary tier (5 products) if no active subscription
      return 5;
    } catch (e) {
      print('Error fetching product limit by shop name: $e');
      return 5; // Default limit on error
    }
  }

  /// Get all subscription tiers and their details
  /// Useful for displaying available plans
  Future<List<Map<String, dynamic>>> getAllSubscriptionPlans() async {
    await _ensureInitialized();

    try {
      final query = await _firestore
          .collection('subscription_plans')
          .orderBy('price', descending: false)
          .get();

      return query.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return [];
    }
  }
}
