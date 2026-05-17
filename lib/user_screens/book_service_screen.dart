import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/service_model.dart';
import 'landing_page_screen.dart';

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  late Service _service;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  String _sellerTier = 'Standard';
  int _commissionPercentage = 5;
  double _commissionFee = 0;
  bool _hasActiveSubscription = false;

  final List<TimeOfDay> _availableTimes = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _service = Get.arguments as Service;
    // Initialize seller tier from service object
    if (_service.sellerTier != null) {
      _sellerTier = _service.sellerTier!;
      _commissionPercentage = _sellerTier == 'Premium' ? 10 : 5;
      _hasActiveSubscription = true;
      _commissionFee = (_service.price * _commissionPercentage) / 100;
    }
    _checkActiveSubscription();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveSubscription() async {
    try {
      // If service already has sellerTier, use it
      if (_service.sellerTier != null) {
        setState(() {
          _sellerTier = _service.sellerTier!;
          _commissionPercentage = _service.sellerTier! == 'Premium' ? 10 : 5;
          _commissionFee = (_service.price * _commissionPercentage) / 100;
          _hasActiveSubscription = true;
        });
        return;
      }

      final shopOwnerId = _service.shopOwnerId;
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

      if (subscriptionQuery.docs.isNotEmpty) {
        final subscription = subscriptionQuery.docs.first.data();
        final tier = subscription['subscriptionTier'] ?? 'Standard';
        final commissionPercentage = tier == 'Premium' ? 10 : 5;
        final commissionFee = (_service.price * commissionPercentage) / 100;

        setState(() {
          _hasActiveSubscription = true;
          _sellerTier = tier;
          _commissionPercentage = commissionPercentage;
          _commissionFee = commissionFee;
        });
      } else {
        setState(() {
          _hasActiveSubscription = false;
          _sellerTier = 'Standard';
          _commissionPercentage = 5;
          _commissionFee = 0;
        });
      }
    } catch (e) {
      setState(() => _hasActiveSubscription = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  Future<void> _confirmBooking() async {
    // Validate that all required fields are filled
    if (_selectedDate == null) {
      Get.snackbar(
        'Error',
        'Please select a date',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedTime == null) {
      Get.snackbar(
        'Error',
        'Please select a time',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get user details
      final userName = user.displayName ?? 'Unknown User';
      final userEmail = user.email ?? 'No Email';
      final userId = user.uid;

      // Combine date and time
      final bookingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Calculate total price including commission
      final totalPrice = _hasActiveSubscription 
        ? _service.price + _commissionFee 
        : _service.price;

      // Prepare booking data
      final bookingData = {
        'serviceId': _service.id,
        'productId': _service.id, // Add productId for consistency with payment service
        'serviceName': _service.serviceName,
        'productName': _service.serviceName, // Add productName for consistency
        'shopOwnerId': _service.shopOwnerId,
        'shopOwnerName': _service.shopOwnerName ?? 'Unknown',
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'price': totalPrice,
        'productPrice': _service.price, // Add productPrice for consistency
        'basePrice': _service.price,
        'quantity': 1, // Add quantity (always 1 for service bookings)
        'bookingType': 'SERVICE', // Add bookingType for consistency
        'commissionFee': _hasActiveSubscription ? _commissionFee : 0,
        'commissionPercentage': _commissionPercentage,
        'subscriptionTier': _sellerTier,
        'hasActiveSubscription': _hasActiveSubscription,
        'bookingDate': Timestamp.now(),
        'selectedDate': Timestamp.fromDate(_selectedDate!),
        'serviceDate': Timestamp.fromDate(bookingDateTime),
        'startDate': Timestamp.fromDate(bookingDateTime), // Add startDate for consistency
        'serviceTime': _selectedTime != null ? _formatTime(_selectedTime!) : 'Not selected',
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'status': 'PENDING',
        'paymentStatus': 'PENDING',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'totalPrice': totalPrice, // Add totalPrice for consistency
      };

      // Insert into Firestore book_service collection
      await FirebaseFirestore.instance
          .collection('book_service')
          .add(bookingData);

      // Show success message
      if (mounted) {
        Get.snackbar(
          'Booking Confirmed',
          'Your service booking has been confirmed',
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
        );

        // Navigate to landing page (discover tab)
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => const LandingPageScreen());
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save booking: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: Get.back,
            ),
          ),
        ),
        title: const Text(
          'Book a Service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Service Section
              _buildServiceSection(),
              const SizedBox(height: 24),

              // Select Date Section
              _buildSelectDateSection(context),
              const SizedBox(height: 24),

              // Available Times Section
              _buildAvailableTimesSection(),
              const SizedBox(height: 24),

              // Commission Fee Section (only if shop owner has subscription)
              if (_hasActiveSubscription)
                Column(
                  children: [
                    _buildCommissionSection(),
                    const SizedBox(height: 24),
                  ],
                ),

              // Additional Notes Section
              _buildAdditionalNotesSection(),
              const SizedBox(height: 24),

              // Booking Summary Section
              _buildBookingSummarySection(),
              const SizedBox(height: 24),

              // Confirm Booking Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDate != null && _selectedTime != null
                      ? _confirmBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm Booking',
                    style: TextStyle(
                      color: _selectedDate != null && _selectedTime != null
                          ? Colors.black87
                          : Colors.grey,
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

  Widget _buildServiceSection() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _showServiceDropdown,
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
                  const Text(
                    'SELECTED SERVICE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _service.serviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_hasActiveSubscription)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
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
            const Icon(
              Icons.expand_more,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );

  void _showServiceDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Service',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.local_offer,
                color: Color(0xFF1EDDAC),
              ),
              title: Text(
                _service.serviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '₱${_service.price.toStringAsFixed(2)} per service',
                style: const TextStyle(
                  color: Color(0xFF1EDDAC),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATFORM FEE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _sellerTier == 'Premium' ? Colors.amber : Colors.blue,
                width: 3,
              ),
            ),
            color: Colors.white12,
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
                      const Text(
                        'Seller Tier',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sellerTier,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _sellerTier == 'Premium'
                              ? Colors.amber[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Commission ($_commissionPercentage%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${_commissionFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _sellerTier == 'Premium'
                              ? Colors.amber[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _sellerTier == 'Premium'
                          ? 'Premium seller - 10% commission applied'
                          : 'Standard seller - 5% commission applied',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1EDDAC),
              onPrimary: Colors.black87,
            ),
          ),
          child: child!,
        ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildSelectDateSection(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT DATE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF1A2B3F),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'Pick a date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDate != null
                        ? Colors.white
                        : Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1EDDAC),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );

  Widget _buildAvailableTimesSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AVAILABLE TIMES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: _availableTimes.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1EDDAC)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1EDDAC)
                        : Colors.white30,
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(time),
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );

  Widget _buildAdditionalNotesSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADDITIONAL NOTES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white12,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: 'Any special instructions?',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );

  Widget _buildBookingSummarySection() {
    final selectedDateString = _selectedDate != null
        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
        : 'Not selected';
    final selectedTimeString =
        _selectedTime != null ? _formatTime(_selectedTime!) : 'Not selected';
    final totalPrice = _service.price + (_hasActiveSubscription ? _commissionFee : 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: const Border(
          left: BorderSide(
            color: Color(0xFF1EDDAC),
            width: 3,
          ),
        ),
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Service', _service.serviceName),
          const SizedBox(height: 8),
          _buildSummaryRow('Date', selectedDateString),
          const SizedBox(height: 8),
          _buildSummaryRow('Time', selectedTimeString),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Price',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '₱${_service.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF1EDDAC),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_hasActiveSubscription) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commission ($_commissionPercentage%)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '₱${_commissionFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF1EDDAC),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₱${totalPrice.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildSummaryRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
}
