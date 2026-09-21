import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:interprep/common/resources/widgets/refresh/enhanced_refresh_indicator.dart';
import 'package:get/get.dart';

class BenchmarksScreen extends StatefulWidget {
  const BenchmarksScreen({super.key});

  @override
  State<BenchmarksScreen> createState() => _BenchmarksScreenState();
}

class _BenchmarksScreenState extends State<BenchmarksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _industryBenchmarks;
  Map<String, dynamic>? _peerComparison;
  bool _isLoading = true;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();
  }

  Future<void> _loadBenchmarks() async {
    setState(() => _isLoading = true);
    try {
      // Get user stats
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final sessionsSnapshot = await sessionsRef.get();
      final sessions = sessionsSnapshot.data()?['sessions'] ?? [];
      
      final completedSessions = sessions
          .where((s) => s['status'] == 'completed' && s['reportGenerated'] != null)
          .toList();

      if (completedSessions.isNotEmpty) {
        double totalPitch = 0;
        double totalSpeechRate = 0;
        double totalSentiment = 0;
        int count = 0;

        for (var session in completedSessions) {
          final report = session['reportGenerated'] as Map<String, dynamic>?;
          if (report != null) {
            totalPitch += (report['averagePitch'] ?? 0.0) as double;
            totalSpeechRate += (report['averageSpeechRate'] ?? 0.0) as double;
            totalSentiment += (report['averageSentiment'] ?? 0.0) as double;
            count++;
          }
        }

        _userStats = {
          'averagePitch': totalPitch / count,
          'averageSpeechRate': totalSpeechRate / count,
          'averageSentiment': totalSentiment / count,
          'totalSessions': count,
        };
      }

      // Get industry benchmarks (mock data for now)
      _industryBenchmarks = {
        'pitch': {'min': 120, 'max': 180, 'average': 150},
        'speechRate': {'min': 120, 'max': 150, 'average': 135},
        'sentiment': {'min': 0.0, 'max': 1.0, 'average': 0.3},
      };

      // Get peer comparison
      final progressSnapshot = await _firestore
          .collection('userProgress')
          .orderBy('totalXP', descending: true)
          .limit(100)
          .get();

      final allUsers = progressSnapshot.docs.map((doc) => doc.data()).toList();
      final userIndex = allUsers.indexWhere((u) => u['userId'] == userId);
      
      if (userIndex != -1) {
        final percentile = ((allUsers.length - userIndex) / allUsers.length * 100).round();
        _peerComparison = {
          'percentile': percentile,
          'totalUsers': allUsers.length,
          'userRank': userIndex + 1,
        };
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading benchmarks: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmarks & Comparison'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _userStats == null
              ? _buildEmptyState()
              : EnhancedRefreshIndicator(
                  onRefresh: _loadBenchmarks,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeerComparisonCard(),
                      const SizedBox(height: 16),
                      _buildIndustryBenchmarksCard(),
                      const SizedBox(height: 16),
                      _buildComparisonChart(),
                    ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonLoader(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        SkeletonLoader(width: double.infinity, height: 300, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        SkeletonLoader(width: double.infinity, height: 250, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.compare_arrows,
      title: 'No comparison data available',
      message: 'Complete practice sessions to see how you compare with industry benchmarks and peers',
      actionLabel: 'Start Practice',
      onAction: () => Get.toNamed('/mode_type'),
    );
  }

  Widget _buildPeerComparisonCard() {
    if (_peerComparison == null) return const SizedBox.shrink();

    final percentile = _peerComparison!['percentile'] as int;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Performance Ranking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$percentile',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getPercentileColor(percentile),
                        ),
                      ),
                      const Text(
                        'Percentile',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rank #${_peerComparison!['userRank']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'out of ${_peerComparison!['totalUsers']} users',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentile / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPercentileColor(percentile),
              ),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustryBenchmarksCard() {
    if (_industryBenchmarks == null || _userStats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Industry Benchmarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenchmarkItem(
              'Pitch',
              _userStats!['averagePitch'] as double,
              _industryBenchmarks!['pitch'] as Map<String, dynamic>,
              'Hz',
            ),
            const SizedBox(height: 12),
            _buildBenchmarkItem(
              'Speech Rate',
              _userStats!['averageSpeechRate'] as double,
              _industryBenchmarks!['speechRate'] as Map<String, dynamic>,
              'WPM',
            ),
            const SizedBox(height: 12),
            _buildBenchmarkItem(
              'Sentiment',
              _userStats!['averageSentiment'] as double,
              _industryBenchmarks!['sentiment'] as Map<String, dynamic>,
              '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkItem(
    String label,
    double userValue,
    Map<String, dynamic> benchmark,
    String unit,
  ) {
    final benchmarkAvg = (benchmark['average'] as num).toDouble();
    final benchmarkMin = (benchmark['min'] as num).toDouble();
    final benchmarkMax = (benchmark['max'] as num).toDouble();
    
    final isInRange = userValue >= benchmarkMin && userValue <= benchmarkMax;
    final difference = userValue - benchmarkAvg;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  '${userValue.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isInRange ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isInRange ? Icons.check_circle : Icons.warning,
                  color: isInRange ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Industry avg: ${benchmarkAvg.toStringAsFixed(1)}$unit '
          '(${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)})',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (userValue - benchmarkMin) / (benchmarkMax - benchmarkMin),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isInRange ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonChart() {
    if (_userStats == null || _industryBenchmarks == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Pitch');
                            case 1:
                              return const Text('Speech\nRate');
                            case 2:
                              return const Text('Sentiment');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _userStats!['averagePitch'] as double,
                          color: Styles.primaryColor,
                          width: 20,
                        ),
                        BarChartRodData(
                          toY: (_industryBenchmarks!['pitch'] as Map)['average'] as double,
                          color: Colors.grey,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _userStats!['averageSpeechRate'] as double,
                          color: Styles.primaryColor,
                          width: 20,
                        ),
                        BarChartRodData(
                          toY: (_industryBenchmarks!['speechRate'] as Map)['average'] as double,
                          color: Colors.grey,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: ((_userStats!['averageSentiment'] as double) + 1) * 100,
                          color: Styles.primaryColor,
                          width: 20,
                        ),
                        BarChartRodData(
                          toY: (((_industryBenchmarks!['sentiment'] as Map<String, dynamic>)['average'] as double) + 1) * 100,
                          color: Colors.grey,
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem('You', Styles.primaryColor),
                const SizedBox(width: 16),
                _buildLegendItem('Industry Avg', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getPercentileColor(int percentile) {
    if (percentile >= 80) return Colors.green;
    if (percentile >= 60) return Colors.blue;
    if (percentile >= 40) return Colors.orange;
    return Colors.red;
  }
}

