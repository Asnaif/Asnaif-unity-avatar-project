// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// import 'package:interprep/screens/feedback/widgets/infocard.dart';

// class FeedBackScreen extends StatefulWidget {
//   @override
//   _FeedBackScreenState createState() => _FeedBackScreenState();
// }

// class _FeedBackScreenState extends State<FeedBackScreen> {
//   Map<dynamic, dynamic> _data = {};
//   bool isLoading = true;
//   bool isTextExpanded = false;
//   bool isRelevanceExpanded = false;
//   bool hasData = false;
//   String loadingMessage =
//       "Your session is ongoing. Please complete your session.";
//   final userId = FirebaseAuth.instance.currentUser!.uid;

//   @override
//   void initState() {
//     super.initState();
//     fetchData(userId);
//   }

//   Future<void> fetchData(String documentId) async {
//     try {
//       DocumentSnapshot snapshot = await FirebaseFirestore.instance
//           .collection('sessions')
//           .doc(documentId)
//           .get();

//       if (snapshot.exists && snapshot.data() != null) {
//         var sessionsData = snapshot.data() as Map<String, dynamic>;
//         var sessionsList = sessionsData['sessions'] as List<dynamic>;

//         if (sessionsList.isNotEmpty) {
//           var lastSession = sessionsList.last;

//           if (lastSession['audioFilePath'] == "") {
//             setState(() {
//               loadingMessage =
//                   "Your session is ongoing. Please complete your session.";
//               isLoading = true;
//               hasData = false;
//             });
//           } else {
//             var lastSessionReport = lastSession['reportGenerated'];
//             if (lastSessionReport != null) {
//               setState(() {
//                 _data = lastSessionReport;
//                 isLoading = false;
//                 hasData = true;
//               });
//             } else {
//               setState(() {
//                 loadingMessage = "Fetching Feedback, Hang Tight!";
//                 isLoading = true;
//                 hasData = false;
//               });
//             }
//           }
//         } else {
//           setState(() {
//             isLoading = false;
//             hasData = false;
//           });
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//           hasData = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         hasData = false;
//       });
//       print(e);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     String displayText = isTextExpanded
//         ? _data["text"]
//         : (_data["text"]?.length ?? 0) > 350
//             ? _data["text"].substring(0, 350) + "..."
//             : _data["text"] ?? "";

//     String relevanceText = isRelevanceExpanded
//         ? _data["relevance"].trim()
//         : (_data["relevance"]?.length ?? 0) > 340
//             ? _data["relevance"].trim().substring(0, 340) + "..."
//             : _data["relevance"]?.trim() ?? "";

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Session Feedback', style: TextStyle(color: Colors.white)),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body: isLoading || !hasData
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 10),
//                   Text(loadingMessage),
//                 ],
//               ),
//             )
//           : SingleChildScrollView(
//               child: Container(
//                 color: Color.fromRGBO(5, 38, 57, 1.000),
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       height: 20,
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(18.0),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               InfoCard(
//                                 title: 'Sentiment Score',
//                                 value: _data["sentiment_score"].toString(),
//                                 dialogInfo:
//                                     "Sentiment Score is a numerical value that represents the sentiment of the audio. The value ranges from -1 to 1. A value of 1 indicates a positive sentiment, a value of -1 indicates a negative sentiment, and a value of 0 indicates a neutral sentiment.",
//                               ),
//                               InfoCard(
//                                 title: 'Speech Rate',
//                                 value: _data["speech_rate"].toStringAsFixed(2),
//                                 dialogInfo:
//                                     "Speech Rate is the speed at which a person speaks. It is measured in words per minute (WPM).",
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               InfoCard(
//                                 title: 'Sentiment Class',
//                                 value: _data.isNotEmpty
//                                     ? _data["sentiment_class"].toString()
//                                     : 'N/A',
//                                 dialogInfo:
//                                     "Sentiment Class is a classification of the sentiment score. It can be either Positive, Negative, or Neutral.",
//                               ),
//                               InfoCard(
//                                 title: 'Vocab Difficulty',
//                                 value: _data.isNotEmpty
//                                     ? _data["difficulty_class"].toString()
//                                     : 'N/A',
//                                 dialogInfo:
//                                     "Vocabulary Difficulty is a classification of the vocabulary used in the audio. It can be either Easy, Medium, or Hard.",
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               InfoCard(
//                                 title: 'Pitch',
//                                 value: _data.isNotEmpty
//                                     ? _data["average_pitch"].toStringAsFixed(2)
//                                     : 'N/A',
//                                 dialogInfo:
//                                     "Pitch is the perceived frequency of a sound. It is measured in Hertz (Hz).",
//                               ),
//                               InfoCard(
//                                 title: 'Grade Level',
//                                 value: _data.isNotEmpty
//                                     ? _data["grade_level"].toStringAsFixed(2)
//                                     : 'N/A',
//                                 dialogInfo:
//                                     "Grade level represents the class standard who can understand this pitch",
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           if (_data.isNotEmpty)
//                             Card(
//                               color: Color.fromARGB(255, 244, 242, 234),
//                               child: Container(
//                                 padding: EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Relevance between Slide Content & Audio',
//                                       style: TextStyle(
//                                           color: Colors.black87,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15),
//                                     ),
//                                     SizedBox(height: 8),
//                                     Text(
//                                       relevanceText,
//                                       style: TextStyle(
//                                         color: Colors.black45,
//                                       ),
//                                     ),
//                                     TextButton(
//                                       onPressed: () {
//                                         setState(() {
//                                           isRelevanceExpanded =
//                                               !isRelevanceExpanded;
//                                         });
//                                       },
//                                       child: Text(
//                                         isRelevanceExpanded
//                                             ? "See Less"
//                                             : "See More",
//                                         style: TextStyle(
//                                             color: const Color.fromARGB(
//                                                 255, 145, 139, 139)),
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           SizedBox(height: 12),
//                           if (_data.isNotEmpty)
//                             Card(
//                               color: Color.fromRGBO(5, 38, 57, 1.000),
//                               shape: RoundedRectangleBorder(
//                                 side:
//                                     BorderSide(color: Colors.grey, width: 2.0),
//                                 borderRadius: BorderRadius.circular(12.0),
//                               ),
//                               child: Container(
//                                 width: double.infinity,
//                                 padding: EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Extracted Text from Audio',
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     SizedBox(height: 8),
//                                     Text(
//                                       displayText,
//                                       style: TextStyle(
//                                         color: Colors.white70,
//                                       ),
//                                     ),
//                                     TextButton(
//                                       onPressed: () {
//                                         setState(() {
//                                           isTextExpanded = !isTextExpanded;
//                                         });
//                                       },
//                                       child: Text(
//                                         isTextExpanded
//                                             ? "See Less"
//                                             : "See More",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interprep/screens/feedback/widgets/infocard.dart';

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

      final lastSession = sessions.last;
      reportData = lastSession['reportGenerated'];

      if (reportData == null) {
        setState(() {
          isLoading = false;
          hasData = false;
          loadingMessage = "Session not completed. Please finish your session.";
        });
        return;
      }

      setState(() {
        sentimentScore = (reportData!['sentiment_score'] ?? 0.0).toDouble();
        sentimentClass = reportData!['sentiment_class'] ?? "N/A";
        speechRate = (reportData!['speech_rate'] ?? 0.0).toDouble();
        vocabDifficulty = reportData!['difficulty_class'] ?? "N/A";
        pitch = (reportData!['average_pitch'] ?? 0.0).toDouble();
        gradeLevel = (reportData!['grade_level'] ?? 0).toInt();
        relevanceText =
            reportData!['relevance'] ?? "No relevance analysis available.";
        extractedText = reportData!['text'] ?? "No text extracted.";
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(loadingMessage),
            ],
          ),
        ),
      );
    }

    if (!hasData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session Feedback'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              Text(loadingMessage, textAlign: TextAlign.center),
            ],
          ),
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
