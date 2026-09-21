import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interprep/services/dashboard_service.dart';
import 'package:interprep/services/badge_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
// import 'package:share_plus/share_plus.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DashboardService _dashboardService = DashboardService();
  final BadgeService _badgeService = BadgeService();

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Generate report data for export
  Future<Map<String, dynamic>> generateReport({
    DateTime? startDate,
    DateTime? endDate,
    String reportType = 'weekly', // weekly, monthly, custom
  }) async {
    try {
      final now = DateTime.now();
      DateTime reportStartDate;
      DateTime reportEndDate = now;

      switch (reportType) {
        case 'weekly':
          reportStartDate = now.subtract(const Duration(days: 7));
          break;
        case 'monthly':
          reportStartDate = now.subtract(const Duration(days: 30));
          break;
        case 'custom':
          reportStartDate = startDate ?? now.subtract(const Duration(days: 7));
          reportEndDate = endDate ?? now;
          break;
        default:
          reportStartDate = now.subtract(const Duration(days: 7));
      }

      // Get user progress
      final progress = await _badgeService.getUserProgress();

      // Get sessions in date range
      final sessions = await _getSessionsInRange(reportStartDate, reportEndDate);

      // Get dashboard data
      final dashboardData = await _dashboardService.getUserDashboardData();

      // Compile report
      return {
        'reportType': reportType,
        'startDate': reportStartDate.toIso8601String(),
        'endDate': reportEndDate.toIso8601String(),
        'generatedAt': now.toIso8601String(),
        'userProgress': progress?.toFirestore(),
        'sessions': sessions,
        'statistics': dashboardData['advancedStats'],
        'achievements': dashboardData['achievements'],
        'summary': _generateSummary(progress, sessions, reportStartDate, reportEndDate),
      };
    } catch (e) {
      debugPrint('Error generating report: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getSessionsInRange(DateTime start, DateTime end) async {
    try {
      final sessionsRef = _firestore.collection('sessions').doc(userId);
      final snapshot = await sessionsRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final allSessions = List<Map<String, dynamic>>.from(snapshot.data()?['sessions'] ?? []);

      return allSessions.where((session) {
        try {
          final dateStr = session['createdAt'] ?? '';
          if (dateStr.isEmpty) return false;
          final date = DateTime.parse(dateStr);
          return date.isAfter(start.subtract(const Duration(days: 1))) &&
              date.isBefore(end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error getting sessions in range: $e');
      return [];
    }
  }

  Map<String, dynamic> _generateSummary(
    dynamic progress,
    List<Map<String, dynamic>> sessions,
    DateTime start,
    DateTime end,
  ) {
    final completedSessions = sessions.where((s) => s['status'] == 'completed').toList();
    final totalQuestions = sessions.fold<int>(
      0,
      (sum, s) => sum + ((s['questionsGenerated'] as List?)?.length ?? 0),
    );

    return {
      'totalSessions': sessions.length,
      'completedSessions': completedSessions.length,
      'totalQuestions': totalQuestions,
      'averageSessionsPerDay': sessions.length / (end.difference(start).inDays + 1),
      'currentLevel': progress?.currentLevel ?? 0,
      'totalXP': progress?.totalXP ?? 0,
      'currentStreak': progress?.currentStreak ?? 0,
    };
  }

  // Export to text format (for now - PDF would require pdf package)
  Future<String> exportToText({
    DateTime? startDate,
    DateTime? endDate,
    String reportType = 'weekly',
  }) async {
    try {
      final reportData = await generateReport(
        startDate: startDate,
        endDate: endDate,
        reportType: reportType,
      );

      final buffer = StringBuffer();
      buffer.writeln('InterPrep Progress Report');
      buffer.writeln('=' * 50);
      buffer.writeln();
      buffer.writeln('Report Type: ${reportData['reportType']}');
      buffer.writeln('Period: ${reportData['startDate']} to ${reportData['endDate']}');
      buffer.writeln('Generated: ${reportData['generatedAt']}');
      buffer.writeln();

      final summary = reportData['summary'] as Map<String, dynamic>;
      buffer.writeln('Summary:');
      buffer.writeln('- Total Sessions: ${summary['totalSessions']}');
      buffer.writeln('- Completed Sessions: ${summary['completedSessions']}');
      buffer.writeln('- Total Questions: ${summary['totalQuestions']}');
      buffer.writeln('- Current Level: ${summary['currentLevel']}');
      buffer.writeln('- Total XP: ${summary['totalXP']}');
      buffer.writeln('- Current Streak: ${summary['currentStreak']} days');
      buffer.writeln();

      buffer.writeln('Sessions:');
      final sessions = reportData['sessions'] as List<dynamic>;
      for (var session in sessions) {
        buffer.writeln('- ${session['mode']}: ${session['createdAt']}');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error exporting to text: $e');
      rethrow;
    }
  }

  // Export to PDF format
  Future<File?> exportToPDF({
    DateTime? startDate,
    DateTime? endDate,
    String reportType = 'weekly',
  }) async {
    try {
      final reportData = await generateReport(
        startDate: startDate,
        endDate: endDate,
        reportType: reportType,
      );

      final pdf = pw.Document();
      final summary = reportData['summary'] as Map<String, dynamic>;
      final sessions = reportData['sessions'] as List<dynamic>;
      final statistics = reportData['statistics'] as Map<String, dynamic>?;
      final achievements = reportData['achievements'] as Map<String, dynamic>?;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'InterPrep Progress Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Info
              pw.Text(
                'Report Type: ${reportData['reportType'].toString().toUpperCase()}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Period: ${_formatDate(reportData['startDate'])} to ${_formatDate(reportData['endDate'])}'),
              pw.Text('Generated: ${_formatDate(reportData['generatedAt'])}'),
              pw.SizedBox(height: 20),

              // Summary Section
              pw.Text(
                'Summary',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow('Total Sessions', '${summary['totalSessions']}'),
                  _buildTableRow('Completed Sessions', '${summary['completedSessions']}'),
                  _buildTableRow('Total Questions', '${summary['totalQuestions']}'),
                  _buildTableRow('Current Level', '${summary['currentLevel']}'),
                  _buildTableRow('Total XP', '${summary['totalXP']}'),
                  _buildTableRow('Current Streak', '${summary['currentStreak']} days'),
                  _buildTableRow('Avg Sessions/Day', '${summary['averageSessionsPerDay'].toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sessions List
              if (sessions.isNotEmpty) ...[
                pw.Text(
                  'Sessions (${sessions.length})',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Mode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...sessions.take(20).map((session) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(session['mode'] ?? (session['isPresentation'] == true ? 'Presentation' : 'Interview')),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(_formatDate(session['createdAt'] ?? '')),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(session['status'] ?? 'N/A'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                if (sessions.length > 20)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text('... and ${sessions.length - 20} more sessions'),
                  ),
                pw.SizedBox(height: 20),
              ],

              // Statistics
              if (statistics != null && statistics.isNotEmpty) ...[
                pw.Text(
                  'Advanced Statistics',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                if (statistics['weeklyProgress'] != null) ...[
                  pw.Text('Weekly Progress:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('  Sessions: ${statistics['weeklyProgress']['sessions'] ?? 0}'),
                  pw.Text('  Questions: ${statistics['weeklyProgress']['questions'] ?? 0}'),
                  pw.SizedBox(height: 10),
                ],
              ],

              // Achievements
              if (achievements != null && achievements['recentAchievements'] != null) ...[
                pw.Text(
                  'Recent Achievements',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ...(achievements['recentAchievements'] as List? ?? []).map((achievement) {
                  return pw.Text('• $achievement');
                }).toList(),
              ],
            ];
          },
        ),
      );

      // Save PDF to file
      if (kIsWeb) {
        // For web, return null and handle download separately
        return null;
      } else {
        final output = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'interprep_report_${reportType}_$timestamp.pdf';
        final file = File('${output.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      rethrow;
    }
  }
  // Export to PDF bytes (for web support)
  Future<Uint8List?> exportToPDFBytes({
    DateTime? startDate,
    DateTime? endDate,
    String reportType = 'weekly',
  }) async {
    try {
      final reportData = await generateReport(
        startDate: startDate,
        endDate: endDate,
        reportType: reportType,
      );

      final pdf = pw.Document();
      final summary = reportData['summary'] as Map<String, dynamic>;
      final sessions = reportData['sessions'] as List<dynamic>;
      final statistics = reportData['statistics'] as Map<String, dynamic>?;
      final achievements = reportData['achievements'] as Map<String, dynamic>?;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'InterPrep Progress Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Info
              pw.Text(
                'Report Type: ${reportData['reportType'].toString().toUpperCase()}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Period: ${_formatDate(reportData['startDate'])} to ${_formatDate(reportData['endDate'])}'),
              pw.Text('Generated: ${_formatDate(reportData['generatedAt'])}'),
              pw.SizedBox(height: 20),

              // Summary Section
              pw.Text(
                'Summary',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow('Total Sessions', '${summary['totalSessions']}'),
                  _buildTableRow('Completed Sessions', '${summary['completedSessions']}'),
                  _buildTableRow('Total Questions', '${summary['totalQuestions']}'),
                  _buildTableRow('Current Level', '${summary['currentLevel']}'),
                  _buildTableRow('Total XP', '${summary['totalXP']}'),
                  _buildTableRow('Current Streak', '${summary['currentStreak']} days'),
                  _buildTableRow('Avg Sessions/Day', '${summary['averageSessionsPerDay'].toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sessions List
              if (sessions.isNotEmpty) ...[
                pw.Text(
                  'Sessions (${sessions.length})',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Mode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...sessions.take(20).map((session) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(session['mode'] ?? 'N/A'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(_formatDate(session['createdAt'] ?? '')),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(session['status'] ?? 'N/A'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                if (sessions.length > 20)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text('... and ${sessions.length - 20} more sessions'),
                  ),
                pw.SizedBox(height: 20),
              ],

              // Statistics
              if (statistics != null && statistics.isNotEmpty) ...[
                pw.Text(
                  'Advanced Statistics',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                if (statistics['weeklyProgress'] != null) ...[
                  pw.Text('Weekly Progress:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('  Sessions: ${statistics['weeklyProgress']['sessions'] ?? 0}'),
                  pw.Text('  Questions: ${statistics['weeklyProgress']['questions'] ?? 0}'),
                  pw.SizedBox(height: 10),
                ],
              ],

              // Achievements
              if (achievements != null && achievements['recentAchievements'] != null) ...[
                pw.Text(
                  'Recent Achievements',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ...(achievements['recentAchievements'] as List? ?? []).map((achievement) {
                  return pw.Text('- $achievement');
                }).toList(),
              ],
            ];
          },
        ),
      );

      // Return PDF bytes
      return await pdf.save();
    } catch (e) {
      debugPrint('Error exporting to PDF bytes: $e');
      return null;
    }
  }
// Export to CSV format
  Future<String> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String reportType = 'weekly',
  }) async {
    try {
      final reportData = await generateReport(
        startDate: startDate,
        endDate: endDate,
        reportType: reportType,
      );

      final buffer = StringBuffer();
      final summary = reportData['summary'] as Map<String, dynamic>;
      final sessions = reportData['sessions'] as List<dynamic>;

      // CSV Header
      buffer.writeln('InterPrep Progress Report - ${reportData['reportType'].toString().toUpperCase()}');
      buffer.writeln('Period,${reportData['startDate']},${reportData['endDate']}');
      buffer.writeln('Generated,${reportData['generatedAt']}');
      buffer.writeln();

      // Summary Section
      buffer.writeln('Summary');
      buffer.writeln('Metric,Value');
      buffer.writeln('Total Sessions,${summary['totalSessions']}');
      buffer.writeln('Completed Sessions,${summary['completedSessions']}');
      buffer.writeln('Total Questions,${summary['totalQuestions']}');
      buffer.writeln('Current Level,${summary['currentLevel']}');
      buffer.writeln('Total XP,${summary['totalXP']}');
      buffer.writeln('Current Streak,${summary['currentStreak']}');
      buffer.writeln('Avg Sessions Per Day,${summary['averageSessionsPerDay'].toStringAsFixed(2)}');
      buffer.writeln();

      // Sessions Section
      if (sessions.isNotEmpty) {
        buffer.writeln('Sessions');
        buffer.writeln('Mode,Date,Status,Questions');
        for (var session in sessions) {
          final mode = session['mode'] ?? 'N/A';
          final date = session['createdAt'] ?? '';
          final status = session['status'] ?? 'N/A';
          final questions = (session['questionsGenerated'] as List?)?.length ?? 0;
          buffer.writeln('$mode,$date,$status,$questions');
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      rethrow;
    }
  }

  // Helper method for PDF table rows
  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  // Helper method to format dates
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

