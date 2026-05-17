import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/subscription_limits.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {

  factory BookingService() => _instance;

  BookingService._internal();
  static final BookingService _instance = BookingService._internal();
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
      print('✅ BookingService initialized');
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

  /// Get the subscription tier for a shop owner
  Future<String> _getShopOwnerSubscriptionTier(String shopOwnerId) async {
    try {
      final subscription = await _firestore
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (subscription.docs.isNotEmpty) {
        final planName = subscription.docs.first['planName'] as String?;
        return SubscriptionLimits.getTierFromPlanName(planName);
      }
      return SubscriptionLimits.tierOrdinary;
    } catch (e) {
      print('Error fetching shop owner subscription tier: $e');
      return SubscriptionLimits.tierOrdinary;
    }
  }

  /// Create a new booking/reservation/rental
  Future<String> createBooking({
    required String shopOwnerId,
    required String productId,
    required String productName,
    required double productPrice,
    required String bookingType, // 'BOOK', 'RESERVE', 'RENT'
    required DateTime startDate,
    required int quantity, required double totalPrice, DateTime? endDate,
    String? notes,
    double? commissionFee,
    String? subscriptionTier,
    String? productType, // 'Laundermats', 'Uniform', 'Eventwear', 'Other'
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Get user's name from authentication or profile
      final userName = _firebaseAuth.currentUser?.displayName ?? 
                       _firebaseAuth.currentUser?.email ?? 
                       'Unknown User';

      // Get shop owner subscription tier if not provided
      final tier = subscriptionTier ?? await _getShopOwnerSubscriptionTier(shopOwnerId);
      
      // Calculate commission fee if not provided
      final fee = commissionFee ?? SubscriptionLimits.calculateCommissionFee(tier, totalPrice);

      // Fetch product to check if it's a user listing
      bool isUserListing = false;
      String productTypeToStore = productType ?? 'Other';
      try {
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          isUserListing = productDoc.data()?['isUserListing'] ?? false;
          // If product type not provided, try to get it from the product document
          if (productType == null || productType.isEmpty) {
            productTypeToStore = productDoc.data()?['category'] ?? 'Other';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch product to determine isUserListing: $e');
      }

      final bookingData = {
        'userId': userId,
        'userName': userName,
        'shopOwnerId': shopOwnerId,
        'productId': productId,
        'productName': productName,
        'productPrice': productPrice,
        'bookingType': bookingType,
        'bookingDate': Timestamp.now(),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'status': 'UNPAID',
        'paymentStatus': 'PENDING',
        'notes': notes,
        'userConfirmed': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'commissionFee': fee,
        'subscriptionTier': tier,
        'isUserListing': isUserListing,
        'productType': productTypeToStore,
      };

      final docRef =
          await _firestore.collection('bookings').add(bookingData);

      print('✅ BOOKING CREATED SUCCESSFULLY');
      print('   Booking ID: ${docRef.id}');
      print('   User ID: $userId');
      print('   Shop Owner ID: $shopOwnerId');
      print('   Product Type: $productTypeToStore');
      print('   Status: UNPAID');
      print('   Is User Listing: $isUserListing');
      print('   User Confirmed: false');

      // Update shop owner booking count based on booking type
      try {
        if (bookingType.toUpperCase() == 'BOOK') {
          await _firestore
              .collection('shop_owners')
              .doc(shopOwnerId)
              .update({
                'totalBookings': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } else if (bookingType.toUpperCase() == 'RESERVE') {
          await _firestore
              .collection('shop_owners')
              .doc(shopOwnerId)
              .update({
                'totalReservations': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } else if (bookingType.toUpperCase() == 'RENT') {
          await _firestore
              .collection('shop_owners')
              .doc(shopOwnerId)
              .update({
                'totalRentals': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        }
      } catch (e) {
        print('Warning: Could not update shop owner booking count: $e');
      }

      return docRef.id;
    } on FirebaseException catch (e) {
      // If permission denied, try storing in user's bookings subcollection
      if (e.code == 'permission-denied') {
        try {
          final userId = _firebaseAuth.currentUser?.uid;
          if (userId == null) throw 'User not authenticated';

          final userName = _firebaseAuth.currentUser?.displayName ?? 
                           _firebaseAuth.currentUser?.email ?? 
                           'Unknown User';

          // Get shop owner subscription tier if not provided
          final tier = subscriptionTier ?? await _getShopOwnerSubscriptionTier(shopOwnerId);
          
          // Calculate commission fee if not provided
          final fee = commissionFee ?? SubscriptionLimits.calculateCommissionFee(tier, totalPrice);

          final bookingData = {
            'userId': userId,
            'userName': userName,
            'shopOwnerId': shopOwnerId,
            'productId': productId,
            'productName': productName,
            'productPrice': productPrice,
            'bookingType': bookingType,
            'startDate': Timestamp.fromDate(startDate),
            'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
            'quantity': quantity,
            'totalPrice': totalPrice,
            'status': 'PENDING',
            'paymentStatus': 'PENDING',
            'notes': notes,
            'userConfirmed': false,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'commissionFee': fee,
            'subscriptionTier': tier,
          };

          // Try alternative collection path
          final docRef = await _firestore
              .collection('users')
              .doc(userId)
              .collection('bookings')
              .add(bookingData);

          print('⚠️  BOOKING CREATED IN FALLBACK LOCATION');
          print('   Booking ID: ${docRef.id}');
          print('   Location: users/$userId/bookings');
          print('   User ID: $userId');
          print('   Shop Owner ID: $shopOwnerId');
          print('   Note: Saved to sub-collection due to permission-denied');

          // Update shop owner booking count based on booking type
          try {
            if (bookingType.toUpperCase() == 'BOOK') {
              await _firestore
                  .collection('shop_owners')
                  .doc(shopOwnerId)
                  .update({
                    'totalBookings': FieldValue.increment(1),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            } else if (bookingType.toUpperCase() == 'RESERVE') {
              await _firestore
                  .collection('shop_owners')
                  .doc(shopOwnerId)
                  .update({
                    'totalReservations': FieldValue.increment(1),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            } else if (bookingType.toUpperCase() == 'RENT') {
              await _firestore
                  .collection('shop_owners')
                  .doc(shopOwnerId)
                  .update({
                    'totalRentals': FieldValue.increment(1),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            }
          } catch (e) {
            print('Warning: Could not update shop owner booking count: $e');
          }

          return docRef.id;
        } catch (e) {
          throw 'Booking permission denied. Please contact support: ${e.toString()}';
        }
      }
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to create booking: $e';
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings() async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final allBookings = <Booking>[];

      try {
        // Fetch product bookings
        final productSnapshot = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .get();

        allBookings.addAll(productSnapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition' && 
            !e.message!.contains('index')) {
          rethrow;
        }
        // If index error, continue without product bookings for now
      }

      try {
        // Fetch service bookings
        final serviceSnapshot = await _firestore
            .collection('book_service')
            .where('userId', isEqualTo: userId)
            .get();

        // Convert service bookings to Booking objects
        final serviceBookings = serviceSnapshot.docs.map((doc) {
          final data = doc.data();
          return Booking(
            id: doc.id,
            userId: data['userId'] ?? '',
            userName: data['userName'],
            shopOwnerId: data['shopOwnerId'] ?? '',
            productId: data['serviceId'] ?? '',
            productName: data['serviceName'] ?? '',
            productPrice: (data['price'] ?? 0.0).toDouble(),
            bookingType: 'SERVICE',
            bookingDate: data['bookingDate'] != null
                ? (data['bookingDate'] as dynamic).toDate()
                : DateTime.now(),
            startDate: data['serviceDate'] != null
                ? (data['serviceDate'] as dynamic).toDate()
                : DateTime.now(),
            endDate: null,
            quantity: 1,
            totalPrice: (data['price'] ?? 0.0).toDouble(),
            status: data['status'] ?? 'PENDING',
            paymentStatus: 'PENDING',
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as dynamic).toDate()
                : DateTime.now(),
            updatedAt: data['updatedAt'] != null
                ? (data['updatedAt'] as dynamic).toDate()
                : null,
            notes: data['notes'],
          );
        }).toList();

        allBookings.addAll(serviceBookings);
      } catch (e) {
        // If service bookings fail, continue with product bookings
        print('Error fetching service bookings: $e');
      }

      // Sort all bookings by createdAt
      allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allBookings;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve bookings: $e';
    }
  }

  /// Get shop owner's bookings (for their products and services)
  Future<List<Booking>> getShopOwnerBookings() async {
    await _ensureInitialized();

    try {
      final shopOwnerId = _firebaseAuth.currentUser?.uid;
      if (shopOwnerId == null) {
        throw 'User not authenticated. Please login first.';
      }

      print('\n================== FETCHING SHOP OWNER BOOKINGS ==================');
      print('Shop Owner ID: $shopOwnerId');

      final allBookings = <Booking>[];

      // Fetch product bookings - ONLY paid/completed payments
      try {
        final productSnapshot = await _firestore
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .get();

        print('   ✅ Found ${productSnapshot.docs.length} product bookings');

        // Filter to only show paid bookings
        final paidBookings = productSnapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .where((booking) => booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'PAID')
            .toList();

        print('   ✅ Filtered to ${paidBookings.length} paid product bookings');
        allBookings.addAll(paidBookings);
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition' && 
            !e.message!.contains('index')) {
          rethrow;
        }
        print('   ⚠️  Index error for product bookings, continuing...');
      }

      // Fetch service bookings - ONLY paid/completed payments
      try {
        final serviceSnapshot = await _firestore
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .get();

        print('   ✅ Found ${serviceSnapshot.docs.length} service bookings');

        // Convert service bookings to Booking objects and filter only paid ones
        final serviceBookings = serviceSnapshot.docs.map((doc) {
          final data = doc.data();
          return Booking(
            id: doc.id,
            userId: data['userId'] ?? '',
            userName: data['userName'],
            shopOwnerId: data['shopOwnerId'] ?? '',
            productId: data['serviceId'] ?? '',
            productName: data['serviceName'] ?? '',
            productPrice: (data['price'] ?? 0.0).toDouble(),
            bookingType: 'SERVICE',
            bookingDate: data['bookingDate'] != null
                ? (data['bookingDate'] as dynamic).toDate()
                : DateTime.now(),
            startDate: data['serviceDate'] != null
                ? (data['serviceDate'] as dynamic).toDate()
                : DateTime.now(),
            endDate: null,
            quantity: 1,
            totalPrice: (data['price'] ?? 0.0).toDouble(),
            status: data['status'] ?? 'PENDING',
            paymentStatus: data['paymentStatus'] ?? 'PENDING',
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as dynamic).toDate()
                : DateTime.now(),
            updatedAt: data['updatedAt'] != null
                ? (data['updatedAt'] as dynamic).toDate()
                : null,
            notes: data['notes'],
            userConfirmed: data['userConfirmed'] ?? false,
          );
        })
        .where((booking) => booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'PAID')
        .toList();

        print('   ✅ Filtered to ${serviceBookings.length} paid service bookings');
        allBookings.addAll(serviceBookings);
      } catch (e) {
        print('   ⚠️  Error fetching service bookings: $e');
      }

      // Sort all bookings by createdAt in descending order
      allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('\n📊 FINAL RESULT:');
      print('   Total bookings for shop owner: ${allBookings.length}');
      if (allBookings.isEmpty) {
        print('   ⚠️  NO BOOKINGS FOUND!');
      } else {
        for (var i = 0; i < allBookings.length; i++) {
          print('   ${i + 1}. ${allBookings[i].productName} (${allBookings[i].bookingType}) - Status: ${allBookings[i].status} - User: ${allBookings[i].userName} - UserConfirmed: ${allBookings[i].userConfirmed}');
        }
      }
      print('===============================================================\n');

      return allBookings;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve bookings: $e';
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await _ensureInitialized();

    try {
      // Get booking details before updating to send notification
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }

      final booking = Booking.fromMap(bookingDoc.data()!, bookingId);

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrease product stock when booking is CONFIRMED
      if (status == 'CONFIRMED' && booking.productId.isNotEmpty) {
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(booking.productId)
              .get();
          
          if (productDoc.exists) {
            final currentStock = (productDoc.get('stockQuantity') as num?)?.toInt() ?? 0;
            final newStock = (currentStock - booking.quantity).clamp(0, double.infinity).toInt();
            
            await _firestore
                .collection('products')
                .doc(booking.productId)
                .update({
              'stockQuantity': newStock,
            });
            
            print('✅ Stock decreased: ${booking.productName} - Old: $currentStock, New: $newStock');
          }
        } catch (e) {
          print('⚠️ Error decreasing stock: $e');
          // Don't throw - booking update was successful, stock update is secondary
        }
      }

      // Send notification to user if status is CONFIRMED
      if (status == 'CONFIRMED' && booking.userId.isNotEmpty) {
        try {
          final notificationService = NotificationService();
          await notificationService.initialize();
          
          await notificationService.createNotification(
            userId: booking.userId,
            title: 'Booking Confirmed!',
            message: '${booking.productName} has been confirmed by the shop owner',
            type: 'booking_confirmed',
            bookingId: bookingId,
            relatedUserId: booking.shopOwnerId,
            data: {
              'productName': booking.productName,
              'bookingDate': booking.startDate.toString(),
              'totalPrice': booking.totalPrice,
            },
          );
          
          print('✅ Notification sent to user ${booking.userId} for booking $bookingId');
        } catch (e) {
          print('⚠️ Error sending notification: $e');
          // Don't throw - booking update was successful
        }
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update booking: $e';
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    await _ensureInitialized();

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update payment status: $e';
    }
  }

  /// Update service booking status
  Future<void> updateServiceBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await _ensureInitialized();

    try {
      // Get service booking details before updating
      final serviceDoc = await _firestore.collection('book_service').doc(bookingId).get();
      
      if (!serviceDoc.exists) {
        throw 'Service booking not found';
      }

      final serviceData = serviceDoc.data()!;

      // Update service booking status
      await _firestore.collection('book_service').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to user if status is CONFIRMED
      if (status == 'CONFIRMED' && serviceData['userId'] != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.initialize();
          
          await notificationService.createNotification(
            userId: serviceData['userId'],
            title: 'Service Booking Confirmed!',
            message: '${serviceData['serviceName'] ?? 'Your service'} has been confirmed by the shop owner',
            type: 'booking_confirmed',
            bookingId: bookingId,
            relatedUserId: serviceData['shopOwnerId'],
            data: {
              'serviceName': serviceData['serviceName'],
              'serviceDate': serviceData['serviceDate']?.toDate().toString(),
              'price': serviceData['price'],
            },
          );
          
          print('✅ Notification sent to user ${serviceData['userId']} for service booking $bookingId');
        } catch (e) {
          print('⚠️ Error sending notification: $e');
          // Don't throw - booking update was successful
        }
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to update service booking: $e';
    }
  }

  /// Cancel booking
  Future<void> cancelBooking({required String bookingId}) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      // Try updating the service booking first (since that's the problematic one)
      try {
        await _firestore.collection('book_service').doc(bookingId).update({
          'status': 'CANCELLED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return; // Success - service booking was cancelled
      } catch (serviceError) {
        // If service booking update fails, try product booking
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': 'CANCELLED',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return; // Success - product booking was cancelled
        } catch (productError) {
          // Both failed, throw the original service error
          throw serviceError;
        }
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to cancel booking: $e';
    }
  }

  /// User confirms booking (makes it visible to shop owner in PENDING state)
  Future<void> confirmBookingByUser({required String bookingId}) async {
    await _ensureInitialized();

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'userConfirmed': true,
        'status': 'PENDING',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to confirm booking: $e';
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    await _ensureInitialized();

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return Booking.fromMap(doc.data()!, doc.id);
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve booking: $e';
    }
  }

  /// Get bookings for a specific product
  Future<List<Booking>> getProductBookings(String productId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('productId', isEqualTo: productId)
          .get();

      final bookings = snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in code to avoid index requirement
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to retrieve product bookings: $e';
    }
  }

  /// Stream of user's bookings (real-time)
  Stream<List<Booking>> getUserBookingsStream() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by createdAt in code to avoid index requirement
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  /// Stream of shop owner's bookings (real-time)
  Stream<List<Booking>> getShopOwnerBookingsStream() {
    final shopOwnerId = _firebaseAuth.currentUser?.uid;
    if (shopOwnerId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('shopOwnerId', isEqualTo: shopOwnerId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by createdAt in code to avoid index requirement
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  /// Shop owner or list creator confirms booking from notification
  Future<void> confirmBookingFromNotification({required String bookingId}) async {
    await _ensureInitialized();

    try {
      // Fetch the booking to check if it's a user listing
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }
      
      final isUserListing = bookingDoc.get('isUserListing') ?? false;
      final booking = Booking.fromMap(bookingDoc.data()!, bookingId);
      
      // For user listings, set status to COMPLETED (since list creator confirming means the transaction is done)
      // For shop owner listings, set status to CONFIRMED (shop owner is confirming they accept the booking)
      final newStatus = isUserListing ? 'COMPLETED' : 'CONFIRMED';
      
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrease product stock when booking is CONFIRMED
      if (newStatus == 'CONFIRMED' && booking.productId.isNotEmpty) {
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(booking.productId)
              .get();
          
          if (productDoc.exists) {
            final currentStock = (productDoc.get('stockQuantity') as num?)?.toInt() ?? 0;
            final newStock = (currentStock - booking.quantity).clamp(0, double.infinity).toInt();
            
            await _firestore
                .collection('products')
                .doc(booking.productId)
                .update({
              'stockQuantity': newStock,
            });
            
            print('✅ Stock decreased: ${booking.productName} - Old: $currentStock, New: $newStock');
          }
        } catch (e) {
          print('⚠️ Error decreasing stock: $e');
          // Don't throw - booking confirmation was successful, stock update is secondary
        }
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to confirm booking: $e';
    }
  }

  /// Shop owner or list creator cancels booking from notification
  Future<void> cancelBookingFromNotification({required String bookingId}) async {
    await _ensureInitialized();

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'CANCELLED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to cancel booking: $e';
    }
  }
}
