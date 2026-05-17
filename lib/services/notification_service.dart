import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {

  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _firestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _isInitialized = true;
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'booking_confirmed', 'booking_cancelled', etc.
    String? bookingId,
    String? relatedUserId,
    Map<String, dynamic>? data,
  }) async {
    await initialize();

    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'bookingId': bookingId,
        'relatedUserId': relatedUserId,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification created: $title for user $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    await initialize();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .get();

      final notifications = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Sort by createdAt in code to avoid index requirement
      notifications.sort((a, b) {
        final aTime = a['createdAt']?.toDate() ?? DateTime.now();
        final bTime = b['createdAt']?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Stream of notifications for real-time updates
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();
          // Sort by createdAt in code to avoid index requirement
          notifications.sort((a, b) {
            final aTime = a['createdAt']?.toDate() ?? DateTime.now();
            final bTime = b['createdAt']?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return notifications;
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await initialize();

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await initialize();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await initialize();

    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Update notification action status
  Future<void> updateNotificationStatus(String notificationId, String actionStatus) async {
    await initialize();

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'actionStatus': actionStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating notification status: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    await initialize();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get booking request notifications
  Future<List<Map<String, dynamic>>> getBookingNotifications() async {
    await initialize();

    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'booking_request')
          .get();

      final notifications = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Sort by createdAt in code
      notifications.sort((a, b) {
        final aTime = a['createdAt']?.toDate() ?? DateTime.now();
        final bTime = b['createdAt']?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return notifications;
    } catch (e) {
      print('Error fetching booking notifications: $e');
      return [];
    }
  }
}
