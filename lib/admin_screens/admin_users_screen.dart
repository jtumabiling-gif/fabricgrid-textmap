import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';
import 'admin_notifications_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'SHOP_OWNER', 'USER'
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      // First, check if admin document exists and create if needed
      try {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (!adminDoc.exists) {
          print('Admin document does not exist. Creating it...');
          // Create admin document
          await _firestore
              .collection('admins')
              .doc(currentUser.uid)
              .set({
            'uid': currentUser.uid,
            'email': currentUser.email,
            'role': 'ADMIN',
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 5));
          print('Admin document created successfully');
        } else {
          print('Admin document exists');
        }
      } catch (e) {
        print('Warning: Could not verify/create admin document: $e');
        // Continue anyway - the query might still work
      }

      // Now try to fetch users
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .get()
            .timeout(const Duration(seconds: 10));
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // If still permission denied, provide a helpful message
          throw 'You do not have permission to view all users. Please ensure your admin account is properly configured.';
        }
        rethrow;
      }

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? 'Unknown User',
          'userType': data['userType'] ?? 'Customer',
          'createdAt': data['createdAt'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message ?? 'Firebase error occurred';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    var filtered = _users;

    // Apply user type filter
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((user) => user['userType'] == _selectedFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              user['fullName']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              user['email']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Future<void> _deleteUser(String userId, String userName, String userType) async {
    try {
      print('🗑️ Starting deletion of user: $userId ($userName)');

      final batch = _firestore.batch();

      // 1. Delete user's bookings
      try {
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in bookingsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        print('   ✅ Marked ${bookingsSnapshot.docs.length} bookings for deletion');
      } catch (e) {
        print('   ⚠️ Error fetching bookings: $e');
      }

      // 2. Delete user's service bookings
      try {
        final serviceBookingsSnapshot = await _firestore
            .collection('book_service')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in serviceBookingsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        print('   ✅ Marked ${serviceBookingsSnapshot.docs.length} service bookings for deletion');
      } catch (e) {
        print('   ⚠️ Error fetching service bookings: $e');
      }

      // 3. Delete user's reviews
      try {
        final reviewsSnapshot = await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in reviewsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        print('   ✅ Marked ${reviewsSnapshot.docs.length} reviews for deletion');
      } catch (e) {
        print('   ⚠️ Error fetching reviews: $e');
      }

      // 4. Delete user's payments
      try {
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in paymentsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        print('   ✅ Marked ${paymentsSnapshot.docs.length} payments for deletion');
      } catch (e) {
        print('   ⚠️ Error fetching payments: $e');
      }

      // 5. If shop owner, delete their products, services, subscriptions, and bookings they received
      if (userType == 'SHOP_OWNER') {
        try {
          // Delete products
          final productsSnapshot = await _firestore
              .collection('products')
              .where('shopOwnerId', isEqualTo: userId)
              .get();
          
          for (final doc in productsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          print('   ✅ Marked ${productsSnapshot.docs.length} products for deletion');
        } catch (e) {
          print('   ⚠️ Error fetching products: $e');
        }

        try {
          // Delete services
          final servicesSnapshot = await _firestore
              .collection('services')
              .where('shopOwnerId', isEqualTo: userId)
              .get();
          
          for (final doc in servicesSnapshot.docs) {
            batch.delete(doc.reference);
          }
          print('   ✅ Marked ${servicesSnapshot.docs.length} services for deletion');
        } catch (e) {
          print('   ⚠️ Error fetching services: $e');
        }

        try {
          // Delete subscriptions
          final subscriptionsSnapshot = await _firestore
              .collection('subscriptions')
              .where('shopOwnerId', isEqualTo: userId)
              .get();
          
          for (final doc in subscriptionsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          print('   ✅ Marked ${subscriptionsSnapshot.docs.length} subscriptions for deletion');
        } catch (e) {
          print('   ⚠️ Error fetching subscriptions: $e');
        }

        try {
          // Delete bookings where they are the shop owner (as recipient)
          final shopBookingsSnapshot = await _firestore
              .collection('bookings')
              .where('shopOwnerId', isEqualTo: userId)
              .get();
          
          for (final doc in shopBookingsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          print('   ✅ Marked ${shopBookingsSnapshot.docs.length} received bookings for deletion');
        } catch (e) {
          print('   ⚠️ Error fetching received bookings: $e');
        }

        try {
          // Delete service bookings where they are the shop owner
          final shopServiceBookingsSnapshot = await _firestore
              .collection('book_service')
              .where('shopOwnerId', isEqualTo: userId)
              .get();
          
          for (final doc in shopServiceBookingsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          print('   ✅ Marked ${shopServiceBookingsSnapshot.docs.length} received service bookings for deletion');
        } catch (e) {
          print('   ⚠️ Error fetching received service bookings: $e');
        }

        try {
          // Delete shop owner document
          batch.delete(_firestore.collection('shop_owners').doc(userId));
          print('   ✅ Marked shop_owners document for deletion');
        } catch (e) {
          print('   ⚠️ Error marking shop owner document: $e');
        }
      }

      // 6. Delete user profile
      try {
        batch.delete(_firestore.collection('users').doc(userId));
        print('   ✅ Marked user document for deletion');
      } catch (e) {
        print('   ⚠️ Error marking user document: $e');
      }

      // 7. Delete notifications
      try {
        final notificationsSnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in notificationsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        print('   ✅ Marked ${notificationsSnapshot.docs.length} notifications for deletion');
      } catch (e) {
        print('   ⚠️ Error fetching notifications: $e');
      }

      // 8. Delete Firebase Auth user
      try {
        // Try to get the user from auth and delete
        final userRecord = _firebaseAuth.currentUser;
        if (userRecord != null && userRecord.uid == userId) {
          print('   ⚠️ Cannot delete currently logged-in user');
          throw 'Cannot delete the currently logged-in admin account';
        }
        // Note: Deleting auth users requires special permissions
        // This should be done through Firebase Admin SDK or custom logic
        print('   ℹ️ Auth user deletion requires admin privileges');
      } catch (e) {
        print('   ⚠️ Cannot delete auth user: $e');
      }

      // Execute batch
      await batch.commit();
      print('✅ User deletion completed successfully!');

      // Reload users
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$userName" and all related data deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String userId, String userName, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this user?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ This action will delete:',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• User account: $userName\n'
                    '• All bookings\n'
                    '• All reviews\n'
                    '• All payments\n'
                    '• All notifications'
                    '${userType == 'SHOP_OWNER' ? '\n• All products & services\n• All subscriptions' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action CANNOT be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId, userName, userType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
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
          'User Management',
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
            const Text(
              'USER MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
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
            const SizedBox(height: 24),
            // Filter buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('All'),
                  const SizedBox(width: 8),
                  _buildFilterButton('USER', label: 'Users'),
                  const SizedBox(width: 8),
                  _buildFilterButton('SHOP_OWNER', label: 'Shop Owner'),
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
            else if (_errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[400], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_getFilteredUsers().isEmpty)
              const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getFilteredUsers().length,
                itemBuilder: (context, index) {
                  final user = _getFilteredUsers()[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildUserCard(
                      user['id'],
                      user['fullName'],
                      user['email'],
                      user['userType'],
                      user['userType'] == 'SHOP_OWNER'
                          ? Icons.store
                          : Icons.person,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId, String name, String email, String role, IconData icon) => Container(
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
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1EDDAC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1EDDAC),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _showDeleteConfirmationDialog(userId, name, role),
            tooltip: 'Delete user and all related data',
          ),
        ],
      ),
    );

  Widget _buildFilterButton(String value, {String? label}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1EDDAC) : const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: Colors.white24),
        ),
        child: Text(
          label ?? value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF0F1F2F) : Colors.white,
          ),
        ),
      ),
    );
  }
}
