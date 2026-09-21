import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/badge_service.dart';
import 'package:interprep/screens/practice_session/widgets/coaching_overlay.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:interprep/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key});

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  int currentQuestionIndex = 0;
  int currentSlideIndex = 0; // Track current slide for navigation
  bool isPlayingAudio = false;
  bool isRecording = false;
  bool hasRecorded = false;
  bool isLoading = true;
  bool isInterview = false; // Track if this is interview mode
  bool showCoaching = false; // Show real-time coaching overlay
  List<String> coachingWarnings = [];
  List<String> coachingSuggestions = [];
  double coachingConfidence = 0.5;

  List<String> questions = [];
  List<String> audioUrls = [];
  List<String> slideUrls = [];
  Map<int, String> recordedAudioUrls = {};

  AudioPlayer? _audioPlayer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  Duration recordingDuration = Duration.zero;
  DateTime? recordingStartTime;

  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please login again.');
    }
    return user.uid;
  }

  StreamSubscription? _slideListener;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSlideImages() async {
    try {
      debugPrint('🔄 Starting to load slide images for user: $userId');

      // Try new collection name first
      final slideDoc = await FirebaseFirestore.instance
          .collection('slideImages')
          .doc(userId)
          .get();

      debugPrint('🔍 slideImages document exists: ${slideDoc.exists}');

      if (slideDoc.exists) {
        final data = slideDoc.data()!;
        debugPrint('📄 Document data keys: ${data.keys}');

        // Check for imageLinks (new format) or imageUrls (old format)
        final loadedUrls =
            List<String>.from(data['imageLinks'] ?? data['imageUrls'] ?? []);
        debugPrint(
            '✅ Slide URLs loaded from slideImages: ${loadedUrls.length}');

        if (loadedUrls.isNotEmpty) {
          debugPrint('📸 First slide URL: ${loadedUrls[0]}');
          debugPrint('📸 Last slide URL: ${loadedUrls[loadedUrls.length - 1]}');

          // Validate URLs
          for (int i = 0; i < loadedUrls.length; i++) {
            if (loadedUrls[i].isEmpty) {
              debugPrint('⚠️ Warning: Slide URL at index $i is empty');
            } else if (!loadedUrls[i].startsWith('http')) {
              debugPrint(
                  '⚠️ Warning: Slide URL at index $i is not a valid HTTP URL: ${loadedUrls[i]}');
            }
          }

          setState(() {
            slideUrls = loadedUrls;
            currentSlideIndex = 0;
          });
          debugPrint('✅ Slide URLs set in state. Total: ${slideUrls.length}');
          return;
        } else {
          debugPrint('⚠️ Document exists but imageLinks/imageUrls is empty');
        }
      }

      // Fallback: Check old collection name
      debugPrint(
          'ℹ️ slideImages collection not found, checking images collection...');
      final oldSlideDoc = await FirebaseFirestore.instance
          .collection('images')
          .doc(userId)
          .get();

      if (oldSlideDoc.exists) {
        final data = oldSlideDoc.data()!;
        final loadedUrls =
            List<String>.from(data['imageUrls'] ?? data['imageLinks'] ?? []);
        debugPrint(
            '✅ Slide URLs loaded from images (old): ${loadedUrls.length}');
        if (loadedUrls.isNotEmpty) {
          setState(() {
            slideUrls = loadedUrls;
            currentSlideIndex = 0;
          });
          return;
        }
      }

      // If still no slides, set up a listener to wait for slides to be generated
      debugPrint('ℹ️ No slides found yet. Setting up real-time listener...');

      // Cancel existing listener if any
      await _slideListener?.cancel();

      _slideListener = FirebaseFirestore.instance
          .collection('slideImages')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        debugPrint(
            '🔄 Listener triggered - document exists: ${snapshot.exists}');
        if (snapshot.exists && mounted) {
          final data = snapshot.data()!;
          final loadedUrls =
              List<String>.from(data['imageLinks'] ?? data['imageUrls'] ?? []);
          debugPrint(
              '🔄 Listener - loaded URLs count: ${loadedUrls.length}, current count: ${slideUrls.length}');
          if (loadedUrls.isNotEmpty) {
            debugPrint(
                '🔄 Slides updated via listener: ${loadedUrls.length} slides');
            debugPrint('📸 First slide URL from listener: ${loadedUrls[0]}');
            setState(() {
              slideUrls = loadedUrls;
              currentSlideIndex = 0;
            });
          }
        }
      });

      debugPrint('✅ Real-time listener set up for slideImages collection');
    } catch (e) {
      debugPrint('⚠️ Could not load slide URLs: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadSessionData() async {
    try {
      setState(() => isLoading = true);

      debugPrint('🔄 Loading session for user: $userId');

      final sessionsRef =
          FirebaseFirestore.instance.collection('sessions').doc(userId);
      final snapshot = await sessionsRef.get();

      if (!snapshot.exists) {
        debugPrint('❌ Session document does not exist');
        _showError('Session not found. Please generate questions first.');
        return;
      }

      final data = snapshot.data()!;
      debugPrint('✅ Session data keys: ${data.keys}');

      final sessions = List<dynamic>.from(data['sessions'] ?? []);

      if (sessions.isEmpty) {
        _showError('No active session found');
        return;
      }

      final lastSession = sessions.last;
      debugPrint('📄 Last session keys: ${lastSession.keys}');

      // Check if this is interview mode
      // If isInterview field exists, use it; otherwise check isPresentation
      if (lastSession.containsKey('isInterview')) {
        isInterview = lastSession['isInterview'] == true;
      } else {
        // Fallback: if isPresentation is false, it's interview mode
        isInterview = lastSession['isPresentation'] != true;
      }
      debugPrint(
          '📋 Interview mode: $isInterview (isPresentation: ${lastSession['isPresentation']})');

      questions = List<String>.from(lastSession['questionsGenerated'] ?? []);
      debugPrint('✅ Questions loaded: ${questions.length}');

      try {
        final audioDoc = await FirebaseFirestore.instance
            .collection('questionAudios')
            .doc(userId)
            .get();

        if (audioDoc.exists) {
          audioUrls = List<String>.from(audioDoc.data()!['audioLinks'] ?? []);
          debugPrint('✅ Audio URLs loaded: ${audioUrls.length}');
        } else {
          debugPrint('⚠️ No audio document found');
        }
      } catch (e) {
        debugPrint('⚠️ Could not load audio URLs: $e');
      }

      // Load slide images (only for presentation mode)
      if (!isInterview) {
        await _loadSlideImages();
      } else {
        // Interview mode: no slides needed
        slideUrls = [];
        debugPrint('ℹ️ Interview mode - slides not needed');
      }

      setState(() {
        isLoading = false;
        // Initialize currentSlideIndex when slides are loaded
        if (slideUrls.isNotEmpty && currentSlideIndex >= slideUrls.length) {
          currentSlideIndex = 0;
        }
      });
    } catch (e) {
      debugPrint('❌ FATAL Load session error: $e');
      _showError('Failed to load session: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _playQuestionAudio() async {
    try {
      if (audioUrls.isEmpty || currentQuestionIndex >= audioUrls.length) {
        _showError('No audio available for this question');
        return;
      }

      final audioUrl = audioUrls[currentQuestionIndex];
      debugPrint('🎵 Playing audio: $audioUrl');

      await _audioPlayer?.stop();

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(UrlSource(audioUrl));

      setState(() => isPlayingAudio = true);

      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => isPlayingAudio = false);
        }
      });
    } catch (e) {
      debugPrint('❌ Play audio error: $e');
      _showError('Failed to play audio');
      setState(() => isPlayingAudio = false);
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer?.stop();
    setState(() => isPlayingAudio = false);
  }

  Future<void> _startRecording() async {
    try {
      // Permission check
      if (!await _audioRecorder.hasPermission()) {
        _showError(
            'Microphone permission required. Please enable in app settings.');
        return;
      }

      // Mobile ke liye proper path
      String? path;
      if (kIsWeb) {
        path = 'temp_recording.opus';
      } else {
        // Mobile ke liye proper file path
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${directory.path}/recording_$timestamp.opus';
      }

      // Recording start karein
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        isRecording = true;
        hasRecorded = false;
        recordingStartTime = DateTime.now();
        recordingDuration = Duration.zero;
      });

      _startDurationTimer();
      debugPrint('🎤 Recording started at: $path');
    } catch (e, stackTrace) {
      debugPrint('❌ Recording error: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      String errorMessage = 'Failed to start recording. ';
      if (e.toString().contains('permission')) {
        errorMessage += 'Please grant microphone permission.';
      } else if (e.toString().contains('path')) {
        errorMessage += 'Invalid recording path.';
      } else {
        errorMessage += 'Error: ${e.toString()}';
      }

      _showError(errorMessage);

      setState(() {
        isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!isRecording) {
        debugPrint('⚠️ Stop called but not recording');
        return;
      }

      final path = await _audioRecorder.stop();

      setState(() {
        isRecording = false;
      });

      if (path != null) {
        debugPrint('✅ Recording saved at: $path');

        if (kIsWeb) {
          await _uploadRecordedAudioWeb(path);
        } else {
          // Mobile ke liye upload function
          await _uploadRecordedAudioMobile(path);
        }
      } else {
        _showError('No audio recorded');
      }

      debugPrint('🎤 Recording stopped');
    } catch (e, stackTrace) {
      debugPrint('❌ Stop recording error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showError('Failed to stop recording: ${e.toString()}');

      setState(() {
        isRecording = false;
      });
    }
  }

// Naya function mobile upload ke liye
  Future<void> _uploadRecordedAudioMobile(String filePath) async {
    try {
      setState(() => isLoading = true);

      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Recorded file not found');
        setState(() => isLoading = false);
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('recordings')
          .child(userId)
          .child('recording_$timestamp.opus');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Firestore mein save karein
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userId)
          .update({
        'sessions': FieldValue.arrayUnion([
          {
            'questionIndex': currentQuestionIndex,
            'audioUrl': downloadUrl,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ])
      });

      setState(() {
        isLoading = false;
        hasRecorded = true;
        recordedAudioUrls[currentQuestionIndex] = downloadUrl;
      });

      CustomToast.showSuccess('Recording uploaded successfully');
      debugPrint('✅ Audio uploaded: $downloadUrl');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      _showError('Failed to upload recording: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  void _startDurationTimer() {
    Future.doWhile(() async {
      if (!isRecording) return false;

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && isRecording) {
        setState(() {
          recordingDuration = DateTime.now().difference(recordingStartTime!);
        });
      }

      return isRecording;
    });
  }

  Future<void> _uploadRecordedAudioWeb(String path) async {
    try {
      _showLoadingDialog('Uploading audio...');

      final response = await http.get(Uri.parse(path));
      final Uint8List audioData = response.bodyBytes;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'responses/$userId/q${currentQuestionIndex}_$timestamp.opus';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putData(
        audioData,
        SettableMetadata(contentType: 'audio/opus'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      recordedAudioUrls[currentQuestionIndex] = downloadUrl;

      final sessionsRef =
          FirebaseFirestore.instance.collection('sessions').doc(userId);
      final snapshot2 = await sessionsRef.get();
      final data = snapshot2.data()!;
      List<dynamic> sessions = List.from(data['sessions']);

      if (sessions.last['responses'] == null) {
        sessions.last['responses'] = {};
      }

      final now = DateTime.now().toIso8601String();

      sessions.last['responses']['q$currentQuestionIndex'] = {
        'audio_url': downloadUrl,
        'duration_seconds': recordingDuration.inSeconds,
        'recorded_at': now,
      };

      await sessionsRef.update({'sessions': sessions});

      if (!mounted) return;
      setState(() {
        hasRecorded = true;
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Response uploaded successfully!', Colors.green);

      debugPrint('✅ Upload successful: $downloadUrl');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('❌ Upload error: $e');
      _showError('Failed to upload: $e');
    }
  }

  void _nextQuestion() {
    if (!hasRecorded) {
      _showError('Please record your response first');
      return;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasRecorded = recordedAudioUrls.containsKey(currentQuestionIndex);
        recordingDuration = Duration.zero;
        // For PPTX: sync slide index with question index (optional)
        // For PDF: keep slide at index 0
        if (slideUrls.length > 1 && currentQuestionIndex < slideUrls.length) {
          currentSlideIndex = currentQuestionIndex;
        }
      });
    } else {
      _finishSession();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        hasRecorded = recordedAudioUrls.containsKey(currentQuestionIndex);
        recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _finishSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Session?'),
        content: Text(
          'You have recorded ${recordedAudioUrls.length} out of ${questions.length} responses.\n\n'
          'Are you ready to submit and get your feedback report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _showLoadingDialog('Analyzing your responses...');

    try {
      final firstAudioUrl = recordedAudioUrls[0];

      if (firstAudioUrl == null) {
        throw Exception('No audio recorded');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.audioProcessingEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audioFilePath': firstAudioUrl,
          'userId': userId,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final sessionsRef =
            FirebaseFirestore.instance.collection('sessions').doc(userId);
        final snapshot = await sessionsRef.get();
        final data = snapshot.data()!;
        List<dynamic> sessions = List.from(data['sessions']);
        sessions.last['status'] = 'completed';
        await sessionsRef.update({'sessions': sessions});

        // Award XP and check for badges
        try {
          final feedbackData = jsonDecode(response.body);
          final badgeService = BadgeService();
          await badgeService.awardSessionXP(
            recordedAudioUrls.length,
            feedbackData,
          );
        } catch (e) {
          debugPrint('Error awarding XP: $e');
          // Continue even if XP awarding fails
        }

        Get.toNamed('/new_feedback');
      } else {
        if (!mounted) return;
        _showError('Analysis failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('❌ Finish session error: $e');
      _showError('Failed to analyze: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (color == Colors.green) {
      CustomToast.showSuccess(message);
    } else if (color == Colors.red) {
      CustomToast.showError(message);
    } else {
      CustomToast.showInfo(message);
    }
  }

  void _showError(String message) {
    CustomToast.showError(message);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Loading Session..."),
          backgroundColor: Styles.primaryColor,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonLoader(
                width: double.infinity,
                height: 400,
                borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 16),
            SkeletonLoader(
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 16),
            SkeletonLoader(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16)),
          ],
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
          backgroundColor: Styles.primaryColor,
        ),
        body: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'No questions found',
          message:
              'Unable to load questions for this session. Please try again or contact support.',
          actionLabel: 'Go Back',
          onAction: () => Get.back(),
          iconColor: Colors.red,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("InterPrep - Practice Session"),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          if (isWideScreen) {
            return Row(
              children: [
                // Only show slide section if NOT in interview mode
                if (!isInterview)
                  Expanded(
                    flex: 3,
                    child: _buildSlideSection(),
                  ),
                Expanded(
                  flex: isInterview ? 1 : 2,
                  child: SingleChildScrollView(
                    child: _buildControlsSection(),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Only show slide section if NOT in interview mode
                  if (!isInterview) _buildSlideSection(),
                  _buildControlsSection(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSlideSection() {
    // Debug: Print slide information
    debugPrint('🔍 _buildSlideSection - slideUrls.length: ${slideUrls.length}');
    debugPrint('🔍 _buildSlideSection - currentSlideIndex: $currentSlideIndex');
    if (slideUrls.isNotEmpty) {
      debugPrint('🔍 _buildSlideSection - First slide URL: ${slideUrls[0]}');
    }

    // For PDF: use first slide (index 0) for all questions
    // For PPTX: allow navigation through all slides, but default to question index
    if (slideUrls.isNotEmpty) {
      // If single slide (PDF), always use index 0
      // If multiple slides (PPTX), use currentSlideIndex but ensure it's valid
      if (slideUrls.length == 1) {
        currentSlideIndex = 0;
      } else {
        // Ensure currentSlideIndex is within bounds
        if (currentSlideIndex >= slideUrls.length) {
          currentSlideIndex = slideUrls.length - 1;
        }
        if (currentSlideIndex < 0) {
          currentSlideIndex = 0;
        }
      }
    }

    final hasSlide = slideUrls.isNotEmpty &&
        currentSlideIndex < slideUrls.length &&
        slideUrls[currentSlideIndex].isNotEmpty;
    final hasMultipleSlides = slideUrls.length > 1;

    debugPrint(
        '🔍 _buildSlideSection - hasSlide: $hasSlide, hasMultipleSlides: $hasMultipleSlides');

    return Container(
      height: 600,
      padding: const EdgeInsets.all(16),
      color: const Color.fromRGBO(5, 38, 57, 1.000),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Presentation Slide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (hasMultipleSlides)
                    Text(
                      'Slide ${currentSlideIndex + 1}/${slideUrls.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Reload slides',
                    onPressed: () {
                      debugPrint('🔄 Manual refresh triggered');
                      _loadSlideImages();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Line 708-716 ko replace karein:
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasSlide
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child:
                              _buildNetworkImage(slideUrls[currentSlideIndex]),
                        ),
                        // Real-time coaching overlay
                        if (isRecording && showCoaching)
                          CoachingOverlay(
                            warnings: coachingWarnings,
                            suggestions: coachingSuggestions,
                            confidenceScore: coachingConfidence,
                            isVisible: showCoaching,
                          ),
                        // Navigation arrows for multiple slides
                        if (hasMultipleSlides) ...[
                          // Previous slide button
                          if (currentSlideIndex > 0)
                            Positioned(
                              left: 10,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left,
                                      color: Colors.white, size: 40),
                                  onPressed: () {
                                    setState(() {
                                      currentSlideIndex--;
                                      if (currentSlideIndex < 0) {
                                        currentSlideIndex = 0;
                                      }
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ),
                          // Next slide button
                          if (currentSlideIndex < slideUrls.length - 1)
                            Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right,
                                      color: Colors.white, size: 40),
                                  onPressed: () {
                                    setState(() {
                                      currentSlideIndex++;
                                      if (currentSlideIndex >=
                                          slideUrls.length) {
                                        currentSlideIndex =
                                            slideUrls.length - 1;
                                      }
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    )
                  : _buildNoSlideWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlideWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.slideshow, size: 64, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            'No slide available',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Slides are generated from PPTX files.\nPDF files show first page only.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    // Clean URL: decode any double-encoding issues
    String cleanUrl = imageUrl;

    // Fix URL encoding - properly encode spaces and special characters
    if (cleanUrl.contains('%20')) {
      cleanUrl = Uri.decodeComponent(cleanUrl);
    }

    // For Firebase Storage URLs, ensure proper encoding
    if (cleanUrl.contains('storage.googleapis.com')) {
      try {
        final uri = Uri.parse(cleanUrl);
        // Re-encode path segments properly
        final pathSegments = uri.pathSegments
            .map((segment) => Uri.encodeComponent(Uri.decodeComponent(segment)))
            .toList();
        cleanUrl = '${uri.scheme}://${uri.host}/${pathSegments.join('/')}';
        if (uri.hasQuery) {
          cleanUrl += '?${uri.query}';
        }
      } catch (e) {
        debugPrint('⚠️ URL parsing error: $e');
      }
    }

    debugPrint('🖼️ Loading image from URL: $cleanUrl');

    // Use Image.network for all platforms (works on web and mobile)
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        cleanUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        headers: const {
          'Cache-Control': 'no-cache',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('✅ Slide image loaded successfully');
            return child;
          }
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text(
                  'Loading slide...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error loading slide image: $error');
          return _buildErrorWidget(cleanUrl);
        },
      ),
    );
  }

  Widget _buildErrorWidget(String cleanUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 10),
          const Text(
            'Failed to load slide',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'URL: ${cleanUrl.length > 50 ? "${cleanUrl.substring(0, 50)}..." : cleanUrl}',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                // Force rebuild to retry loading
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.question_answer, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        'Question:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    questions[currentQuestionIndex],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🔊 Listen to Question',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: audioUrls.isEmpty
                ? null
                : (isPlayingAudio ? _stopAudio : _playQuestionAudio),
            icon: Icon(isPlayingAudio ? Icons.stop : Icons.play_arrow),
            label: Text(
              isPlayingAudio ? 'Stop Audio' : 'Play Question Audio',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  isPlayingAudio ? Colors.orange : Styles.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '🎤 Record Your Response',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRecording ? _stopRecording : _startRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  label: Text(
                    isRecording ? 'Stop Recording' : 'Start Recording',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isRecording ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  showCoaching ? Icons.visibility : Icons.visibility_off,
                  color: showCoaching ? Styles.primaryColor : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    showCoaching = !showCoaching;
                  });
                },
                tooltip: showCoaching ? 'Hide Coaching' : 'Show Coaching',
              ),
            ],
          ),
          if (isRecording) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Recording...',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(recordingDuration),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      backgroundColor: Colors.red[100],
                      valueColor: const AlwaysStoppedAnimation(Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasRecorded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Response Recorded Successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              if (currentQuestionIndex > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: hasRecorded ? _nextQuestion : null,
                  icon: Icon(
                    currentQuestionIndex < questions.length - 1
                        ? Icons.arrow_forward
                        : Icons.check_circle,
                  ),
                  label: Text(
                    currentQuestionIndex < questions.length - 1
                        ? 'Next Question'
                        : 'Finish & Get Feedback',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Styles.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[700]),
                      const SizedBox(width: 10),
                      const Text(
                        'Communication Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Speak clearly and maintain steady pace'),
                  if (!isInterview) _buildTip('Reference the slide content'),
                  _buildTip('Take a moment to organize thoughts'),
                  if (isInterview)
                    _buildTip('Address the question directly with examples')
                  else
                    _buildTip('Aim for 1-2 minutes per response'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideListener?.cancel();
    _audioPlayer?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
