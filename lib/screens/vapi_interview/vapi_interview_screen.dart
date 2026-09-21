import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:interprep/services/vapi_service.dart';
import 'package:interprep/services/vapi_web.dart';
import 'package:interprep/services/badge_service.dart';

/// Real-time interview screen using VAPI
/// Layout: AI Interviewer (left) | User (right) with transcript and timer
class VapiInterviewScreen extends StatefulWidget {
  const VapiInterviewScreen({super.key});

  @override
  State<VapiInterviewScreen> createState() => _VapiInterviewScreenState();
}

class _VapiInterviewScreenState extends State<VapiInterviewScreen> {
  // State variables
  bool _isLoading = true;
  bool _isInterviewActive = false;
  bool _isConnecting = false;
  bool _isAISpeaking = false;
  bool _isUserSpeaking = false;
  bool _isMuted = false;
  bool _isEndingInterview = false; // Guard to prevent double-call of _endInterview
  
  String _currentTranscript = '';
  List<String> _transcriptHistory = [];
  String _statusMessage = 'Preparing interview...';
  String? _assistantId;
  String? _callId;
  String? _publicKey;
  
  // NEW: Secure session variables
  String? _sessionId;
  String? _sessionToken;
  List<String> _focusAreas = [];
  int _durationMinutes = 15;
  
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _transcriptPollTimer;  // For live transcript updates
  
  // Stream subscriptions
  StreamSubscription? _callStartSub;
  StreamSubscription? _callEndSub;
  StreamSubscription? _speechStartSub;
  StreamSubscription? _speechEndSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _errorSub;
  
  String _resumeText = '';
  String _jd = '';
  String _position = '';
  String _experience = '';
  bool _isAvatarInterview = false;
  
  // Unity avatar view type registered
  static bool _viewTypeRegistered = false;
  // NVC camera view registered
  static bool _nvcViewRegistered = false;
  bool _nvcActive = false;
  String _nvcEmotion = '';
  bool _nvcEyeContact = false;
  
  @override
  void initState() {
    super.initState();
    _registerUnityView();
    _registerNVCView();
    _initializeInterview();
  }
  
  void _registerUnityView() {
    if (!kIsWeb || _viewTypeRegistered) return;
    _viewTypeRegistered = true;
    
    // Build absolute URL to avoid Flutter dev server SPA fallback
    // The relative 'unity/avatar.html' gets intercepted and serves index.html instead
    final origin = html.window.location.origin;
    final basePath = html.document.querySelector('base')?.getAttribute('href') ?? '/';
    final avatarUrl = '${origin}${basePath}unity/avatar.html?t=${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('🎭 Unity Avatar URL: $avatarUrl');
    
    // Register Unity iframe as platform view
    ui_web.platformViewRegistry.registerViewFactory(
      'unity-avatar-view',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..id = 'unity-avatar-iframe'
          ..src = avatarUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..style.pointerEvents = 'none'  // CRITICAL: let clicks pass through to Flutter buttons
          ..allow = 'autoplay'
          ..setAttribute('allowTransparency', 'true');
        return iframe;
      },
    );
  }
  
  void _registerNVCView() {
    if (!kIsWeb || _nvcViewRegistered) return;
    _nvcViewRegistered = true;
    
    ui_web.platformViewRegistry.registerViewFactory(
      'nvc-camera-view',
      (int viewId) {
        final video = html.VideoElement()
          ..id = 'nvc-camera-preview-$viewId'
          ..autoplay = true
          ..setAttribute('playsinline', 'true')
          ..muted = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.transform = 'scaleX(-1)'; // Mirror
        
        // Tell JS to attach the stream to this new video element
        // (JS searches by ID prefix 'nvc-camera-preview')
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            js.context.callMethod('attachNVCPreview');
          } catch (_) {}
        });
        Future.delayed(const Duration(seconds: 2), () {
          try {
            js.context.callMethod('attachNVCPreview');
          } catch (_) {}
        });
        
        return video;
      },
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _transcriptPollTimer?.cancel();
    _cleanupSubscriptions();
    if (_isInterviewActive && kIsWeb) {
      VapiWeb.stopCall();
    }
    super.dispose();
  }
  
  void _cleanupSubscriptions() {
    _callStartSub?.cancel();
    _callEndSub?.cancel();
    _speechStartSub?.cancel();
    _speechEndSub?.cancel();
    _transcriptSub?.cancel();
    _errorSub?.cancel();
  }
  
  void _setupVapiListeners() {
    if (!kIsWeb) return;
    
    _callStartSub = VapiWeb.onCallStart.listen((_) {
      debugPrint('📞 VAPI Call Started');
      setState(() {
        _isInterviewActive = true;
        _isConnecting = false;
        _statusMessage = 'Interview in progress';
      });
      _startTimer();
    });
    
    _callEndSub = VapiWeb.onCallEnd.listen((callId) {
      debugPrint('📞 VAPI Call Ended event: $callId');
      _callId = callId ?? _callId;
      // Only auto-end if user hasn't already clicked End Interview
      if (!_isEndingInterview && _isInterviewActive) {
        _endInterview();
      }
    });
    
    _speechStartSub = VapiWeb.onSpeechStart.listen((_) {
      setState(() {
        _isAISpeaking = true;
        _isUserSpeaking = false;
      });
    });
    
    _speechEndSub = VapiWeb.onSpeechEnd.listen((_) {
      setState(() {
        _isAISpeaking = false;
      });
    });
    
    _transcriptSub = VapiWeb.onTranscript.listen((message) {
      setState(() {
        _currentTranscript = message.toString();
        _transcriptHistory.add(message.toString());
        // Keep only last 50 messages
        if (_transcriptHistory.length > 50) {
          _transcriptHistory.removeAt(0);
        }
        // Update speaking indicators
        _isAISpeaking = message.isAI;
        _isUserSpeaking = message.isUser;
      });
    });
    
    _errorSub = VapiWeb.onError.listen((error) {
      debugPrint('❌ VAPI Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
  
  Future<void> _initializeInterview() async {
    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _resumeText = args['resumeText'] ?? '';
    _jd = args['jd'] ?? '';
    _position = args['position'] ?? '';
    _experience = args['experience'] ?? '';
    _durationMinutes = args['durationMinutes'] ?? 15;
    _isAvatarInterview = args['isAvatarInterview'] == true;
    
    if (_resumeText.isEmpty) {
      setState(() {
        _statusMessage = 'Error: No resume provided';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _statusMessage = 'Creating AI Interviewer with LLM brain...';
    });
    
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    
    // Create SECURE session with LLM brain (no API keys exposed)
    final result = await VapiService.createSecureSession(
      resumeText: _resumeText,
      userId: userId,
      jd: _jd,
      position: _position,
      experience: _experience,
      durationMinutes: _durationMinutes,
    );
    
    if (result['success'] == true) {
      _assistantId = result['assistantId'];
      _sessionId = result['sessionId'];
      _publicKey = result['publicKey'];
      _sessionToken = result['sessionToken'];
      
      // Store interview strategy info
      final strategy = result['interviewStrategy'] as Map<String, dynamic>?;
      if (strategy != null) {
        _focusAreas = List<String>.from(strategy['focusAreas'] ?? []);
      }
      
      setState(() {
        _statusMessage = 'AI Interviewer ready! Click Start to begin.';
        _isLoading = false;
      });
    } else {
      setState(() {
        _statusMessage = 'Error: ${result['error']}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _startInterview() async {
    if (_assistantId == null || _publicKey == null) {
      setState(() {
        _statusMessage = 'Error: Session not initialized properly';
      });
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Loading VAPI SDK...';
    });
    
    // Initialize VAPI Web SDK on web platform
    // NOTE: publicKey already obtained from secure session in _initializeInterview
    if (kIsWeb) {
      debugPrint('🎙️ Initializing VAPI Web SDK...');
      
      // Use async initialize to wait for SDK to load
      final initialized = await VapiWeb.initializeAsync(_publicKey!);
      
      if (initialized) {
        // Set up event listeners
        _setupVapiListeners();
        
        // Start the call with assistant ID from secure session
        debugPrint('🎙️ Starting call with assistant: $_assistantId');
        _callId = await VapiWeb.startCall(_assistantId!);
        
        if (_callId != null) {
          debugPrint('✅ Call started: $_callId');
          setState(() {
            _isConnecting = false;
            _isInterviewActive = true;
            _statusMessage = 'Interview in progress';
            _currentTranscript = 'Connecting to AI interviewer...';
          });
          _startTimer();
          // Start NVC body language recording AFTER a delay
          // to let VAPI's Daily.co WebRTC fully acquire the microphone first.
          // Starting getUserMedia({video}) too early conflicts with VAPI's
          // audio setup, causing "error-assistant-did-not-receive-customer-audio"
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _isInterviewActive) {
              _startNVCRecording();
            }
          });
        } else {
          setState(() {
            _isConnecting = false;
            _statusMessage = 'Failed to start call. Please try again.';
          });
        }
      } else {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Failed to initialize VAPI. Please refresh the page.';
        });
      }
    } else {
      // Fallback for non-web platforms
      setState(() {
        _isConnecting = false;
        _isInterviewActive = true;
        _statusMessage = 'Interview in progress';
        _currentTranscript = 'AI: Hello! Thank you for joining...';
      });
      _callId = 'demo_call_${DateTime.now().millisecondsSinceEpoch}';
      _startTimer();
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
      
      // Auto-end after 20 minutes
      if (_elapsedSeconds >= 1200) {
        _endInterview();
      }
    });
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  void _toggleMute() {
    if (kIsWeb) {
      final newMuted = !_isMuted;
      if (VapiWeb.setMuted(newMuted)) {
        setState(() {
          _isMuted = newMuted;
        });
      }
    }
  }
  
  Future<void> _endInterview() async {
    // Guard: prevent double-call (button click + call-end event)
    if (_isEndingInterview) {
      debugPrint('⚠️ _endInterview already in progress, skipping');
      return;
    }
    _isEndingInterview = true;
    
    debugPrint('🛑 _endInterview() called');
    
    _timer?.cancel();
    _transcriptPollTimer?.cancel();
    
    // Cancel subscriptions FIRST to stop receiving events during teardown
    _cleanupSubscriptions();
    
    // Stop VAPI call — fail-safe
    if (kIsWeb) {
      // Stop NVC body language recording
      _stopNVCRecording();
      
      try {
        VapiWeb.stopCall();
        debugPrint('🛑 VAPI call stop requested');
      } catch (e) {
        debugPrint('⚠️ Error stopping VAPI call: $e');
      }
    }
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isInterviewActive = false;
      _statusMessage = 'Analyzing interview...';
    });
    
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    
    // Use secure session completion for LLM-powered feedback
    // Add timeout to prevent hanging forever
    try {
      final localTranscript = _transcriptHistory.join('\n');
      final result = await VapiService.completeSession(
        sessionId: _sessionId ?? '',
        userId: userId,
        callId: _callId,
        durationSeconds: _elapsedSeconds,
        transcript: localTranscript,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('⏰ completeSession timed out after 60s');
          return {'success': false, 'error': 'Analysis timed out'};
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to feedback screen with comprehensive results
      if (result['success'] == true) {
        try {
          // A standard Vapi session counts as 5 questions for XP scaling
          final badgeService = BadgeService();
          await badgeService.awardSessionXP(
            5, 
            result['feedback'] ?? {},
          );
        } catch (e) {
          debugPrint('Error awarding XP: $e');
        }

        Get.offNamed('/vapi_feedback', arguments: {
          'feedback': result['feedback'],
          'transcript': result['transcript'] ?? _transcriptHistory.join('\n'),
          'duration': _elapsedSeconds,
          'recordingUrl': result['recordingUrl'],
          'sessionId': _sessionId,
        });
      } else {
        Get.offNamed('/vapi_feedback', arguments: {
          'feedback': {'detailed_feedback': 'Interview completed. Server analysis: ${result['error'] ?? 'unavailable'}.'},
          'transcript': _transcriptHistory.join('\n'),
          'duration': _elapsedSeconds,
          'sessionId': _sessionId,
        });
      }
    } catch (e) {
      debugPrint('❌ Error completing session: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Always navigate even if completion fails
      Get.offNamed('/vapi_feedback', arguments: {
        'feedback': {'detailed_feedback': 'Interview completed. Analysis could not be generated.'},
        'transcript': _transcriptHistory.join('\n'),
        'duration': _elapsedSeconds,
        'sessionId': _sessionId,
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Interview Session',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isInterviewActive) {
              _showExitConfirmation();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          if (_isInterviewActive)
            IconButton(
              icon: Icon(
                _isMuted ? Icons.mic_off : Icons.mic,
                color: _isMuted ? Colors.red : Colors.white,
              ),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute' : 'Mute',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _isInterviewActive
              ? _buildInterviewView()
              : _buildReadyView(),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReadyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Interviewer icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.blue.withOpacity(0.5), width: 3),
            ),
            child: const Icon(
              Icons.record_voice_over,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_position.isNotEmpty)
            Text(
              'Position: $_position',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          const SizedBox(height: 40),
          if (_assistantId != null)
            ElevatedButton(
              onPressed: _isConnecting ? null : _startInterview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Start Interview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInterviewView() {
    if (_isAvatarInterview) {
      return _buildAvatarInterviewView();
    }
    return _buildRegularInterviewView();
  }
  
  /// Full-screen Unity Avatar interview view
  Widget _buildAvatarInterviewView() {
    return Stack(
      children: [
        // Solid dark background — prevents Dashboard from bleeding through
        // if the Unity iframe fails to load or loads the wrong content
        Positioned.fill(
          child: Container(
            color: const Color(0xFF1A1A2E),
          ),
        ),
        // Full screen Unity Avatar (on top of dark background)
        Positioned.fill(
          child: kIsWeb
              ? const HtmlElementView(viewType: 'unity-avatar-view')
              : const Center(
                  child: Icon(Icons.record_voice_over, size: 80, color: Colors.white54),
                ),
        ),
        
        // Timer overlay (top right)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTime(_elapsedSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Speaking indicator (top left)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isAISpeaking ? Colors.green.withOpacity(0.8) : Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isAISpeaking ? Colors.white : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isAISpeaking ? 'AI Speaking...' : 'Listening',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        
        // End button (bottom center)
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _endInterview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: const Text(
                'End Interview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        
        // NVC Webcam Preview (top-right corner)
        if (_nvcActive)
          Positioned(
            top: 60,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _nvcEyeContact ? Colors.greenAccent : Colors.cyanAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? const HtmlElementView(viewType: 'nvc-camera-view')
                        : Container(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 4),
                // NVC status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _nvcEyeContact ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _nvcEmotion.isNotEmpty ? _nvcEmotion : 'Analyzing...',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Original 2-panel interview view (for Real-Time Interview without avatar)
  Widget _buildRegularInterviewView() {
    return Column(
      children: [
        // Main interview area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // AI Interviewer panel
                Expanded(
                  child: _buildParticipantCard(
                    name: 'AI Interviewer',
                    isAI: true,
                    isSpeaking: _isAISpeaking,
                  ),
                ),
                const SizedBox(width: 16),
                // User panel
                Expanded(
                  child: _buildParticipantCard(
                    name: 'You',
                    isAI: false,
                    isSpeaking: _isUserSpeaking,
                    isMuted: _isMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Transcript area
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            reverse: true,
            child: Text(
              _currentTranscript.isNotEmpty 
                  ? _currentTranscript 
                  : 'Listening...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        // Timer and controls
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _endInterview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'End',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAvatarPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAISpeaking ? Colors.blue : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          // Unity Avatar iframe
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: kIsWeb
                  ? const HtmlElementView(viewType: 'unity-avatar-view')
                  : const Center(
                      child: Icon(
                        Icons.record_voice_over,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          // Name and status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'AI Interviewer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isAISpeaking ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAISpeaking ? 'Speaking...' : 'Listening',
                      style: TextStyle(
                        color: _isAISpeaking ? Colors.green.shade300 : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticipantCard({
    required String name,
    required bool isAI,
    required bool isSpeaking,
    bool isMuted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? Colors.blue : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isAI ? Colors.white : Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: isAI
                    ? const Icon(
                        Icons.record_voice_over,
                        size: 40,
                        color: Color(0xFF1A1A2E),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
              ),
              if (!isAI && isMuted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSpeaking)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    width: 8,
                    height: 8 + (index % 2 == 0 ? 4.0 : 0),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'End Interview?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to end this interview session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endInterview();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Interview'),
          ),
        ],
      ),
    );
  }
  
  // ══════════════════════════════════════════
  // NVC Body Language Recording
  // ══════════════════════════════════════════
  
  void _startNVCRecording() {
    if (!kIsWeb || _sessionId == null) return;
    
    try {
      js.context.callMethod('startNVCRecording', [_sessionId]);
      setState(() => _nvcActive = true);
      debugPrint('NVC recording started');
      
      // Listen for NVC metrics events from JS
      html.window.addEventListener('nvc-metrics', _onNVCMetrics);
    } catch (e) {
      debugPrint('NVC recording failed: $e');
    }
  }
  
  void _stopNVCRecording() {
    if (!kIsWeb) return;
    
    try {
      js.context.callMethod('stopNVCRecording');
      html.window.removeEventListener('nvc-metrics', _onNVCMetrics);
      setState(() => _nvcActive = false);
      debugPrint('NVC recording stopped');
    } catch (e) {
      debugPrint('NVC stop failed: $e');
    }
  }
  
  void _onNVCMetrics(html.Event event) {
    if (event is html.CustomEvent && event.detail != null) {
      final detail = event.detail;
      if (mounted) {
        setState(() {
          _nvcEmotion = (detail['emotion'] ?? '').toString();
          _nvcEyeContact = detail['eyeContact'] == true;
        });
      }
    }
  }
}
