import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ActivityType {
  // Authentication
  login,
  logout,
  signup,
  passwordReset,
  
  // Session Activities
  sessionCreated,
  sessionCompleted,
  sessionCancelled,
  sessionViewed,
  
  // Content Activities
  fileUploaded,
  feedbackViewed,
  analyticsViewed,
  dashboardViewed,
  
  // Social Activities
  friendAdded,
  friendRequestSent,
  communityPostCreated,
  leaderboardViewed,
  
  // Admin Activities
  userRoleUpdated,
  userDeleted,
  contentModerated,
  reportResolved,
  
  // System Activities
  apiCall,
  errorOccurred,
  settingsUpdated,
  profileUpdated,
}

class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId {
    return _auth.currentUser?.uid;
  }

  // Log user activity
  Future<void> logActivity({
    required ActivityType type,
    String? userId,
    Map<String, dynamic>? metadata,
    String? description,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logUserId = userId ?? this.userId;
      if (logUserId == null) {
        debugPrint('Cannot log activity: User not authenticated');
        return;
      }

      await _firestore.collection('activityLogs').add({
        'userId': logUserId,
        'type': type.name,
        'description': description ?? _getDefaultDescription(type),
        'metadata': metadata ?? {},
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // For easy querying
        'hour': DateTime.now().hour, // For hourly analysis
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
      // Don't throw - logging should not break the app
    }
  }

  // Convenience methods for common activities
  Future<void> logLogin(String userId) async {
    await logActivity(
      type: ActivityType.login,
      userId: userId,
      description: 'User logged in',
    );
  }

  Future<void> logLogout(String userId) async {
    await logActivity(
      type: ActivityType.logout,
      userId: userId,
      description: 'User logged out',
    );
  }

  Future<void> logSignup(String userId, {String? email}) async {
    await logActivity(
      type: ActivityType.signup,
      userId: userId,
      description: 'New user registered',
      metadata: {'email': email},
    );
  }

  Future<void> logSessionCreated(String sessionId, {String? mode}) async {
    await logActivity(
      type: ActivityType.sessionCreated,
      description: 'Practice session created',
      metadata: {
        'sessionId': sessionId,
        'mode': mode,
      },
    );
  }

  Future<void> logSessionCompleted(String sessionId, {
    int? questionsAnswered,
    double? performanceScore,
  }) async {
    await logActivity(
      type: ActivityType.sessionCompleted,
      description: 'Practice session completed',
      metadata: {
        'sessionId': sessionId,
        'questionsAnswered': questionsAnswered,
        'performanceScore': performanceScore,
      },
    );
  }

  Future<void> logFileUpload(String fileType, {int? fileSize}) async {
    await logActivity(
      type: ActivityType.fileUploaded,
      description: 'File uploaded',
      metadata: {
        'fileType': fileType,
        'fileSize': fileSize,
      },
    );
  }

  Future<void> logAdminAction({
    required ActivityType type,
    required String targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await logActivity(
      type: type,
      description: 'Admin action performed',
      metadata: {
        'targetUserId': targetUserId,
        ...?metadata,
      },
    );
  }

  Future<void> logError({
    required String error,
    String? stackTrace,
    String? context,
  }) async {
    await logActivity(
      type: ActivityType.errorOccurred,
      description: 'Error occurred',
      metadata: {
        'error': error,
        'stackTrace': stackTrace,
        'context': context,
      },
    );
  }

  // Get activities for a specific user
  Future<List<Map<String, dynamic>>> getUserActivities({
    String? userId,
    ActivityType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final targetUserId = userId ?? this.userId;
      if (targetUserId == null) return [];

      Query query = _firestore
          .collection('activityLogs')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> activities = [];
      for (var doc in snapshot.docs) {
        final dataMap = doc.data() as Map<String, dynamic>?;
        if (dataMap == null) continue;
        
        // Filter by date range if provided
        if (startDate != null || endDate != null) {
          final timestamp = dataMap['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (startDate != null && date.isBefore(startDate)) continue;
            if (endDate != null && date.isAfter(endDate)) continue;
          }
        }

        activities.add({
          'id': doc.id,
          ...dataMap,
        });
      }

      return activities;
    } catch (e) {
      debugPrint('Error getting user activities: $e');
      return [];
    }
  }

  // Get all activities (admin only)
  Future<List<Map<String, dynamic>>> getAllActivities({
    ActivityType? type,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('activityLogs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> activities = [];
      for (var doc in snapshot.docs) {
        final dataMap = doc.data() as Map<String, dynamic>?;
        if (dataMap == null) continue;
        
        // Filter by date range if provided
        if (startDate != null || endDate != null) {
          final timestamp = dataMap['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (startDate != null && date.isBefore(startDate)) continue;
            if (endDate != null && date.isAfter(endDate)) continue;
          }
        }

        // Get user info
        final userDoc = await _firestore
            .collection('users')
            .doc(dataMap['userId'] as String)
            .get();
        final userData = userDoc.data();

        activities.add({
          'id': doc.id,
          ...dataMap,
          'userName': userData?['name'] ?? 'Unknown',
          'userEmail': userData?['email'] ?? '',
        });
      }

      return activities;
    } catch (e) {
      debugPrint('Error getting all activities: $e');
      return [];
    }
  }

  // Get activity statistics
  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('activityLogs');

      final snapshot = await query.get();

      Map<String, int> byType = {};
      Map<String, int> byDate = {};
      Map<String, int> byHour = {};
      int total = 0;

      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      for (var doc in snapshot.docs) {
        final dataMap = doc.data() as Map<String, dynamic>?;
        if (dataMap == null) continue;
        
        final timestamp = dataMap['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          if (date.isBefore(start) || date.isAfter(end)) continue;
        }

        total++;
        
        // Count by type
        final type = (dataMap['type'] as String?) ?? 'unknown';
        byType[type] = (byType[type] ?? 0) + 1;

        // Count by date
        final dateStr = (dataMap['date'] as String?) ?? '';
        if (dateStr.isNotEmpty) {
          byDate[dateStr] = (byDate[dateStr] ?? 0) + 1;
        }

        // Count by hour
        final hour = (dataMap['hour'] as int?) ?? 0;
        byHour[hour.toString()] = (byHour[hour.toString()] ?? 0) + 1;
      }

      return {
        'total': total,
        'byType': byType,
        'byDate': byDate,
        'byHour': byHour,
        'mostActiveHour': byHour.entries.isNotEmpty
            ? byHour.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'mostActiveType': byType.entries.isNotEmpty
            ? byType.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      debugPrint('Error getting activity stats: $e');
      return {};
    }
  }

  // Get real-time activity stream (for monitoring)
  Stream<List<Map<String, dynamic>>> getActivityStream({
    int limit = 20,
  }) {
    return _firestore
        .collection('activityLogs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> activities = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get user info
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'])
            .get();
        final userData = userDoc.data();

        activities.add({
          'id': doc.id,
          ...data,
          'userName': userData?['name'] ?? 'Unknown',
          'userEmail': userData?['email'] ?? '',
        });
      }
      
      return activities;
    });
  }

  // Get user activity summary
  Future<Map<String, dynamic>> getUserActivitySummary(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final activities = await getUserActivities(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // Get more for accurate summary
      );

      Map<String, int> byType = {};
      int loginCount = 0;
      int sessionCount = 0;
      DateTime? lastLogin;

      for (var activity in activities) {
        final type = activity['type'] ?? '';
        byType[type] = (byType[type] ?? 0) + 1;

        if (type == ActivityType.login.name) {
          loginCount++;
          final timestamp = activity['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (lastLogin == null || date.isAfter(lastLogin)) {
              lastLogin = date;
            }
          }
        }

        if (type == ActivityType.sessionCompleted.name ||
            type == ActivityType.sessionCreated.name) {
          sessionCount++;
        }
      }

      return {
        'totalActivities': activities.length,
        'byType': byType,
        'loginCount': loginCount,
        'sessionCount': sessionCount,
        'lastLogin': lastLogin?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting user activity summary: $e');
      return {};
    }
  }

  String _getDefaultDescription(ActivityType type) {
    switch (type) {
      case ActivityType.login:
        return 'User logged in';
      case ActivityType.logout:
        return 'User logged out';
      case ActivityType.signup:
        return 'New user registered';
      case ActivityType.sessionCreated:
        return 'Practice session created';
      case ActivityType.sessionCompleted:
        return 'Practice session completed';
      case ActivityType.fileUploaded:
        return 'File uploaded';
      case ActivityType.userRoleUpdated:
        return 'User role updated';
      case ActivityType.userDeleted:
        return 'User deleted';
      case ActivityType.errorOccurred:
        return 'Error occurred';
      default:
        return 'Activity logged';
    }
  }
}