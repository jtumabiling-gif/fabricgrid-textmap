import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShopOwnerNotificationsScreen extends StatefulWidget {
  const ShopOwnerNotificationsScreen({super.key});

  @override
  State<ShopOwnerNotificationsScreen> createState() =>
      _ShopOwnerNotificationsScreenState();
}

class _ShopOwnerNotificationsScreenState
    extends State<ShopOwnerNotificationsScreen> {
  late FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F1F2F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1F2F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notifications marked as read')),
                );
              },
              child: const Text(
                'Mark All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: _buildNotificationsList(),
      );

  Widget _buildNotificationsList() => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1EDDAC)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              return _buildNotificationTile(data, index);
            },
          );
        },
      );

  Widget _buildNotificationTile(Map<String, dynamic> data, int index) {
    final userName = data['userName'] ?? 'User';
    final status = data['status'] ?? 'PENDING';
    final timestamp = data['createdAt'] as Timestamp?;
    final productName = data['productName'] ?? 'Product';

    var timeAgo = 'Just now';
    if (timestamp != null) {
      final difference = DateTime.now().difference(timestamp.toDate());
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = '${difference.inDays}d ago';
      }
    }

    final notificationType = _getNotificationType(status);
    final notificationTitle = _getNotificationTitle(status);
    final notificationIcon = _getNotificationIcon(notificationType);
    final notificationColor = _getNotificationColor(notificationType);
    final isRead = index > 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: notificationColor.withOpacity(0.2),
          ),
          child: Icon(
            notificationIcon,
            color: notificationColor,
            size: 24,
          ),
        ),
        title: Text(
          notificationTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$userName booked $productName',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1EDDAC),
                ),
              )
            : null,
      ),
    );
  }

  String _getNotificationType(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'pending';
      case 'CONFIRMED':
        return 'success';
      case 'COMPLETED':
        return 'success';
      case 'CANCELLED':
        return 'warning';
      case 'DELETED':
        return 'warning';
      default:
        return 'info';
    }
  }

  String _getNotificationTitle(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'New Booking - Pending';
      case 'CONFIRMED':
        return 'Booking Confirmed';
      case 'COMPLETED':
        return 'Booking Completed';
      case 'CANCELLED':
        return 'Booking Cancelled';
      case 'DELETED':
        return 'Booking Deleted';
      default:
        return 'New Booking';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'warning':
        return Icons.warning;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'pending':
        return const Color(0xFF1EDDAC);
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }
}
