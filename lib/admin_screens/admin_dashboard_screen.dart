import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';
import 'admin_notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    
    setState(() {
      _isInitialized = true;
    });
    
    // Verify admin status after initialization
    _verifyAdminStatus();
  }

  Future<void> _verifyAdminStatus() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(currentUser.uid)
          .get();

      if (!adminDoc.exists) {
        // Create admin document if it doesn't exist
        await _firestore
            .collection('admins')
            .doc(currentUser.uid)
            .set({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'role': 'ADMIN',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error verifying admin status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1F2F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
        ),
      );
    }

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
          'Admin Dashboard',
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
            Text(
              'SYSTEM OVERVIEW',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  small: 10,
                  medium: 11,
                  large: 12,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            // Summary Cards with Real-time Data
            Row(
              children: [
                Expanded(
                  child: _buildRealTimeSummaryCard(
                    icon: Icons.people,
                    label: 'Total Users',
                    collection: 'users',
                    color: const Color(0xFF1EDDAC),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: _buildShopOwnersCard(),
                ),
              ],
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context) / 2,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildRealTimeSummaryCard(
                    icon: Icons.shopping_bag,
                    label: 'Products',
                    collection: 'products',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context) / 2),
                Expanded(
                  child: _buildRevenueCard(),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context) * 2),
            Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  small: 10,
                  medium: 11,
                  large: 12,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
            _buildRecentActivityStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeSummaryCard({
    required IconData icon,
    required String label,
    required String collection,
    required Color color,
  }) =>
      StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(collection).snapshots(),
        builder: (context, snapshot) {
          var count = 0;
          if (snapshot.hasData) {
            count = snapshot.data!.docs.length;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? '--'
                      : count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildShopOwnersCard() => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          var shopOwnerCount = 0;
          if (snapshot.hasData) {
            // Count users with userType == 'SHOP_OWNER'
            for (final doc in snapshot.data!.docs) {
              final data = doc.data()! as Map<String, dynamic>;
              if (data['userType'] == 'SHOP_OWNER') {
                shopOwnerCount++;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: Colors.blue, size: 20),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Shops',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? '--'
                      : shopOwnerCount.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildRevenueCard() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCommissionEarningsStream(),
        builder: (context, snapshot) {
          double totalCommission = 0;

          if (snapshot.hasData) {
            final products = snapshot.data!;
            for (final product in products) {
              final commissionFee = product['commissionFee'] as double;
              totalCommission += commissionFee;
            }
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.green, size: 20),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Commission Earned',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? '--'
                      : '₱${totalCommission.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildRecentActivityStream() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCombinedActivityStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final activities = snapshot.data!;
          
          return Column(
            children: activities.map((activity) {
              final title = activity['title'] as String;
              final subtitle = activity['subtitle'] as String;
              final icon = activity['icon'] as IconData;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityCard(title, subtitle, icon),
              );
            }).toList(),
          );
        },
      );

  Stream<List<Map<String, dynamic>>> _getCombinedActivityStream() {
    // Get current time for filtering recent activities
    return Stream.fromFuture(_buildCombinedActivity());
  }

  Future<List<Map<String, dynamic>>> _buildCombinedActivity() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Fetch recent product bookings
      try {
        final productBookings = await _firestore
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        for (final doc in productBookings.docs) {
          final data = doc.data();
          final userName = data['userName'] ?? 'User';
          final productName = data['productName'] ?? 'Product';
          final status = data['status'] ?? 'PENDING';
          final timestamp = data['createdAt'] as Timestamp?;
          final timeAgo = _getTimeAgoString(timestamp);

          // Show different activity based on status
          String title;
          IconData icon;
          
          if (status == 'CANCELLED') {
            title = 'Booking Cancelled - $status';
            icon = Icons.cancel;
          } else if (status == 'COMPLETED') {
            title = 'Product Booking - $status';
            icon = Icons.check_circle;
          } else {
            title = 'Product Booking - $status';
            icon = Icons.shopping_bag;
          }

          activities.add({
            'title': title,
            'subtitle': '$userName booked "$productName" • $timeAgo',
            'icon': icon,
            'timestamp': timestamp?.toDate() ?? DateTime.now(),
          });
        }
      } catch (e) {
        print('Error fetching product bookings: $e');
      }

      // Fetch recent service bookings
      try {
        final serviceBookings = await _firestore
            .collection('book_service')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        for (final doc in serviceBookings.docs) {
          final data = doc.data();
          final userName = data['userName'] ?? 'User';
          final serviceName = data['serviceName'] ?? 'Service';
          final status = data['status'] ?? 'PENDING';
          final timestamp = data['createdAt'] as Timestamp?;
          final timeAgo = _getTimeAgoString(timestamp);

          // Show different activity based on status
          String title;
          IconData icon;
          
          if (status == 'CANCELLED') {
            title = 'Service Booking Cancelled - $status';
            icon = Icons.cancel;
          } else if (status == 'COMPLETED') {
            title = 'Service Booking - $status';
            icon = Icons.check_circle;
          } else {
            title = 'Service Booking - $status';
            icon = Icons.miscellaneous_services;
          }

          activities.add({
            'title': title,
            'subtitle': '$userName booked "$serviceName" • $timeAgo',
            'icon': icon,
            'timestamp': timestamp?.toDate() ?? DateTime.now(),
          });
        }
      } catch (e) {
        print('Error fetching service bookings: $e');
      }

      // Fetch recent products
      try {
        final products = await _firestore
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        for (final doc in products.docs) {
          final data = doc.data();
          final productName = data['productName'] ?? 'Product';
          final timestamp = data['createdAt'] as Timestamp?;
          final timeAgo = _getTimeAgoString(timestamp);

          // Get shop owner name from shop_owners collection
          var shopOwnerName = 'Shop Owner';
          try {
            final shopOwnerId = data['shopOwnerId'] as String?;
            if (shopOwnerId != null) {
              final shopOwnerDoc = await _firestore
                  .collection('shop_owners')
                  .doc(shopOwnerId)
                  .get();
              if (shopOwnerDoc.exists) {
                shopOwnerName = shopOwnerDoc['businessName'] ?? shopOwnerDoc['shopName'] ?? 'Shop Owner';
              }
            }
          } catch (e) {
            print('Error fetching shop owner: $e');
          }

          activities.add({
            'title': 'New Product Added',
            'subtitle': '$shopOwnerName added "$productName" • $timeAgo',
            'icon': Icons.inventory_2,
            'timestamp': timestamp?.toDate() ?? DateTime.now(),
          });
        }
      } catch (e) {
        print('Error fetching products: $e');
      }

      // Sort all activities by timestamp (most recent first)
      activities.sort((a, b) {
        final timeA = a['timestamp'] as DateTime;
        final timeB = b['timestamp'] as DateTime;
        return timeB.compareTo(timeA);
      });

      // Return only the 10 most recent activities
      return activities.take(10).toList();
    } catch (e) {
      print('Error building combined activity: $e');
      return [];
    }
  }

  String _getTimeAgoString(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Widget _buildActivityCard(String title, String subtitle, IconData icon) =>
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1EDDAC).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1EDDAC), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Stream<List<Map<String, dynamic>>> _getCommissionEarningsStream() => Stream.fromFuture(_fetchCommissionEarnings());

  Future<List<Map<String, dynamic>>> _fetchCommissionEarnings() async {
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

      print('Fetched ${products.length} products/services with commission');
      // Return all results
      return products;
    } catch (e) {
      print('Error fetching commission earnings: $e');
      return [];
    }
  }
}


