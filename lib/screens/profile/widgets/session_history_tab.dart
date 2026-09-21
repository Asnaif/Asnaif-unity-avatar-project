import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interprep/services/dashboard_service.dart';

class SessionHistoryTab extends StatefulWidget {
  const SessionHistoryTab({super.key});

  @override
  State<SessionHistoryTab> createState() => _SessionHistoryTabState();
}

class _SessionHistoryTabState extends State<SessionHistoryTab> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dashboardService.getRecentSessions(limit: 100);
      setState(() {
        _sessions = sessions;
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

    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sessions yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  session['mode'] == 'Presentation' ? Icons.slideshow : Icons.question_answer,
                ),
              ),
              title: Text(session['mode'] ?? 'Session'),
              subtitle: Text(_formatDate(session['createdAt'] ?? '')),
              trailing: Chip(
                label: Text(
                  (session['status']?.toString().toUpperCase() ?? 'UNKNOWN').substring(0, 3),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              onTap: () => Get.toNamed('/analytics'),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}




