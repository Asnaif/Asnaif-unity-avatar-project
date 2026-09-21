import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interprep/services/goals_service.dart';
import 'package:interprep/widgets/goal_progress_card.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  final GoalsService _goalsService = GoalsService();
  List<dynamic> _activeGoals = [];
  List<dynamic> _completedGoals = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final active = await _goalsService.getActiveGoals();
      final completed = await _goalsService.getCompletedGoals();
      setState(() {
        _activeGoals = active;
        _completedGoals = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DefaultTabBar(
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedIndex == 0
                  ? _buildActiveGoals()
                  : _buildCompletedGoals(),
        ),
      ],
    );
  }

  Widget _buildActiveGoals() {
    if (_activeGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No active goals', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/goals'),
              icon: const Icon(Icons.add),
              label: const Text('Create Goal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeGoals.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GoalProgressCard(goal: _activeGoals[index]),
        );
      },
    );
  }

  Widget _buildCompletedGoals() {
    if (_completedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No completed goals', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedGoals.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GoalProgressCard(goal: _completedGoals[index]),
        );
      },
    );
  }
}

// Simple TabBar widget
class DefaultTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final Function(int) onTap;
  final int selectedIndex;

  const DefaultTabBar({
    super.key,
    required this.tabs,
    required this.onTap,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab.text ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}




