import 'package:flutter/material.dart';
import 'package:interprep/models/user_progress.dart' as models;
import 'package:interprep/widgets/achievement_card.dart';

class AchievementsGallery extends StatelessWidget {
  final Map<String, int> userBadges;
  final List<String> userAchievements;

  const AchievementsGallery({
    super.key,
    required this.userBadges,
    required this.userAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final allBadges = models.BadgeDefinitions.allBadges;
    final unlockedBadges = userAchievements.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showAllAchievements(context),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', true, () {}),
              const SizedBox(width: 8),
              _buildFilterChip('Unlocked', false, () {}),
              const SizedBox(width: 8),
              _buildFilterChip('Locked', false, () {}),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Achievements Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: allBadges.length > 6 ? 6 : allBadges.length,
          itemBuilder: (context, index) {
            final badge = allBadges[index];
            final isUnlocked = unlockedBadges.contains(badge.id);
            final progress = userBadges[badge.id];

            return AchievementCard(
              badge: badge,
              isUnlocked: isUnlocked,
              progress: progress,
              onTap: () => _showAchievementDetails(context, badge, isUnlocked, progress),
            );
          },
        ),
        if (allBadges.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton(
                onPressed: () => _showAllAchievements(context),
                child: Text('View ${allBadges.length - 6} more achievements'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onTap(),
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      checkmarkColor: Colors.blue,
    );
  }

  void _showAchievementDetails(
    BuildContext context,
    models.Badge badge,
    bool isUnlocked,
    int? progress,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (progress != null) ...[
              Text(
                'Progress: $progress/5',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 5.0,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'XP Reward: ${badge.xpReward}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllAchievements(BuildContext context) {
    // Navigate to full achievements page or show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Achievements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: models.BadgeDefinitions.allBadges.length,
                itemBuilder: (context, index) {
                  final badge = models.BadgeDefinitions.allBadges[index];
                  final isUnlocked = userAchievements.contains(badge.id);
                  final progress = userBadges[badge.id];

                  return AchievementCard(
                    badge: badge,
                    isUnlocked: isUnlocked,
                    progress: progress,
                    onTap: () => _showAchievementDetails(context, badge, isUnlocked, progress),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

