import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
import 'package:interprep/screens/start_session/ui_start_session.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/providers/interview_position_experience_text_controller_provider.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/providers/interview_position_text_controller_provider.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/providers/job_description_text_controller_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class InterviewQuestions extends ConsumerStatefulWidget {
  const InterviewQuestions({super.key});

  @override
  ConsumerState<InterviewQuestions> createState() => _InterviewQuestionsState();
}

class _InterviewQuestionsState extends ConsumerState<InterviewQuestions> {
  // Resume controller for Real-Time Interview
  final TextEditingController _resumeController = TextEditingController();
  
  String? _fileName;
  bool _isExtracting = false;

  Future<void> _pickAndExtractPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isExtracting = true;
          _fileName = result.files.first.name;
        });

        Uint8List? bytes = result.files.first.bytes;
        
        if (bytes == null && result.files.first.path != null && !kIsWeb) {
          bytes = await io.File(result.files.first.path!).readAsBytes();
        }

        if (bytes != null) {
          // Parse the PDF document
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          // Extract text
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          String text = extractor.extractText();
          document.dispose();
          
          setState(() {
            _resumeController.text = text;
            _isExtracting = false;
          });
        } else {
          setState(() {
            _isExtracting = false;
          });
          Get.snackbar('Error', 'Failed to read file bytes', 
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
      });
      Get.snackbar('Error', 'Failed to read PDF: $e', 
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  // Check if this is Real-Time Interview mode
  bool get isRealTimeInterview {
    final args = Get.arguments as Map<String, dynamic>?;
    return args?['isRealTimeInterview'] == true;
  }
  
  // Check if this is Avatar Interview mode
  bool get isAvatarInterview {
    final args = Get.arguments as Map<String, dynamic>?;
    return args?['isAvatarInterview'] == true;
  }
  
  @override
  void dispose() {
    _resumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionController =
        ref.watch(interviewPositionTextControllerProvider);
    final positionExperienceController =
        ref.watch(interviewPositionExperienceTextControllerProvider);
    final jobDescriptionController =
        ref.watch(jobDescriptionTextControllerProvider);
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAvatarInterview ? 'Avatar Interview Setup' : isRealTimeInterview ? 'Real-Time Interview Setup' : 'Interview Questions'),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Show Real-Time Interview info banner
                      if (isRealTimeInterview)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.mic, color: Colors.blue.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Real-Time Voice Interview',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You will have a live voice conversation with an AI interviewer for 15-20 minutes.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Resume Text Area for Real-Time Interview
                      if (isRealTimeInterview) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Upload Your Resume (PDF)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: _isExtracting 
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton.icon(
                                      onPressed: _pickAndExtractPdf,
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(_fileName != null ? 'Change PDF' : 'Select PDF File'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                  ),
                              ),
                              if (_fileName != null && !_isExtracting) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$_fileName loaded successfully',
                                          style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Hidden form field for validation to ensure resume is provided
                              Offstage(
                                child: TextFormField(
                                  controller: _resumeController,
                                  validator: (value) {
                                    if (isRealTimeInterview && (value == null || value.isEmpty)) {
                                      return 'Please upload a PDF resume';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      AppTextField(
                        label: "Position you're applying for?",
                        keyboardType: TextInputType.text,
                        controller: positionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Position is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: "Experience in the particular field?",
                        keyboardType: TextInputType.text,
                        controller: positionExperienceController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Experience is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: "Job Description?",
                        keyboardType: TextInputType.multiline,
                        controller: jobDescriptionController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Job Description is required';
                          }
                          return null;
                        },
                        maxLines: null,
                        minLines: 3,
                      ),
                      
                      // Extra space at bottom for button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            left: 10,
            child: AppTextButton(
              text: isAvatarInterview ? 'Start Avatar Interview' : isRealTimeInterview ? 'Start Real-Time Interview' : 'Next',
              onTap: () {
                if (formKey.currentState!.validate()) {
                  if (isRealTimeInterview) {
                    // ✅ Navigate to VAPI Real-Time Interview Screen
                    Get.toNamed(
                      '/vapi_interview',
                      arguments: {
                        'resumeText': _resumeController.text,
                        'position': positionController.text,
                        'experience': positionExperienceController.text,
                        'jd': jobDescriptionController.text,
                        'durationMinutes': 15,
                        'isAvatarInterview': isAvatarInterview,
                      },
                    );
                  } else {
                    // Regular interview flow
                    Get.to(
                      () => const StartSessionScreen(
                        isPresentation: false,
                      ),
                      arguments: {
                        'position': positionController.text,
                        'experience': positionExperienceController.text,
                        'jd': jobDescriptionController.text,
                      },
                    );
                  }
                }
              },
              color: Styles.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
