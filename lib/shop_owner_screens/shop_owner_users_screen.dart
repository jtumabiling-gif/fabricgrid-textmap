import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class ShopOwnerUsersScreen extends StatefulWidget {
  const ShopOwnerUsersScreen({super.key});

  @override
  State<ShopOwnerUsersScreen> createState() => _ShopOwnerUsersScreenState();
}

class _ShopOwnerUsersScreenState extends State<ShopOwnerUsersScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  late UserProfileService _userProfileService;
  List<Map<String, dynamic>> _activeUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent', 'spent', 'bookings'

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _userProfileService = UserProfileService();
    // Add a small delay to ensure Firebase is initialized
    Future.delayed(Duration.zero, _fetchActiveUsers);
  }

  Future<void> _fetchActiveUsers() async {
    try {
      await _userProfileService.initialize();
      
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        print('ERROR: No current user logged in');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      print('=====================================');
      print('CURRENT LOGGED IN USER UID: ${currentUser.uid}');
      print('=====================================');

      // Get all bookings for this shop owner using a filtered query
      // (More efficient and respects Firestore security rules)
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('shopOwnerId', isEqualTo: currentUser.uid)
          .get();

      print('Total bookings in collection: ${bookingsSnapshot.docs.length}');
      
      if (bookingsSnapshot.docs.isEmpty) {
        print('WARNING: No bookings found in collection');
      }

      final usersMap = <String, Map<String, dynamic>>{};
      var matchedBookings = 0;
      var unmatchedBookings = 0;

      // Process bookings (already filtered to this shop owner)
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final bookingUserName = data['userName'] as String?;
        
        print('---');
        print('Booking Doc ID: ${doc.id}');
        print('  userId: $userId');
        print('  userName: $bookingUserName');
        print('  totalPrice: ${data['totalPrice']}');

        if (userId != null) {
          matchedBookings++;
          print('  ✓ PROCESSED!');
          
          if (!usersMap.containsKey(userId)) {
            usersMap[userId] = {
              'userId': userId,
              'userName': bookingUserName, // Store booking's userName
              'bookingCount': 0,
              'totalSpent': 0.0,
              'lastBookingDate': null,
            };
          }

          usersMap[userId]!['bookingCount'] =
              (usersMap[userId]!['bookingCount'] as int) + 1;

          // Add to total spent
          final price = data['totalPrice'] as num?;
          if (price != null) {
            usersMap[userId]!['totalSpent'] =
                (usersMap[userId]!['totalSpent'] as double) + price.toDouble();
          }

          // Track last booking date
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final bookingDate = createdAt.toDate();
            final lastDate = usersMap[userId]!['lastBookingDate'] as DateTime?;
            if (lastDate == null || bookingDate.isAfter(lastDate)) {
              usersMap[userId]!['lastBookingDate'] = bookingDate;
            }
          }
        } else {
          unmatchedBookings++;
          print('  ✗ NO USER ID');
        }
      }

      print('=====================================');
      print('SUMMARY: Matched: $matchedBookings, Unmatched: $unmatchedBookings');
      print('Unique users with bookings: ${usersMap.length}');
      print('=====================================');

      // Fetch user details for each user
      final activeUsers = <Map<String, dynamic>>[];
      for (final entry in usersMap.entries) {
        try {
          // Try to fetch from 'users' collection first
          var userDoc =
              await _firestore.collection('users').doc(entry.key).get();

          // If not found, try 'customers' collection
          if (!userDoc.exists) {
            userDoc =
                await _firestore.collection('customers').doc(entry.key).get();
          }

          var fullName = 'Unknown User';
          var email = '';
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              fullName = userData['fullName'] ?? userData['displayName'] ?? 'Unknown User';
              email = userData['email'] ?? '';
            }
            print('✓ User from DB: $fullName (${entry.key})');
          } else {
            // User profile doesn't exist, but they have bookings
            // Try to get username from booking data
            if (usersMap[entry.key]?['userName'] != null) {
              fullName = usersMap[entry.key]!['userName'] as String;
            } else {
              fullName = 'Customer ${entry.key.substring(0, 6).toUpperCase()}';
            }
            print('! User without profile: $fullName (${entry.key})');
          }
          
          activeUsers.add({
            'uid': entry.key,
            'fullName': fullName,
            'email': email,
            'bookingCount': entry.value['bookingCount'],
            'totalSpent': entry.value['totalSpent'],
            'lastBookingDate': entry.value['lastBookingDate'],
            'profileImageUrl': null,
          });
        } catch (e) {
          print('✗ Error processing user ${entry.key}: $e');
          // Still add the user even if there's an error fetching their profile
          var fallbackName = 'Customer ${entry.key.substring(0, 6).toUpperCase()}';
          if (usersMap[entry.key]?['userName'] != null) {
            fallbackName = usersMap[entry.key]!['userName'] as String;
          }
          activeUsers.add({
            'uid': entry.key,
            'fullName': fallbackName,
            'email': '',
            'bookingCount': entry.value['bookingCount'],
            'totalSpent': entry.value['totalSpent'],
            'lastBookingDate': entry.value['lastBookingDate'],
            'profileImageUrl': null,
          });
        }
      }

      print('FINAL: ${activeUsers.length} active users to display');

      if (mounted) {
        setState(() {
          _activeUsers = activeUsers;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('ERROR in _fetchActiveUsers: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var users = _activeUsers;
    
    if (_searchQuery.isNotEmpty) {
      users = users
          .where((user) =>
              (user['fullName'] as String)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (user['email'] as String)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort based on _sortBy
    switch (_sortBy) {
      case 'spent':
        users.sort((a, b) => (b['totalSpent'] as double).compareTo(a['totalSpent'] as double));
        break;
      case 'bookings':
        users.sort((a, b) => (b['bookingCount'] as int).compareTo(a['bookingCount'] as int));
        break;
      case 'recent':
      default:
        users.sort((a, b) {
          final dateA = (a['lastBookingDate'] as DateTime?) ?? DateTime(1970);
          final dateB = (b['lastBookingDate'] as DateTime?) ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
    }

    return users;
  }

  String _formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _formatBookings(int count) => '$count ${count == 1 ? 'order' : 'orders'}';

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
              'USERS & CUSTOMERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Users',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!_isLoading)
              Text(
                '${_activeUsers.length} ${_activeUsers.length == 1 ? 'customer' : 'customers'} with active bookings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A2B3F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Sort buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortButton('Recent', 'recent'),
                  const SizedBox(width: 8),
                  _buildSortButton('Most Spent', 'spent'),
                  const SizedBox(width: 8),
                  _buildSortButton('Most Bookings', 'bookings'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1EDDAC)),
                ),
              )
            else if (_filteredUsers.isEmpty)
              const Center(
                child: Text(
                  'No active users found',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ..._filteredUsers.map((user) => Column(
                  children: [
                    _buildUserCard(
                      user['fullName'] as String,
                      user['email'] as String,
                      _formatCurrency(user['totalSpent'] as double),
                      _formatBookings(user['bookingCount'] as int),
                      user['lastBookingDate'] as DateTime?,
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

  Widget _buildUserCard(
      String name, String email, String spent, String orders, DateTime? lastBookingDate) => 
  GestureDetector(
    onTap: () {
      // Show user details modal or navigate to detailed view
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1EDDAC).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1EDDAC),
                ),
                child:
                    const Icon(Icons.person, color: Colors.black87, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1EDDAC).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1EDDAC),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Spent', spent, const Color(0xFF1EDDAC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('Bookings', orders.split(' ')[0], const Color(0xFF1EDDAC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Last Active',
                  lastBookingDate != null
                      ? _formatDate(lastBookingDate)
                      : 'N/A',
                  const Color(0xFF1EDDAC),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildStatItem(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  String _formatDate(DateTime date) {
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

  Widget _buildSortButton(String label, String value) => GestureDetector(
    onTap: () {
      setState(() => _sortBy = value);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _sortBy == value
            ? const Color(0xFF1EDDAC)
            : const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _sortBy == value
              ? const Color(0xFF1EDDAC)
              : Colors.white12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _sortBy == value
              ? Colors.black87
              : Colors.white,
        ),
      ),
    ),
  );
}

