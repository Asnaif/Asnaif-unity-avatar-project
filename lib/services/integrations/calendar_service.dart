import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  // Create calendar event for practice reminder
  Future<void> createPracticeReminder({
    required String title,
    required DateTime dateTime,
    String? description,
  }) async {
    try {
      // Format date for calendar URL
      final dateStr = '${dateTime.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z';
      final endDateStr = '${dateTime.add(const Duration(hours: 1)).toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0]}Z';
      
      // Google Calendar URL
      final url = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&dates=$dateStr/$endDateStr'
        '&details=${Uri.encodeComponent(description ?? "Practice session reminder")}'
        '&sf=true&output=xml'
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error creating calendar reminder: $e');
    }
  }

  // Create recurring reminder
  Future<void> createRecurringReminder({
    required String title,
    required List<int> daysOfWeek, // 0 = Sunday, 1 = Monday, etc.
    required String time, // HH:MM format
    String? description,
  }) async {
    // Implementation would create recurring calendar events
    // This is a simplified version
    debugPrint('Creating recurring reminder for: $title on days: $daysOfWeek at $time');
  }
}

