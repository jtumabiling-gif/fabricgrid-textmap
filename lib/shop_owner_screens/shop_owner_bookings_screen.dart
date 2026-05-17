import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../utils/responsive_helper.dart';

class ShopOwnerBookingsScreen extends StatefulWidget {
  const ShopOwnerBookingsScreen({super.key});

  @override
  State<ShopOwnerBookingsScreen> createState() =>
      _ShopOwnerBookingsScreenState();
}

class _ShopOwnerBookingsScreenState extends State<ShopOwnerBookingsScreen> {
  late BookingService _bookingService;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedTab = 'PENDING';

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      await _bookingService.initialize();
      
      final bookings = await _bookingService.getShopOwnerBookings();
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  List<Booking> _getFilteredBookings() {
    if (_selectedTab == 'PENDING') {
      // Show only PENDING bookings
      // For product bookings: user has confirmed (userConfirmed=true)
      // For service bookings: all PENDING (userConfirmed may be false)
      return _bookings.where((booking) => 
        booking.status == 'PENDING'
      ).toList();
    } else if (_selectedTab == 'COMPLETED') {
      // Show completed bookings
      return _bookings.where((booking) => booking.status == 'COMPLETED').toList();
    } else if (_selectedTab == 'CANCELLED') {
      // Show cancelled bookings
      return _bookings.where((booking) => booking.status == 'CANCELLED').toList();
    }
    return [];
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      // Find the booking in the list
      late Booking booking;
      late bool isServiceBooking;
      
      try {
        booking = _bookings.firstWhere((b) => b.id == bookingId);
        isServiceBooking = booking.bookingType == 'SERVICE';
      } catch (e) {
        throw 'Booking not found';
      }

      // Update based on booking type
      if (isServiceBooking) {
        // Update service booking in book_service collection
        await _bookingService.updateServiceBookingStatus(
          bookingId: bookingId,
          status: newStatus,
        );
      } else {
        // Update product booking
        await _bookingService.updateBookingStatus(
          bookingId: bookingId,
          status: newStatus,
        );
      }
      
      // Reload all bookings to move items between tabs
      await _fetchBookings();
      
      // Send notification to user (wrapped in try-catch to not block UI)
      try {
        final notificationService = NotificationService();
        await notificationService.initialize();
        
        if (newStatus == 'COMPLETED') {
          await notificationService.createNotification(
            userId: booking.userId,
            title: 'Booking Confirmed!',
            message: 'Your ${booking.productName} booking has been confirmed by the shop owner.',
            type: 'booking_confirmed',
            bookingId: bookingId,
            data: {
              'productName': booking.productName,
              'bookingType': booking.bookingType,
              'totalPrice': booking.totalPrice,
            },
          );
        } else if (newStatus == 'CANCELLED') {
          await notificationService.createNotification(
            userId: booking.userId,
            title: 'Booking Cancelled',
            message: 'Your ${booking.productName} booking has been cancelled by the shop owner.',
            type: 'booking_cancelled',
            bookingId: bookingId,
            data: {
              'productName': booking.productName,
              'bookingType': booking.bookingType,
              'totalPrice': booking.totalPrice,
            },
          );
        }
      } catch (e) {
        print('⚠️ Notification error (non-blocking): $e');
        // Don't throw - status update was successful
      }
      
      if (mounted) {
        var title = '';
        var message = '';
        if (newStatus == 'COMPLETED') {
          title = 'Success!';
          message = 'Booking confirmed! Customer has been notified.';
          setState(() => _selectedTab = 'COMPLETED');
        } else if (newStatus == 'CANCELLED') {
          title = 'Success!';
          message = 'Booking cancelled! Customer has been notified.';
          setState(() => _selectedTab = 'CANCELLED');
        }
        Get.snackbar(
          title,
          message,
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error updating booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFB84D);
      case 'CONFIRMED':
        return const Color(0xFF1EDDAC);
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookingCard(Booking booking) => Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveCardPadding(context).top),
      padding: ResponsiveHelper.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.userName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                booking.bookingType,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Color(0xFF1EDDAC)),
              const SizedBox(width: 8),
              Text(
                '₱${booking.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (booking.status == 'PENDING')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateBookingStatus(booking.id, 'COMPLETED'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1EDDAC),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateBookingStatus(booking.id, 'CANCELLED'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )

        ],
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ORDERS MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bookings (${_bookings.length} Total)',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Tab buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('PENDING'),
                    const SizedBox(width: 12),
                    _buildTabButton('COMPLETED'),
                    const SizedBox(width: 12),
                    _buildTabButton('CANCELLED'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1EDDAC),
                  ),
                )
              else if (_getFilteredBookings().isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedTab bookings',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'When customers book, they\'ll appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _getFilteredBookings()
                      .map(_buildBookingCard)
                      .toList(),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );

  Widget _buildTabButton(String status) {
    final isSelected = _selectedTab == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1EDDAC)
              : const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1EDDAC)
                : Colors.white12,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}