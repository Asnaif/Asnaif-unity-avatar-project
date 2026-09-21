import 'package:flutter/material.dart';
import 'package:interprep/models/goal.dart';
import 'package:interprep/common/constants/styles.dart';

class GoalProgressCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.isCompleted;
    final daysRemaining = goal.deadline.difference(DateTime.now()).inDays;

    return Card(
      elevation: isCompleted ? 3 : 2,
      color: isCompleted ? Colors.green.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24)
                  else
                    Icon(
                      _getGoalTypeIcon(goal.type),
                      size: 20,
                      color: Styles.primaryColor,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              // Progress Bar
              LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Styles.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.current} / ${goal.target}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Styles.primaryColor,
                    ),
                  ),
                  if (!isCompleted)
                    Text(
                      daysRemaining > 0
                          ? '$daysRemaining days left'
                          : 'Overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysRemaining > 0 ? Colors.grey[600] : Colors.red,
                      ),
                    )
                  else
                    Text(
                      'Completed!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.daily:
        return Icons.today;
      case GoalType.weekly:
        return Icons.date_range;
      case GoalType.monthly:
        return Icons.calendar_month;
      case GoalType.custom:
        return Icons.flag;
    }
  }
}




