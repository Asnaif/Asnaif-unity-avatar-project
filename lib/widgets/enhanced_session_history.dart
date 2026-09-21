import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interprep/common/constants/styles.dart';

class EnhancedSessionHistory extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;

  const EnhancedSessionHistory({
    super.key,
    required this.sessions,
  });

  @override
  State<EnhancedSessionHistory> createState() => _EnhancedSessionHistoryState();
}

class _EnhancedSessionHistoryState extends State<EnhancedSessionHistory> {
  String _selectedFilter = 'All';
  final Set<String> _expandedSessions = {};
  final Set<String> _selectedSessions = {};

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _filterSessions(widget.sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Session History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (_selectedSessions.length == 2)
                  TextButton.icon(
                    onPressed: () => _compareSessions(context),
                    icon: const Icon(Icons.compare_arrows, size: 18),
                    label: const Text('Compare'),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _selectedFilter = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'All', child: Text('All Sessions')),
                    const PopupMenuItem(value: 'Interview', child: Text('Interview')),
                    const PopupMenuItem(value: 'Presentation', child: Text('Presentation')),
                    const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                    const PopupMenuItem(value: 'Recent', child: Text('Recent (7 days)')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list, size: 18),
                      const SizedBox(width: 4),
                      Text(_selectedFilter),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/analytics'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No sessions found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...filteredSessions.map((session) => _buildSessionCard(session)),
      ],
    );
  }

  List<Map<String, dynamic>> _filterSessions(List<Map<String, dynamic>> sessions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    switch (_selectedFilter) {
      case 'Interview':
        return sessions.where((s) => s['mode'] == 'Interview').toList();
      case 'Presentation':
        return sessions.where((s) => s['mode'] == 'Presentation').toList();
      case 'Completed':
        return sessions.where((s) => s['status'] == 'completed').toList();
      case 'Recent':
        return sessions.where((s) {
          try {
            final date = DateTime.parse(s['createdAt'] ?? '');
            return date.isAfter(weekAgo);
          } catch (e) {
            return false;
          }
        }).toList();
      default:
        return sessions;
    }
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionId = session['id'] ?? '';
    final isExpanded = _expandedSessions.contains(sessionId);
    final isSelected = _selectedSessions.contains(sessionId);

    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Styles.primaryColor.withValues(alpha: 0.1) : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Styles.primaryColor.withValues(alpha: 0.1),
              child: Icon(
                session['mode'] == 'Presentation' ? Icons.slideshow : Icons.question_answer,
                color: Styles.primaryColor,
              ),
            ),
            title: Text(session['mode'] ?? 'Session'),
            subtitle: Text(_formatDate(session['createdAt'] ?? '')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedSessions.length < 2)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSessions.add(sessionId);
                        } else {
                          _selectedSessions.remove(sessionId);
                        }
                      });
                    },
                  ),
                Chip(
                  label: Text(
                    (session['status']?.toString().toUpperCase() ?? 'UNKNOWN').substring(0, 3),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getStatusColor(session['status']).withValues(alpha: 0.2),
                ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSessions.remove(sessionId);
                      } else {
                        _expandedSessions.add(sessionId);
                      }
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSessions.remove(sessionId);
                } else {
                  _expandedSessions.add(sessionId);
                }
              });
            },
          ),
          if (isExpanded) _buildSessionDetails(session),
        ],
      ),
    );
  }

  Widget _buildSessionDetails(Map<String, dynamic> session) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow('Session ID', session['id'] ?? 'N/A'),
          _buildDetailRow('Mode', session['mode'] ?? 'N/A'),
          _buildDetailRow('Status', session['status']?.toString().toUpperCase() ?? 'N/A'),
          _buildDetailRow('Questions', '${session['questionsCount'] ?? 0}'),
          _buildDetailRow('Has Feedback', session['hasFeedback'] == true ? 'Yes' : 'No'),
          if (session['hasFeedback'] == true) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (session['isVapi'] == true) {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                  try {
                    final doc = await FirebaseFirestore.instance
                        .collection('vapi_interviews')
                        .doc(session['id'])
                        .get();
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Dismiss loading indicator
                    }
                    
                    if (doc.exists) {
                      final data = doc.data()!;
                      final rawScores = data['scores'] ?? {};
                      
                      // Map vapi_interviews doc structure to what /vapi_feedback expects
                      final feedback = {
                        'overall_score': rawScores['overall_score'] ?? data['overallScore'] ?? 0,
                        'communication_score': rawScores['scores']?['communication_clarity'] ?? 0,
                        'technical_score': rawScores['scores']?['technical_accuracy'] ?? 0,
                        'confidence_score': rawScores['scores']?['confidence'] ?? 0,
                        'problem_solving_score': rawScores['scores']?['problem_solving'] ?? 0,
                        'cultural_fit_score': rawScores['scores']?['cultural_fit'] ?? 0,
                        'nvc_scores': data['nvcScores'] ?? {},
                        'strengths': rawScores['strengths'] ?? [],
                        'areas_for_improvement': rawScores['areas_for_improvement'] ?? [],
                        'detailed_feedback': rawScores['detailed_feedback'] ?? '',
                        'recommendation': rawScores['recommendation'] ?? '',
                      };
                      
                      Get.toNamed('/vapi_feedback', arguments: {
                        'feedback': feedback,
                        'transcript': data['transcript'] ?? '',
                        'duration': data['durationSeconds'] ?? 0,
                        'recordingUrl': data['recordingUrl'],
                        'sessionId': session['id'],
                      });
                    } else {
                      Get.snackbar(
                        'Error',
                        'Feedback report not found in database.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(); // Dismiss loading indicator
                    }
                    Get.snackbar(
                      'Error',
                      'Failed to load report: $e',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                } else {
                  // Regular session: navigate to /new_feedback with sessionId
                  Get.toNamed('/new_feedback', arguments: {'sessionId': session['id']});
                }
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Full Report'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status?.toString().toLowerCase() ?? '';
    if (statusStr == 'completed') return Colors.green;
    if (statusStr == 'started') return Colors.blue;
    return Colors.grey;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _compareSessions(BuildContext context) {
    if (_selectedSessions.length != 2) return;

    final session1 = widget.sessions.firstWhere(
      (s) => (s['id'] ?? '') == _selectedSessions.elementAt(0),
    );
    final session2 = widget.sessions.firstWhere(
      (s) => (s['id'] ?? '') == _selectedSessions.elementAt(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Comparison'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonRow('Mode', session1['mode'], session2['mode']),
                _buildComparisonRow('Date', _formatDate(session1['createdAt'] ?? ''), _formatDate(session2['createdAt'] ?? '')),
                _buildComparisonRow('Questions', '${session1['questionsCount'] ?? 0}', '${session2['questionsCount'] ?? 0}'),
                _buildComparisonRow('Status', session1['status']?.toString() ?? 'N/A', session2['status']?.toString() ?? 'N/A'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSessions.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value1, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.compare_arrows, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value2, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




