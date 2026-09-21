import 'package:flutter/material.dart';
import 'package:interprep/services/badge_service.dart';
import 'package:interprep/models/user_progress.dart' as models;
import 'package:interprep/widgets/achievement_card.dart';

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  final BadgeService _badgeService = BadgeService();
  models.UserProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _badgeService.getUserProgress();
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_progress == null) {
      return const Center(child: Text('No achievements data available'));
    }

    final allBadges = models.BadgeDefinitions.allBadges;
    final unlockedBadges = _progress!.achievements.toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Achievements (${unlockedBadges.length}/${allBadges.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isUnlocked = unlockedBadges.contains(badge.id);
              final progress = _progress!.badges[badge.id];

              return AchievementCard(
                badge: badge,
                isUnlocked: isUnlocked,
                progress: progress,
              );
            },
          ),
        ],
      ),
    );
  }
}




