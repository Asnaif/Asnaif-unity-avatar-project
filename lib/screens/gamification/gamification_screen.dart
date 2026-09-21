import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/models/user_progress.dart';
import 'package:interprep/services/badge_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final BadgeService _badgeService = BadgeService();
  UserProgress? _userProgress;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String _selectedTab = 'progress'; // 'progress', 'badges', 'leaderboard'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _badgeService.getUserProgress();
      final leaderboard = await _badgeService.getLeaderboard(limit: 20);
      
      setState(() {
        _userProgress = progress;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: _selectedTab == 'progress'
                      ? _buildProgressTab()
                      : _selectedTab == 'badges'
                          ? _buildBadgesTab()
                          : _buildLeaderboardTab(),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildTab('progress', 'Progress', Icons.trending_up),
          _buildTab('badges', 'Badges', Icons.emoji_events),
          _buildTab('leaderboard', 'Leaderboard', Icons.leaderboard),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final isSelected = _selectedTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Styles.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    if (_userProgress == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No progress yet',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a practice session to start earning XP!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${_userProgress!.currentLevel}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_userProgress!.totalXP} XP',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Styles.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star,
                          size: 48,
                          color: Styles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP to Level ${_userProgress!.currentLevel + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_userProgress!.xpProgress}/${_userProgress!.xpForNextLevel - ((_userProgress!.currentLevel - 1) * (_userProgress!.currentLevel - 1) * 100)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _userProgress!.levelProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Styles.primaryColor,
                        ),
                        minHeight: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions',
                  '${_userProgress!.totalSessions}',
                  Icons.event_note,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Questions',
                  '${_userProgress!.totalQuestionsAnswered}',
                  Icons.help_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Streak',
                  '${_userProgress!.currentStreak} days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Badges',
                  '${_userProgress!.badges.length}',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recent Achievements
          if (_userProgress!.achievements.isNotEmpty) ...[
            const Text(
              'Recent Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._userProgress!.achievements.take(5).map((achievementId) {
              final badge = BadgeDefinitions.getBadgeById(achievementId);
              if (badge == null) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(badge.icon, style: const TextStyle(fontSize: 32)),
                  title: Text(badge.name),
                  subtitle: Text(badge.description),
                  trailing: Text(
                    '+${badge.xpReward} XP',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesTab() {
    final userBadges = _userProgress?.badges ?? {};
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: BadgeDefinitions.allBadges.length,
      itemBuilder: (context, index) {
        final badge = BadgeDefinitions.allBadges[index];
        final isUnlocked = userBadges.containsKey(badge.id);
        
        return Card(
          elevation: isUnlocked ? 4 : 1,
          color: isUnlocked ? null : Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 48,
                    color: isUnlocked ? null : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? null : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text('No leaderboard data available'),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        final isCurrentUser = entry['userId'] == currentUserId;
        final rank = index + 1;
        
        return Card(
          color: isCurrentUser ? Styles.primaryColor.withOpacity(0.1) : null,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              isCurrentUser ? 'You' : 'User ${entry['userId'].substring(0, 8)}',
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              'Level ${entry['currentLevel']} • ${entry['totalSessions']} sessions',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry['totalXP']} XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rank <= 3)
                  Text(
                    _getRankEmoji(rank),
                    style: const TextStyle(fontSize: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    return Styles.primaryColor;
  }

  String _getRankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '';
  }
}

