import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/services/badge_service.dart';
import 'package:interprep/models/user_progress.dart' as models;

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BadgeService _badgeService = BadgeService();

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }
    // Get user dashboard data
  DateTime parseSessionDate(Map<String, dynamic> session) {
    if (session['createdAt'] != null && session['createdAt'].toString().isNotEmpty) {
      final parsed = DateTime.tryParse(session['createdAt'].toString());
      if (parsed != null) return parsed;
    }
    if (session['completedAt'] != null && session['completedAt'].toString().isNotEmpty) {
      final parsed = DateTime.tryParse(session['completedAt'].toString());
      if (parsed != null) return parsed;
    }
    // Fallback: search responses for recorded_at
    if (session['responses'] is Map) {
      final responses = session['responses'] as Map;
      for (var key in responses.keys) {
        final resp = responses[key];
        if (resp is Map && resp['recorded_at'] != null) {
          final parsed = DateTime.tryParse(resp['recorded_at'].toString());
          if (parsed != null) return parsed;
        }
      }
    }
    return DateTime(1970);
  }

  // Get user dashboard data
  Future<Map<String, dynamic>> getUserDashboardData() async {
    try {
      // Single Firestore read for the sessions document — shared across sub-methods
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final snapshot = await sessionsRef.get();

      // Get recent sessions (using shared snapshot)
      final recentSessions = await getRecentSessions(limit: 5, cachedSnapshot: snapshot);
      
      // Get user progress
      var progress = await _badgeService.getUserProgress();
      
      // Dynamically calculate total sessions, questions, and average metrics to prevent zero displays
      int totalSessions = 0;
      int totalQuestions = 0;
      double avgPitch = 0.0;
      double avgSpeechRate = 0.0;
      double avgSentiment = 0.0;

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        final regularList = List.from(data['sessions'] ?? []);
        final vapiList = List.from(data['vapiInterviews'] ?? []);
        
        final completedRegs = regularList.where((s) => s is Map && s['status'] == 'completed').toList();
        totalSessions = completedRegs.length + vapiList.length;
        
        int regQuestions = completedRegs.fold<int>(0, (acc, s) => acc + ((s['questionsGenerated'] as List?)?.length ?? 0));
        int vapiQuestions = vapiList.length * 5; // assume 5 questions per Vapi interview
        totalQuestions = regQuestions + vapiQuestions;

        // Calculate metrics
        double pitchSum = 0.0;
        double speechSum = 0.0;
        double sentimentSum = 0.0;
        int pitchCount = 0;
        int speechCount = 0;
        int sentimentCount = 0;

        for (var s in completedRegs) {
          if (s is Map) {
            final report = s['reportGenerated'] as Map?;
            if (report != null) {
              final pitch = (report['average_pitch'] ?? report['averagePitch'] ?? 0.0).toDouble();
              final rate = (report['speech_rate'] ?? report['averageSpeechRate'] ?? 0.0).toDouble();
              final sentiment = (report['sentiment_score'] ?? report['averageSentiment'] ?? 0.0).toDouble();

              if (pitch > 0) {
                pitchSum += pitch;
                pitchCount++;
              }
              if (rate > 0) {
                speechSum += rate;
                speechCount++;
              }
              sentimentSum += sentiment;
              sentimentCount++;
            }
          }
        }

        avgPitch = pitchCount > 0 ? pitchSum / pitchCount : 0.0;
        avgSpeechRate = speechCount > 0 ? speechSum / speechCount : 0.0;
        avgSentiment = sentimentCount > 0 ? sentimentSum / sentimentCount : 0.0;
      }

      if (progress != null) {
        progress = progress.copyWith(
          totalSessions: totalSessions > progress.totalSessions ? totalSessions : progress.totalSessions,
          totalQuestionsAnswered: totalQuestions > progress.totalQuestionsAnswered ? totalQuestions : progress.totalQuestionsAnswered,
          averagePitch: avgPitch > 0 ? avgPitch : progress.averagePitch,
          averageSpeechRate: avgSpeechRate > 0 ? avgSpeechRate : progress.averageSpeechRate,
          averageSentiment: avgSentiment != 0.0 ? avgSentiment : progress.averageSentiment,
        );
      } else {
        progress = models.UserProgress(
          userId: userId,
          totalSessions: totalSessions,
          totalQuestionsAnswered: totalQuestions,
          totalXP: totalSessions * 100,
          currentLevel: models.UserProgress.calculateLevel(totalSessions * 100),
          currentStreak: 1,
          averagePitch: avgPitch,
          averageSpeechRate: avgSpeechRate,
          averageSentiment: avgSentiment,
        );
      }

      // Get performance trends (using shared snapshot)
      final performanceTrends = await getPerformanceTrends(cachedSnapshot: snapshot);
      
      // Get achievements summary
      final achievements = await getAchievementsSummary();
      
      // Get learning path preview
      final learningPathPreview = await getLearningPathPreview();
      
      // Get community stats
      final communityStats = await getCommunityStats();

      // Get advanced statistics
      final advancedStats = await getAdvancedStatistics();

      return {
        'progress': progress,
        'recentSessions': recentSessions,
        'performanceTrends': performanceTrends,
        'achievements': achievements,
        'learningPathPreview': learningPathPreview,
        'communityStats': communityStats,
        'advancedStats': advancedStats,
      };
    } catch (e) {
      debugPrint('Error getting user dashboard data: $e');
      rethrow;
    }
  }

  // // Get recent sessions
  // Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 5}) async {
  //   try {
  //     final sessionsRef = _firestore.collection('sessions').doc(userId);
  //     final snapshot = await sessionsRef.get();
      
  //     if (!snapshot.exists) {
  //       return [];
  //     }

  //     // Convert the data properly
  //     final data = snapshot.data();
  //     if (data == null) return [];
      
  //     final sessionsList = data['sessions'];
  //     if (sessionsList == null) return [];
      
  //     // Convert each session map properly
  //     final sessions = (sessionsList as List).map((session) {
  //       if (session is Map) {
  //         return Map<String, dynamic>.from(session);
  //       }
  //       return session as Map<String, dynamic>;
  //     }).toList();
      
  //     // Sort by creation date (most recent first)
  //     sessions.sort((a, b) {
  //       final dateA = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime(1970);
  //       final dateB = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime(1970);
  //       return dateB.compareTo(dateA);
  //     });

  //     // Return limited sessions with formatted data
  //     return sessions.take(limit).map((session) {
  //       return {
  //         'id': session['id'] ?? '',
  //         'mode': session['isPresentation'] == true ? 'Presentation' : 'Interview',
  //         'status': session['status'] ?? 'unknown',
  //         'createdAt': session['createdAt'] ?? DateTime.now().toIso8601String(),
  //         'questionsCount': (session['questionsGenerated'] as List?)?.length ?? 0,
  //         'hasFeedback': session['reportGenerated'] != null,
  //       };
  //     }).toList();
  //   } catch (e) {
  //     debugPrint('Error getting recent sessions: $e');
  //     return [];
  //   }
  // }

  // Get recent sessions — accepts optional cached snapshot to avoid duplicate reads
  Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 5, DocumentSnapshot<Map<String, dynamic>>? cachedSnapshot}) async {
    try {
      final snapshot = cachedSnapshot ?? await _firestore.collection('sessions').doc(userId).get();
      
      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.data() ?? {};
      final regularList = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      final vapiList = List<Map<String, dynamic>>.from(data['vapiInterviews'] ?? []);

      final List<Map<String, dynamic>> merged = [];
      
      // Parse regular sessions
      for (var session in regularList) {
        final date = parseSessionDate(session);
        final id = session['id'] ?? 'reg_${date.millisecondsSinceEpoch}';
        merged.add({
          ...session,
          'id': id,
          'parsedDate': date,
          'mode': session['isPresentation'] == true ? 'Presentation' : 'Interview',
          'isVapi': false,
          'status': session['status'] ?? 'unknown',
          'createdAt': session['createdAt'] ?? date.toIso8601String(),
          'questionsCount': (session['questionsGenerated'] as List?)?.length ?? 0,
          'hasFeedback': session['reportGenerated'] != null && session['reportGenerated'] != "",
        });
      }

      // Parse Vapi sessions
      for (var session in vapiList) {
        final date = parseSessionDate(session);
        final id = session['sessionId'] ?? '';
        merged.add({
          'id': id,
          'parsedDate': date,
          'mode': 'Interview', // Vapi is always interview
          'isVapi': true,
          'status': 'completed',
          'createdAt': session['completedAt'] ?? date.toIso8601String(),
          'questionsCount': 5, // typical questions count
          'hasFeedback': true,
          'overallScore': session['overallScore'] ?? 0,
        });
      }

      // Sort by date (most recent first)
      merged.sort((a, b) {
        final dateA = a['parsedDate'] as DateTime;
        final dateB = b['parsedDate'] as DateTime;
        return dateB.compareTo(dateA);
      });

      return merged.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent sessions: $e');
      return [];
    }
  }

  // Get performance trends (last 10 sessions) — loads both regular and Vapi
  Future<Map<String, dynamic>> getPerformanceTrends({DocumentSnapshot<Map<String, dynamic>>? cachedSnapshot}) async {
    try {
      final snapshot = cachedSnapshot ?? await _firestore.collection('sessions').doc(userId).get();
      
      if (!snapshot.exists) {
        return {
          'pitchTrend': [],
          'speechRateTrend': [],
          'sentimentTrend': [],
          'overallScoreTrend': [],
        };
      }

      final data = snapshot.data();
      if (data == null) {
        return {
          'pitchTrend': [],
          'speechRateTrend': [],
          'sentimentTrend': [],
          'overallScoreTrend': [],
        };
      }

      // Load both regular and Vapi sessions
      final regularList = (data['sessions'] as List?)?.map((s) {
        if (s is Map) return Map<String, dynamic>.from(s);
        return s as Map<String, dynamic>;
      }).toList() ?? [];
      final vapiList = List<Map<String, dynamic>>.from(data['vapiInterviews'] ?? []);

      final List<Map<String, dynamic>> allCompleted = [];

      // Regular completed sessions with reports
      for (var s in regularList) {
        if (s['status'] == 'completed' && s['reportGenerated'] != null && s['reportGenerated'] != "") {
          allCompleted.add({...s, 'isVapi': false});
        }
      }

      // Vapi sessions (always completed)
      for (var s in vapiList) {
        allCompleted.add({
          ...s,
          'isVapi': true,
          'createdAt': s['completedAt'],
        });
      }

      // Sort by date
      allCompleted.sort((a, b) {
        final dateA = parseSessionDate(a);
        final dateB = parseSessionDate(b);
        return dateA.compareTo(dateB);
      });

      // Take last 10 sessions
      final recentSessions = allCompleted.length > 10
          ? allCompleted.sublist(allCompleted.length - 10)
          : allCompleted;

      List<double> pitchTrend = [];
      List<double> speechRateTrend = [];
      List<double> sentimentTrend = [];
      List<double> overallScoreTrend = [];

      for (var session in recentSessions) {
        if (session['isVapi'] == true) {
          // Vapi sessions: only have overallScore, no audio metrics
          final score = (session['overallScore'] ?? 0.0).toDouble();
          if (score > 0) overallScoreTrend.add(score);
        } else {
          final reportData = session['reportGenerated'];
          if (reportData != null) {
            final report = reportData is Map
                ? Map<String, dynamic>.from(reportData)
                : reportData as Map<String, dynamic>?;

            if (report != null) {
              final pitch = (report['average_pitch'] ?? report['averagePitch'] ?? 0.0).toDouble();
              final rate = (report['speech_rate'] ?? report['averageSpeechRate'] ?? 0.0).toDouble();
              final sentiment = (report['sentiment_score'] ?? report['averageSentiment'] ?? 0.0).toDouble();
              if (pitch > 0) pitchTrend.add(pitch);
              if (rate > 0) speechRateTrend.add(rate);
              sentimentTrend.add(sentiment);
              // Normalize regular score to 0-100 scale
              final score = (report['final_interview_score'] ?? 0.0).toDouble();
              if (score > 0) overallScoreTrend.add(score * 20.0);
            }
          }
        }
      }

      return {
        'pitchTrend': pitchTrend,
        'speechRateTrend': speechRateTrend,
        'sentimentTrend': sentimentTrend,
        'overallScoreTrend': overallScoreTrend,
      };
    } catch (e) {
      debugPrint('Error getting performance trends: $e');
      return {
        'pitchTrend': [],
        'speechRateTrend': [],
        'sentimentTrend': [],
        'overallScoreTrend': [],
      };
    }
  }

  // Get achievements summary
  Future<Map<String, dynamic>> getAchievementsSummary() async {
    try {
      final progress = await _badgeService.getUserProgress();
      
      if (progress == null) {
        return {
          'recentAchievements': [],
          'nextBadge': null,
          'badgesCount': 0,
        };
      }

      // Get recent achievements (last 3)
      final recentAchievements = progress.achievements.take(3).toList();

      // Find next badge to unlock
      // This is simplified - you can add more logic to determine next badge
      String? nextBadge;
      if (!progress.achievements.contains('first_session')) {
        nextBadge = 'first_session';
      } else if (!progress.achievements.contains('streak_7') && progress.currentStreak < 7) {
        nextBadge = 'streak_7';
      } else if (!progress.achievements.contains('perfect_pitch')) {
        nextBadge = 'perfect_pitch';
      }

      return {
        'recentAchievements': recentAchievements,
        'nextBadge': nextBadge,
        'badgesCount': progress.badges.length,
        'totalAchievements': progress.achievements.length,
      };
    } catch (e) {
      debugPrint('Error getting achievements summary: $e');
      return {
        'recentAchievements': [],
        'nextBadge': null,
        'badgesCount': 0,
      };
    }
  }

  // Get learning path preview
  Future<Map<String, dynamic>> getLearningPathPreview() async {
    try {
      // This would integrate with LearningPathService
      // For now, return basic structure
      return {
        'currentMilestone': 'Basics of Communication',
        'nextMilestone': 'Advanced Presentation Skills',
        'progressPercentage': 45.0,
        'completedModules': 3,
        'totalModules': 7,
      };
    } catch (e) {
      debugPrint('Error getting learning path preview: $e');
      return {
        'currentMilestone': null,
        'nextMilestone': null,
        'progressPercentage': 0.0,
        'completedModules': 0,
        'totalModules': 0,
      };
    }
  }

  // Get community stats
  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final leaderboard = await _badgeService.getLeaderboard(limit: 100);
      
      // Find user's position
      int userPosition = -1;
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['userId'] == userId) {
          userPosition = i + 1;
          break;
        }
      }

      return {
        'leaderboardPosition': userPosition > 0 ? userPosition : null,
        'totalUsers': leaderboard.length,
      };
    } catch (e) {
      debugPrint('Error getting community stats: $e');
      return {
        'leaderboardPosition': null,
        'totalUsers': 0,
      };
    }
  }

  // Get advanced statistics
  Future<Map<String, dynamic>> getAdvancedStatistics() async {
    try {
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final snapshot = await sessionsRef.get();
      
      if (!snapshot.exists) {
        return _getEmptyAdvancedStats();
      }

      final data = snapshot.data();
      if (data == null) {
        return _getEmptyAdvancedStats();
      }

      final regularList = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      final vapiList = List<Map<String, dynamic>>.from(data['vapiInterviews'] ?? []);

      final List<Map<String, dynamic>> completedSessions = [];

      for (var s in regularList) {
        if (s['status'] == 'completed' && s['reportGenerated'] != null && s['reportGenerated'] != "") {
          completedSessions.add({
            ...s,
            'isVapi': false,
          });
        }
      }

      for (var s in vapiList) {
        completedSessions.add({
          'id': s['sessionId'] ?? '',
          'status': 'completed',
          'isPresentation': false,
          'isVapi': true,
          'completedAt': s['completedAt'],
          'createdAt': s['completedAt'],
          'questionsGenerated': List.filled(5, ''), // 5 dummy questions
          'reportGenerated': {
            'average_pitch': 0.0,
            'speech_rate': 0.0,
            'sentiment_score': 0.0,
          }
        });
      }

      if (completedSessions.isEmpty) {
        return _getEmptyAdvancedStats();
      }

      // Sort by date
      completedSessions.sort((a, b) {
        final dateA = parseSessionDate(a);
        final dateB = parseSessionDate(b);
        return dateA.compareTo(dateB);
      });

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      // Weekly/Monthly progress
      final weeklySessions = completedSessions.where((s) {
        final date = parseSessionDate(s);
        return date.isAfter(weekAgo);
      }).toList();

      final monthlySessions = completedSessions.where((s) {
        final date = parseSessionDate(s);
        return date.isAfter(monthAgo);
      }).toList();

      final previousWeekSessions = completedSessions.where((s) {
        final date = parseSessionDate(s);
        return date.isAfter(twoWeeksAgo) && date.isBefore(weekAgo);
      }).toList();

      // Calculate weekly progress
      final weeklyProgress = {
        'sessions': weeklySessions.length,
        'questions': weeklySessions.fold<int>(0, (acc, s) => acc + ((s['questionsGenerated'] as List?)?.length ?? 0)),
        'avgPitch': _calculateAverage(weeklySessions, 'averagePitch'),
        'avgSpeechRate': _calculateAverage(weeklySessions, 'averageSpeechRate'),
        'avgSentiment': _calculateAverage(weeklySessions, 'averageSentiment'),
      };

      // Calculate monthly progress
      final monthlyProgress = {
        'sessions': monthlySessions.length,
        'questions': monthlySessions.fold<int>(0, (acc, s) => acc + ((s['questionsGenerated'] as List?)?.length ?? 0)),
        'avgPitch': _calculateAverage(monthlySessions, 'averagePitch'),
        'avgSpeechRate': _calculateAverage(monthlySessions, 'averageSpeechRate'),
        'avgSentiment': _calculateAverage(monthlySessions, 'averageSentiment'),
      };

      // Accuracy trends (based on sentiment and relevance scores)
      final accuracyTrends = _calculateAccuracyTrends(completedSessions);

      // Session duration stats (estimate based on questions count)
      final sessionDurationStats = _calculateSessionDurationStats(completedSessions);

      // Improvement metrics (week-over-week)
      final improvementMetrics = _calculateImprovementMetrics(weeklySessions, previousWeekSessions);

      // Category-wise performance
      final categoryPerformance = _calculateCategoryPerformance(completedSessions);

      for (var session in completedSessions) {
        final reportData = session['reportGenerated'];
        if (reportData != null && reportData is Map) {
          session['reportGenerated'] = Map<String, dynamic>.from(reportData);
        }
      }

      return {
        'weeklyProgress': weeklyProgress,
        'monthlyProgress': monthlyProgress,
        'accuracyTrends': accuracyTrends,
        'sessionDurationStats': sessionDurationStats,
        'improvementMetrics': improvementMetrics,
        'categoryPerformance': categoryPerformance,
      };
    } catch (e) {
      debugPrint('Error getting advanced statistics: $e');
      return _getEmptyAdvancedStats();
    }
  }

  Map<String, dynamic> _getEmptyAdvancedStats() {
    return {
      'weeklyProgress': {'sessions': 0, 'questions': 0, 'avgPitch': 0.0, 'avgSpeechRate': 0.0, 'avgSentiment': 0.0},
      'monthlyProgress': {'sessions': 0, 'questions': 0, 'avgPitch': 0.0, 'avgSpeechRate': 0.0, 'avgSentiment': 0.0},
      'accuracyTrends': [],
      'sessionDurationStats': {'averageMinutes': 0.0, 'totalHours': 0.0, 'longestSession': 0.0},
      'improvementMetrics': {'sessions': 0.0, 'pitch': 0.0, 'speechRate': 0.0, 'sentiment': 0.0},
      'categoryPerformance': {'Interview': {}, 'Presentation': {}},
    };
  }

  double _calculateAverage(List<Map<String, dynamic>> sessions, String field) {
    if (sessions.isEmpty) return 0.0;
    
    double sum = 0.0;
    int count = 0;
    
    // Map field names to actual report field names
    final fieldMap = {
      'averagePitch': ['average_pitch', 'averagePitch'],
      'averageSpeechRate': ['speech_rate', 'averageSpeechRate'],
      'averageSentiment': ['sentiment_score', 'averageSentiment'],
    };
    
    final possibleFields = fieldMap[field] ?? [field];
    
    for (var session in sessions) {
      final report = session['reportGenerated'] as Map<String, dynamic>?;
      if (report != null) {
        dynamic value;
        for (var f in possibleFields) {
          value = report[f];
          if (value != null) break;
        }
        if (value != null) {
          final valDouble = (value as num).toDouble();
          // Exclude 0.0 for pitch and speech rate (which Vapi has)
          if ((field == 'averagePitch' || field == 'averageSpeechRate') && valDouble <= 0.0) {
            continue;
          }
          sum += valDouble;
          count++;
        }
      }
    }
    
    return count > 0 ? sum / count : 0.0;
  }

  List<Map<String, dynamic>> _calculateAccuracyTrends(List<Map<String, dynamic>> sessions) {
    // Group by week and calculate average accuracy (sentiment + relevance)
    final Map<String, List<double>> weeklyAccuracy = {};
    
    for (var session in sessions) {
      // Skip Vapi sessions — they have fake 0.0 sentiment which would pollute accuracy
      if (session['isVapi'] == true) continue;
      final date = parseSessionDate(session);
      if (date == DateTime(1970)) continue;
      
      final weekKey = '${date.year}-W${_getWeekNumber(date)}';
      
      final report = session['reportGenerated'] as Map<String, dynamic>?;
      if (report != null) {
        final sentiment = (report['sentiment_score'] ?? report['averageSentiment'] ?? 0.0).toDouble();
        // Normalize sentiment to 0-1 scale if needed (assuming -1 to 1 scale)
        final normalizedSentiment = sentiment > 1 ? sentiment / 100 : (sentiment + 1) / 2;
        weeklyAccuracy.putIfAbsent(weekKey, () => []).add(normalizedSentiment);
      }
    }
    
    return weeklyAccuracy.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return {
        'week': entry.key,
        'accuracy': avg,
        'sessions': entry.value.length,
      };
    }).toList()
      ..sort((a, b) => a['week'].toString().compareTo(b['week'].toString()));
  }

  int _getWeekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysSince = date.difference(firstJan).inDays;
    return ((daysSince + firstJan.weekday) / 7).ceil();
  }

  Map<String, dynamic> _calculateSessionDurationStats(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return {'averageMinutes': 0.0, 'totalHours': 0.0, 'longestSession': 0.0};
    }
    
    // Estimate: ~2 minutes per question
    final durations = sessions.map((s) {
      final questions = (s['questionsGenerated'] as List?)?.length ?? 0;
      return questions * 2.0; // minutes
    }).toList();
    
    final totalMinutes = durations.reduce((a, b) => a + b);
    final averageMinutes = totalMinutes / durations.length;
    final longestSession = durations.reduce((a, b) => a > b ? a : b);
    
    return {
      'averageMinutes': averageMinutes,
      'totalHours': totalMinutes / 60.0,
      'longestSession': longestSession,
    };
  }

  Map<String, double> _calculateImprovementMetrics(
    List<Map<String, dynamic>> currentWeek,
    List<Map<String, dynamic>> previousWeek,
  ) {
    if (previousWeek.isEmpty) {
      return {'sessions': 0.0, 'pitch': 0.0, 'speechRate': 0.0, 'sentiment': 0.0};
    }
    
    final currentAvgPitch = _calculateAverage(currentWeek, 'averagePitch');
    final previousAvgPitch = _calculateAverage(previousWeek, 'averagePitch');
    final currentAvgSpeechRate = _calculateAverage(currentWeek, 'averageSpeechRate');
    final previousAvgSpeechRate = _calculateAverage(previousWeek, 'averageSpeechRate');
    final currentAvgSentiment = _calculateAverage(currentWeek, 'averageSentiment');
    final previousAvgSentiment = _calculateAverage(previousWeek, 'averageSentiment');
    
    double calculateImprovement(double current, double previous) {
      if (previous == 0) return current > 0 ? 100.0 : 0.0;
      return ((current - previous) / previous) * 100;
    }
    
    return {
      'sessions': previousWeek.isNotEmpty ? ((currentWeek.length - previousWeek.length) / previousWeek.length) * 100 : 0.0,
      'pitch': calculateImprovement(currentAvgPitch, previousAvgPitch),
      'speechRate': calculateImprovement(currentAvgSpeechRate, previousAvgSpeechRate),
      'sentiment': calculateImprovement(currentAvgSentiment, previousAvgSentiment),
    };
  }

  Map<String, Map<String, dynamic>> _calculateCategoryPerformance(List<Map<String, dynamic>> sessions) {
    final interviewSessions = sessions.where((s) => s['isPresentation'] != true).toList();
    final presentationSessions = sessions.where((s) => s['isPresentation'] == true).toList();
    
    return {
      'Interview': {
        'count': interviewSessions.length,
        'avgPitch': _calculateAverage(interviewSessions, 'averagePitch'),
        'avgSpeechRate': _calculateAverage(interviewSessions, 'averageSpeechRate'),
        'avgSentiment': _calculateAverage(interviewSessions, 'averageSentiment'),
      },
      'Presentation': {
        'count': presentationSessions.length,
        'avgPitch': _calculateAverage(presentationSessions, 'averagePitch'),
        'avgSpeechRate': _calculateAverage(presentationSessions, 'averageSpeechRate'),
        'avgSentiment': _calculateAverage(presentationSessions, 'averageSentiment'),
      },
    };
  }
}

