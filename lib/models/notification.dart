import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  achievement,
  goal,
  reminder,
  tip,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime timestamp;
  final Map<String, dynamic>? data; // Additional data (e.g., badgeId, goalId)

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    required this.timestamp,
    this.data,
  });

  // Factory method from Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
    };
  }
}




