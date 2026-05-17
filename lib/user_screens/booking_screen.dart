import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/user_profile_service.dart';
import '../utils/responsive_helper.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Map<String, dynamic> _product;
  late String _selectedDuration;
  late TextEditingController _notesController;
  late TextEditingController _addressController;
  bool _isProcessing = false;
  double _commissionFee = 0;
  String _sellerTier = 'Standard'; // 'Standard' or 'Premium'
  int _commissionPercentage = 5; // 5% or 10%
  bool _hasActiveSubscription = false;

  late UserProfileService _userProfileService;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _addressController = TextEditingController();
    _userProfileService = UserProfileService();

    // Get product data from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _product = args;
      _selectedDuration = _product['selectedDuration'] ?? '1 Day';
      
      // Get seller tier and calculate commission
      _sellerTier = _product['sellerTier'] ?? 'Standard';
      _commissionPercentage = _sellerTier == 'Premium' ? 10 : 5;
      
      // Calculate commission fee based on total price
      final totalPrice = (_product['price'] ?? 0.0) as num;
      _commissionFee = (totalPrice.toDouble() * _commissionPercentage) / 100;
      
      // Check if shop owner has active subscription
      _checkActiveSubscription();
    } else {
      _product = {};
      _selectedDuration = '1 Day';
      _sellerTier = 'Standard';
      _commissionPercentage = 5;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveSubscription() async {
    try {
      final shopOwnerId = _product['shopOwnerId'] ?? '';
      if (shopOwnerId.isEmpty) {
        setState(() => _hasActiveSubscription = false);
        return;
      }

      // Check if shop owner has an active subscription
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('shopOwnerId', isEqualTo: shopOwnerId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      setState(() {
        _hasActiveSubscription = subscriptionQuery.docs.isNotEmpty;
        // Recalculate commission fee based on subscription status
        final totalPrice = _calculateTotalPrice();
        _commissionFee = _hasActiveSubscription 
          ? (totalPrice * _commissionPercentage) / 100 
          : 0;
      });
    } catch (e) {
      setState(() => _hasActiveSubscription = false);
    }
  }

  int _getDurationDays() {
    switch (_selectedDuration) {
      case '1 Day':
        return 1;
      case '3 Days':
        return 3;
      case '1 Week':
        return 7;
      default:
        return 1;
    }
  }

  double _calculateTotalPrice() {
    final price = (_product['price'] ?? 0.0) as num;
    final baseTotal = price.toDouble();
    
    // Add commission only if shop owner has active subscription
    if (_hasActiveSubscription) {
      return baseTotal + (baseTotal * _commissionPercentage) / 100;
    }
    return baseTotal;
  }

  Future<void> _confirmBooking() async {
    // Validate that address field is filled
    if (_addressController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an address',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not authenticated. Please login first.';
      }

      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: _getDurationDays()));
      final totalPrice = _calculateTotalPrice();

      // Get user's name from authentication or profile
      final userName = user.displayName ?? user.email ?? 'Unknown User';

      // Get product category if available
      final productType = _product['category'] ?? 'Other';

      // Create booking data
      final bookingData = {
        'userId': user.uid,
        'userName': userName,
        'shopOwnerId': _product['shopOwnerId'] ?? '',
        'productId': _product['productId'] ?? _product['id'] ?? '',
        'productName': _product['productName'] ?? 'Product',
        'productPrice': (_product['price'] ?? 0.0).toDouble(),
        'bookingType': 'RENT',
        'bookingDate': Timestamp.fromDate(DateTime.now()),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'quantity': 1,
        'price': totalPrice,  // This is the final total with commission
        'totalPrice': totalPrice,
        'status': 'PENDING',
        'paymentStatus': 'PENDING',
        'address': _addressController.text,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'userConfirmed': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'commissionFee': _hasActiveSubscription ? _commissionFee : 0,
        'commissionPercentage': _commissionPercentage,
        'subscriptionTier': _sellerTier,
        'hasActiveSubscription': _hasActiveSubscription,
        'productType': productType,
      };

      // Create booking in Firebase bookings collection
      await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Try to update user rental count (non-critical)
      try {
        await _userProfileService.incrementRentalCount();
      } catch (e) {
        print('Warning: Could not update rental count: $e');
      }

      if (mounted) {
        // Show success message
        Get.snackbar(
          'Order Confirmed',
          'Your order has been confirmed. You can check it in your order list, confirm and pay',
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
        );
        
        // Navigate back to market screen
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        // Show error dialog instead of snackbar
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: Get.back,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        title: const Text(
          'Order a Product',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0F1F2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Details Section
              _buildProductSection(),
              const SizedBox(height: 24),

              // Commission Fee Section (only if shop owner has subscription)
              if (_hasActiveSubscription)
                Column(
                  children: [
                    _buildCommissionSection(),
                    const SizedBox(height: 24),
                  ],
                ),

              // Address Section
              _buildAddressSection(),
              const SizedBox(height: 24),

              // Booking Notes Section
              _buildNotesSection(),
              const SizedBox(height: 24),

              // Booking Summary Section
              _buildSummarySection(),
              const SizedBox(height: 24),

              // Confirm Booking Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

  Widget _buildAddressSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DELIVERY ADDRESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Enter delivery address',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1A2B3F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1EDDAC)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(color: Colors.white),
          minLines: 2,
          maxLines: 3,
        ),
      ],
    );

  Widget _buildProductSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECTED PRODUCT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1EDDAC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF1EDDAC).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1EDDAC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Color(0xFF1EDDAC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product['productName'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₱${(_product['price'] ?? 0.0).toStringAsFixed(2)}/day',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1EDDAC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_hasActiveSubscription)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _sellerTier == 'Premium'
                                  ? Colors.amber.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _sellerTier,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _sellerTier == 'Premium'
                                    ? Colors.amber[700]
                                    : Colors.blue[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildCommissionSection() {
    final price = (_product['price'] ?? 0.0) as num;
    final baseTotal = price.toDouble() * _getDurationDays();
    final commissionAmount = _hasActiveSubscription 
      ? (baseTotal * _commissionPercentage) / 100 
      : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATFORM FEE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _hasActiveSubscription
                    ? (_sellerTier == 'Premium' ? Colors.amber : Colors.blue)
                    : Colors.grey,
                width: 3,
              ),
            ),
            color: const Color(0xFF1EDDAC).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Tier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasActiveSubscription ? _sellerTier : 'None',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _hasActiveSubscription
                              ? (_sellerTier == 'Premium'
                                  ? Colors.amber[700]
                                  : Colors.blue[700])
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Commission ($_commissionPercentage%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${commissionAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1EDDAC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sellerTier == 'Premium'
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: _sellerTier == 'Premium'
                          ? Colors.amber[700]
                          : Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sellerTier == 'Premium'
                            ? 'Premium seller - 10% commission applied'
                            : 'Standard seller - 5% commission applied',
                        style: TextStyle(
                          fontSize: 11,
                          color: _sellerTier == 'Premium'
                              ? Colors.amber[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Add any special requests or notes',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1A2B3F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1EDDAC),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );

  Widget _buildSummarySection() {
    final price = (_product['price'] ?? 0.0) as num;
    final baseTotal = price.toDouble() * _getDurationDays();
    final commissionAmount = _hasActiveSubscription 
      ? (baseTotal * _commissionPercentage) / 100 
      : 0.0;
    final finalTotal = _calculateTotalPrice();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(
          left: BorderSide(
            color: Color(0xFF1EDDAC),
            width: 3,
          ),
        ),
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Product',
            _product['productName'] ?? 'Product',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Seller Tier', _hasActiveSubscription ? _sellerTier : 'Standard (No Subscription'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Price',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₱${baseTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Only show platform fee if shop owner has subscription
                if (_hasActiveSubscription) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Fee ($_commissionPercentage%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₱${commissionAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '₱${finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF1EDDAC),
                        fontSize: 16,
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
    );
  }

  Widget _buildSummaryRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
}