import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:interprep/config/api_config.dart';

/// Service to communicate with backend VAPI endpoints
/// Uses secure session tokens - NO API keys exposed to client
class VapiService {
  // Use centralized API config
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/vapi';
  
  // ============================================================
  // SECURE SESSION METHODS (Recommended)
  // ============================================================
  
  /// Create a secure VAPI session with LLM interview brain
  /// Returns session token (NOT API keys) for client-side use
  static Future<Map<String, dynamic>> createSecureSession({
    required String resumeText,
    required String userId,
    String jd = '',
    String position = '',
    String experience = '',
    int durationMinutes = 15,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/secure-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resumeText': resumeText,
          'userId': userId,
          'jd': jd,
          'position': position,
          'experience': experience,
          'durationMinutes': durationMinutes,
        }),
      ).timeout(const Duration(seconds: 90));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Try to parse server error message
        String errorMsg = 'Server error: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['error'] != null) {
            errorMsg = errorBody['error'];
          }
        } catch (_) {}
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Complete interview session and get comprehensive feedback
  static Future<Map<String, dynamic>> completeSession({
    required String sessionId,
    required String userId,
    String? callId,
    int durationSeconds = 0,
    String? transcript,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/complete-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'userId': userId,
          'callId': callId,
          'durationSeconds': durationSeconds,
          if (transcript != null && transcript.isNotEmpty) 'localTranscript': transcript,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to complete session: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Get live transcript during interview
  static Future<Map<String, dynamic>> getLiveTranscript({
    required String sessionId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/session/$sessionId/transcript'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get transcript: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Validate a session token
  static Future<Map<String, dynamic>> validateToken({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validate-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'valid': false};
      }
    } catch (e) {
      return {'valid': false, 'error': e.toString()};
    }
  }
  
  // ============================================================
  // LEGACY METHODS (For backward compatibility)
  // ============================================================
  
  /// Create a VAPI assistant for interview based on resume
  @Deprecated('Use createSecureSession instead')
  static Future<Map<String, dynamic>> createAssistant({
    required String resumeText,
    String jd = '',
    String position = '',
    String experience = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-assistant'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resumeText': resumeText,
          'jd': jd,
          'position': position,
          'experience': experience,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to create assistant: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Start a VAPI interview session
  @Deprecated('Use createSecureSession instead')
  static Future<Map<String, dynamic>> startSession({
    required String assistantId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/start-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'assistantId': assistantId,
          'userId': userId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to start session: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// End VAPI session and get feedback
  @Deprecated('Use completeSession instead')
  static Future<Map<String, dynamic>> endSession({
    required String callId,
    required String userId,
    String? assistantId,
    String resumeText = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/end-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'callId': callId,
          'userId': userId,
          'assistantId': assistantId,
          'resumeText': resumeText,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to end session: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Get feedback for a specific session
  static Future<Map<String, dynamic>> getFeedback({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get-feedback/$sessionId?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get feedback: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
