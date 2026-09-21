import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Feedback screen for VAPI real-time interview
class VapiFeedbackScreen extends StatelessWidget {
  const VapiFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final feedback = args['feedback'] as Map<String, dynamic>? ?? {};
    final transcript = args['transcript'] as String? ?? '';
    final duration = args['duration'] as int? ?? 0;
    final recordingUrl = args['recordingUrl'] as String?;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Interview Feedback',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration card
            _buildInfoCard(
              icon: Icons.timer,
              title: 'Interview Duration',
              value: _formatDuration(duration),
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            
            // Overall score
            if (feedback['overall_score'] != null)
              _buildScoreCard(
                title: 'Overall Score',
                score: feedback['overall_score'] ?? 0,
                color: _getScoreColor(feedback['overall_score'] ?? 0),
              ),
            const SizedBox(height: 16),
            
            // Score breakdown
            Row(
              children: [
                Expanded(
                  child: _buildMiniScoreCard(
                    title: 'Communication',
                    score: feedback['communication_score'] ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniScoreCard(
                    title: 'Technical',
                    score: feedback['technical_score'] ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniScoreCard(
                    title: 'Confidence',
                    score: feedback['confidence_score'] ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Body Language Scores (NVC)
            if (feedback['nvc_scores'] != null && feedback['nvc_scores'] is Map) ...[
              _buildSectionTitle('Body Language Analysis', Icons.face, Colors.cyan),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniScoreCard(
                      title: 'Eye Contact',
                      score: ((feedback['nvc_scores']['eye_contact_score'] ?? 5) * 10).toInt(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniScoreCard(
                      title: 'Posture',
                      score: ((feedback['nvc_scores']['posture_score'] ?? 5) * 10).toInt(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniScoreCard(
                      title: 'Gestures',
                      score: ((feedback['nvc_scores']['gesture_score'] ?? 5) * 10).toInt(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniScoreCard(
                      title: 'Engagement',
                      score: ((feedback['nvc_scores']['engagement_score'] ?? 5) * 10).toInt(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniScoreCard(
                      title: 'Body Language',
                      score: ((feedback['nvc_scores']['overall_body_language_score'] ?? 5) * 10).toInt(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      label: 'Emotion',
                      value: feedback['nvc_scores']['dominant_emotion'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            
            // Strengths
            if (feedback['strengths'] != null && (feedback['strengths'] as List).isNotEmpty)
              _buildListSection(
                title: 'Strengths',
                items: List<String>.from(feedback['strengths']),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            const SizedBox(height: 16),
            
            // Areas for improvement
            if (feedback['areas_for_improvement'] != null && 
                (feedback['areas_for_improvement'] as List).isNotEmpty)
              _buildListSection(
                title: 'Areas for Improvement',
                items: List<String>.from(feedback['areas_for_improvement']),
                icon: Icons.lightbulb,
                color: Colors.orange,
              ),
            const SizedBox(height: 16),
            
            // Detailed feedback
            if (feedback['detailed_feedback'] != null)
              _buildTextSection(
                title: 'Detailed Feedback',
                content: feedback['detailed_feedback'],
              ),
            const SizedBox(height: 16),
            
            // Recommendation
            if (feedback['recommendation'] != null)
              _buildHighlightSection(
                title: 'Recommendation',
                content: feedback['recommendation'],
              ),
            const SizedBox(height: 24),
            
            // Transcript section
            if (transcript.isNotEmpty)
              _buildExpandableSection(
                title: 'Interview Transcript',
                content: transcript,
              ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.offAllNamed('/home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.offNamed('/mode_type'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Interview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
  
  Color _getScoreColor(num score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreCard({
    required String title,
    required num score,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'out of 100',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniScoreCard({required String title, required num score}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              color: _getScoreColor(score),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTextSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHighlightSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandableSection({required String title, required String content}) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      collapsedBackgroundColor: const Color(0xFF16213E),
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: Colors.white54,
      collapsedIconColor: Colors.white54,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
