import 'dart:io' as io; // IMPORTANT: Alias dart:io
// Import for Uint8List
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:interprep/services/file_picker_service.dart'; // Import helper functions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';

class StartSessionScreen extends ConsumerStatefulWidget {
  const StartSessionScreen({required this.isPresentation, super.key});
  final bool isPresentation;

  @override
  ConsumerState<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends ConsumerState<StartSessionScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _templateData; // Add template data state
  bool _isTemplateMode = false; // Track if using template

  // State variables updated for platform compatibility
  io.File? _pickedFile;
  Uint8List? _pickedFileBytes;

  String? _fileName;
  String documentId = "";
  String _selectedModel = 'openai'; // Default model is openai    

  // Available AI models
  final List<Map<String, String>> _availableModels = [
    {'value': 'openai', 'label': 'ChatGPT (GPT-3.5)', 'icon': '🤖'},
    {'value': 'grok', 'label': 'Grok (xAI)', 'icon': '🧠'},
    {'value': 'claude', 'label': 'Claude (Anthropic)', 'icon': '✨'},
  ];

  @override
  void initState() {
    super.initState();
    // Check if template data was passed
    final args = Get.arguments;
    if (args != null && args['template'] != null) {
      _templateData = args['template'] as Map<String, dynamic>;
      _isTemplateMode = true;
    }
  }

  // New method to start session with template
  Future<void> startTemplateSession() async {
    if (_templateData == null) return;

    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        showErrorDialog("User not authenticated");
        return;
      }

      // Create session with template questions
      final sessionsDocRef = FirebaseFirestore.instance.collection('sessions').doc(userId);
      final snapshot = await sessionsDocRef.get();

      List<dynamic> sessions = [];
      if (snapshot.exists) {
        sessions = List.from(snapshot.data()?['sessions'] ?? []);
      }

      // Add new session with template data
      sessions.add({
        'id': 'reg_${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'started',
        'isPresentation': false, // Templates are for interview mode
        'isInterview': true,
        'templateId': _templateData!['templateId'],
        'templateName': _templateData!['templateName'],
        'industry': _templateData!['industry'],
        'questionsGenerated': _templateData!['questions'] ?? [],
        'scenarios': _templateData!['scenarios'] ?? [],
      });

      await sessionsDocRef.set({'sessions': sessions}, SetOptions(merge: true));

      // Navigate directly to practice session
      Get.toNamed('/practice_session');

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorDialog("Failed to start template session: $e");
    }
  }

  // --- MODIFIED: Uses platform check for upload ---
  // The old signature `Future<String> uploadPdfToFirebase(String fileName, File file)` is replaced.
  Future<String> uploadPdfToFirebase(String fileName,
      {io.File? file, Uint8List? bytes}) async {
    final reference = FirebaseStorage.instance.ref().child("files/$fileName");
    UploadTask uploadTask;

    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('File bytes are missing for web upload.');
      }
      uploadTask = reference.putData(bytes); // Use putData for web
    } else {
      if (file == null) {
        throw Exception('File is missing for mobile/desktop upload.');
      }
      uploadTask = reference.putFile(file); // Use putFile for mobile/desktop
    }

    await uploadTask.whenComplete(() => {});
    final downloadLink = await reference.getDownloadURL();
    return downloadLink;
  }

  final _fireStoreRef = FirebaseFirestore.instance;

  // --- REPLACED: Calls platform-aware helper and sets state correctly ---
  void pickFile() async {
    final pickedFileData = await pickFileForPlatform(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx'],
    );

    if (pickedFileData != null && pickedFileData.name != null && pickedFileData.name!.isNotEmpty) {
      // Clear previous data
      _pickedFile = null;
      _pickedFileBytes = null;

      setState(() {
        _fileName = pickedFileData.name!; // Safe: already checked above
        // Assign data based on platform helpers
        _pickedFileBytes = pickedFileData.bytes;
        _pickedFile = getFileFromPath(pickedFileData.path);
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIED: Passes correct arguments to upload function ---
  Future<void> uploadFile() async {
    // Check if we have file data (either File or Bytes) AND a file name
    if ((_pickedFile != null || _pickedFileBytes != null) &&
        _fileName != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Pass both file and bytes, one will be null depending on the platform
        final fileDownloadLink = await uploadPdfToFirebase(
          _fileName!,
          file: _pickedFile,
          bytes: _pickedFileBytes,
        );

        final docRef = await _fireStoreRef.collection("files").add({
          "name": _fileName,
          "url": fileDownloadLink,
        });

        documentId = docRef.id;

        final userId = FirebaseAuth.instance.currentUser?.uid;

        final sessionsDocRef =
            FirebaseFirestore.instance.collection('sessions').doc(userId);
        final snapshot = await sessionsDocRef.get();

        List<dynamic> sessions = List.from(snapshot.data()!['sessions']);
        sessions.last['filePath'] = fileDownloadLink;
        await sessionsDocRef.update({'sessions': sessions});

        if (widget.isPresentation) {
          Get.toNamed(
            '/generated_questions',
            arguments: {
              "id": documentId,
              "model": _selectedModel,
            },
          );
        } else {
          dynamic args = Get.arguments;
          Get.toNamed(
            '/generated_questions',
            arguments: {
              "id": documentId,
              "jd": args['jd'],
              "position": args['position'],
              "experience": args['experience'],
              "model": _selectedModel,
            },
          );
        }

        setState(() {
          _pickedFile = null;
          _pickedFileBytes = null; // Clear bytes state
          _fileName = null;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showErrorDialog("Failed to upload file: $e");
      }
    } else {
      showErrorDialog("Please attach a file before uploading.");
    }
  }

  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    // If template mode, show template info and skip file upload
    if (_isTemplateMode && _templateData != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Template Session"),
          backgroundColor: Styles.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      color: Styles.primaryColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Styles.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _templateData!['templateName'] ?? 'Template',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_templateData!['industry'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _templateData!['industry'],
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(_templateData!['questions'] as List?)?.length ?? 0} Practice Questions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Template Questions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_templateData!['questions'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final question = (_templateData!['questions'] as List?)?[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Styles.primaryColor.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Styles.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              question ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if ((_templateData!['scenarios'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Practice Scenarios:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_templateData!['scenarios'] as List?)
                                ?.map((scenario) => Chip(
                                      label: Text(scenario ?? ''),
                                      backgroundColor: Colors.green.withOpacity(0.1),
                                    ))
                                .toList() ??
                            [],
                      ),
                    ],
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
            _isLoading
                ? const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Positioned(
                    left: 10,
                    bottom: 5,
                    right: 10,
                    child: AppTextButton(
                      text: "Start Practice Session",
                      onTap: startTemplateSession,
                      color: Styles.primaryColor,
                    ),
                  ),
          ],
        ),
      );
    }

    // Original file upload UI (existing code)
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  widget.isPresentation
                      ? Text(
                          "Upload your presentation",
                          style: Styles.displayXlBoldStyle,
                        )
                      : Text(
                          "Attach your resume",
                          style: Styles.displayLargeNormalStyle,
                        ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text("Allowed Formats: .pptx & .pdf"),
                  const SizedBox(height: 30),
                    
                  // AI Model Selection Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedModel,
                      decoration: const InputDecoration(
                        labelText: "AI Model for Question Generation",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: _availableModels.map((model) {
                        return DropdownMenuItem<String>(
                          value: model['value'],
                          child: Row(
                            children: [
                              Text(model['icon']!),
                              const SizedBox(width: 8),
                              Text(model['label']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedModel = newValue ?? 'openai';
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(250, 249, 246, 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: IconButton(
                              onPressed: pickFile,
                              icon: const Icon(Icons.upload_file_outlined),
                              iconSize: 40,
                            ),
                          ),
                          const Text("Choose File from Device"),
                          if (_fileName != null) ...[
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getFileExtension(_fileName!) == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.slideshow,
                                    color: getFileExtension(_fileName!) == 'pdf'
                                        ? Colors.red
                                        : Colors.orange,
                                  ), // File Icon
                                  const SizedBox(width: 8),
                                  Flexible(
                                      child: Text(
                                        _fileName!,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                    ),
                                  ), // File name
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _isLoading
              ? const Positioned(
                  left: 10,
                  bottom: 10,
                  right: 10,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Positioned(
                  left: 10,
                  bottom: 5,
                  right: 10,
                  child: AppTextButton(
                    text: "Upload",
                    onTap: uploadFile,
                    color: Styles.primaryColor,
                  ),
                )
        ],
      ),
    );
  }
}