import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import 'payment_method_screen.dart';
import 'review_submission_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingService _bookingService;
  late ReviewService _reviewService;
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  Set<String> _reviewedBookingIds = {};
  final Map<String, String> _shopOwnerNameCache = {}; // Cache for shop owner names

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingService = BookingService();
    _reviewService = ReviewService();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      await _bookingService.initialize();
      await _reviewService.initialize();
      final bookings = await _bookingService.getUserBookings();
      
      // Check which bookings have been reviewed
      final reviewedIds = <String>{};
      for (final booking in bookings) {
        final hasReviewed = await _reviewService.hasReviewedBooking(booking.id);
        if (hasReviewed) {
          reviewedIds.add(booking.id);
        }
      }
      
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _reviewedBookingIds = reviewedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error only if there are actual errors (not just empty results)
        if (e.toString().isNotEmpty && !e.toString().contains('index')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading bookings: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      if (newStatus == 'CONFIRMED') {
        // User confirming the booking - this sends it to shop owner
        await _bookingService.confirmBookingByUser(bookingId: bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking confirmed! Sent to shop owner for review.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (newStatus == 'CANCELLED') {
        // User cancelling the booking
        await _bookingService.cancelBooking(bookingId: bookingId);
        if (mounted) {
          Get.snackbar(
            'Booking Cancelled',
            'Your booking has been cancelled successfully.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
      // Reload bookings to move items between sections
      await _loadBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  Future<String> _getShopOwnerName(String shopOwnerId) async {
    // Check cache first
    if (_shopOwnerNameCache.containsKey(shopOwnerId)) {
      return _shopOwnerNameCache[shopOwnerId]!;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final shopOwnerDoc = await firestore
          .collection('shop_owners')
          .doc(shopOwnerId)
          .get();
      
      if (shopOwnerDoc.exists) {
        final data = shopOwnerDoc.data() as Map<String, dynamic>;
        print('Shop owner data: $data');
        
        // Try multiple field names that might contain the shop owner name
        final shopName = data['shopName'] ?? 
                        data['shop_name'] ?? 
                        data['name'] ?? 
                        data['ownerFullName'] ?? 
                        data['ownerName'] ??
                        data['firstName'];
        
        if (shopName != null && shopName.toString().isNotEmpty) {
          print('Found shop name: $shopName');
          final result = shopName.toString();
          _shopOwnerNameCache[shopOwnerId] = result; // Cache it
          return result;
        }
      } else {
        print('Shop owner document does not exist for ID: $shopOwnerId');
      }
      
      print('Could not find shop owner name, returning default');
      _shopOwnerNameCache[shopOwnerId] = 'Shop Owner'; // Cache the default
      return 'Shop Owner';
    } catch (e) {
      print('Error fetching shop owner name: $e');
      _shopOwnerNameCache[shopOwnerId] = 'Shop Owner'; // Cache the error result
      return 'Shop Owner';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Booking> _getFilteredBookings(String status) {
    if (_allBookings.isEmpty) return [];
    
    switch (status) {
      case 'Upcoming':
        // Show bookings that are waiting for payment, pending shop owner confirmation, or already confirmed
        // For user listings with completed payment, they are NOT included in Upcoming (they go to Completed)
        return _allBookings
            .where((b) {
              // If it's a user listing with completed payment, show in Completed tab instead
              if (b.isUserListing && b.paymentStatus == 'COMPLETED' && b.status == 'PENDING') {
                return false;
              }
              return b.status == 'UNPAID' || b.status == 'PENDING' || b.status == 'CONFIRMED';
            })
            .toList();
      case 'Completed':
        // Show completed bookings OR user listings with completed payment
        return _allBookings
            .where((b) => 
              b.status == 'COMPLETED' || 
              (b.isUserListing && b.paymentStatus == 'COMPLETED' && b.status == 'PENDING'))
            .toList();
      case 'Cancelled':
        return _allBookings.where((b) => b.status == 'CANCELLED').toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0F1F2F),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList('Upcoming'),
                  _buildBookingsList('Completed'),
                  _buildBookingsList('Cancelled'),
                ],
              ),
            ),
    );

  Widget _buildBookingsList(String status) {
    final bookings = _getFilteredBookings(status);

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No $status bookings',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          color: const Color(0xFF1A2B3F),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                        style: AppTheme.headingMedium.copyWith(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getBookingStatusColor(booking.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: _getBookingStatusColor(booking.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.productName,
                            style: AppTheme.bodyLarge.copyWith(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FutureBuilder<String>(
                            future: _getShopOwnerName(booking.shopOwnerId),
                            builder: (context, snapshot) {
                              final shopOwnerName = snapshot.data ?? 'Shop Owner';
                              return Text(
                                'Shop: $shopOwnerName',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          Text(
                            '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          if (booking.bookingType == 'SERVICE')
                            Text(
                              '${booking.startDate.hour.toString().padLeft(2, '0')}:${booking.startDate.minute.toString().padLeft(2, '0')}',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Duration', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          Text(
                            booking.bookingType == 'SERVICE' ? 'Service' : booking.bookingType,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Amount', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          Text(
                            '₱${(booking.totalPrice > 0 ? booking.totalPrice : booking.productPrice).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1EDDAC)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          booking.notes!,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'Upcoming' && booking.status == 'UNPAID') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to payment method screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentMethodScreen(
                                  bookingId: booking.id,
                                  booking: booking,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadBookings();
                              }
                            });
                          },
                          icon: const Icon(Icons.payment, size: 14),
                          label: const Text('Pay Now', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateBookingStatus(booking.id, 'CANCELLED'),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'Upcoming' && booking.status == 'PENDING' && !booking.userConfirmed) ...[
                  const SizedBox(height: 8),
                  // Check if payment has been completed
                  if (booking.paymentStatus == 'COMPLETED')
                    // If it's a user listing, show as completed; otherwise show waiting message
                    if (booking.isUserListing)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Purchase Complete',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your purchase has been successfully completed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentColor, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: AppTheme.accentColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Payment Completed',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waiting for shop owner to confirm your booking',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.accentColor.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to payment method screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentMethodScreen(
                                    bookingId: booking.id,
                                    booking: booking,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment, size: 14),
                            label: const Text('Confirm & Pay', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1EDDAC),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateBookingStatus(booking.id, 'CANCELLED'),
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
                if (status == 'Upcoming' && booking.status == 'CONFIRMED' && booking.userConfirmed) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.accentColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Waiting for shop owner confirmation',
                            style: TextStyle(
                              color: AppTheme.accentColor.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'Completed') ...[
                  const SizedBox(height: 8),
                  if (_reviewedBookingIds.contains(booking.id))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Review Submitted',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReviewSubmissionScreen(booking: booking),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadBookings();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1EDDAC),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Leave Review', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBookingStatusColor(String bookingStatus) {
    switch (bookingStatus.toUpperCase()) {
      case 'UNPAID':
        return Colors.orange;
      case 'PENDING':
        return AppTheme.primaryColor;
      case 'CONFIRMED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
