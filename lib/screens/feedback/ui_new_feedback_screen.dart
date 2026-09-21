// import 'package:firebase_auth/firebase_auth.dart';
// Duplicate imports removed

// import 'package:interprep/screens/feedback/widgets/infocard.dart';

// class NewFeedBackScreen extends StatefulWidget {
//   @override
//   _NewFeedBackScreenState createState() => _NewFeedBackScreenState();
// }

// class _NewFeedBackScreenState extends State<NewFeedBackScreen> {
//   bool isLoading = true;
//   bool isTextExpanded = false;
//   bool isRelevanceExpanded = false;
//   bool hasData = false;
//   String loadingMessage =
//       "Your session is ongoing. Please complete your session.";
//   final userId = FirebaseAuth.instance.currentUser!.uid;

//   @override
//   Widget build(BuildContext context) {
//     String relevanceTextExtracted =
//         "In your presentation, the inclusion of memory-mapped files speaks directly to the core of modern computing architectures and their efficiency. Memory-mapped files provide a crucial mechanism for programs to interact with files as if they were portions of the computer's memory. This concept aligns perfectly with the contemporary emphasis on optimizing data access and manipulation for improved performance. By mapping files into memory, applications can seamlessly read from and write to disk-resident data with the same ease and speed as if it were already loaded into memory. This approach not only simplifies programming tasks but also leverages the underlying hardware's capabilities more effectively, enhancing overall system performance. Furthermore, memory-mapped files facilitate interprocess communication and data sharing, enabling collaborative computing environments and streamlined workflows. Thus, the inclusion of memory-mapped files in your presentation underscores the importance of leveraging innovative techniques to maximize computational efficiency and enhance the user experience in modern computing environments.";

//     String relevanceText = isRelevanceExpanded
//         ? relevanceTextExtracted
//         : relevanceTextExtracted.length > 200
//             ? relevanceTextExtracted.trim().substring(0, 340) + "..."
//             : relevanceTextExtracted.trim();

//     List<String> answers = [
//       "1) That was a clear and concise explanation of the difference between private and shared memory mapped files. You highlighted the main differences and benefits of each type effectively. Great job!",
//       "2) Thank you for providing a detailed explanation of the `mmap()` function and its required arguments. Your answer was informative and well-organized. However, it would have been more helpful to also mention the purpose or benefits of using the `mmap()` function in a mockup interview scenario.",
//       "3) Great answer! You have properly explained the purpose and working of the `mmap()` function. You have also mentioned all the necessary arguments required when using it. Keep up the good work!",
//       "4) Great job explaining the concept of persisted and non-persisted memory mapped files! Your explanation is clear and concise, and you have provided a useful comparison between the two. It's important to consider performance needs and data durability when choosing between the two options, and you have effectively highlighted this. Keep up the good work!",
//       "5) Great response! You have clearly explained the difference between persisted and non-persisted memory-mapped files, as well as their importance in an application. Your answer is informative and easy to understand. Keep up the good work!"
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Session Feedback', style: TextStyle(color: Colors.white)),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: SingleChildScrollView(
//         child: Container(
//           color: Color.fromRGBO(5, 38, 57, 1.000),
//           child: Column(
//             children: [
//               SizedBox(
//                 height: 20,
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         InfoCard(
//                           title: 'Sentiment Score',
//                           value: "0.2",
//                           dialogInfo:
//                               "Sentiment Score is a numerical value that represents the sentiment of the audio. The value ranges from -1 to 1. A value of 1 indicates a positive sentiment, a value of -1 indicates a negative sentiment, and a value of 0 indicates a neutral sentiment.",
//                         ),
//                         InfoCard(
//                           title: 'Speech Rate',
//                           value: "54.0",
//                           dialogInfo:
//                               "Speech Rate is the speed at which a person speaks. It is measured in words per minute (WPM).",
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         InfoCard(
//                           title: 'Sentiment Class',
//                           value: "Neutral",
//                           dialogInfo:
//                               "Sentiment Class is a classification of the sentiment score. It can be either Positive, Negative, or Neutral.",
//                         ),
//                         InfoCard(
//                           title: 'Vocab Difficulty',
//                           value: "Easy",
//                           dialogInfo:
//                               "Vocabulary Difficulty is a classification of the vocabulary used in the audio. It can be either Easy, Medium, or Hard.",
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         InfoCard(
//                           title: 'Pitch',
//                           value: "148.09",
//                           dialogInfo:
//                               "Pitch is the perceived frequency of a sound. It is measured in Hertz (Hz).",
//                         ),
//                         InfoCard(
//                           title: 'Grade Level',
//                           value: "5",
//                           dialogInfo:
//                               "Grade level represents the class standard who can understand this pitch",
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 12),
//                     Card(
//                       color: Color.fromARGB(255, 244, 242, 234),
//                       child: Container(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Relevance between Slide Content & Audio',
//                               style: TextStyle(
//                                   color: Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               relevanceText,
//                               style: TextStyle(
//                                 color: Colors.black45,
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   isRelevanceExpanded = !isRelevanceExpanded;
//                                 });
//                               },
//                               child: Text(
//                                 isRelevanceExpanded ? "See Less" : "See More",
//                                 style: TextStyle(
//                                     color: const Color.fromARGB(
//                                         255, 145, 139, 139)),
//                               ),
//                             )
//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Card(
//                       color: Color.fromARGB(255, 244, 242, 234),
//                       child: Container(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Evaluation of Questions Answered',
//                               style: TextStyle(
//                                   color: Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15),
//                             ),
//                             SizedBox(height: 8),
//                             SingleChildScrollView(
//                               scrollDirection: Axis.vertical,
//                               child: SizedBox(
//                                 height:
//                                     300,
//                                 child: ListView.builder(
//                                   shrinkWrap: true,
//                                   itemCount: answers.length,
//                                   itemBuilder: (context, index) {
//                                     return Padding(
//                                       padding: const EdgeInsets.only(bottom: 8),
//                                       child: Text(
//                                         answers[index],
//                                         style: TextStyle(
//                                           color: Colors.black45,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),

//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Card(
//                       color: Color.fromRGBO(5, 38, 57, 1.000),
//                       shape: RoundedRectangleBorder(
//                         side: BorderSide(color: Colors.grey, width: 2.0),
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                       child: Container(
//                         width: double.infinity,
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Extracted Text from Audio',
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               "Memory Mapped Files is an important concept in Operating System where we interact with files as if they are part of the memory. This concept..",
//                               style: TextStyle(
//                                 color: Colors.white70,
//                               ),
//                             ),
//                             // TextButton(
//                             //   onPressed: () {
//                             //     setState(() {
//                             //       isTextExpanded = !isTextExpanded;
//                             //     });
//                             //   },
//                             //   child: Text(
//                             //     isTextExpanded ? "See Less" : "See More",
//                             //     style: TextStyle(color: Colors.white),
//                             //   ),
//                             // ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:interprep/screens/feedback/widgets/infocard.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';

class NewFeedBackScreen extends StatefulWidget {
  const NewFeedBackScreen({super.key});

  @override
  _NewFeedBackScreenState createState() => _NewFeedBackScreenState();
}

class _NewFeedBackScreenState extends State<NewFeedBackScreen> {
  bool isLoading = true;
  bool isRelevanceExpanded = false;
  bool hasData = false;
  String loadingMessage = "Loading your feedback...";
  
  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please login again.');
    }
    return user.uid;
  }

  // Real data from Firestore
  Map<String, dynamic>? reportData;
  String relevanceText = "";
  String extractedText = "";
  double sentimentScore = 0.0;
  String sentimentClass = "";
  double speechRate = 0.0;
  String vocabDifficulty = "";
  double pitch = 0.0;
  int gradeLevel = 0;

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  Future<void> _loadFeedbackData() async {
    try {
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      final targetSessionId = args['sessionId'] as String?;

      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(userId)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
          hasData = false;
          loadingMessage = "No session found.";
        });
        return;
      }

      final sessions = List.from(doc.data()!['sessions'] ?? []);
      if (sessions.isEmpty) {
        setState(() {
          isLoading = false;
          hasData = false;
          loadingMessage = "No sessions completed yet.";
        });
        return;
      }

      Map<String, dynamic>? targetSession;
      if (targetSessionId != null && targetSessionId.isNotEmpty) {
        try {
          targetSession = sessions.firstWhere(
            (s) => s is Map && (s['id'] == targetSessionId || (s['createdAt'] != null && 'reg_${DateTime.parse(s['createdAt']).millisecondsSinceEpoch}' == targetSessionId)),
          ) as Map<String, dynamic>?;
        } catch (_) {
          // Fallback if not found by ID
        }
      }

      // Fallback to the last completed session with a report
      if (targetSession == null) {
        try {
          targetSession = sessions.lastWhere(
            (s) => s is Map && s['status'] == 'completed' && s['reportGenerated'] != null && s['reportGenerated'] != "",
          ) as Map<String, dynamic>?;
        } catch (_) {
          // Fallback to absolute last session
          targetSession = sessions.last as Map<String, dynamic>?;
        }
      }

      if (targetSession == null) {
        setState(() {
          isLoading = false;
          hasData = false;
          loadingMessage = "No completed session found.";
        });
        return;
      }

      reportData = targetSession['reportGenerated'] is Map
          ? Map<String, dynamic>.from(targetSession['reportGenerated'])
          : null;

      if (reportData == null || reportData!.isEmpty) {
        setState(() {
          isLoading = false;
          hasData = false;
          loadingMessage = "Session not completed. Please finish your session.";
        });
        return;
      }

      setState(() {
        sentimentScore = (reportData!['sentiment_score'] ?? reportData!['averageSentiment'] ?? 0.0).toDouble();
        sentimentClass = reportData!['sentiment_class'] ?? reportData!['averageSentimentClass'] ?? "N/A";
        speechRate = (reportData!['speech_rate'] ?? reportData!['averageSpeechRate'] ?? 0.0).toDouble();
        vocabDifficulty = reportData!['difficulty_class'] ?? reportData!['averageVocabLevel'] ?? "N/A";
        pitch = (reportData!['average_pitch'] ?? reportData!['averagePitch'] ?? 0.0).toDouble();
        gradeLevel = (reportData!['grade_level'] ?? reportData!['averageGradeLevel'] ?? 0).toInt();
        relevanceText =
            reportData!['relevance'] ?? reportData!['averageRelevance']?.toString() ?? "No relevance analysis available.";
        extractedText = reportData!['text'] ?? reportData!['extractedText'] ?? "No text extracted.";
        hasData = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading feedback: $e");
      setState(() {
        isLoading = false;
        hasData = false;
        loadingMessage = "Error loading feedback: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session Feedback'),
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back();
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: SkeletonLoader(width: 100, height: 120, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 12),
                Expanded(child: SkeletonLoader(width: 100, height: 120, borderRadius: BorderRadius.circular(12))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonLoader(width: 100, height: 120, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 12),
                Expanded(child: SkeletonLoader(width: 100, height: 120, borderRadius: BorderRadius.circular(12))),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonLoader(width: double.infinity, height: 150, borderRadius: BorderRadius.circular(12)),
            const SizedBox(height: 12),
            SkeletonLoader(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(12)),
          ],
        ),
      );
    }

    if (!hasData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session Feedback'),
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back();
            },
          ),
        ),
        body: EmptyStateWidget(
          icon: Icons.info_outline,
          title: 'No Feedback Available',
          message: loadingMessage,
          iconColor: Colors.grey,
        ),
      );
    }

    String displayRelevance = isRelevanceExpanded
        ? relevanceText
        : (relevanceText.length > 340
            ? "${relevanceText.substring(0, 340)}..."
            : relevanceText);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to practice session screen
            Get.back();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color.fromRGBO(5, 38, 57, 1.000),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InfoCard(
                          title: 'Sentiment Score',
                          value: sentimentScore.toStringAsFixed(2),
                          dialogInfo:
                              "Sentiment Score is a numerical value that represents the sentiment of the audio. The value ranges from -1 to 1. A value of 1 indicates a positive sentiment, a value of -1 indicates a negative sentiment, and a value of 0 indicates a neutral sentiment.",
                        ),
                        InfoCard(
                          title: 'Speech Rate',
                          value: speechRate.toStringAsFixed(1),
                          dialogInfo:
                              "Speech Rate is the speed at which a person speaks. It is measured in words per minute (WPM).",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InfoCard(
                          title: 'Sentiment Class',
                          value: sentimentClass,
                          dialogInfo:
                              "Sentiment Class is a classification of the sentiment score. It can be either Positive, Negative, or Neutral.",
                        ),
                        InfoCard(
                          title: 'Vocab Difficulty',
                          value: vocabDifficulty,
                          dialogInfo:
                              "Vocabulary Difficulty is a classification of the vocabulary used in the audio. It can be either Easy, Medium, or Hard.",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InfoCard(
                          title: 'Pitch',
                          value: pitch.toStringAsFixed(2),
                          dialogInfo:
                              "Pitch is the perceived frequency of a sound. It is measured in Hertz (Hz).",
                        ),
                        InfoCard(
                          title: 'Grade Level',
                          value: gradeLevel.toString(),
                          dialogInfo:
                              "Grade level represents the class standard who can understand this vocabulary complexity.",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color.fromARGB(255, 244, 242, 234),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Relevance Analysis',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              displayRelevance,
                              style: const TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                            if (relevanceText.length > 340)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isRelevanceExpanded = !isRelevanceExpanded;
                                  });
                                },
                                child: Text(
                                  isRelevanceExpanded ? "See Less" : "See More",
                                  style: const TextStyle(
                                      color: Color.fromARGB(
                                          255, 145, 139, 139)),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color.fromRGBO(5, 38, 57, 1.000),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey, width: 2.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Extracted Text from Audio',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              extractedText,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
