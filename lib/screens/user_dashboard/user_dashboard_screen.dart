import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/dashboard_service.dart';
import 'package:interprep/models/user_progress.dart' as models;
import 'package:interprep/widgets/advanced_statistics_section.dart';
import 'package:interprep/widgets/achievements_gallery.dart';
import 'package:interprep/widgets/goals_section.dart';
import 'package:interprep/widgets/enhanced_session_history.dart';
import 'package:interprep/widgets/notification_bell.dart';
import 'package:interprep/widgets/notifications_center.dart';
import 'package:interprep/services/export_service.dart';
import 'package:flutter/services.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/refresh/enhanced_refresh_indicator.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/common/resources/widgets/fab/speed_dial_fab.dart';
import 'package:interprep/common/resources/widgets/swipeable/swipeable_card.dart';
import 'package:interprep/services/notification_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cross_file/cross_file.dart';

// Conditional import for web download
import 'package:interprep/utils/web_download_helper_stub.dart'
    if (dart.library.html) 'package:interprep/utils/web_download_helper.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _dashboardData;
  models.UserProgress? _progress;
  String _userName = '';
  bool _isLoading = true;

  // Helper method to convert LinkedMap to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUserName();
    Future.delayed(const Duration(seconds: 2), () {
      _checkAndSendReminders();
    });
  }

  Future<void> _loadUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.getUserDashboardData();
      setState(() {
        _dashboardData = data;
        _progress = data['progress'] as models.UserProgress?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          NotificationBell(
            onTap: () => Get.to(() => const NotificationsCenter()),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Get.offAllNamed('/login');
              } else if (value == 'profile') {
                Get.toNamed('/profile');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonDashboard()
          : EnhancedRefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    if (_dashboardData?['advancedStats'] != null) ...[
                      AdvancedStatisticsSection(
                        advancedStats: _convertToMap(_dashboardData!['advancedStats']),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildPerformanceMetrics(),
                    const SizedBox(height: 24),
                    if (_dashboardData?['recentSessions'] != null) ...[
                      EnhancedSessionHistory(
                        sessions: List<Map<String, dynamic>>.from(
                            _dashboardData!['recentSessions'] ?? []),
                      ),
                      const SizedBox(height: 24),
                    ] else
                      _buildRecentSessions(),
                    const SizedBox(height: 24),
                    _buildProgressOverview(),
                    const SizedBox(height: 24),
                    if (_progress != null) ...[
                      AchievementsGallery(
                        userBadges: _progress!.badges,
                        userAchievements: _progress!.achievements,
                      ),
                      const SizedBox(height: 24),
                    ],
                    const GoalsSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildExportSection(),
                    const SizedBox(height: 24),
                    _buildLearningPathPreview(),
                    const SizedBox(height: 24),
                    _buildCommunityStats(),
                  ],
                ),
              ),
            ),
      floatingActionButton: SpeedDialFAB(
        children: [
          SpeedDialAction(
            label: 'Start Practice',
            icon: Icons.mic,
            onTap: () => Get.toNamed('/mode_type'),
          ).toWidget(),
          SpeedDialAction(
            label: 'View Analytics',
            icon: Icons.analytics,
            onTap: () => Get.toNamed('/analytics'),
          ).toWidget(),
          SpeedDialAction(
            label: 'Learning Path',
            icon: Icons.school,
            onTap: () => Get.toNamed('/learning_path'),
          ).toWidget(),
        ],
      ),
    );
  }

  Widget _buildSkeletonDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SkeletonLoader(
                width: 100,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SkeletonLoader(
                width: 100,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SkeletonLoader(
                width: 100,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SkeletonLoader(
                width: 100,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SkeletonLoader(
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 16),
        SkeletonLoader(
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Styles.primaryColor,
                      Styles.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $_userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_progress != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level ${_progress!.currentLevel}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_progress!.totalXP} XP',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: _progress!.levelProgress,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_progress!.levelProgress * 100).toStringAsFixed(0)}% to next level',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_progress!.currentStreak > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_progress!.currentStreak} day streak',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Get.toNamed('/mode_type');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Styles.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Start Practice Session',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    if (_progress == null) {
      return const SizedBox.shrink();
    }

    // Calculate responsive aspect ratio based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio =
        screenWidth < 360 ? 1.3 : 1.5; // Smaller ratio for very small screens
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: [
                _buildStatCard(
                  'Total Sessions',
                  '${_progress!.totalSessions}',
                  Icons.event_note,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Questions Answered',
                  '${_progress!.totalQuestionsAnswered}',
                  Icons.help_outline,
                  Colors.green,
                ),
                _buildStatCard(
                  'Current Level',
                  '${_progress!.currentLevel}',
                  Icons.star,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Total XP',
                  '${_progress!.totalXP}',
                  Icons.workspace_premium,
                  Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double val, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return Transform.scale(
          scale: val,
          child: Opacity(
            opacity: val,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (title == 'Total Sessions' || title == 'Questions Answered') {
                    Get.toNamed('/analytics');
                  } else if (title == 'Current Level' || title == 'Total XP') {
                    Get.toNamed('/gamification');
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            color: color, size: isSmallScreen ? 24 : 32),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Flexible(
                        child: TweenAnimationBuilder<int>(
                          tween: IntTween(
                            begin: 0,
                            end: int.tryParse(value) ?? 0,
                          ),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, int animatedValue, child) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                animatedValue.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics() {
    final trendsData = _dashboardData?['performanceTrends'];
    final trends = _convertToMap(trendsData);
    
    if (trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final pitchTrend = trends['pitchTrend'] as List<dynamic>? ?? [];
    final speechRateTrend = trends['speechRateTrend'] as List<dynamic>? ?? [];
    final sentimentTrend = trends['sentimentTrend'] as List<dynamic>? ?? [];

    if (pitchTrend.isEmpty &&
        speechRateTrend.isEmpty &&
        sentimentTrend.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (pitchTrend.isNotEmpty) ...[
          _buildMiniChart('Average Pitch (Hz)', pitchTrend, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (speechRateTrend.isNotEmpty) ...[
          _buildMiniChart('Speech Rate (WPM)', speechRateTrend, Colors.green),
          const SizedBox(height: 16),
        ],
        if (sentimentTrend.isNotEmpty)
          _buildMiniChart('Sentiment Score', sentimentTrend, Colors.orange),
      ],
    );
  }

  Widget _buildMiniChart(String title, List<dynamic> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((e) => (e as num).toDouble()).toList();

    final minYVal = values.reduce((a, b) => a < b ? a : b);
    final maxYVal = values.reduce((a, b) => a > b ? a : b);

    // If all values are the same (e.g. single data point), create a padding around it
    final minYAdjusted = minYVal == maxYVal ? (minYVal == 0.0 ? -1.0 : minYVal * 0.9) : minYVal * 0.9;
    final maxYAdjusted = minYVal == maxYVal ? (minYVal == 0.0 ? 1.0 : minYVal * 1.1) : maxYVal * 1.1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                  maxX: values.length > 1 ? (values.length - 1).toDouble() : 1.0,
                  minY: minYAdjusted,
                  maxY: maxYAdjusted,
                  lineBarsData: [
                    LineChartBarData(
                      spots: values.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: values.length > 1,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: values.length == 1),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
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

  Widget _buildRecentSessions() {
    final recentSessions =
        _dashboardData?['recentSessions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/analytics'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentSessions.isEmpty)
          EmptyStateWidget(
            icon: Icons.event_note,
            title: 'No sessions yet',
            message:
                'Start your first practice session to see your progress here',
            actionLabel: 'Start Your First Session',
            onAction: () => Get.toNamed('/mode_type'),
          )
        else
          ...recentSessions.map((session) {
            return SwipeableCard(
              endActions: [
                SwipeAction(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () {
                    // TODO: Implement delete session
                    CustomToast.showInfo('Delete functionality coming soon');
                  },
                ),
              ],
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Styles.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      session['mode'] == 'Presentation'
                          ? Icons.slideshow
                          : Icons.question_answer,
                      color: Styles.primaryColor,
                    ),
                  ),
                  title: Text(session['mode'] ?? 'Session'),
                  subtitle: Text(
                    _formatDate(session['createdAt'] ?? ''),
                  ),
                  trailing: Chip(
                    label: Text(
                      session['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getStatusColor(session['status'])
                        .withValues(alpha: 0.2),
                  ),
                  onTap: () {
                    // Navigate to session details
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProgressOverview() {
    final achievementsData = _dashboardData?['achievements'];
    final achievements = _convertToMap(achievementsData);
    if (_progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress & Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Level Progress'),
                    Text(
                        '${_progress!.currentLevel} → ${_progress!.currentLevel + 1}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress!.levelProgress,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Styles.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_progress!.xpProgress} / ${_progress!.xpForNextLevel - ((_progress!.currentLevel - 1) * (_progress!.currentLevel - 1) * 100)} XP',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        if (achievements != null && achievements['nextBadge'] != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Badge',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getBadgeName(achievements['nextBadge']),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (achievements != null &&
            (achievements['recentAchievements'] as List?)?.isNotEmpty ==
                true) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Achievements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(achievements['recentAchievements'] as List)
                      .map((badgeId) {
                    final badge = models.BadgeDefinitions.getBadgeById(badgeId);
                    if (badge == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(badge.icon,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  badge.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  badge.description,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
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
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Practice',
              Icons.mic,
              Colors.blue,
              () => Get.toNamed('/mode_type'),
            ),
            _buildActionCard(
              'Analytics',
              Icons.analytics,
              Colors.orange,
              () => Get.toNamed('/analytics'),
            ),
            _buildActionCard(
              'Learning Path',
              Icons.school,
              Colors.purple,
              () => Get.toNamed('/learning_path'),
            ),
            _buildActionCard(
              'Community',
              Icons.groups,
              Colors.green,
              () => Get.toNamed('/community'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearningPathPreview() {
    final learningPathData = _dashboardData?['learningPathPreview'];
    final learningPath = _convertToMap(learningPathData);
    if (learningPath.isEmpty) return const SizedBox.shrink();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Learning Path',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/learning_path'),
              child: const Text('View Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (learningPath['currentMilestone'] != null)
                  Text(
                    'Current: ${learningPath['currentMilestone']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (learningPath['nextMilestone'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Next: ${learningPath['nextMilestone']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                if (learningPath['progressPercentage'] != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (learningPath['progressPercentage'] as num?)
                            ?.toDouble() ??
                        0.0 / 100,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${learningPath['completedModules'] ?? 0} / ${learningPath['totalModules'] ?? 0} modules completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityStats() {
    final communityStatsData = _dashboardData?['communityStats'];
    final communityStats = _convertToMap(communityStatsData);
    if (communityStats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/community'),
              child: const Text('View Leaderboard'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.leaderboard,
                            size: 32, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text(
                          communityStats['leaderboardPosition'] != null
                              ? '#${communityStats['leaderboardPosition']}'
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Rank'),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.people, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          '${communityStats['totalUsers'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Total Users'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialAction(
                      Icons.share,
                      'Share',
                      () => _shareProgress(),
                    ),
                    _buildSocialAction(
                      Icons.groups,
                      'Community',
                      () => Get.toNamed('/community'),
                    ),
                    _buildSocialAction(
                      Icons.emoji_events,
                      'Challenges',
                      () => _showChallenges(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Styles.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProgress() {
    if (_progress == null) return;

    // In a real app, you would use share_plus package here
    // final shareText = '''
    // 🎯 InterPrep Progress Update!
    // Level: ${_progress!.currentLevel}
    // XP: ${_progress!.totalXP}
    // Sessions: ${_progress!.totalSessions}
    // Streak: ${_progress!.currentStreak} days 🔥
    // ''';

    CustomToast.showInfo(
        'Share functionality will be available with share_plus package');
  }

  void _showChallenges() {
    CustomToast.showInfo('Weekly challenges feature coming soon!');
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status?.toString().toLowerCase() ?? '';
    if (statusStr == 'completed') return Colors.green;
    if (statusStr == 'started') return Colors.blue;
    return Colors.grey;
  }

  String _getBadgeName(String? badgeId) {
    if (badgeId == null) return '';
    final badge = models.BadgeDefinitions.getBadgeById(badgeId);
    return badge?.name ?? badgeId;
  }

  Widget _buildExportSection() {
    final exportService = ExportService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export & Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Generate comprehensive reports of your progress',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportReport(exportService, 'weekly'),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Weekly'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport(exportService, 'monthly'),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Monthly'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport(exportService, 'custom'),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Custom'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportReport(ExportService service, String type) async {
    try {
      // Show format selection dialog
      final format = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Export Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF Format'),
                subtitle: const Text('Best for sharing and printing'),
                onTap: () => Get.back(result: 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.blue),
                title: const Text('CSV Format'),
                subtitle: const Text('Best for data analysis'),
                onTap: () => Get.back(result: 'csv'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (format == null) return;

      if (format == 'pdf') {
  // Export to PDF
  if (kIsWeb) {
    // For web, download PDF bytes
    final pdfBytes = await service.exportToPDFBytes(reportType: type);
    if (pdfBytes != null) {
      downloadFileWeb(
        pdfBytes,
        'interprep_report_${type}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      CustomToast.showSuccess('PDF report downloaded successfully!');
    } else {
      CustomToast.showError('Failed to generate PDF report');
    }
  } else {
    // For mobile
    final pdfFile = await service.exportToPDF(reportType: type);
    
    if (pdfFile != null) {
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'InterPrep Progress Report - ${type.toUpperCase()}',
        subject: 'InterPrep Progress Report',
      );
      CustomToast.showSuccess('PDF report shared successfully!');
    } else {
      // Fallback: save to documents folder
      final pdfBytes = await service.exportToPDFBytes(reportType: type);
      if (pdfBytes != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final filename = 'interprep_report_${type}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final file = File('${directory.path}/$filename');
          await file.writeAsBytes(pdfBytes);
          
          CustomToast.showSuccess('PDF saved to: ${file.path}');
        } catch (e) {
          CustomToast.showError('Failed to save PDF: $e');
        }
      } else {
        CustomToast.showError('Failed to generate PDF report');
      }
    }
  }
} else if (format == 'csv') {
  // Export to CSV
  final csvData = await service.exportToCSV(reportType: type);
  
  
  if (kIsWeb) {
    // For web, download CSV
    downloadFileWeb(
      csvData,
      'interprep_report_${type}_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    CustomToast.showSuccess('CSV report downloaded successfully!');
  } else {
    // For mobile, save to file and share
    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'interprep_report_${type}_$timestamp.csv';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(csvData);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'InterPrep Progress Report - ${type.toUpperCase()}',
      subject: 'InterPrep Progress Report',
    );
    CustomToast.showSuccess('CSV report shared successfully!');
  }
}} catch (e) {
      debugPrint('Error exporting report: $e');
      CustomToast.showError('Failed to export report: $e');
    }
  }

  Future<void> _checkAndSendReminders() async {
    try {
      final notificationService = NotificationService();
      final progress = _progress;

      if (progress != null) {
        // Check if user hasn't practiced today
        final lastSession = progress.lastSessionDate;
        if (lastSession != null) {
          final daysSinceLastSession =
              DateTime.now().difference(lastSession).inDays;

          if (daysSinceLastSession >= 1) {
            await notificationService.notifyReminder(
              'You haven\'t practiced in $daysSinceLastSession day(s). Keep your streak going!',
            );
          }
        }

        // Send tip notification occasionally
        if (progress.totalSessions % 5 == 0 && progress.totalSessions > 0) {
          final tips = [
            'Try practicing at different times of day to see when you perform best!',
            'Focus on one area at a time - pitch, speed, or vocabulary.',
            'Record yourself and listen back to identify areas for improvement.',
            'Practice with different topics to improve versatility.',
          ];
          final randomTip = tips[progress.totalSessions % tips.length];
          await notificationService.notifyTip(randomTip);
        }
      }
    } catch (e) {
      debugPrint('Error sending reminders: $e');
    }
  }
}
