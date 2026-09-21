import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:fl_chart/fl_chart.dart';

class AdvancedStatisticsSection extends StatelessWidget {
  final Map<String, dynamic> advancedStats;

  const AdvancedStatisticsSection({
    super.key,
    required this.advancedStats,
  });

  @override
  Widget build(BuildContext context) {
    // Convert LinkedMap to Map<String, dynamic> for all nested maps
    final weeklyProgressData = advancedStats['weeklyProgress'];
    final weeklyProgress = weeklyProgressData is Map 
        ? Map<String, dynamic>.from(weeklyProgressData) 
        : (weeklyProgressData as Map<String, dynamic>?) ?? {};
    
    final monthlyProgressData = advancedStats['monthlyProgress'];
    final monthlyProgress = monthlyProgressData is Map 
        ? Map<String, dynamic>.from(monthlyProgressData) 
        : (monthlyProgressData as Map<String, dynamic>?) ?? {};
    
    final accuracyTrends = advancedStats['accuracyTrends'] as List<dynamic>? ?? [];
    
    final sessionDurationStatsData = advancedStats['sessionDurationStats'];
    final sessionDurationStats = sessionDurationStatsData is Map 
        ? Map<String, dynamic>.from(sessionDurationStatsData) 
        : (sessionDurationStatsData as Map<String, dynamic>?) ?? {};
    
    final improvementMetricsData = advancedStats['improvementMetrics'];
    final improvementMetrics = improvementMetricsData is Map 
        ? Map<String, dynamic>.from(improvementMetricsData) 
        : (improvementMetricsData as Map<String, dynamic>?) ?? {};
    
    final categoryPerformanceData = advancedStats['categoryPerformance'];
    final categoryPerformance = categoryPerformanceData is Map 
        ? Map<String, dynamic>.from(categoryPerformanceData) 
        : (categoryPerformanceData as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advanced Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Weekly/Monthly Progress Cards
        _buildProgressComparison(weeklyProgress, monthlyProgress),
        const SizedBox(height: 16),
        // Accuracy Trends
        if (accuracyTrends.isNotEmpty) ...[
          _buildAccuracyTrends(accuracyTrends),
          const SizedBox(height: 16),
        ],
        // Session Duration Stats
        _buildSessionDurationStats(sessionDurationStats),
        const SizedBox(height: 16),
        // Improvement Metrics
        _buildImprovementMetrics(improvementMetrics),
        const SizedBox(height: 16),
        // Category-wise Performance
        _buildCategoryPerformance(categoryPerformance),
      ],
    );
  }

  Widget _buildProgressComparison(
    Map<String, dynamic> weekly,
    Map<String, dynamic> monthly,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Sessions', '${weekly['sessions'] ?? 0}', Icons.event_note),
                  const SizedBox(height: 8),
                  _buildStatRow('Questions', '${weekly['questions'] ?? 0}', Icons.help_outline),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 20, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Sessions', '${monthly['sessions'] ?? 0}', Icons.event_note),
                  const SizedBox(height: 8),
                  _buildStatRow('Questions', '${monthly['questions'] ?? 0}', Icons.help_outline),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyTrends(List<dynamic> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final accuracyValues = trends.map((t) => (t['accuracy'] as num?)?.toDouble() ?? 0.0).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Accuracy Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (accuracyValues.length - 1).toDouble(),
                  minY: 0,
                  maxY: 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: accuracyValues.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDurationStats(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Session Duration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDurationStat(
                  'Average',
                  '${(stats['averageMinutes'] ?? 0.0).toStringAsFixed(1)} min',
                  Icons.access_time,
                ),
                _buildDurationStat(
                  'Total',
                  '${(stats['totalHours'] ?? 0.0).toStringAsFixed(1)} hrs',
                  Icons.hourglass_empty,
                ),
                _buildDurationStat(
                  'Longest',
                  '${(stats['longestSession'] ?? 0.0).toStringAsFixed(1)} min',
                  Icons.timer_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Styles.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementMetrics(Map<String, dynamic> metrics) {
    final sessionsChange = (metrics['sessions'] ?? 0.0).toDouble();
    final pitchChange = (metrics['pitch'] ?? 0.0).toDouble();
    final speechRateChange = (metrics['speechRate'] ?? 0.0).toDouble();
    final sentimentChange = (metrics['sentiment'] ?? 0.0).toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Week-over-Week Improvement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildImprovementRow('Sessions', sessionsChange, Icons.event_note),
            const SizedBox(height: 8),
            _buildImprovementRow('Pitch', pitchChange, Icons.music_note),
            const SizedBox(height: 8),
            _buildImprovementRow('Speech Rate', speechRateChange, Icons.speed),
            const SizedBox(height: 8),
            _buildImprovementRow('Sentiment', sentimentChange, Icons.mood),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementRow(String label, double change, IconData icon) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final iconData = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Row(
          children: [
            Icon(iconData, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '${change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPerformance(Map<String, dynamic> categoryPerformance) {
    // Convert nested maps properly
    final interviewData = categoryPerformance['Interview'];
    final interview = interviewData is Map 
        ? Map<String, dynamic>.from(interviewData) 
        : (interviewData as Map<String, dynamic>?) ?? {};
    
    final presentationData = categoryPerformance['Presentation'];
    final presentation = presentationData is Map 
        ? Map<String, dynamic>.from(presentationData) 
        : (presentationData as Map<String, dynamic>?) ?? {};

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Category-wise Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard('Interview', interview, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryCard('Presentation', presentation, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, Map<String, dynamic> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sessions: ${data['count'] ?? 0}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg Pitch: ${(data['avgPitch'] ?? 0.0).toStringAsFixed(1)} Hz',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg Rate: ${(data['avgSpeechRate'] ?? 0.0).toStringAsFixed(1)} WPM',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}




