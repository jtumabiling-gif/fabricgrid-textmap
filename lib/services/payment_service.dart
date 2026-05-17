import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize payment service
  Future<void> initialize() async {
    // Payment service initialization if needed
  }

  /// Process payment for a booking
  Future<String> processPayment({
    required String bookingId,
    required String paymentMethod,
    required double amount,
    required String currency,
    String? cardHolderName,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? phoneNumber,
    String? bankName,
    String? accountHolderName,
    Map<String, dynamic>? bookingSummaryData,
    String? shopOwnerIdOverride,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      if (bookingId.isEmpty) throw Exception('Invalid booking ID');
      if (amount <= 0) throw Exception('Invalid payment amount');
      if (paymentMethod.isEmpty) throw Exception('Payment method is required');

      // Fetch user profile to get full name
      var userName = '';
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['fullName'] ?? '';
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }

      // Fetch booking details for summary (check both bookings and book_service collections)
      var bookingSummary = <String, dynamic>{};
      var shopOwnerId = shopOwnerIdOverride ?? '';
      
      // First, try to use provided booking summary data (from client)
      if (bookingSummaryData != null && bookingSummaryData.isNotEmpty) {
        print('DEBUG: Using provided bookingSummaryData from client');
        bookingSummary = bookingSummaryData;
        if (shopOwnerId.isEmpty) {
          shopOwnerId = bookingSummaryData['shopOwnerId'] ?? '';
        }
      } else {
        // Fall back to fetching from Firestore if no data was provided
        try {
          // Add a small delay to ensure booking is committed to Firestore
          await Future.delayed(const Duration(milliseconds: 500));
          
          print('DEBUG: Attempting to fetch booking with ID: $bookingId');
          
          // First try to fetch from 'bookings' collection (for product bookings)
          var bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
          print('DEBUG: Looking for booking in bookings collection: $bookingId');
          print('DEBUG: Booking found in bookings: ${bookingDoc.exists}');
          
          // If not found, try 'book_service' collection (for service bookings)
          if (!bookingDoc.exists) {
            print('DEBUG: Booking not found in bookings, trying book_service collection');
            bookingDoc = await _firestore.collection('book_service').doc(bookingId).get();
            print('DEBUG: Booking found in book_service: ${bookingDoc.exists}');
          }

          if (bookingDoc.exists) {
            final bookingData = bookingDoc.data() ?? {};
            print('DEBUG: Booking data retrieved: $bookingData');
            
            shopOwnerId = bookingData['shopOwnerId'] ?? '';
            
            // Build booking summary from booking data
            // Handle both product bookings and service bookings
            final productName = bookingData['productName'] ?? bookingData['serviceName'] ?? '';
            final quantity = (bookingData['quantity'] ?? 1).toInt();
            final productPrice = (bookingData['productPrice'] ?? bookingData['price'] ?? bookingData['basePrice'] ?? 0.0).toDouble();
            final bookingType = bookingData['bookingType'] ?? 'SERVICE';
            final bookingDate = bookingData['bookingDate'] ?? bookingData['selectedDate'];
            final startDate = bookingData['startDate'] ?? bookingData['serviceDate'];
            final endDate = bookingData['endDate'];
            final totalPrice = (bookingData['totalPrice'] ?? bookingData['price'] ?? 0.0).toDouble();
            
            print('DEBUG: Extracted productName: $productName, quantity: $quantity, productPrice: $productPrice, totalPrice: $totalPrice');
            
            bookingSummary = {
              'productName': productName,
              'quantity': quantity,
              'productPrice': productPrice,
              'totalPrice': totalPrice,
              'bookingType': bookingType,
              'bookingDate': bookingDate,
              'startDate': startDate,
              'endDate': endDate,
            };
            
            print('DEBUG: Final bookingSummary: $bookingSummary');
          } else {
            print('DEBUG: Booking document not found in either collection for ID: $bookingId');
          }
        } catch (e) {
          print('Error fetching booking details: $e');
          print('DEBUG: Stack trace: ${StackTrace.current}');
        }
      }

      // Create payment record
      final paymentId = _firestore.collection('payments').doc().id;
      
      final paymentData = <String, dynamic>{
        'paymentId': paymentId,
        'bookingId': bookingId,
        'userId': userId,
        'shopOwnerId': shopOwnerId,
        'userName': userName,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'currency': currency,
        'status': 'COMPLETED',
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': FieldValue.serverTimestamp(),
      };
      
      // Only add bookingSummary if it has content
      if (bookingSummary.isNotEmpty) {
        paymentData['bookingSummary'] = bookingSummary;
        print('DEBUG: bookingSummary added to payment: $bookingSummary');
      } else {
        print('DEBUG: WARNING - bookingSummary is empty, not adding to payment data');
      }

      // Add sensitive payment data (in production, use Stripe/PayPal tokenization)
      if (paymentMethod == 'CREDIT_CARD' || paymentMethod == 'DEBIT_CARD') {
        // Add individual card fields for backward compatibility
        if (cardHolderName != null && cardHolderName.isNotEmpty) {
          paymentData['cardHolderName'] = cardHolderName;
        }
        if (cardNumber != null && cardNumber.isNotEmpty) {
          paymentData['cardLast4'] = cardNumber.length >= 4 
              ? cardNumber.substring(cardNumber.length - 4) 
              : cardNumber;
          paymentData['cardNumberMasked'] = cardNumber.length >= 4
              ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}'
              : cardNumber;
        }
        if (expiryDate != null && expiryDate.isNotEmpty) {
          final parts = expiryDate.split('/');
          if (parts.length == 2) {
            paymentData['expiryMonth'] = parts[0];
            paymentData['expiryYear'] = parts[1];
          }
        }
        
        // Add structured cardDetails object for service bookings
        final cardDetails = <String, dynamic>{};
        if (cardHolderName != null && cardHolderName.isNotEmpty) {
          cardDetails['cardHolderName'] = cardHolderName;
        }
        if (cardNumber != null && cardNumber.isNotEmpty) {
          cardDetails['cardLast4'] = cardNumber.length >= 4 
              ? cardNumber.substring(cardNumber.length - 4) 
              : cardNumber;
          cardDetails['cardNumberMasked'] = cardNumber.length >= 4
              ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}'
              : cardNumber;
        }
        if (expiryDate != null && expiryDate.isNotEmpty) {
          final parts = expiryDate.split('/');
          if (parts.length == 2) {
            cardDetails['expiryMonth'] = parts[0];
            cardDetails['expiryYear'] = parts[1];
          }
        }
        if (cardDetails.isNotEmpty) {
          paymentData['cardDetails'] = cardDetails;
        }
      } else if (paymentMethod == 'BANK_TRANSFER') {
        if (bankName != null && bankName.isNotEmpty) {
          paymentData['bankName'] = bankName;
        }
        if (accountHolderName != null && accountHolderName.isNotEmpty) {
          paymentData['accountHolderName'] = accountHolderName;
        }
      } else if (paymentMethod == 'E_WALLET') {
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          paymentData['phoneNumber'] = phoneNumber;
        }
      }

      // Save payment to Firestore
      await _firestore.collection('payments').doc(paymentId).set(paymentData);

      // Update booking status - try both collections
      final updateData = {
        'status': 'PENDING',  // Move booking to PENDING status
        'paymentStatus': 'COMPLETED',
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'paymentDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        // Try to update bookings collection
        await _firestore.collection('bookings').doc(bookingId).update(updateData);
      } catch (e) {
        print('Error updating bookings collection: $e');
        try {
          // If that fails, try book_service collection
          await _firestore.collection('book_service').doc(bookingId).update(updateData);
        } catch (e2) {
          print('Error updating book_service collection: $e2');
          // Don't throw - payment was already created successfully
        }
      }

      return paymentId;
    } catch (e) {
      print('Error processing payment: $e');
      rethrow;
    }
  }

  /// Get payment history for user
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      rethrow;
    }
  }

  /// Get payment details by payment ID
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      return doc.data();
    } catch (e) {
      print('Error fetching payment details: $e');
      rethrow;
    }
  }

  /// Refund a payment
  Future<void> refundPayment({
    required String paymentId,
    required String bookingId,
    String? reason,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      // Create refund record
      final refundId = _firestore.collection('refunds').doc().id;

      await _firestore.collection('refunds').doc(refundId).set({
        'refundId': refundId,
        'paymentId': paymentId,
        'bookingId': bookingId,
        'userId': userId,
        'status': 'PROCESSED',
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update payment status
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'REFUNDED',
        'refundId': refundId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentStatus': 'REFUNDED',
        'status': 'CANCELLED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error refunding payment: $e');
      rethrow;
    }
  }
}
