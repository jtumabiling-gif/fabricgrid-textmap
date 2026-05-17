import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  late BookingService _bookingService;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _bookingService = BookingService();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      await _notificationService.initialize();
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // Reload notifications to update UI
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      // Reload notifications to update UI
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      // Reload notifications to update UI
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleBookingConfirm(String bookingId, String notificationId) async {
    try {
      await _bookingService.initialize();
      await _bookingService.confirmBookingFromNotification(bookingId: bookingId);
      
      // Mark notification as read
      await _notificationService.markAsRead(notificationId);
      
      // Update notification with action status to hide buttons
      await _notificationService.updateNotificationStatus(notificationId, 'confirmed');
      
      // Reload notifications to reflect the change
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming booking: $e')),
        );
      }
    }
  }

  Future<void> _handleBookingCancel(String bookingId, String notificationId) async {
    try {
      await _bookingService.initialize();
      await _bookingService.cancelBookingFromNotification(bookingId: bookingId);
      
      // Mark notification as read
      await _notificationService.markAsRead(notificationId);
      
      // Update notification with action status to hide buttons
      await _notificationService.updateNotificationStatus(notificationId, 'cancelled');
      
      // Reload notifications to reflect the change
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
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
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) =>
                      _buildNotificationTile(_notifications[index]),
                ),
    );

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final isRead = notif['isRead'] as bool? ?? false;
    final type = notif['type'] as String? ?? 'info';
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);
    final isBookingRequest = type == 'booking_request';
    final bookingId = notif['bookingId'] as String?;

    return GestureDetector(
      onTap: () {
        if (!isRead && !isBookingRequest) {
          _markAsRead(notif['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              title: Text(
                _removeEmojis(notif['title'] as String? ?? 'Notification'),
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notif['message'] as String? ?? '',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif['createdAt']),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              trailing: !isRead && !isBookingRequest
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onLongPress: () {
                _deleteNotification(notif['id']);
              },
            ),
            // Show action buttons for booking requests
            if (isBookingRequest && bookingId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                child: _buildBookingActionWidget(bookingId, notif['id']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingActionWidget(String bookingId, String notificationId) {
    // Find the notification to get its action status
    final notification = _notifications.firstWhere(
      (n) => n['id'] == notificationId,
      orElse: () => {},
    );
    
    final actionStatus = notification['actionStatus'] as String?;
    
    if (actionStatus == 'confirmed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Booking Confirmed ✓',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (actionStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Booking Cancelled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show action buttons by default
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _handleBookingConfirm(bookingId, notificationId),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _handleBookingCancel(bookingId, notificationId),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'booking_confirmed':
      case 'booking_completed':
        return AppTheme.accentColor;
      case 'booking_cancelled':
        return Colors.red;
      case 'payment_received':
        return Colors.green;
      case 'review_request':
        return Colors.orange;
      case 'offer':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.shopping_bag;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_completed':
        return Icons.done_all;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.credit_card;
      case 'review_request':
        return Icons.star;
      case 'offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        // Assume it's a Firestore Timestamp-like object
        dateTime = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return dateTime.toString().split(' ')[0];
      }
    } catch (e) {
      return 'Recently';
    }
  }

  String _removeEmojis(String text) {
    // Remove emoji characters using a simpler pattern
    return text.replaceAll(RegExp(r'[\p{Emoji}]', unicode: true), '').trim();
  }
}
