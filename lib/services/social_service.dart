import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Add friend
  Future<void> addFriend(String friendUserId) async {
    try {
      await _firestore.collection('friendships').doc('${userId}_$friendUserId').set({
        'userId': userId,
        'friendId': friendUserId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding friend: $e');
      rethrow;
    }
  }
  // Check friendship status between current user and another user
  Future<String?> getFriendshipStatus(String otherUserId) async {
    try {
      // Check if current user sent request
      final sentRequest = await _firestore
          .collection('friendships')
          .doc('${userId}_$otherUserId')
          .get();
      
      if (sentRequest.exists) {
        final data = sentRequest.data();
        final status = data?['status'];
        if (status == 'pending') return 'pending_sent';
        if (status == 'accepted') return 'friends';
      }
      
      // Check if other user sent request
      final receivedRequest = await _firestore
          .collection('friendships')
          .doc('${otherUserId}_$userId')
          .get();
      
      if (receivedRequest.exists) {
        final data = receivedRequest.data();
        final status = data?['status'];
        if (status == 'pending') return 'pending_received';
        if (status == 'accepted') return 'friends';
      }
      
      return null; // No friendship exists
    } catch (e) {
      debugPrint('Error checking friendship status: $e');
      return null;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).update({
        'status': 'accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Get friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final snapshot = await _firestore
          .collection('friendships')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'friendshipId': doc.id,
          'friendId': data['friendId'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  // Share practice session (anonymized)
  Future<void> shareSession(String sessionId, {bool anonymize = true}) async {
    try {
      final sessionRef = _firestore.collection('sessions').doc(userId);
      final snapshot = await sessionRef.get();
      final sessions = snapshot.data()?['sessions'] ?? [];
      
      final session = sessions.firstWhere(
        (s) => s['id'] == sessionId,
        orElse: () => null,
      );

      if (session == null) return;

      // Create shareable data
      final shareData = {
        'sessionId': sessionId,
        'anonymized': anonymize,
        'sharedAt': DateTime.now().toIso8601String(),
      };

      // Save to shared sessions
      await _firestore.collection('sharedSessions').add({
        'originalUserId': anonymize ? null : userId,
        'sessionData': shareData,
        'sharedAt': DateTime.now().toIso8601String(),
      });

      // Share via platform
      await Share.share(
        'Check out my practice session on InterPrep!',
        subject: 'InterPrep Practice Session',
      );
    } catch (e) {
      debugPrint('Error sharing session: $e');
    }
  }

    // Get public leaderboard
  Future<List<Map<String, dynamic>>> getPublicLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('userProgress')
          .orderBy('totalXP', descending: true)
          .limit(limit * 2)  // Get more to filter out users with 0 sessions
          .get();

      // Fetch user names and friendship status for each entry
      final List<Map<String, dynamic>> leaderboard = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final entryUserId = doc.id;
        
        // Only include users who have completed at least 1 session
        final totalSessions = data['totalSessions'] ?? 0;
        if (totalSessions == 0 || totalSessions == null) {
          continue; // Skip users with no sessions
        }
        
        // Stop if we have enough entries
        if (leaderboard.length >= limit) {
          break;
        }
        
        // Fetch user name from users collection
        String displayName = 'Anonymous User';
        try {
          final userDoc = await _firestore.collection('users').doc(entryUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            displayName = userData?['name'] ?? 'Anonymous User';
          }
        } catch (e) {
          debugPrint('Error fetching user name for $entryUserId: $e');
        }
        
        // Get friendship status (only if not current user)
        String? friendshipStatus;
        if (entryUserId != userId) {
          friendshipStatus = await getFriendshipStatus(entryUserId);
        }
        
        leaderboard.add({
          'userId': entryUserId,
          'totalXP': data['totalXP'] ?? 0,
          'currentLevel': data['currentLevel'] ?? 1,
          'totalSessions': totalSessions,
          'displayName': displayName,
          'friendshipStatus': friendshipStatus, // null, 'pending_sent', 'pending_received', 'friends'
        });
      }
      
      return leaderboard;
    } catch (e) {
      debugPrint('Error getting public leaderboard: $e');
      return [];
    }
  }

  // Create study group
  Future<String> createStudyGroup(String name, String description) async {
    try {
      final docRef = await _firestore.collection('studyGroups').add({
        'name': name,
        'description': description,
        'createdBy': userId,
        'members': [userId],
        'createdAt': DateTime.now().toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating study group: $e');
      rethrow;
    }
  }

  // Join study group
  Future<void> joinStudyGroup(String groupId) async {
    try {
      await _firestore.collection('studyGroups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error joining study group: $e');
      rethrow;
    }
  }

  // Get study groups
  Future<List<Map<String, dynamic>>> getStudyGroups() async {
    try {
      final snapshot = await _firestore
          .collection('studyGroups')
          .where('members', arrayContains: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'groupId': doc.id,
          'name': data['name'],
          'description': data['description'],
          'memberCount': (data['members'] as List?)?.length ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting study groups: $e');
      return [];
    }
  }
}

