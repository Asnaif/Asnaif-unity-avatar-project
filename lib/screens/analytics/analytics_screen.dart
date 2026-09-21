import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:interprep/common/resources/widgets/refresh/enhanced_refresh_indicator.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _sessionHistory = [];
  bool _isLoading = true;
  Map<String, dynamic>? _insights;

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
    _loadAnalytics();
  }

  DateTime _parseSessionDate(Map<String, dynamic> session) {
    if (session['createdAt'] != null && session['createdAt'].toString().isNotEmpty) {
      final parsed = DateTime.tryParse(session['createdAt'].toString());
      if (parsed != null) return parsed;
    }
    if (session['completedAt'] != null && session['completedAt'].toString().isNotEmpty) {
      final parsed = DateTime.tryParse(session['completedAt'].toString());
      if (parsed != null) return parsed;
    }
    // Fallback: search responses for recorded_at
    if (session['responses'] is Map) {
      final responses = session['responses'] as Map;
      for (var key in responses.keys) {
        final resp = responses[key];
        if (resp is Map && resp['recorded_at'] != null) {
          final parsed = DateTime.tryParse(resp['recorded_at'].toString());
          if (parsed != null) return parsed;
        }
      }
    }
    return DateTime(1970);
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final snapshot = await sessionsRef.get();
      
      final List<Map<String, dynamic>> parsedList = [];
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
        final vapiSessionsList = List<Map<String, dynamic>>.from(data['vapiInterviews'] ?? []);
        
        // Filter and map completed regular sessions
        for (var session in sessions) {
          if (session['status'] == 'completed' && session['reportGenerated'] != null && session['reportGenerated'] != "") {
            final report = session['reportGenerated'] as Map<String, dynamic>?;
            final date = _parseSessionDate(session);
            final finalScore = (report?['final_interview_score'] ?? 0.0).toDouble();
            
            parsedList.add({
              'date': session['createdAt'] ?? date.toIso8601String(),
              'parsedDate': date,
              'pitch': (report?['average_pitch'] ?? report?['averagePitch'] ?? 0.0).toDouble(),
              'speechRate': (report?['speech_rate'] ?? report?['averageSpeechRate'] ?? 0.0).toDouble(),
              'sentiment': (report?['sentiment_score'] ?? report?['averageSentiment'] ?? 0.0).toDouble(),
              'vocabLevel': (report?['grade_level'] ?? report?['averageVocabLevel'] ?? 0.0).toDouble(),
              'relevance': (report?['relevance_score'] ?? report?['averageRelevance'] ?? 0.0).toDouble(),
              'score': finalScore > 0.0 ? finalScore * 20.0 : 0.0,
              'isVapi': false,
            });
          }
        }
        
        // Map Vapi sessions
        for (var session in vapiSessionsList) {
          final date = _parseSessionDate(session);
          parsedList.add({
            'date': session['completedAt'] ?? date.toIso8601String(),
            'parsedDate': date,
            'pitch': 0.0,
            'speechRate': 0.0,
            'sentiment': 0.0,
            'vocabLevel': 0.0,
            'relevance': 0.0,
            'score': (session['overallScore'] ?? 0.0).toDouble(),
            'isVapi': true,
          });
        }
        
        // Sort by date
        parsedList.sort((a, b) {
          final dateA = a['parsedDate'] as DateTime;
          final dateB = b['parsedDate'] as DateTime;
          return dateA.compareTo(dateB);
        });
        
        _sessionHistory = parsedList;
        // Generate insights
        _insights = _generateInsights(_sessionHistory);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _generateInsights(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return {
        'strengths': [],
        'weaknesses': [],
        'trends': [],
        'averagePitch': 0.0,
        'averageSpeechRate': 0.0,
        'averageSentiment': 0.0,
      };
    }

    // Calculate averages (filtering out Vapi zero metrics)
    final pitchList = history.map((h) => (h['pitch'] ?? 0.0) as double).where((p) => p > 0.0).toList();
    final avgPitch = pitchList.isNotEmpty ? pitchList.reduce((a, b) => a + b) / pitchList.length : 0.0;

    final speechRateList = history.map((h) => (h['speechRate'] ?? 0.0) as double).where((r) => r > 0.0).toList();
    final avgSpeechRate = speechRateList.isNotEmpty ? speechRateList.reduce((a, b) => a + b) / speechRateList.length : 0.0;

    final sentimentList = history.where((h) => h['isVapi'] != true).map((h) => (h['sentiment'] ?? 0.0) as double).toList();
    final avgSentiment = sentimentList.isNotEmpty ? sentimentList.reduce((a, b) => a + b) / sentimentList.length : 0.0;

    // Calculate trends (using regular session history)
    final regularHistory = history.where((h) => h['isVapi'] != true).toList();
    final recentSessions = regularHistory.length > 3 ? regularHistory.sublist(regularHistory.length - 3) : regularHistory;
    final olderSessions = regularHistory.length > 3 ? regularHistory.sublist(0, regularHistory.length - 3) : [];
    
    List<String> strengths = [];
    List<String> weaknesses = [];
    List<String> trends = [];

    if (pitchList.isNotEmpty) {
      // Pitch analysis
      if (avgPitch >= 120 && avgPitch <= 180) {
        strengths.add('Your pitch is in the optimal range');
      } else if (avgPitch < 120 && avgPitch > 0) {
        weaknesses.add('Your pitch is too low - try to speak with more energy');
      } else if (avgPitch > 180) {
        weaknesses.add('Your pitch is too high - try to speak more calmly');
      }
    }

    if (speechRateList.isNotEmpty) {
      // Speech rate analysis
      if (avgSpeechRate >= 120 && avgSpeechRate <= 150) {
        strengths.add('Your speech rate is ideal for professional communication');
      } else if (avgSpeechRate < 120 && avgSpeechRate > 0) {
        weaknesses.add('You speak too slowly - practice speaking faster');
      } else if (avgSpeechRate > 150) {
        weaknesses.add('You speak too fast - slow down for better clarity');
      }
    }

    if (sentimentList.isNotEmpty) {
      // Sentiment analysis
      if (avgSentiment > 0.3) {
        strengths.add('You maintain a positive and confident tone');
      } else if (avgSentiment < -0.3) {
        weaknesses.add('Your tone is too negative - try to be more positive');
      }
    }

    // Trend analysis
    if (olderSessions.isNotEmpty && recentSessions.isNotEmpty) {
      final recentPitches = recentSessions.map((h) => (h['pitch'] ?? 0.0) as double).where((p) => p > 0).toList();
      final olderPitches = olderSessions.map((h) => (h['pitch'] ?? 0.0) as double).where((p) => p > 0).toList();
      if (recentPitches.isNotEmpty && olderPitches.isNotEmpty) {
        final recentAvgPitch = recentPitches.reduce((a, b) => a + b) / recentPitches.length;
        final olderAvgPitch = olderPitches.reduce((a, b) => a + b) / olderPitches.length;
        if (recentAvgPitch > olderAvgPitch + 5) {
          trends.add('Your pitch has improved significantly');
        } else if (recentAvgPitch < olderAvgPitch - 5) {
          trends.add('Your pitch has decreased - focus on maintaining energy');
        }
      }

      final recentRates = recentSessions.map((h) => (h['speechRate'] ?? 0.0) as double).where((r) => r > 0).toList();
      final olderRates = olderSessions.map((h) => (h['speechRate'] ?? 0.0) as double).where((r) => r > 0).toList();
      if (recentRates.isNotEmpty && olderRates.isNotEmpty) {
        final recentAvgSpeechRate = recentRates.reduce((a, b) => a + b) / recentRates.length;
        final olderAvgSpeechRate = olderRates.reduce((a, b) => a + b) / olderRates.length;
        if (recentAvgSpeechRate > olderAvgSpeechRate + 10) {
          trends.add('Your speech rate has improved');
        } else if (recentAvgSpeechRate < olderAvgSpeechRate - 10) {
          trends.add('Your speech rate has slowed down');
        }
      }
    }

    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
      'trends': trends,
      'averagePitch': avgPitch,
      'averageSpeechRate': avgSpeechRate,
      'averageSentiment': avgSentiment,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToPDF,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _sessionHistory.isEmpty
              ? _buildEmptyState()
              : EnhancedRefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightsCard(),
                      const SizedBox(height: 16),
                      _buildOverallScoreChart(),
                      const SizedBox(height: 16),
                      _buildPitchChart(),
                      const SizedBox(height: 16),
                      _buildSpeechRateChart(),
                      const SizedBox(height: 16),
                      _buildSentimentChart(),
                      const SizedBox(height: 16),
                      _buildMetricsSummary(),
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
        SkeletonLoader(width: double.infinity, height: 250, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        SkeletonLoader(width: double.infinity, height: 250, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        SkeletonLoader(width: double.infinity, height: 250, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.analytics_outlined,
      title: 'No analytics data yet',
      message: 'Complete practice sessions to see your progress and detailed analytics here',
      actionLabel: 'Start Practice',
      onAction: () => Get.toNamed('/mode_type'),
    );
  }

  Widget _buildInsightsCard() {
    if (_insights == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Powered Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_insights!['strengths'].isNotEmpty) ...[
              _buildInsightSection('Strengths', _insights!['strengths'], Colors.green),
              const SizedBox(height: 12),
            ],
            if (_insights!['weaknesses'].isNotEmpty) ...[
              _buildInsightSection('Areas for Improvement', _insights!['weaknesses'], Colors.orange),
              const SizedBox(height: 12),
            ],
            if (_insights!['trends'].isNotEmpty)
              _buildInsightSection('Trends', _insights!['trends'], Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildOverallScoreChart() {
    final filtered = _sessionHistory
        .where((s) => (s['score'] ?? 0.0) > 0.0)
        .toList();

    if (filtered.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Overall Performance Score Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'No scores available yet. Complete a session to see your progress!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final spots = filtered
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), (entry.value['score'] as num).toDouble()))
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Performance Score Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= filtered.length) return const Text('');
                          return Text(
                            'S${idx + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 1,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchChart() {
    final filtered = _sessionHistory
        .where((s) => (s['pitch'] ?? 0.0) > 0.0)
        .toList();

    if (filtered.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pitch Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'No pitch data available yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final spots = filtered
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), (entry.value['pitch'] as num).toDouble()))
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pitch Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= filtered.length) return const Text('');
                          return Text(
                            'S${idx + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 1,
                      color: Styles.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: () {
                    final pitches = filtered.map((h) => (h['pitch'] ?? 0.0) as double).where((p) => p > 0).toList();
                    if (pitches.isEmpty) return 250.0;
                    return pitches.reduce((a, b) => a > b ? a : b) + 50.0;
                  }(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechRateChart() {
    final filtered = _sessionHistory
        .where((s) => (s['speechRate'] ?? 0.0) > 0.0)
        .toList();

    if (filtered.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Speech Rate Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'No speech rate data available yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final spots = filtered
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), (entry.value['speechRate'] as num).toDouble()))
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speech Rate Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= filtered.length) return const Text('');
                          return Text(
                            'S${idx + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 1,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: () {
                    final rates = filtered.map((h) => (h['speechRate'] ?? 0.0) as double).where((r) => r > 0).toList();
                    if (rates.isEmpty) return 200.0;
                    return rates.reduce((a, b) => a > b ? a : b) + 50.0;
                  }(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentChart() {
    final filtered = _sessionHistory
        .where((s) => s['isVapi'] != true)
        .toList();

    if (filtered.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Sentiment Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: Text(
                  'No sentiment data available yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final spots = filtered
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), (entry.value['sentiment'] as num).toDouble()))
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sentiment Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= filtered.length) return const Text('');
                          return Text(
                            'S${idx + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 1,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: -1,
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSummary() {
    if (_insights == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Pitch',
                    '${_insights!['averagePitch'].toStringAsFixed(1)} Hz',
                    Icons.music_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Speech Rate',
                    '${_insights!['averageSpeechRate'].toStringAsFixed(1)} WPM',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Sentiment',
                    _insights!['averageSentiment'] > 0.3
                        ? 'Positive'
                        : _insights!['averageSentiment'] < -0.3
                            ? 'Negative'
                            : 'Neutral',
                    Icons.mood,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Sessions',
                    '${_sessionHistory.length}',
                    Icons.event_note,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'InterPrep Analytics Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              if (_insights != null) ...[
                pw.Text(
                  'Average Metrics',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Average Pitch: ${_insights!['averagePitch'].toStringAsFixed(1)} Hz'),
                pw.Text('Average Speech Rate: ${_insights!['averageSpeechRate'].toStringAsFixed(1)} WPM'),
                pw.Text('Average Sentiment: ${_insights!['averageSentiment'].toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                if (_insights!['strengths'].isNotEmpty) ...[
                  pw.Text(
                    'Strengths',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  ..._insights!['strengths'].map((s) => pw.Text('• $s')),
                  pw.SizedBox(height: 10),
                ],
                if (_insights!['weaknesses'].isNotEmpty) ...[
                  pw.Text(
                    'Areas for Improvement',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  ..._insights!['weaknesses'].map((w) => pw.Text('• $w')),
                ],
              ],
            ];
          },
        ),
      );

      // Save PDF (for web, this would need different handling)
      if (!kIsWeb) {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/analytics_report.pdf');
        await file.writeAsBytes(await pdf.save());
        
        if (mounted) {
          CustomToast.showSuccess('Report saved to ${file.path}');
        }
      } else {
        // For web, download directly
        await pdf.save();
        // Note: Web download would need additional implementation
        if (mounted) {
          CustomToast.showWarning('PDF export not yet available on web');
        }
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (mounted) {
        CustomToast.showError('Error exporting: $e');
      }
    }
  }
}

