import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/models/user_progress.dart';
import 'package:interprep/services/notification_service.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Award XP for completing a session
  Future<void> awardSessionXP(int questionsAnswered, Map<String, dynamic> feedback) async {
    try {
      final userProgressRef = _firestore.collection('userProgress').doc(userId);
      final doc = await userProgressRef.get();
      
      int xpGained = questionsAnswered * 10; // 10 XP per question
      int currentXP = doc.exists ? (doc.data()?['totalXP'] ?? 0) : 0;
      int newXP = currentXP + xpGained;
      int newLevel = UserProgress.calculateLevel(newXP);

      // Update streak
      DateTime now = DateTime.now();
      DateTime? lastSession = doc.exists && doc.data()?['lastSessionDate'] != null
          ? (doc.data()!['lastSessionDate'] as Timestamp).toDate()
          : null;
      
      int currentStreak = doc.exists ? (doc.data()?['currentStreak'] ?? 0) : 0;
      int newStreak = _calculateStreak(lastSession, now, currentStreak);

      // Update progress
      await userProgressRef.set({
        'totalXP': newXP,
        'currentLevel': newLevel,
        'currentStreak': newStreak,
        'lastSessionDate': Timestamp.now(),
        'totalSessions': FieldValue.increment(1),
        'totalQuestionsAnswered': FieldValue.increment(questionsAnswered),
      }, SetOptions(merge: true));

      // Check for badges
      await _checkAndAwardBadges(newXP, newStreak, questionsAnswered, feedback);
    } catch (e) {
      debugPrint('Error awarding XP: $e');
    }
  }

  int _calculateStreak(DateTime? lastSession, DateTime now, int currentStreak) {
    if (lastSession == null) {
      return 1; // First session
    }

    final difference = now.difference(lastSession).inDays;
    
    if (difference == 0) {
      return currentStreak; // Same day, no change
    } else if (difference == 1) {
      return currentStreak + 1; // Consecutive day
    } else {
      return 1; // Streak broken, start over
    }
  }

  Future<void> _checkAndAwardBadges(
    int totalXP,
    int streak,
    int questionsAnswered,
    Map<String, dynamic> feedback,
  ) async {
    final userProgressRef = _firestore.collection('userProgress').doc(userId);
    final doc = await userProgressRef.get();
    final currentBadges = Map<String, int>.from(doc.data()?['badges'] ?? {});
    final achievements = List<String>.from(doc.data()?['achievements'] ?? []);
    
    List<String> newBadges = [];

    // Check first session badge
    if (!currentBadges.containsKey('first_session') && questionsAnswered > 0) {
      newBadges.add('first_session');
    }

    // Check streak badges
    if (streak >= 7 && !currentBadges.containsKey('streak_7')) {
      newBadges.add('streak_7');
    }
    if (streak >= 30 && !currentBadges.containsKey('streak_30')) {
      newBadges.add('streak_30');
    }

    // Check session count badge
    final totalSessions = (doc.data()?['totalSessions'] ?? 0) + 1;
    if (totalSessions >= 100 && !currentBadges.containsKey('century')) {
      newBadges.add('century');
    }

    // Check performance badges from feedback
    if (feedback.containsKey('averagePitch')) {
      final pitch = feedback['averagePitch'] as double? ?? 0.0;
      // Perfect pitch range: 120-180 Hz for males, 165-255 for females
      if (pitch >= 120 && pitch <= 180 && !currentBadges.containsKey('perfect_pitch')) {
        // Check if user has achieved this 5 times
        final perfectPitchCount = currentBadges['perfect_pitch'] ?? 0;
        if (perfectPitchCount >= 4) {
          newBadges.add('perfect_pitch');
        } else {
          await userProgressRef.set({
            'badges.perfect_pitch': perfectPitchCount + 1,
          }, SetOptions(merge: true));
        }
      }
    }

    if (feedback.containsKey('averageSpeechRate')) {
      final speechRate = feedback['averageSpeechRate'] as double? ?? 0.0;
      if (speechRate >= 150 && !currentBadges.containsKey('fast_talker')) {
        newBadges.add('fast_talker');
      }
    }

    if (feedback.containsKey('averageSentiment')) {
      final sentiment = feedback['averageSentiment'] as double? ?? 0.0;
      if (sentiment > 0.3 && !currentBadges.containsKey('positive_vibes')) {
        final positiveCount = currentBadges['positive_vibes'] ?? 0;
        if (positiveCount >= 4) {
          newBadges.add('positive_vibes');
        } else {
          await userProgressRef.set({
            'badges.positive_vibes': positiveCount + 1,
          }, SetOptions(merge: true));
        }
      }
    }

    // Award new badges
    if (newBadges.isNotEmpty) {
      Map<String, int> updatedBadges = Map.from(currentBadges);
      int totalXPGained = 0;
      final notificationService = NotificationService(); // Add notification service

      for (String badgeId in newBadges) {
        final badge = BadgeDefinitions.getBadgeById(badgeId);
        if (badge != null) {
          updatedBadges[badgeId] = 1;
          totalXPGained += badge.xpReward;
          achievements.add(badgeId);

          // Send achievement notification
          try {
            await notificationService.notifyAchievement(badgeId, badge.name);
          } catch (e) {
            debugPrint('Error sending achievement notification: $e');
          }
        }
      }

      // Update badges and add XP
      final currentXP = doc.data()?['totalXP'] ?? 0;
      final newXP = currentXP + totalXPGained;
      final newLevel = UserProgress.calculateLevel(newXP);

      await userProgressRef.set({
        'badges': updatedBadges,
        'achievements': achievements,
        'totalXP': newXP,
        'currentLevel': newLevel,
      }, SetOptions(merge: true));
    }
  }

  // Get user progress
  Future<UserProgress?> getUserProgress() async {
    try {
      final doc = await _firestore.collection('userProgress').doc(userId).get();
      if (doc.exists) {
        // Convert LinkedMap to Map<String, dynamic>
        final data = doc.data();
        if (data != null) {
          return UserProgress.fromFirestore(Map<String, dynamic>.from(data), userId);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return null;
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('userProgress')
          .orderBy('totalXP', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'totalXP': data['totalXP'] ?? 0,
          'currentLevel': data['currentLevel'] ?? 1,
          'totalSessions': data['totalSessions'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }
}

