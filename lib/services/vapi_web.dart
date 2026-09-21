// ignore_for_file: avoid_web_libraries_in_flutter
/// VAPI Web SDK Interop for Flutter Web
/// This file provides Dart bindings to the VAPI JavaScript SDK

import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// VAPI Web SDK wrapper for Flutter
class VapiWeb {
  static bool _isInitialized = false;
  static String? _currentCallId;
  
  // Stream controllers for events
  static final _callStartController = StreamController<void>.broadcast();
  static final _callEndController = StreamController<String?>.broadcast();
  static final _speechStartController = StreamController<void>.broadcast();
  static final _speechEndController = StreamController<void>.broadcast();
  static final _transcriptController = StreamController<TranscriptMessage>.broadcast();
  static final _errorController = StreamController<String>.broadcast();
  
  /// Stream of call start events
  static Stream<void> get onCallStart => _callStartController.stream;
  
  /// Stream of call end events (with call ID)
  static Stream<String?> get onCallEnd => _callEndController.stream;
  
  /// Stream of AI speech start events
  static Stream<void> get onSpeechStart => _speechStartController.stream;
  
  /// Stream of AI speech end events
  static Stream<void> get onSpeechEnd => _speechEndController.stream;
  
  /// Stream of transcript updates
  static Stream<TranscriptMessage> get onTranscript => _transcriptController.stream;
  
  /// Stream of error events
  static Stream<String> get onError => _errorController.stream;
  
  /// Initialize VAPI with public key (async to handle SDK loading)
  static Future<bool> initializeAsync(String publicKey) async {
    if (!kIsWeb) {
      debugPrint('⚠️ VAPI Web SDK only works on web platform');
      return false;
    }
    
    try {
      // Set up Dart callbacks for JS to call
      js.context['onVapiCallStart'] = js.allowInterop(() {
        _callStartController.add(null);
      });
      
      js.context['onVapiCallEnd'] = js.allowInterop((callId) {
        _currentCallId = callId?.toString();
        _callEndController.add(_currentCallId);
      });
      
      js.context['onVapiSpeechStart'] = js.allowInterop(() {
        _speechStartController.add(null);
      });
      
      js.context['onVapiSpeechEnd'] = js.allowInterop(() {
        _speechEndController.add(null);
      });
      
      js.context['onVapiTranscript'] = js.allowInterop((role, transcript) {
        _transcriptController.add(TranscriptMessage(
          role: role?.toString() ?? 'unknown',
          transcript: transcript?.toString() ?? '',
        ));
      });
      
      js.context['onVapiError'] = js.allowInterop((error) {
        _errorController.add(error?.toString() ?? 'Unknown error');
      });
      
      // Initialize VAPI - may return Promise if SDK is still loading
      final result = js.context.callMethod('initVapi', [publicKey]);
      
      // Check if result is a Promise
      if (result != null && result.hasProperty('then')) {
        // It's a Promise, wait for it
        final completer = Completer<bool>();
        result.callMethod('then', [
          js.allowInterop((value) {
            _isInitialized = value == true;
            debugPrint(_isInitialized 
              ? '✅ VAPI Web initialized (async)' 
              : '❌ VAPI Web initialization failed (async)');
            completer.complete(_isInitialized);
          })
        ]).callMethod('catch', [
          js.allowInterop((error) {
            debugPrint('❌ VAPI init error: $error');
            completer.complete(false);
          })
        ]);
        return completer.future;
      } else {
        // Synchronous result
        _isInitialized = result == true;
        debugPrint(_isInitialized 
          ? '✅ VAPI Web initialized' 
          : '❌ VAPI Web initialization failed');
        return _isInitialized;
      }
    } catch (e) {
      debugPrint('❌ Error initializing VAPI Web: $e');
      return false;
    }
  }
  
  /// Synchronous initialize (legacy, may fail if SDK not loaded)
  static bool initialize(String publicKey) {
    if (!kIsWeb) {
      debugPrint('⚠️ VAPI Web SDK only works on web platform');
      return false;
    }
    
    try {
      // Set up Dart callbacks for JS to call
      js.context['onVapiCallStart'] = js.allowInterop(() {
        _callStartController.add(null);
      });
      
      js.context['onVapiCallEnd'] = js.allowInterop((callId) {
        _currentCallId = callId?.toString();
        _callEndController.add(_currentCallId);
      });
      
      js.context['onVapiSpeechStart'] = js.allowInterop(() {
        _speechStartController.add(null);
      });
      
      js.context['onVapiSpeechEnd'] = js.allowInterop(() {
        _speechEndController.add(null);
      });
      
      js.context['onVapiTranscript'] = js.allowInterop((role, transcript) {
        _transcriptController.add(TranscriptMessage(
          role: role?.toString() ?? 'unknown',
          transcript: transcript?.toString() ?? '',
        ));
      });
      
      js.context['onVapiError'] = js.allowInterop((error) {
        _errorController.add(error?.toString() ?? 'Unknown error');
      });
      
      // Initialize VAPI
      final result = js.context.callMethod('initVapi', [publicKey]);
      _isInitialized = result == true;
      
      debugPrint(_isInitialized 
        ? '✅ VAPI Web initialized' 
        : '❌ VAPI Web initialization failed');
      
      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error initializing VAPI Web: $e');
      return false;
    }
  }
  
  /// Start a call with the given assistant ID
  static Future<String?> startCall(String assistantId) async {
    if (!kIsWeb) {
      debugPrint('⚠️ VAPI Web SDK only works on web platform');
      return null;
    }
    
    if (!_isInitialized) {
      debugPrint('⚠️ VAPI not initialized. Call initialize() first.');
      return null;
    }
    
    try {
      // Call the JS function and handle the Promise
      final jsPromise = js.context.callMethod('startVapiCall', [assistantId]);
      
      // Convert JS Promise to Dart Future
      final completer = Completer<String?>();
      
      jsPromise.callMethod('then', [
        js.allowInterop((result) {
          _currentCallId = result?.toString();
          completer.complete(_currentCallId);
        })
      ]).callMethod('catch', [
        js.allowInterop((error) {
          debugPrint('❌ startCall error: $error');
          completer.complete(null);
        })
      ]);
      
      return completer.future;
    } catch (e) {
      debugPrint('❌ Error starting VAPI call: $e');
      return null;
    }
  }
  
  /// Stop the current call
  static bool stopCall() {
    if (!kIsWeb) return false;
    if (!_isInitialized) return false;
    
    try {
      final result = js.context.callMethod('stopVapiCall', []);
      return result == true;
    } catch (e) {
      debugPrint('❌ Error stopping VAPI call: $e');
      return false;
    }
  }
  
  /// Check if VAPI is active
  static bool get isActive {
    if (!kIsWeb) return false;
    try {
      return js.context.callMethod('isVapiActive', []) == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Set microphone muted state
  static bool setMuted(bool muted) {
    if (!kIsWeb) return false;
    if (!_isInitialized) return false;
    
    try {
      return js.context.callMethod('setVapiMuted', [muted]) == true;
    } catch (e) {
      debugPrint('❌ Error setting mute: $e');
      return false;
    }
  }
  
  /// Get the current call ID
  static String? get currentCallId => _currentCallId;
  
  /// Check if VAPI is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Dispose resources
  static void dispose() {
    _callStartController.close();
    _callEndController.close();
    _speechStartController.close();
    _speechEndController.close();
    _transcriptController.close();
    _errorController.close();
  }
}

/// Transcript message from VAPI
class TranscriptMessage {
  final String role;
  final String transcript;
  
  TranscriptMessage({required this.role, required this.transcript});
  
  bool get isAI => role == 'assistant';
  bool get isUser => role == 'user';
  
  @override
  String toString() => '${isAI ? "AI" : "You"}: $transcript';
}
