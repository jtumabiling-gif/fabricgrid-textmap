import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_model.dart';

class UserBalanceScreen extends StatefulWidget {
  const UserBalanceScreen({super.key});

  @override
  State<UserBalanceScreen> createState() => _UserBalanceScreenState();
}

class _UserBalanceScreenState extends State<UserBalanceScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  double _totalEarnings = 0.0;
  late Stream<QuerySnapshot> _bookingStream;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _initializeBookingStream();
  }

  void _initializeBookingStream() {
    final currentUserId = _firebaseAuth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    _bookingStream = _firestore
        .collection('bookings')
        .where('shopOwnerId', isEqualTo: currentUserId)
        .snapshots();
  }

  double _calculateTotalEarnings(List<QueryDocumentSnapshot> bookings) {
    double total = 0.0;
    for (final doc in bookings) {
      final booking = Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      // Count bookings where payment has been completed/paid
      if (booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'PAID') {
        total += booking.totalPrice;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        title: const Text(
          'My Balance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          var bookings = snapshot.data?.docs ?? [];
          // Sort by createdAt descending
          bookings.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
          
          // Filter only paid bookings
          final paidBookings = bookings
              .where((doc) {
                final booking = Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                return booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'PAID';
              })
              .toList();
          
          final totalEarnings = _calculateTotalEarnings(bookings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEarningsCard(totalEarnings),
                const SizedBox(height: 24),
                _buildBookingTransactionsSection(paidBookings),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );

  Widget _buildEarningsCard(double totalEarnings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1EDDAC),
            const Color(0xFF1EDDAC).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1EDDAC).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Withdrawal feature coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTransactionsSection(List<QueryDocumentSnapshot> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Text(
                'No bookings yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = Booking.fromMap(
                bookings[index].data() as Map<String, dynamic>,
                bookings[index].id,
              );
              return _buildBookingTransactionCard(booking);
            },
          ),
      ],
    );
  }

  Widget _buildBookingTransactionCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final formattedDate = DateFormat('MMM dd, yyyy').format(booking.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
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
                      booking.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booked by: ${booking.userName ?? 'Unknown User'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${booking.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
