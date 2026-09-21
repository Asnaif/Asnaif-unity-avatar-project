import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['role'] == 'admin';
      }
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Get all users with pagination
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('users').limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>?;
        if (userData == null) continue;
        
        // Get user progress stats
        final progressDoc = await _firestore.collection('userProgress').doc(doc.id).get();
        final progressData = progressDoc.data();
        
        // Count sessions
        final sessionsDoc = await _firestore.collection('sessions').doc(doc.id).get();
        int sessionCount = 0;
        if (sessionsDoc.exists) {
          final sessions = sessionsDoc.data()?['sessions'] as List?;
          sessionCount = sessions?.length ?? 0;
        }

        users.add({
          'userId': doc.id,
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? 'Unknown',
          'role': userData['role'] ?? 'user',
          'createdAt': userData['createdAt'] ?? '',
          'totalSessions': sessionCount,
          'totalXP': progressData?['totalXP'] ?? 0,
          'currentLevel': progressData?['currentLevel'] ?? 1,
        });
      }
      
      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String targetUserId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final progressDoc = await _firestore.collection('userProgress').doc(targetUserId).get();
      final progressData = progressDoc.data();

      final sessionsDoc = await _firestore.collection('sessions').doc(targetUserId).get();
      int sessionCount = 0;
      if (sessionsDoc.exists) {
        final sessions = sessionsDoc.data()?['sessions'] as List?;
        sessionCount = sessions?.length ?? 0;
      }

      return {
        'userId': targetUserId,
        'email': userData['email'] ?? '',
        'name': userData['name'] ?? 'Unknown',
        'role': userData['role'] ?? 'user',
        'createdAt': userData['createdAt'] ?? '',
        'totalSessions': sessionCount,
        'totalXP': progressData?['totalXP'] ?? 0,
        'currentLevel': progressData?['currentLevel'] ?? 1,
        'currentStreak': progressData?['currentStreak'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String targetUserId, String newRole) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      await _firestore.collection('users').doc(targetUserId).update({
        'role': newRole,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String targetUserId) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Unauthorized: Admin access required');
      }

      // Delete user data from all collections
      await Future.wait([
        _firestore.collection('users').doc(targetUserId).delete(),
        _firestore.collection('userProgress').doc(targetUserId).delete(),
        _firestore.collection('sessions').doc(targetUserId).delete(),
      ]);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      final adminUsers = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'admin').length;
      final regularUsers = totalUsers - adminUsers;

      // Get all sessions
      int totalSessions = 0;
      int activeSessionsLast24h = 0;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final sessionsSnapshot = await _firestore.collection('sessions').get();
      for (var doc in sessionsSnapshot.docs) {
        final sessions = doc.data()['sessions'] as List?;
        if (sessions != null) {
          totalSessions += sessions.length;
          
          // Count sessions from last 24 hours
          for (var session in sessions) {
            if (session['createdAt'] != null) {
              try {
                final createdAt = DateTime.parse(session['createdAt']);
                if (createdAt.isAfter(yesterday)) {
                  activeSessionsLast24h++;
                }
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
        }
      }

      // Get average performance metrics
      double avgPitch = 0.0;
      double avgSpeechRate = 0.0;
      double avgSentiment = 0.0;
      int metricsCount = 0;

      final progressSnapshot = await _firestore.collection('userProgress').get();
      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        if (data['averagePitch'] != null) {
          avgPitch += (data['averagePitch'] as num).toDouble();
        }
        if (data['averageSpeechRate'] != null) {
          avgSpeechRate += (data['averageSpeechRate'] as num).toDouble();
        }
        if (data['averageSentiment'] != null) {
          avgSentiment += (data['averageSentiment'] as num).toDouble();
        }
        metricsCount++;
      }

      if (metricsCount > 0) {
        avgPitch /= metricsCount;
        avgSpeechRate /= metricsCount;
        avgSentiment /= metricsCount;
      }

      // Calculate average performance score (0-100 scale)
      double avgPerformanceScore = ((avgSentiment + 1) / 2 * 100).clamp(0, 100);

      return {
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'regularUsers': regularUsers,
        'totalSessions': totalSessions,
        'activeSessionsLast24h': activeSessionsLast24h,
        'averagePitch': avgPitch,
        'averageSpeechRate': avgSpeechRate,
        'averageSentiment': avgSentiment,
        'averagePerformanceScore': avgPerformanceScore,
      };
    } catch (e) {
      debugPrint('Error getting system stats: $e');
      return {
        'totalUsers': 0,
        'adminUsers': 0,
        'regularUsers': 0,
        'totalSessions': 0,
        'activeSessionsLast24h': 0,
        'averagePitch': 0.0,
        'averageSpeechRate': 0.0,
        'averageSentiment': 0.0,
        'averagePerformanceScore': 0.0,
      };
    }
  }

  // Get user growth over time
  Future<List<Map<String, dynamic>>> getUserGrowth({int days = 30}) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final now = DateTime.now();
      
      Map<String, int> growthByDate = {};
      
      for (var doc in usersSnapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        if (createdAt != null) {
          try {
            final date = DateTime.parse(createdAt);
            final daysAgo = now.difference(date).inDays;
            
            if (daysAgo <= days) {
              final dateKey = date.toIso8601String().split('T')[0];
              growthByDate[dateKey] = (growthByDate[dateKey] ?? 0) + 1;
            }
          } catch (e) {
            // Skip invalid dates
          }
        }
      }

      // Convert to list and sort by date
      List<Map<String, dynamic>> growth = [];
      growthByDate.forEach((date, userCount) {
        growth.add({'date': date, 'count': userCount});
      });
      
      growth.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      
      return growth;
    } catch (e) {
      debugPrint('Error getting user growth: $e');
      return [];
    }
  }

  // Get sessions per day
  Future<List<Map<String, dynamic>>> getSessionsPerDay({int days = 30}) async {
    try {
      final sessionsSnapshot = await _firestore.collection('sessions').get();
      final now = DateTime.now();
      
      Map<String, int> sessionsByDate = {};
      
      for (var doc in sessionsSnapshot.docs) {
        final sessions = doc.data()['sessions'] as List?;
        if (sessions != null) {
          for (var session in sessions) {
            if (session['createdAt'] != null) {
              try {
                final date = DateTime.parse(session['createdAt']);
                final daysAgo = now.difference(date).inDays;
                
                if (daysAgo <= days) {
                  final dateKey = date.toIso8601String().split('T')[0];
                  sessionsByDate[dateKey] = (sessionsByDate[dateKey] ?? 0) + 1;
                }
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
        }
      }

      // Convert to list and sort by date
      List<Map<String, dynamic>> sessionsList = [];
      sessionsByDate.forEach((date, sessionCount) {
        sessionsList.add({'date': date, 'count': sessionCount});
      });
      
      sessionsList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      
      return sessionsList;
    } catch (e) {
      debugPrint('Error getting sessions per day: $e');
      return [];
    }
  }

  // Get most active users
  Future<List<Map<String, dynamic>>> getMostActiveUsers({int limit = 10}) async {
    try {
      final progressSnapshot = await _firestore
          .collection('userProgress')
          .orderBy('totalXP', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> activeUsers = [];
      
      for (var doc in progressSnapshot.docs) {
        final progressData = doc.data();
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        final userData = userDoc.data() ?? {};

        activeUsers.add({
          'userId': doc.id,
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'totalXP': progressData['totalXP'] ?? 0,
          'totalSessions': progressData['totalSessions'] ?? 0,
          'currentLevel': progressData['currentLevel'] ?? 1,
        });
      }

      return activeUsers;
    } catch (e) {
      debugPrint('Error getting most active users: $e');
      return [];
    }
  }
}

