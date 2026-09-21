import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LearningPathService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Get user's learning path based on their progress
  Future<Map<String, dynamic>> getLearningPath() async {
    try {
      // Get user progress
      final progressDoc = await _firestore.collection('userProgress').doc(userId).get();
      final progress = progressDoc.data() ?? {};
      
      // Get session history
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final sessionsSnapshot = await sessionsRef.get();
      final sessions = sessionsSnapshot.data()?['sessions'] ?? [];
      
      // Analyze weaknesses
      final weaknesses = _analyzeWeaknesses(sessions);
      
      // Generate personalized recommendations
      final recommendations = await _generateRecommendations(weaknesses, progress);
      
      return {
        'weaknesses': weaknesses,
        'recommendations': recommendations,
        'currentLevel': progress['currentLevel'] ?? 1,
        'nextMilestone': _getNextMilestone(progress['currentLevel'] ?? 1),
      };
    } catch (e) {
      debugPrint('Error getting learning path: $e');
      return {
        'weaknesses': [],
        'recommendations': [],
        'currentLevel': 1,
        'nextMilestone': 'Complete your first session',
      };
    }
  }

  List<String> _analyzeWeaknesses(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return ['Start practicing to identify areas for improvement'];
    }

    List<String> weaknesses = [];
    
    // Get completed sessions with feedback
    final completedSessions = sessions
        .where((s) => s['status'] == 'completed' && s['reportGenerated'] != null)
        .toList();

    if (completedSessions.isEmpty) {
      return ['Complete a session to get personalized feedback'];
    }

    // Calculate averages
    double totalPitch = 0;
    double totalSpeechRate = 0;
    double totalSentiment = 0;
    int count = 0;

    for (var session in completedSessions) {
      final report = session['reportGenerated'] as Map<String, dynamic>?;
      if (report != null) {
        totalPitch += (report['averagePitch'] ?? 0.0) as double;
        totalSpeechRate += (report['averageSpeechRate'] ?? 0.0) as double;
        totalSentiment += (report['averageSentiment'] ?? 0.0) as double;
        count++;
      }
    }

    if (count == 0) return weaknesses;

    final avgPitch = totalPitch / count;
    final avgSpeechRate = totalSpeechRate / count;
    final avgSentiment = totalSentiment / count;

    // Identify weaknesses
    if (avgPitch < 120) {
      weaknesses.add('Low pitch - practice speaking with more energy');
    } else if (avgPitch > 180) {
      weaknesses.add('High pitch - practice speaking more calmly');
    }

    if (avgSpeechRate < 120) {
      weaknesses.add('Slow speech rate - practice speaking faster');
    } else if (avgSpeechRate > 180) {
      weaknesses.add('Fast speech rate - slow down for clarity');
    }

    if (avgSentiment < 0) {
      weaknesses.add('Negative tone - practice being more positive');
    }

    if (weaknesses.isEmpty) {
      weaknesses.add('Great job! Keep practicing to maintain your skills');
    }

    return weaknesses;
  }

  Future<List<Map<String, dynamic>>> _generateRecommendations(
    List<String> weaknesses,
    Map<String, dynamic> progress,
  ) async {
    List<Map<String, dynamic>> recommendations = [];

    // Skill-based recommendations
    for (String weakness in weaknesses) {
      if (weakness.contains('pitch')) {
        recommendations.add({
          'type': 'practice',
          'title': 'Pitch Practice',
          'description': 'Focus on maintaining optimal pitch (120-180 Hz)',
          'difficulty': 'intermediate',
          'estimatedTime': '15 minutes',
          'topics': ['Voice modulation', 'Energy control'],
        });
      } else if (weakness.contains('speech rate')) {
        recommendations.add({
          'type': 'practice',
          'title': 'Speech Rate Practice',
          'description': 'Practice speaking at optimal pace (120-150 WPM)',
          'difficulty': 'beginner',
          'estimatedTime': '20 minutes',
          'topics': ['Pacing', 'Clarity'],
        });
      } else if (weakness.contains('tone') || weakness.contains('sentiment')) {
        recommendations.add({
          'type': 'practice',
          'title': 'Tone Practice',
          'description': 'Practice maintaining positive and confident tone',
          'difficulty': 'beginner',
          'estimatedTime': '15 minutes',
          'topics': ['Confidence', 'Positivity'],
        });
      }
    }

    // Level-based recommendations
    final level = progress['currentLevel'] ?? 1;
    if (level < 5) {
      recommendations.add({
        'type': 'milestone',
        'title': 'Reach Level 5',
        'description': 'Complete 5 more practice sessions to level up',
        'difficulty': 'beginner',
        'estimatedTime': '1 hour',
        'topics': ['Consistency', 'Practice'],
      });
    }

    // Topic-specific recommendations
    recommendations.addAll([
      {
        'type': 'topic',
        'title': 'Technical Communication',
        'description': 'Practice explaining technical concepts clearly',
        'difficulty': 'advanced',
        'estimatedTime': '30 minutes',
        'topics': ['Technical terms', 'Clarity'],
      },
      {
        'type': 'topic',
        'title': 'Soft Skills',
        'description': 'Practice emotional intelligence and empathy',
        'difficulty': 'intermediate',
        'estimatedTime': '25 minutes',
        'topics': ['Empathy', 'Emotional intelligence'],
      },
    ]);

    return recommendations;
  }

  String _getNextMilestone(int currentLevel) {
    if (currentLevel < 5) {
      return 'Reach Level 5';
    } else if (currentLevel < 10) {
      return 'Reach Level 10';
    } else if (currentLevel < 20) {
      return 'Reach Level 20';
    } else {
      return 'Master Level Achieved!';
    }
  }

  // Save user preferences
  Future<void> savePreferences({
    List<String>? preferredTopics,
    String? difficultyLevel,
    int? dailyGoal,
  }) async {
    try {
      await _firestore.collection('userPreferences').doc(userId).set({
        'preferredTopics': preferredTopics ?? [],
        'difficultyLevel': difficultyLevel ?? 'beginner',
        'dailyGoal': dailyGoal ?? 1,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final doc = await _firestore.collection('userPreferences').doc(userId).get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {
        'preferredTopics': [],
        'difficultyLevel': 'beginner',
        'dailyGoal': 1,
      };
    } catch (e) {
      debugPrint('Error getting preferences: $e');
      return {
        'preferredTopics': [],
        'difficultyLevel': 'beginner',
        'dailyGoal': 1,
      };
    }
  }
}

