import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile_model.dart';
import '../models/user_role.dart';

// Role-specific collection names
const String USERS_COLLECTION = 'users';
const String ADMIN_COLLECTION = 'admins';
const String CUSTOMER_COLLECTION = 'customers';
const String SHOP_OWNER_COLLECTION = 'shopOwners';

class UserProfileService {

  factory UserProfileService() => _instance;

  UserProfileService._internal();
  static final UserProfileService _instance =
      UserProfileService._internal();
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

  /// Create user profile when signing up
  Future<void> createUserProfile({
    required String email,
    required String fullName,
    required String userType, // 'USER' or 'SHOP_OWNER'
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final userProfile = UserProfile(
        uid: userId,
        email: email,
        fullName: fullName,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userProfile.toMap());
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  /// Create user profile with role - stores in role-specific collection
  Future<void> createUserProfileWithRole({
    required String email,
    required String fullName,
    required String userType,
    dynamic role, // UserRole enum
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Determine role collection based on userType
      String roleCollection;
      String roleString;

      if (role is UserRole) {
        switch (role) {
          case UserRole.admin:
            roleCollection = ADMIN_COLLECTION;
            roleString = 'ADMIN';
            break;
          case UserRole.shopOwner:
            roleCollection = SHOP_OWNER_COLLECTION;
            roleString = 'SHOP_OWNER';
            break;
          case UserRole.user:
            roleCollection = CUSTOMER_COLLECTION;
            roleString = 'CUSTOMER';
            break;
        }
      } else {
        // Default to customer if role not specified
        roleCollection = CUSTOMER_COLLECTION;
        roleString = 'CUSTOMER';
      }

      final userProfile = UserProfile(
        uid: userId,
        email: email,
        fullName: fullName,
        userType: userType,
        createdAt: DateTime.now(),
      );

      // 1. Save to main users collection
      await _firestore
          .collection(USERS_COLLECTION)
          .doc(userId)
          .set({
        ...userProfile.toMap(),
        'role': roleString,
        'roleCollection': roleCollection,
      });

      // 2. Save to role-specific collection
      await _firestore
          .collection(roleCollection)
          .doc(userId)
          .set({
        ...userProfile.toMap(),
        'role': roleString,
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  /// Get user role from Firestore
  Future<UserRole?> getUserRole(String userId) async {
    await _ensureInitialized();

    try {
      final doc = await _firestore
          .collection(USERS_COLLECTION)
          .doc(userId)
          .get();

      if (doc.exists) {
        final roleString = doc.data()?['role'] as String?;
        if (roleString != null) {
          return UserRoleExtension.fromString(roleString);
        }
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to get user role: $e';
    }
  }

  /// Get current user role
  Future<UserRole?> getCurrentUserRole() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        return null;
      }
      return getUserRole(userId);
    } catch (e) {
      throw 'Failed to get current user role: $e';
    }
  }

  /// Verify if user can sign in with specific role
  /// Returns true if user exists in the specified role collection
  Future<bool> verifyUserRoleAccess({
    required String userId,
    required UserRole role,
  }) async {
    await _ensureInitialized();

    try {
      String roleCollection;
      switch (role) {
        case UserRole.admin:
          roleCollection = ADMIN_COLLECTION;
          break;
        case UserRole.shopOwner:
          roleCollection = SHOP_OWNER_COLLECTION;
          break;
        case UserRole.user:
          roleCollection = CUSTOMER_COLLECTION;
          break;
      }

      final doc = await _firestore
          .collection(roleCollection)
          .doc(userId)
          .get();

      return doc.exists;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to verify user role access: $e';
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    await _ensureInitialized();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve user profile: $e';
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      return getUserProfile(userId);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve current user profile: $e';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? phone,
    String? address,
    String? profileImageUrl,
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(userId).update(updateData);
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  /// Increment user booking counter
  Future<void> incrementBookingCount() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('users').doc(userId).update({
        'totalBookings': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update booking count: $e';
    }
  }

  /// Increment user reservation counter
  Future<void> incrementReservationCount() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('users').doc(userId).update({
        'totalReservations': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update reservation count: $e';
    }
  }

  /// Increment user rental counter
  Future<void> incrementRentalCount() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      await _firestore.collection('users').doc(userId).update({
        'totalRentals': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update rental count: $e';
    }
  }

  /// Stream of user profile (real-time updates)
  Stream<UserProfile?> getUserProfileStream(String userId) => _firestore.collection('users').doc(userId).snapshots().map(
      (doc) {
        if (doc.exists) {
          return UserProfile.fromMap(doc.data()!);
        }
        return null;
      },
    );
}
