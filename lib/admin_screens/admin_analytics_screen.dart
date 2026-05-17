import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';
import 'admin_notifications_screen.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late FirebaseFirestore _firestore;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    final adminName = currentUser?.displayName ?? 'Admin';
    final firstName = adminName.split(' ').first;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A2B3F),
              ),
              child: Center(
                child: Text(
                  firstName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Color(0xFF1EDDAC),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminNotificationsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commission Earnings Card
            _buildCommissionEarningsCard(),
            const SizedBox(height: 32),
            const Text(
              'PLATFORM ANALYTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Period selector
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B3F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                  DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                  DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                ].map((item) => DropdownMenuItem(
                    value: item.value,
                    child: Text(
                      item.value ?? 'This Month',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  }
                },
                dropdownColor: const Color(0xFF1A2B3F),
                isExpanded: true,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // Metrics - Real-time data
            _buildUserGrowthCard(),
            const SizedBox(height: 12),
            _buildTransactionVolumeCard(),
            const SizedBox(height: 12),
            _buildActiveSessionsCard(),
            const SizedBox(height: 24),
            const Text(
              'PRODUCTS COMMISSIONED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildProductCommissionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionEarningsCard() => StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getProductCommissionStream(),
      builder: (context, snapshot) {
        double totalCommissionEarned = 0;

        if (snapshot.hasData) {
          final products = snapshot.data!;
          for (final product in products) {
            final commissionFee = product['commissionFee'] as double;
            totalCommissionEarned += commissionFee;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1EDDAC), Color(0xFF15C896)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Commission Earned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${totalCommissionEarned.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // Add withdraw functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdraw feature coming soon')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Withdraw',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

  Widget _buildUserGrowthCard() => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          var userCount = 0;
          var previousMonthCount = 0;

          if (snapshot.hasData) {
            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);
            final startOfLastMonth =
                DateTime(now.year, now.month - 1, 1);

            for (final doc in snapshot.data!.docs) {
              final data = doc.data()! as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;

              if (createdAt != null) {
                final date = createdAt.toDate();
                if (date.isAfter(startOfMonth)) {
                  userCount++;
                } else if (date.isAfter(startOfLastMonth) &&
                    date.isBefore(startOfMonth)) {
                  previousMonthCount++;
                }
              }
            }
          }

          final growth = previousMonthCount > 0
              ? ((userCount - previousMonthCount) / previousMonthCount * 100)
              : 0.0;
          final trend = growth >= 0 ? '↑' : '↓';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Growth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${growth.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      trend,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildTransactionVolumeCard() => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          var transactionCount = 0;
          var previousMonthCount = 0;

          if (snapshot.hasData) {
            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);
            final startOfLastMonth =
                DateTime(now.year, now.month - 1, 1);

            for (final doc in snapshot.data!.docs) {
              final data = doc.data()! as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;

              if (createdAt != null) {
                final date = createdAt.toDate();
                if (date.isAfter(startOfMonth)) {
                  transactionCount++;
                } else if (date.isAfter(startOfLastMonth) &&
                    date.isBefore(startOfMonth)) {
                  previousMonthCount++;
                }
              }
            }
          }

          final volume = previousMonthCount > 0
              ? ((transactionCount - previousMonthCount) /
                      previousMonthCount *
                      100)
              : 0.0;
          final trend = volume >= 0 ? '↑' : '↓';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Volume',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${volume.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      trend,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildActiveSessionsCard() => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          var activeSessions = 0;

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data()! as Map<String, dynamic>;
              final status = data['status'] as String?;
              if (status == 'pending' || status == 'in_progress') {
                activeSessions++;
              }
            }
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeSessions.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '→',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildProductCommissionList() => StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getProductCommissionStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No commissioned products found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final products = snapshot.data!;
        return Column(
          children: List.generate(
            products.length,
            (index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProductCommissionCard(
                  index + 1,
                  product['productName'] as String,
                  product['shopOwnerName'] as String,
                  product['commissionPercent'] as double,
                  product['commissionFee'] as double,
                  product['tier'] as String,
                  product['source'] as String,
                ),
              );
            },
          ),
        );
      },
    );

  Stream<List<Map<String, dynamic>>> _getProductCommissionStream() => Stream.fromFuture(_fetchProductsWithCommission());

  Future<List<Map<String, dynamic>>> _fetchProductsWithCommission() async {
    try {
      final products = <Map<String, dynamic>>[];

      // Fetch from bookings collection (product bookings from market screen)
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .get();

      for (final doc in bookings.docs) {
        final data = doc.data();
        final commissionFee = (data['commissionFee'] as num?)?.toDouble() ?? 0.0;
        final commissionPercentage = (data['commissionPercentage'] as num?)?.toDouble() ?? 0.0;
        
        // Only add products with commission > 0
        if (commissionFee > 0 || commissionPercentage > 0) {
          products.add({
            'productName': data['productName'] ?? 'Unknown Product',
            'shopOwnerName': data['shopOwnerName'] ?? 'Unknown Shop',
            'commissionPercent': commissionPercentage,
            'commissionFee': commissionFee,
            'tier': data['subscriptionTier'] ?? 'Standard',
            'createdAt': data['createdAt'] as Timestamp?,
            'source': 'booking', // Market screen product booking
          });
        }
      }

      // Fetch from book_service collection (service bookings from discover screen)
      final services = await FirebaseFirestore.instance
          .collection('book_service')
          .get();

      for (final doc in services.docs) {
        final data = doc.data();
        final commissionFee = (data['commissionFee'] as num?)?.toDouble() ?? 0.0;
        final commissionPercentage = (data['commissionPercentage'] as num?)?.toDouble() ?? 0.0;
        
        // Only add services with commission > 0
        if (commissionFee > 0 || commissionPercentage > 0) {
          products.add({
            'productName': data['serviceName'] ?? 'Unknown Service',
            'shopOwnerName': data['shopOwnerName'] ?? 'Unknown Shop',
            'commissionPercent': commissionPercentage,
            'commissionFee': commissionFee,
            'tier': data['subscriptionTier'] ?? 'Standard',
            'createdAt': data['createdAt'] as Timestamp?,
            'source': 'service', // Discover screen service booking
          });
        }
      }

      // Sort by commission fee (highest first), then by creation date
      products.sort((a, b) {
        final feeA = a['commissionFee'] as double;
        final feeB = b['commissionFee'] as double;
        
        if (feeA != feeB) {
          return feeB.compareTo(feeA); // Highest fee first
        }
        
        final timeA = a['createdAt'] as Timestamp?;
        final timeB = b['createdAt'] as Timestamp?;
        
        if (timeA == null || timeB == null) return 0;
        return timeB.compareTo(timeA); // Newest first
      });

      print('Fetched ${products.length} products with commission');
      // Return top 10
      return products.take(10).toList();
    } catch (e) {
      print('Error fetching products with commission: $e');
      return [];
    }
  }

  Widget _buildProductCommissionCard(
    int rank,
    String productName,
    String shopOwnerName,
    double commissionPercent,
    double commissionFee,
    String tier,
    String source,
  ) =>
      Container(
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
                color: tier == 'Premium'
                    ? Colors.amber.withOpacity(0.3)
                    : const Color(0xFF1EDDAC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tier == 'Premium' ? Colors.amber : const Color(0xFF1EDDAC),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shop: $shopOwnerName • Tier: $tier',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source == 'booking' ? 'Market Booking' : 'Service Booking',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${commissionFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1EDDAC),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${commissionPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commission',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}