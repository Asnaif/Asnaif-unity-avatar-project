import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/integrations/calendar_service.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final CalendarService _calendarService = CalendarService();
  bool _linkedInConnected = false;
  bool _calendarEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrations'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntegrationCard(
            'LinkedIn',
            'Import your LinkedIn profile for interview practice',
            Icons.work,
            Colors.blue,
            _linkedInConnected,
            () => _connectLinkedIn(),
          ),
          const SizedBox(height: 12),
          _buildIntegrationCard(
            'Calendar',
            'Set practice reminders in your calendar',
            Icons.calendar_today,
            Colors.green,
            _calendarEnabled,
            () => _enableCalendar(),
          ),
          const SizedBox(height: 12),
          _buildIntegrationCard(
            'Export to Portfolio',
            'Export your progress and achievements',
            Icons.file_download,
            Colors.purple,
            false,
            () => _exportToPortfolio(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isConnected,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: isConnected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _connectLinkedIn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect LinkedIn'),
        content: const Text(
          'This will open LinkedIn to authorize access to your profile. '
          'Your profile data will be used to personalize interview questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // In real implementation, this would open OAuth flow
              // For now, just show a message
              setState(() {
                _linkedInConnected = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('LinkedIn integration coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _enableCalendar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Calendar Reminders'),
        content: const Text(
          'Set up daily practice reminders in your calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _calendarService.createPracticeReminder(
                title: 'InterPrep Practice Session',
                dateTime: DateTime.now().add(const Duration(days: 1)),
                description: 'Time for your daily practice session!',
              );
              setState(() {
                _calendarEnabled = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _exportToPortfolio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to Portfolio'),
        content: const Text(
          'Export your progress, achievements, and feedback reports '
          'to share in your portfolio or resume.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon!'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

