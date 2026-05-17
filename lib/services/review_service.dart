import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_model.dart';

class ReviewService {
  factory ReviewService() => _instance;

  ReviewService._internal();
  static final ReviewService _instance = ReviewService._internal();
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

  /// Submit a new review
  Future<String> submitReview({
    required String bookingId,
    required String shopOwnerId,
    required String shopOwnerName,
    required String productId,
    required String productName,
    required int rating,
    required String reviewText,
    required List<String> tags,
  }) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated. Please login first.';
      }

      final userName =
          _firebaseAuth.currentUser?.displayName ??
          _firebaseAuth.currentUser?.email ??
          'Anonymous User';

      final reviewData = {
        'bookingId': bookingId,
        'userId': userId,
        'userName': userName,
        'shopOwnerId': shopOwnerId,
        'shopOwnerName': shopOwnerName,
        'productId': productId,
        'productName': productName,
        'rating': rating,
        'reviewText': reviewText,
        'tags': tags,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection('reviews').add(reviewData);

      return docRef.id;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to submit review: $e';
    }
  }

  /// Get reviews for a specific shop owner
  Future<List<Review>> getShopOwnerReviews(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // If index error, fallback to simple query without orderBy
      if (e.code == 'failed-precondition' ||
          e.message?.contains('index') == true) {
        final snapshot = await _firestore
            .collection('reviews')
            .where('shopOwnerId', isEqualTo: shopOwnerId)
            .get();

        final reviews = snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList();

        // Sort in memory by createdAt
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      }
      rethrow;
    } catch (e) {
      throw 'Failed to retrieve reviews: $e';
    }
  }

  /// Get reviews for a specific product
  Future<List<Review>> getProductReviews(String productId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // If index error, fallback to simple query without orderBy
      if (e.code == 'failed-precondition' ||
          e.message?.contains('index') == true) {
        final snapshot = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();

        final reviews = snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList();

        // Sort in memory by createdAt
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      }
      rethrow;
    } catch (e) {
      throw 'Failed to retrieve reviews: $e';
    }
  }

  /// Get user's reviews
  Future<List<Review>> getUserReviews(String userId) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      // If index error, fallback to simple query without orderBy
      if (e.code == 'failed-precondition' ||
          e.message?.contains('index') == true) {
        final snapshot = await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .get();

        final reviews = snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList();

        // Sort in memory by createdAt
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      }
      rethrow;
    } catch (e) {
      throw 'Failed to retrieve reviews: $e';
    }
  }

  /// Check if user has already reviewed a booking
  Future<bool> hasReviewedBooking(String bookingId) async {
    await _ensureInitialized();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to check review: $e';
    }
  }

  /// Get average rating for a shop owner
  Future<double> getAverageRating(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final reviews = await getShopOwnerReviews(shopOwnerId);
      if (reviews.isEmpty) return 0.0;

      final totalRating =
          reviews.fold<int>(0, (sum, review) => sum + review.rating);
      return totalRating / reviews.length;
    } catch (e) {
      throw 'Failed to calculate average rating: $e';
    }
  }

  /// Get review count for a shop owner
  Future<int> getReviewCount(String shopOwnerId) async {
    await _ensureInitialized();

    try {
      final reviews = await getShopOwnerReviews(shopOwnerId);
      return reviews.length;
    } catch (e) {
      throw 'Failed to get review count: $e';
    }
  }

  /// Delete a review (only by the reviewer or admin)
  Future<void> deleteReview(String reviewId) async {
    await _ensureInitialized();

    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message}';
    } catch (e) {
      throw 'Failed to delete review: $e';
    }
  }

  /// Stream of shop owner's reviews (real-time)
  Stream<List<Review>> getShopOwnerReviewsStream(String shopOwnerId) => _firestore
        .collection('reviews')
        .where('shopOwnerId', isEqualTo: shopOwnerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());

  /// Get average rating for a shop owner (real-time stream)
  Stream<double> getShopOwnerAverageRatingStream(String shopOwnerId) =>
      _firestore
          .collection('reviews')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return 0.0;
        final reviews = snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList();
        final totalRating =
            reviews.fold<int>(0, (sum, review) => sum + review.rating);
        return totalRating / reviews.length;
      });

  /// Get review count for a shop owner (real-time stream)
  Stream<int> getShopOwnerReviewCountStream(String shopOwnerId) =>
      _firestore
          .collection('reviews')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

  /// Get average rating for a product by product name (real-time)
  Stream<double> getProductRatingByNameStream(String productName) =>
      _firestore
          .collection('reviews')
          .where('productName', isEqualTo: productName)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return 0.0;
        final reviews = snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList();
        final totalRating =
            reviews.fold<int>(0, (sum, review) => sum + review.rating);
        return totalRating / reviews.length;
      });

  /// Get review count for a product by product name (real-time)
  Stream<int> getProductReviewCountByNameStream(String productName) =>
      _firestore
          .collection('reviews')
          .where('productName', isEqualTo: productName)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

  /// Get average rating for a product by product name
  Future<double> getProductRatingByName(String productName) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productName', isEqualTo: productName)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final reviews = snapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
      final totalRating =
          reviews.fold<int>(0, (sum, review) => sum + review.rating);
      return totalRating / reviews.length;
    } catch (e) {
      throw 'Failed to calculate average rating: $e';
    }
  }

  /// Get review count for a product by product name
  Future<int> getProductReviewCountByName(String productName) async {
    await _ensureInitialized();

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productName', isEqualTo: productName)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw 'Failed to get review count: $e';
    }
  }
}
