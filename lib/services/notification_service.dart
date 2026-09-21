import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Create a notification
  Future<String> createNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  // Get all notifications
  Future<List<AppNotification>> getNotifications({int? limit, bool? unreadOnly}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true);

      if (unreadOnly == true) {
        query = query.where('read', isEqualTo: false);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  // Create achievement notification
  Future<void> notifyAchievement(String badgeId, String badgeName) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.achievement,
        title: 'Achievement Unlocked! 🎉',
        message: 'You earned the "$badgeName" badge!',
        timestamp: DateTime.now(),
        data: {'badgeId': badgeId},
      );
      await createNotification(notification);
    } catch (e) {
      debugPrint('Error creating achievement notification: $e');
    }
  }

  // Create goal notification
  Future<void> notifyGoalCompleted(String goalTitle) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.goal,
        title: 'Goal Completed! ✅',
        message: 'You completed your goal: "$goalTitle"',
        timestamp: DateTime.now(),
      );
      await createNotification(notification);
    } catch (e) {
      debugPrint('Error creating goal notification: $e');
    }
  }

  // Create reminder notification
  Future<void> notifyReminder(String message) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.reminder,
        title: 'Practice Reminder',
        message: message,
        timestamp: DateTime.now(),
      );
      await createNotification(notification);
    } catch (e) {
      debugPrint('Error creating reminder notification: $e');
    }
  }

  // Create tip notification
  Future<void> notifyTip(String tip) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.tip,
        title: 'Practice Tip 💡',
        message: tip,
        timestamp: DateTime.now(),
      );
      await createNotification(notification);
    } catch (e) {
      debugPrint('Error creating tip notification: $e');
    }
  }
}




