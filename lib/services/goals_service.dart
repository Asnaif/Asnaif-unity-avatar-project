import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/models/goal.dart';
import 'package:interprep/services/notification_service.dart';


class GoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Get all goals for user
  Future<List<Goal>> getUserGoals({GoalStatus? status}) async {
    try {
      Query query = _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user goals: $e');
      return [];
    }
  }

  // Get active goals
  Future<List<Goal>> getActiveGoals() async {
    return getUserGoals(status: GoalStatus.active);
  }

  // Get completed goals
  Future<List<Goal>> getCompletedGoals() async {
    return getUserGoals(status: GoalStatus.completed);
  }

  // Create a new goal
  Future<String> createGoal(Goal goal) async {
    try {
      final docRef = await _firestore.collection('goals').add(goal.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating goal: $e');
      rethrow;
    }
  }

  // Update goal
  Future<void> updateGoal(Goal goal) async {
    try {
      await _firestore.collection('goals').doc(goal.id).update(goal.toFirestore());
    } catch (e) {
      debugPrint('Error updating goal: $e');
      rethrow;
    }
  }

  // Update goal progress
  Future<void> updateGoalProgress(String goalId, int newCurrent) async {
    try {
      final goalDoc = await _firestore.collection('goals').doc(goalId).get();
      if (!goalDoc.exists) return;

      final goal = Goal.fromFirestore(goalDoc);
      final wasCompleted = goal.isCompleted;
      final updatedGoal = goal.copyWith(
        current: newCurrent,
        status: newCurrent >= goal.target
            ? GoalStatus.completed
            : goal.status,
        completedAt: newCurrent >= goal.target && goal.completedAt == null
            ? DateTime.now()
            : goal.completedAt,
      );

      await updateGoal(updatedGoal);

       // Send notification if goal was just completed
      if (!wasCompleted && updatedGoal.isCompleted) {
        try {
          final notificationService = NotificationService();
          await notificationService.notifyGoalCompleted(updatedGoal.title);
        } catch (e) {
          debugPrint('Error sending goal completion notification: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
      rethrow;
    }
  }

  // Delete goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('goals').doc(goalId).delete();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  // Get goal suggestions based on user progress
  Future<List<Map<String, dynamic>>> getGoalSuggestions() async {
    try {
      // Get user progress to suggest relevant goals
      final userProgressRef = _firestore.collection('userProgress').doc(userId);
      final progressDoc = await userProgressRef.get();

      if (!progressDoc.exists) {
        return _getDefaultSuggestions();
      }

      final progress = progressDoc.data()!;
      final totalSessions = progress['totalSessions'] ?? 0;
      final currentStreak = progress['currentStreak'] ?? 0;

      List<Map<String, dynamic>> suggestions = [];

      // Suggest daily practice goal
      suggestions.add({
        'title': 'Daily Practice',
        'description': 'Complete at least 1 practice session every day',
        'type': GoalType.daily.toString().split('.').last,
        'target': 7,
        'deadline': DateTime.now().add(const Duration(days: 7)),
      });

      // Suggest weekly sessions goal
      if (totalSessions < 10) {
        suggestions.add({
          'title': 'Weekly Sessions',
          'description': 'Complete 5 practice sessions this week',
          'type': GoalType.weekly.toString().split('.').last,
          'target': 5,
          'deadline': DateTime.now().add(const Duration(days: 7)),
        });
      } else {
        suggestions.add({
          'title': 'Weekly Sessions',
          'description': 'Complete 10 practice sessions this week',
          'type': GoalType.weekly.toString().split('.').last,
          'target': 10,
          'deadline': DateTime.now().add(const Duration(days: 7)),
        });
      }

      // Suggest streak goal
      if (currentStreak < 7) {
        suggestions.add({
          'title': 'Build Your Streak',
          'description': 'Maintain a 7-day practice streak',
          'type': GoalType.custom.toString().split('.').last,
          'target': 7,
          'deadline': DateTime.now().add(const Duration(days: 14)),
        });
      }

      // Suggest questions goal
      suggestions.add({
        'title': 'Answer Questions',
        'description': 'Answer 50 questions this week',
        'type': GoalType.weekly.toString().split('.').last,
        'target': 50,
        'deadline': DateTime.now().add(const Duration(days: 7)),
      });

      return suggestions;
    } catch (e) {
      debugPrint('Error getting goal suggestions: $e');
      return _getDefaultSuggestions();
    }
  }

  List<Map<String, dynamic>> _getDefaultSuggestions() {
    return [
      {
        'title': 'Daily Practice',
        'description': 'Complete at least 1 practice session every day',
        'type': GoalType.daily.toString().split('.').last,
        'target': 7,
        'deadline': DateTime.now().add(const Duration(days: 7)),
      },
      {
        'title': 'Weekly Sessions',
        'description': 'Complete 5 practice sessions this week',
        'type': GoalType.weekly.toString().split('.').last,
        'target': 5,
        'deadline': DateTime.now().add(const Duration(days: 7)),
      },
    ];
  }

  // Increment goal progress (called when user completes a session)
  Future<void> incrementGoalProgress(GoalType goalType, {int amount = 1}) async {
    try {
      final activeGoals = await getActiveGoals();
      final relevantGoals = activeGoals.where((goal) => goal.type == goalType).toList();

      for (var goal in relevantGoals) {
        final newCurrent = goal.current + amount;
        await updateGoalProgress(goal.id, newCurrent);
      }
    } catch (e) {
      debugPrint('Error incrementing goal progress: $e');
    }
  }
}

