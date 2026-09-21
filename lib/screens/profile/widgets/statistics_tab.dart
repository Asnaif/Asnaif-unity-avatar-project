import 'package:flutter/material.dart';
import 'package:interprep/services/badge_service.dart';
import 'package:interprep/services/dashboard_service.dart';
import 'package:interprep/models/user_progress.dart' as models;

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final BadgeService _badgeService = BadgeService();
  final DashboardService _dashboardService = DashboardService();
  models.UserProgress? _progress;
  Map<String, dynamic>? _advancedStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dashboardData = await _dashboardService.getUserDashboardData();
      setState(() {
        _progress = dashboardData['progress'] as models.UserProgress?;
        _advancedStats = dashboardData['advancedStats'];
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
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Lifetime Statistics', [
            _buildStatCard('Total Sessions', '${_progress!.totalSessions}', Icons.event_note),
            _buildStatCard('Questions Answered', '${_progress!.totalQuestionsAnswered}', Icons.help_outline),
            _buildStatCard('Total XP', '${_progress!.totalXP}', Icons.workspace_premium),
            _buildStatCard('Current Level', '${_progress!.currentLevel}', Icons.star),
          ]),
          const SizedBox(height: 24),
          _buildSection('Best Performances', [
            _buildStatCard('Longest Streak', '${_progress!.currentStreak} days', Icons.local_fire_department),
            _buildStatCard('Average Pitch', '${_progress!.averagePitch.toStringAsFixed(1)} Hz', Icons.music_note),
            _buildStatCard('Speech Rate', '${_progress!.averageSpeechRate.toStringAsFixed(1)} WPM', Icons.speed),
          ]),
          if (_advancedStats != null) ...[
            const SizedBox(height: 24),
            _buildSection('Session Duration', [
              _buildStatCard(
                'Total Hours',
                '${((_advancedStats!['sessionDurationStats']?['totalHours'] ?? 0.0) as num).toStringAsFixed(1)} hrs',
                Icons.timer,
              ),
              _buildStatCard(
                'Avg Session',
                '${((_advancedStats!['sessionDurationStats']?['averageMinutes'] ?? 0.0) as num).toStringAsFixed(1)} min',
                Icons.access_time,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: children,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}




