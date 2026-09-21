import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interprep/models/goal.dart';
import 'package:interprep/services/goals_service.dart';
import 'package:interprep/widgets/goal_progress_card.dart';

class GoalsSection extends StatefulWidget {
  const GoalsSection({super.key});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  final GoalsService _goalsService = GoalsService();
  List<Goal> _activeGoals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalsService.getActiveGoals();
      setState(() {
        _activeGoals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Goals & Targets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showCreateGoalDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Goal'),
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/goals'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_activeGoals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No active goals',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateGoalDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Goal'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._activeGoals.take(3).map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GoalProgressCard(
                  goal: goal,
                  onTap: () => _showGoalDetails(context, goal),
                ),
              )),
        if (_activeGoals.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () => Get.toNamed('/goals'),
                child: Text('View ${_activeGoals.length - 3} more goals'),
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Goal'),
        content: const Text('Goal creation feature will be available in the Goals page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed('/goals');
            },
            child: const Text('Go to Goals Page'),
          ),
        ],
      ),
    );
  }

  void _showGoalDetails(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 16),
            Text('Type: ${goal.type.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Progress: ${goal.current} / ${goal.target}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text('Deadline: ${_formatDate(goal.deadline)}'),
            if (goal.isCompleted && goal.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Completed: ${_formatDate(goal.completedAt!)}',
                  style: TextStyle(color: Colors.green[700]),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}




