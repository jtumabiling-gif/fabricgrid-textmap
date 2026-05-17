import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/shop_owner_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import 'payment_method_screen.dart';

class BookingConfirmationScreenFirebase extends StatefulWidget {

  const BookingConfirmationScreenFirebase({
    required this.shopOwnerId, required this.productId, required this.productName, required this.productPrice, required this.bookingType, required this.startDate, required this.quantity, required this.totalPrice, super.key,
    this.endDate,
    this.notes,
  });
  final String shopOwnerId;
  final String productId;
  final String productName;
  final double productPrice;
  final String bookingType;
  final DateTime startDate;
  final DateTime? endDate;
  final int quantity;
  final double totalPrice;
  final String? notes;

  @override
  State<BookingConfirmationScreenFirebase> createState() =>
      _BookingConfirmationScreenFirebaseState();
}

class _BookingConfirmationScreenFirebaseState
    extends State<BookingConfirmationScreenFirebase> {
  late BookingService _bookingService;
  late UserProfileService _userProfileService;
  late ShopOwnerService _shopOwnerService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;
  String? _generatedBookingId;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService();
    _userProfileService = UserProfileService();
    _shopOwnerService = ShopOwnerService();
    _createAndSaveBooking();
  }

  Future<void> _createAndSaveBooking() async {
    setState(() => _isProcessing = true);

    try {
      // Ensure booking service is initialized
      await _bookingService.initialize();
      
      // 1. Create booking in Firebase
      final bookingId = await _bookingService.createBooking(
        shopOwnerId: widget.shopOwnerId,
        productId: widget.productId,
        productName: widget.productName,
        productPrice: widget.productPrice,
        bookingType: widget.bookingType,
        startDate: widget.startDate,
        endDate: widget.endDate,
        quantity: widget.quantity,
        totalPrice: widget.totalPrice,
        notes: widget.notes,
      );

      // Store booking ID immediately after successful creation
      if (mounted) {
        setState(() {
          _generatedBookingId = bookingId;
        });
      }

      // 2. Update user profile counters (non-critical, don't fail if errors occur)
      try {
        if (widget.bookingType == 'BOOK') {
          await _userProfileService.incrementBookingCount();
        } else if (widget.bookingType == 'RESERVE') {
          await _userProfileService.incrementReservationCount();
        } else if (widget.bookingType == 'RENT') {
          await _userProfileService.incrementRentalCount();
        }
      } catch (e) {
        print('Warning: Failed to update user profile: $e');
        // Non-critical - continue
      }

      // 3. Update shop owner counters (non-critical, don't fail if errors occur)
      try {
        if (widget.bookingType == 'BOOK') {
          await _shopOwnerService.incrementBookingCount();
        } else if (widget.bookingType == 'RESERVE') {
          await _shopOwnerService.incrementReservationCount();
        } else if (widget.bookingType == 'RENT') {
          await _shopOwnerService.incrementRentalCount();
        }
      } catch (e) {
        print('Warning: Could not update shop owner booking count: $e');
        // Non-critical - continue
      }

      // 4. Add revenue to shop owner (non-critical, don't fail if errors occur)
      try {
        await _shopOwnerService.addRevenue(widget.totalPrice);
      } catch (e) {
        print('Warning: Failed to add revenue: $e');
        // Non-critical - continue
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Show success message
        Get.snackbar(
          'Booking Confirmed',
          'Successfully booked a product. You can check your booking list for confirmation and payment',
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
          duration: const Duration(seconds: 4),
        );
        
        Future.delayed(const Duration(seconds: 3), _navigateToMyBookings);
      }
    } catch (e) {
      if (mounted) {
        // If booking creation itself failed, show error
        print('Error creating booking: $e');
        setState(() => _isProcessing = false);
        
        // Show error dialog
        _showErrorDialog('Booking Failed', 'Unable to process your booking. Please try again.');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToProducts();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _navigateToHome() => Get.offAllNamed('/discover');
  void _navigateToMyBookings() => Get.offAllNamed('/discover');
  void _navigateToProducts() {
    // Navigate back to landing page and select products tab
    Get.offAllNamed('/discover');
  }

  void _navigateToPayment(String bookingId) {
    // Create a Booking object from widget data
    final booking = Booking(
      id: bookingId,
      userId: _auth.currentUser?.uid ?? '',
      shopOwnerId: widget.shopOwnerId,
      productId: widget.productId,
      productName: widget.productName,
      productPrice: widget.productPrice,
      bookingType: widget.bookingType,
      bookingDate: DateTime.now(),
      startDate: widget.startDate,
      endDate: widget.endDate,
      quantity: widget.quantity,
      totalPrice: widget.totalPrice,
      status: 'PENDING',
      paymentStatus: 'PENDING',
      createdAt: DateTime.now(),
      notes: widget.notes,
      userConfirmed: false,
    );

    Get.to(
      () => PaymentMethodScreen(
        bookingId: bookingId,
        booking: booking,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(elevation: 0, automaticallyImplyLeading: false),
        body: _buildBody(),
      ),
    );

  Widget _buildBody() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1EDDAC).withOpacity(0.1),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1EDDAC)),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing Your Booking...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we confirm your booking',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_generatedBookingId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '❌ Booking Failed',
                style: AppTheme.headingLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to process your booking at this moment. Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  label: const Text(
                    'Back to Products',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.accentColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text('✅ Successfully Booked!', style: AppTheme.headingLarge),
            const SizedBox(height: 12),
            Text(
              'Your ${widget.bookingType.toLowerCase()} for ${widget.productName} has been confirmed.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B3F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Booking ID:', _generatedBookingId!),
                  const SizedBox(height: 8),
                  _buildDetailRow('Type:', widget.bookingType),
                  const SizedBox(height: 8),
                  _buildDetailRow('Product:', widget.productName),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Start Date:',
                    '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}',
                  ),
                  if (widget.endDate != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'End Date:',
                      '${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow('Quantity:', widget.quantity.toString()),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: const Color(0xFF1EDDAC).withOpacity(0.1),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Total Price:',
                    '₱${widget.totalPrice.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToPayment(_generatedBookingId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.payment, color: Colors.black87),
                    label: const Text(
                      'Proceed to Payment',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _navigateToMyBookings,
                        icon: const Icon(Icons.bookmark, color: Color(0xFF1EDDAC)),
                        label: const Text(
                          'My Bookings',
                          style: TextStyle(color: Color(0xFF1EDDAC)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF1EDDAC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _navigateToHome,
                        icon: const Icon(Icons.home, color: Color(0xFF1EDDAC)),
                        label: const Text(
                          'Home',
                          style: TextStyle(color: Color(0xFF1EDDAC)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF1EDDAC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          value,
          style: isHighlight
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.bodyLarge,
        ),
      ],
    );
}
