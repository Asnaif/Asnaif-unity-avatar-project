import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/learning_path_service.dart';
import 'package:get/get.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  final LearningPathService _learningPathService = LearningPathService();
  Map<String, dynamic>? _learningPath;
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLearningPath();
  }

  Future<void> _loadLearningPath() async {
    setState(() => _isLoading = true);
    try {
      final path = await _learningPathService.getLearningPath();
      final prefs = await _learningPathService.getPreferences();
      
      setState(() {
        _learningPath = path;
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading learning path: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Path'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPreferencesDialog,
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _learningPath == null
              ? const Center(child: Text('No learning path available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentLevelCard(),
                      const SizedBox(height: 16),
                      _buildWeaknessesCard(),
                      const SizedBox(height: 16),
                      _buildRecommendationsCard(),
                      const SizedBox(height: 16),
                      _buildMilestoneCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentLevelCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Styles.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    color: Styles.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${_learningPath!['currentLevel']}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Keep practicing to level up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaknessesCard() {
    final weaknesses = _learningPath!['weaknesses'] as List<dynamic>? ?? [];
    
    if (weaknesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Areas for Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...weaknesses.map((weakness) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          weakness.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _learningPath!['recommendations'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Personalized Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final difficulty = recommendation['difficulty'] as String? ?? 'beginner';
    final difficultyColor = _getDifficultyColor(difficulty);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getRecommendationIcon(recommendation['type'] as String? ?? 'practice'),
            color: difficultyColor,
          ),
        ),
        title: Text(
          recommendation['title'] as String? ?? 'Practice',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recommendation['description'] as String? ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: difficultyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  recommendation['estimatedTime'] as String? ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // Navigate to practice session with recommendation
            Get.toNamed('/start_session');
          },
        ),
      ),
    );
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'milestone':
        return Icons.flag;
      case 'topic':
        return Icons.topic;
      default:
        return Icons.school;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildMilestoneCard() {
    final nextMilestone = _learningPath!['nextMilestone'] as String? ?? 'Keep practicing';
    
    return Card(
      elevation: 2,
      color: Styles.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Styles.primaryColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Milestone',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextMilestone,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Styles.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learning Preferences'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Difficulty Level:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _preferences?['difficultyLevel'] ?? 'beginner',
                items: ['beginner', 'intermediate', 'advanced']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _learningPathService.savePreferences(difficultyLevel: value);
                    _loadLearningPath();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Daily Goal (sessions per day):'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _preferences?['dailyGoal'] ?? 1,
                items: [1, 2, 3, 5]
                    .map((goal) => DropdownMenuItem(
                          value: goal,
                          child: Text('$goal session${goal > 1 ? 's' : ''}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _learningPathService.savePreferences(dailyGoal: value);
                    _loadLearningPath();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

