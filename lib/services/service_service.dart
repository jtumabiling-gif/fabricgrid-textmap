import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_model.dart';

class ServiceService {

  factory ServiceService() => _instance;

  ServiceService._internal();
  static final ServiceService _instance = ServiceService._internal();
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

  /// Create a new service
  Future<String> createService({
    required String serviceName,
    required String category,
    required double price,
    required String description,
    required String estimatedTime,
    required bool expressDelivery,
    required bool homePickup,
    required bool materialIncluded,
    required double latitude,
    required double longitude,
    required String location,
    List<String> imageUrls = const [],
  }) async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'Shop owner not authenticated. Please login first.';
      }

      // Get shop owner name from Firebase Auth displayName
      var shopOwnerName = _firebaseAuth.currentUser?.displayName ?? 'Shop Owner';
      
      // Try to fetch additional shop owner details from Firestore
      try {
        final shopOwnerDoc = await _firestore
            .collection('shop_owners')
            .doc(shopOwnerId)
            .get();
        
        if (shopOwnerDoc.exists) {
          final shopOwnerData = shopOwnerDoc.data();
          final firebaseShopName = shopOwnerData?['shopName'];
          if (firebaseShopName != null && firebaseShopName.isNotEmpty) {
            shopOwnerName = firebaseShopName;
          }
        }
      } catch (e) {
        // Continue with displayName if fetch fails
      }

      final serviceData = {
        'shopOwnerId': shopOwnerId,
        'shopOwnerName': shopOwnerName,
        'serviceName': serviceName,
        'category': category,
        'price': price,
        'description': description,
        'estimatedTime': estimatedTime,
        'expressDelivery': expressDelivery,
        'homePickup': homePickup,
        'materialIncluded': materialIncluded,
        'imageUrls': imageUrls,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': location,
        },
        'status': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection('services').add(serviceData);

      return docRef.id;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to create service: $e';
    }
  }

  /// Get shop owner's services
  Future<List<Service>> getShopOwnerServices() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'Shop owner not authenticated. Please login first.';
      }

      try {
        final snapshot = await _firestore
            .collection('services')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => Service.fromMap(doc.data(), doc.id))
            .toList();
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition' || 
            e.message?.contains('index') == true) {
          final snapshot = await _firestore
              .collection('services')
              .where('shopOwnerId', isEqualTo: shopOwnerId)
              .get();

          final services = snapshot.docs
              .map((doc) => Service.fromMap(doc.data(), doc.id))
              .toList();
          
          services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return services;
        }
        rethrow;
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve services: $e';
    }
  }

  /// Get all services (for browsing)
  Future<List<Service>> getAllServices() async {
    await _ensureInitialized();

    try {
      try {
        final snapshot = await _firestore
            .collection('services')
            .where('status', isEqualTo: 'ACTIVE')
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => Service.fromMap(doc.data(), doc.id))
            .toList();
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition' || 
            e.message?.contains('index') == true) {
          final snapshot = await _firestore
              .collection('services')
              .where('status', isEqualTo: 'ACTIVE')
              .get();

          final services = snapshot.docs
              .map((doc) => Service.fromMap(doc.data(), doc.id))
              .toList();
          
          services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return services;
        }
        rethrow;
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve services: $e';
    }
  }

  /// Update service
  Future<void> updateService({
    required String serviceId,
    String? serviceName,
    String? category,
    double? price,
    String? description,
    String? estimatedTime,
    bool? expressDelivery,
    bool? homePickup,
    bool? materialIncluded,
    String? status,
    List<String>? imageUrls,
  }) async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'Shop owner not authenticated. Please login first.';
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (serviceName != null) updateData['serviceName'] = serviceName;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = price;
      if (description != null) updateData['description'] = description;
      if (estimatedTime != null) updateData['estimatedTime'] = estimatedTime;
      if (expressDelivery != null) updateData['expressDelivery'] = expressDelivery;
      if (homePickup != null) updateData['homePickup'] = homePickup;
      if (materialIncluded != null) updateData['materialIncluded'] = materialIncluded;
      if (status != null) updateData['status'] = status;
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;

      await _firestore
          .collection('services')
          .doc(serviceId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update service: $e';
    }
  }

  /// Delete service and all associated bookings and ratings
  Future<void> deleteService(String serviceId) async {
    await _ensureInitialized();

    try {
      // Delete all bookings associated with this service
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      for (final bookingDoc in bookingsQuery.docs) {
        await bookingDoc.reference.delete();
      }

      // Delete all ratings associated with this service
      final ratingsQuery = await _firestore
          .collection('ratings')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      for (final ratingDoc in ratingsQuery.docs) {
        await ratingDoc.reference.delete();
      }

      // Delete the service itself
      await _firestore.collection('services').doc(serviceId).delete();
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to delete service: $e';
    }
  }

  /// Get the count of active services for a shop owner
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
}
