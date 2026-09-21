import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
import 'package:interprep/services/activity_log_service.dart';
import 'package:interprep/screens/start_session/widgets/mode_type/providers/mode_type_provider.dart';
import 'package:interprep/screens/start_session/ui_start_session.dart';

enum MenuOption { logout }

enum StatusOption {
  started,
  fileUploaded,
  questionsGenerated,
  audioUploaded,
  reportGenerated
}

class ModeTypeScreen extends ConsumerStatefulWidget {
  const ModeTypeScreen({super.key});

  @override
  ConsumerState<ModeTypeScreen> createState() => _ModeTypeScreenState();
}

class _ModeTypeScreenState extends ConsumerState<ModeTypeScreen> {
  late final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedValue;
  // In lib/screens/start_session/widgets/mode_type/ui_mode_type_screen.dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modeTypeProvider.notifier).state = "";
    });
  }

  void onSelected(BuildContext context, MenuOption item) {
    switch (item) {
      case MenuOption.logout:
        FirebaseAuth.instance.signOut();
        Get.toNamed('/login');
        break;
    }
  }

  Future<bool> createSession() async {
    try {
      final isPresentation =
          ref.read(modeTypeProvider.notifier).state == "Presentation";
      final nowStr = DateTime.now().toIso8601String();
      Map<String, dynamic> sessionData = {
        'id': 'reg_${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': nowStr,
        'isPresentation': isPresentation,
        'questionsGenerated': <List<String>>[],
        'audioFilePath': "",
        'filePath': "",
        'reportGenerated': "",
        'status': StatusOption.started.name,
        'mode': isPresentation ? 'Presentation' : 'Interview',
      };

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final collectionRef = FirebaseFirestore.instance.collection('sessions');
        final docRef = collectionRef.doc(userId);
        final docSnapshot = await docRef.get();

        List<dynamic> sessions;
        if (!docSnapshot.exists) {
          sessions = [sessionData];
          await docRef.set({
            'sessions': sessions
          });
        } else {
          sessions = List.from(docSnapshot.data()?['sessions'] ?? []);
          sessions.add(sessionData);
          await docRef.update({'sessions': sessions});
        }
        
        // Log session creation activity
        final activityLogService = ActivityLogService();
        await activityLogService.logSessionCreated(
          sessions.length.toString(),
          mode: isPresentation ? 'presentation' : 'interview',
        );
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in createSession: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> modes = [
      'Interview',
      'Presentation',
      'Real-Time Interview',  // VAPI-powered continuous interview
      'Avatar Interview',     // 3D Avatar + VAPI interview
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Mode"),
        backgroundColor: Styles.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Get.toNamed('/home');
          },
        ),
        actions: [
          PopupMenuButton<MenuOption>(
            onSelected: (item) => onSelected(context, item),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
              const PopupMenuItem<MenuOption>(
                value: MenuOption.logout,
                child: Text('Logout'),
              ),
            ],
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Text(
                        "Select Mode Type",
                        style: Styles.displayXlBoldStyle,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text(
                      "Select the type of mode you want to practice on",
                      style: Styles.displayMedLightStyle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField2<String>(
                        value: _selectedValue,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        hint: const Text(
                          'Select Mode Type',
                          style: TextStyle(fontSize: 14),
                        ),
                        items: modes
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select mode';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedValue = value;
                          });
                          ref.read(modeTypeProvider.notifier).state =
                              value ?? "Presentation";
                        },
                        onSaved: (value) {
                          _selectedValue = value.toString();
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.only(right: 8),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black45,
                          ),
                          iconSize: 24,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
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
                      text: "Next",
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });

                          bool sessionCreated = await createSession();

                          if (sessionCreated) {
                            final modeTypeValue =
                                ref.read(modeTypeProvider.notifier).state;
                            final isPresentation =
                                modeTypeValue == "Presentation";
                            final isRealTimeInterview = 
                                modeTypeValue == "Real-Time Interview";
                            
                            if (isPresentation) {
                              Get.to(
                                () => StartSessionScreen(
                                  isPresentation: isPresentation,
                                ),
                              );
                            } else if (isRealTimeInterview) {
                              // For Real-Time Interview, go to interview setup first
                              // Resume will be uploaded there, then navigate to VAPI
                              Get.toNamed("/interview_questions", arguments: {
                                'isRealTimeInterview': true,
                              });
                            } else if (modeTypeValue == 'Avatar Interview') {
                              // Avatar Interview: same flow as Real-Time but with 3D avatar
                              Get.toNamed("/interview_questions", arguments: {
                                'isRealTimeInterview': true,
                                'isAvatarInterview': true,
                              });
                            } else {
                              Get.toNamed("/interview_questions");
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Failed to create session. Please try again.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      color: Styles.primaryColor,
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
