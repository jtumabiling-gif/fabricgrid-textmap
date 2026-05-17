import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../services/auth_service.dart';
import '../widgets/subscription_badge.dart';

class ShopOwnerInsightsScreen extends StatefulWidget {
  const ShopOwnerInsightsScreen({super.key});

  @override
  State<ShopOwnerInsightsScreen> createState() =>
      _ShopOwnerInsightsScreenState();
}

class _ShopOwnerInsightsScreenState extends State<ShopOwnerInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final fullName = currentUser?.displayName ?? 'Shop Owner';
    // Extract first name from full name
    final firstName = fullName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Back Greeting
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subscriptions')
                      .where('uid', isEqualTo: currentUser?.uid)
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? planName;
                    
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final doc = snapshot.data!.docs.first;
                      planName = doc['planName'] as String?;
                    }
                    
                    return SubscriptionBadge(
                      subscriptionTier: planName,
                      compact: true,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome back, $firstName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s your shop performance overview',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            // Total Revenue Card
            _buildRevenueCard(),
            const SizedBox(height: 24),
            // Active Bookings
            _buildActiveBookingsCard(),
            const SizedBox(height: 24),
            // Revenue Growth Chart
            _buildRevenueGrowthCard(),
            const SizedBox(height: 24),
            // Recent Orders
            _buildRecentOrdersCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        FirebaseFirestore.instance
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        (snapshot1, snapshot2) => [snapshot1, snapshot2],
      ),
      builder: (context, snapshot) {
        var totalRevenue = 0.0;
        
        if (snapshot.hasData && snapshot.data != null) {
          // Process product bookings
          for (final doc in snapshot.data![0].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
            totalRevenue += totalPrice;
          }
          // Process service bookings
          for (final doc in snapshot.data![1].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
            totalRevenue += totalPrice;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B3F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL REVENUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₱${totalRevenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Bar chart
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChartBar(height: 20),
                    _buildChartBar(height: 28),
                    _buildChartBar(height: 32),
                    _buildChartBar(height: 24),
                    _buildChartBar(height: 40, isHighlight: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartBar({required double height, bool isHighlight = false}) => Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFF1EDDAC) : const Color(0xFF2A4B6F),
        borderRadius: BorderRadius.circular(6),
      ),
    );

  Widget _buildActiveBookingsCard() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .snapshots(),
        FirebaseFirestore.instance
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .snapshots(),
        (snapshot1, snapshot2) => [snapshot1, snapshot2],
      ),
      builder: (context, snapshot) {
        var activeUserCount = 0;
        
        if (snapshot.hasData && snapshot.data != null) {
          // Collect unique user IDs from all bookings
          final userIds = <String>{};
          
          for (final doc in snapshot.data![0].docs) {
            final userId = doc['userId'] as String?;
            if (userId != null) {
              userIds.add(userId);
            }
          }
          for (final doc in snapshot.data![1].docs) {
            final userId = doc['userId'] as String?;
            if (userId != null) {
              userIds.add(userId);
            }
          }
          
          activeUserCount = userIds.length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
                  const Text(
                    'ACTIVE USERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EDDAC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people,
                        color: Color(0xFF1EDDAC), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$activeUserCount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'customers with active bookings',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueGrowthCard() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .snapshots(),
        FirebaseFirestore.instance
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .snapshots(),
        (snapshot1, snapshot2) => [snapshot1, snapshot2],
      ),
      builder: (context, snapshot) {
        // Calculate monthly revenue for the past 5 months
        final monthlyRevenue = <int, double>{}; // month (1-12) -> revenue
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1EDDAC),
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Process product bookings (all statuses)
          for (final doc in snapshot.data![0].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final month = createdAt.toDate().month;
              final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
              monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + totalPrice;
            }
          }
          // Process service bookings (all statuses)
          for (final doc in snapshot.data![1].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final month = createdAt.toDate().month;
              final totalPrice = (data['totalPrice'] ?? 0.0).toDouble();
              monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + totalPrice;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Revenue Growth',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    label: const Text(
                      'MONTHLY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                      ),
                    ),
                    icon: const Icon(Icons.calendar_today,
                        color: Colors.white54, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: RevenueChartPainter(monthlyRevenue: monthlyRevenue),
                  size: const Size(double.infinity, 120),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMonthLabel('JAN'),
                  _buildMonthLabel('FEB'),
                  _buildMonthLabel('MAR'),
                  _buildMonthLabel('APR'),
                  _buildMonthLabel('MAY'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthLabel(String month) => Text(
      month,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white54,
      ),
    );

  Widget _buildRecentOrdersCard() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance
            .collection('bookings')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        FirebaseFirestore.instance
            .collection('book_service')
            .where('shopOwnerId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        (snapshot1, snapshot2) => [snapshot1, snapshot2],
      ),
      builder: (context, snapshot) {
        final allBookings = <MapEntry<String, Map<String, dynamic>>>[];
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1EDDAC),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Completed Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Error loading orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade300,
                  ),
                ),
              ),
            ],
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Combine product and service bookings
          for (final doc in snapshot.data![0].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            allBookings.add(MapEntry(doc.id, data));
          }
          for (final doc in snapshot.data![1].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            allBookings.add(MapEntry(doc.id, data));
          }
          
          // Sort by createdAt descending
          allBookings.sort((a, b) {
            final aCreatedAt = a.value['createdAt'] as Timestamp?;
            final bCreatedAt = b.value['createdAt'] as Timestamp?;
            if (aCreatedAt == null || bCreatedAt == null) return 0;
            return bCreatedAt.compareTo(aCreatedAt);
          });
        }

        if (allBookings.isEmpty) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Completed Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'No completed orders yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Completed Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                for (int i = 0; i < allBookings.length; i++) ...[
                  _buildCompletedBookingItem(allBookings[i].value),
                  if (i < allBookings.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedBookingItem(Map<String, dynamic> booking) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A2B3F),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1EDDAC).withOpacity(0.1),
          ),
          child: const Icon(Icons.check_circle,
              color: Color(0xFF1EDDAC), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking['userName'] ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking['productName'] ?? booking['serviceName'] ?? 'Service',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${((booking['totalPrice'] ?? 0.0) as num).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1EDDAC),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCompletedDate(booking['createdAt'] as Timestamp?),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  String _formatCompletedDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


}

class RevenueChartPainter extends CustomPainter {

  RevenueChartPainter({this.monthlyRevenue = const {}});
  final Map<int, double> monthlyRevenue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1EDDAC)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF1EDDAC).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const padding = 20.0;
    final width = size.width - (padding * 2);
    final height = size.height - (padding * 2);

    // Get max revenue for scaling
    var maxRevenue = monthlyRevenue.isEmpty ? 10000 : (monthlyRevenue.values.isEmpty ? 10000 : monthlyRevenue.values.reduce((a, b) => a > b ? a : b));
    if (maxRevenue == 0) maxRevenue = 10000;

    // Create points for months: JAN(1), FEB(2), MAR(3), APR(4), MAY(5)
    final months = [1, 2, 3, 4, 5];
    final points = <Offset>[];
    
    if (monthlyRevenue.isEmpty) {
      // Sample data if no revenue data
      points.addAll([
        Offset(padding, padding + height * 0.6),
        Offset(padding + width * 0.25, padding + height * 0.3),
        Offset(padding + width * 0.5, padding + height * 0.4),
        Offset(padding + width * 0.75, padding + height * 0.2),
        Offset(padding + width, padding + height * 0.35),
      ]);
    } else {
      for (var i = 0; i < months.length; i++) {
        final month = months[i];
        final revenue = monthlyRevenue[month] ?? 0.0;
        final normalizedRevenue = revenue / maxRevenue;
        final xPos = padding + (width / 4) * i;
        final yPos = padding + height - (normalizedRevenue * height);
        points.add(Offset(xPos, yPos));
      }
    }

    if (points.isEmpty) return;

    // Draw filled area
    final path = Path();
    path.moveTo(points[0].dx, padding + height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, padding + height);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Draw line
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(RevenueChartPainter oldDelegate) => oldDelegate.monthlyRevenue != monthlyRevenue;
}
