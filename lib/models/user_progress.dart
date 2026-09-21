import 'dart:math' as math;

class UserProgress {
  final String userId;
  final int totalXP;
  final int currentLevel;
  final int currentStreak;
  final DateTime? lastSessionDate;
  final Map<String, int> badges;
  final List<String> achievements;
  final int totalSessions;
  final int totalQuestionsAnswered;
  final double averagePitch;
  final double averageSpeechRate;
  final double averageSentiment;

  UserProgress({
    required this.userId,
    this.totalXP = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.lastSessionDate,
    Map<String, int>? badges,
    List<String>? achievements,
    this.totalSessions = 0,
    this.totalQuestionsAnswered = 0,
    this.averagePitch = 0.0,
    this.averageSpeechRate = 0.0,
    this.averageSentiment = 0.0,
  })  : badges = badges ?? {},
        achievements = achievements ?? [];

  // Calculate level from XP
  static int calculateLevel(int xp) {
    // Level formula: level = sqrt(xp / 100)
    return math.sqrt(xp / 100).floor() + 1;
  }

  // XP needed for next level
  int get xpForNextLevel {
    int nextLevel = currentLevel + 1;
    return (nextLevel - 1) * (nextLevel - 1) * 100;
  }

  // XP progress to next level
  int get xpProgress {
    int currentLevelXP = (currentLevel - 1) * (currentLevel - 1) * 100;
    return totalXP - currentLevelXP;
  }

  // Progress percentage to next level
  double get levelProgress {
    if (xpForNextLevel == 0) return 1.0;
    int currentLevelXP = (currentLevel - 1) * (currentLevel - 1) * 100;
    int xpNeeded = xpForNextLevel - currentLevelXP;
    return (xpProgress / xpNeeded).clamp(0.0, 1.0);
  }

  // Factory method from Firestore
  factory UserProgress.fromFirestore(Map<String, dynamic> data, String userId) {
    return UserProgress(
      userId: userId,
      totalXP: data['totalXP'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      currentStreak: data['currentStreak'] ?? 0,
      lastSessionDate: data['lastSessionDate']?.toDate(),
      badges: Map<String, int>.from(data['badges'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
      totalSessions: data['totalSessions'] ?? 0,
      totalQuestionsAnswered: data['totalQuestionsAnswered'] ?? 0,
      averagePitch: (data['averagePitch'] ?? 0.0).toDouble(),
      averageSpeechRate: (data['averageSpeechRate'] ?? 0.0).toDouble(),
      averageSentiment: (data['averageSentiment'] ?? 0.0).toDouble(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'currentStreak': currentStreak,
      'lastSessionDate': lastSessionDate,
      'badges': badges,
      'achievements': achievements,
      'totalSessions': totalSessions,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'averagePitch': averagePitch,
      'averageSpeechRate': averageSpeechRate,
      'averageSentiment': averageSentiment,
    };
  }

  UserProgress copyWith({
    String? userId,
    int? totalXP,
    int? currentLevel,
    int? currentStreak,
    DateTime? lastSessionDate,
    Map<String, int>? badges,
    List<String>? achievements,
    int? totalSessions,
    int? totalQuestionsAnswered,
    double? averagePitch,
    double? averageSpeechRate,
    double? averageSentiment,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      totalSessions: totalSessions ?? this.totalSessions,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      averagePitch: averagePitch ?? this.averagePitch,
      averageSpeechRate: averageSpeechRate ?? this.averageSpeechRate,
      averageSentiment: averageSentiment ?? this.averageSentiment,
    );
  }
}

// Badge definitions
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.xpReward = 50,
  });
}

class BadgeDefinitions {
  static const List<Badge> allBadges = [
    Badge(
      id: 'first_session',
      name: 'First Steps',
      description: 'Complete your first practice session',
      icon: '🎯',
      xpReward: 100,
    ),
    Badge(
      id: 'perfect_pitch',
      name: 'Perfect Pitch',
      description: 'Maintain optimal pitch in 5 sessions',
      icon: '🎵',
      xpReward: 200,
    ),
    Badge(
      id: 'fast_talker',
      name: 'Fast Talker',
      description: 'Achieve 150+ WPM speech rate',
      icon: '⚡',
      xpReward: 150,
    ),
    Badge(
      id: 'vocab_master',
      name: 'Vocabulary Master',
      description: 'Use advanced vocabulary in 10 sessions',
      icon: '📚',
      xpReward: 250,
    ),
    Badge(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Practice for 7 days straight',
      icon: '🔥',
      xpReward: 300,
    ),
    Badge(
      id: 'streak_30',
      name: 'Monthly Master',
      description: 'Practice for 30 days straight',
      icon: '💪',
      xpReward: 1000,
    ),
    Badge(
      id: 'century',
      name: 'Century Club',
      description: 'Complete 100 practice sessions',
      icon: '💯',
      xpReward: 500,
    ),
    Badge(
      id: 'positive_vibes',
      name: 'Positive Vibes',
      description: 'Maintain positive sentiment in 5 sessions',
      icon: '😊',
      xpReward: 150,
    ),
  ];

  static Badge? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }
}

