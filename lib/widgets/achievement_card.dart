import 'package:flutter/material.dart';
import 'package:interprep/models/user_progress.dart' as models;

class AchievementCard extends StatelessWidget {
  final models.Badge badge;
  final bool isUnlocked;
  final int? progress; // Progress count for badges that require multiple completions
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.badge,
    this.isUnlocked = false,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isUnlocked ? 4 : 1,
      color: isUnlocked ? null : Colors.grey[200],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: isUnlocked ? 32 : 24,
                      color: isUnlocked ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Badge Name
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black87 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Progress Indicator (if not unlocked and has progress)
              if (!isUnlocked && progress != null) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress! / 5.0, // Assuming max progress is 5
                  minHeight: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 2),
                Text(
                  '$progress/5',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ] else if (isUnlocked) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

