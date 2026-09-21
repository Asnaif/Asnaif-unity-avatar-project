# InterPrep - File Structure aur Purpose

## 📁 Project Directory Structure

```
InterPrep/
│
├── 📱 FLUTTER APP (Frontend)
│   ├── lib/
│   │   ├── main.dart                          ⭐ App entry point
│   │   │
│   │   ├── common/
│   │   │   └── constants/
│   │   │       ├── routes.dart                🛣️ All app routes
│   │   │       ├── theme.dart                 🎨 App theme
│   │   │       └── styles.dart                💅 UI styles
│   │   │
│   │   ├── models/
│   │   │   └── app_user.dart                  👤 User data model
│   │   │
│   │   ├── screens/                           📺 All app screens
│   │   │   ├── signup/
│   │   │   │   ├── ui_signup_screen.dart      ✍️ Sign up screen
│   │   │   │   └── provider/                  🔄 State management
│   │   │   │
│   │   │   ├── login/
│   │   │   │   ├── ui_login_screen.dart       🔐 Login screen
│   │   │   │   └── provider/                  🔄 State management
│   │   │   │
│   │   │   ├── start_session/
│   │   │   │   ├── ui_start_session.dart      📤 File upload screen
│   │   │   │   └── widgets/
│   │   │   │       ├── industry_selection/    🏢 Industry selection
│   │   │   │       └── mode_type/            🎯 Mode selection (Pres/Int)
│   │   │   │
│   │   │   ├── audio_upload/
│   │   │   │   └── ui_audio_upload_screen.dart 📤 Upload confirmation
│   │   │   │
│   │   │   ├── fetched_questions/
│   │   │   │   └── ui_fetch_questions_screen.dart ❓ Questions display
│   │   │   │
│   │   │   ├── practice_session/
│   │   │   │   └── practice_session_screen.dart 🎤 Practice session
│   │   │   │
│   │   │   └── feedback/
│   │   │       ├── ui_new_feedback_screen.dart 📊 Feedback display
│   │   │       └── widgets/
│   │   │           └── infocard.dart          📋 Metric cards
│   │   │
│   │   ├── services/
│   │   │   └── file_picker_service.dart       📁 File picking service
│   │   │
│   │   └── common/resources/widgets/          🧩 Reusable widgets
│   │       ├── buttons/
│   │       ├── textfields/
│   │       └── options/
│   │
│   ├── assets/
│   │   └── images/
│   │       └── logo.png                       🖼️ App logo
│   │
│   ├── android/                               🤖 Android config
│   │   └── app/
│   │       ├── google-services.json           🔥 Firebase config
│   │       └── src/main/
│   │
│   ├── ios/                                    🍎 iOS config
│   ├── web/                                    🌐 Web config
│   ├── windows/                               🪟 Windows config
│   ├── macos/                                  🍎 macOS config
│   │
│   ├── pubspec.yaml                           📦 Flutter dependencies
│   └── firebase.json                          🔥 Firebase config
│
│
├── 🐍 PYTHON SERVER (Backend)
│   └── python_server/
│       ├── server.py                          ⭐ Main Flask server
│       │
│       ├── questionGeneration.py             ❓ Presentation questions
│       ├── interviewQuestionGeneration.py    💼 Interview questions
│       ├── relevanceChecking.py              ✅ Relevance analysis
│       │
│       ├── textExtractionPDF.py              📄 PDF text extraction
│       ├── textExtractionPPTX.py              📊 PPTX text extraction
│       │
│       ├── textToSpeech.py                    🔊 Text-to-speech
│       ├── download_file.py                   ⬇️ File download
│       ├── lineSeparator.py                   📝 Text formatting
│       │
│       ├── pptx_to_png.py                     🖼️ PPTX to images
│       ├── pdf_to_image.py                    🖼️ PDF to image
│       │
│       ├── firebase_admin_instance.py         🔥 Firebase Admin SDK
│       │
│       ├── Audio_modules/                     🎵 Audio analysis
│       │   ├── stt.py                         🗣️ Speech-to-text
│       │   ├── pitch.py                       🎵 Pitch analysis
│       │   ├── sentiment.py                   😊 Sentiment analysis
│       │   ├── vocab_level.py                 📚 Vocabulary analysis
│       │   └── speechrate.py                  ⚡ Speech rate
│       │
│       ├── requirements.txt                   📦 Python dependencies
│       └── key.py                             🔑 API keys (not in git)
│
│
└── 📚 DOCUMENTATION
    ├── README.md                              📖 Project overview
    ├── ANDROID_SETUP.md                       🤖 Android setup guide
    ├── TASK_DIVISION.md                        👥 Team contributions
    ├── MILESTONES_ACHIEVED.md                 ✅ Completed features
    ├── FUTURE_PLANS.md                        🚀 Planned features
    ├── PROJECT_FLOW_DOCUMENTATION.md          📋 Detailed flow
    ├── PROJECT_FLOW_SUMMARY.md                📝 Quick summary
    └── FILE_STRUCTURE.md                      📁 This file
```

---

## 🎯 File Categories

### ⭐ Entry Points
- `lib/main.dart` - Flutter app start
- `python_server/server.py` - Flask server start

### 🛣️ Routing & Navigation
- `lib/common/constants/routes.dart` - All app routes

### 📺 UI Screens
- `lib/screens/*/ui_*.dart` - All user-facing screens

### 🔄 State Management
- `lib/screens/*/provider/*.dart` - Riverpod providers

### 🧩 Reusable Components
- `lib/common/resources/widgets/` - Custom widgets

### 🔌 Backend APIs
- `python_server/server.py` - API endpoints

### 🤖 AI/ML Processing
- `python_server/questionGeneration.py` - Question generation
- `python_server/relevanceChecking.py` - Relevance analysis
- `python_server/Audio_modules/*.py` - Audio analysis

### 📄 File Processing
- `python_server/textExtraction*.py` - Text extraction
- `python_server/*_to_*.py` - File conversion

### 🔥 Firebase Integration
- `lib/firebase_options.dart` - Flutter Firebase config
- `python_server/firebase_admin_instance.py` - Python Firebase

### 📦 Configuration
- `pubspec.yaml` - Flutter dependencies
- `requirements.txt` - Python dependencies
- `firebase.json` - Firebase project config

---

## 🔍 Important Files Detail

### Frontend (Flutter)

| File | Purpose | Key Function |
|------|---------|--------------|
| `main.dart` | App entry | Firebase init, routing setup |
| `routes.dart` | Navigation | All screen routes |
| `ui_signup_screen.dart` | Registration | User signup |
| `ui_login_screen.dart` | Authentication | User login |
| `ui_start_session.dart` | File upload | PDF/PPTX upload |
| `practice_session_screen.dart` | Practice | Questions, recording |
| `ui_new_feedback_screen.dart` | Feedback | Results display |
| `file_picker_service.dart` | File picking | Cross-platform file pick |

### Backend (Python)

| File | Purpose | Key Function |
|------|---------|--------------|
| `server.py` | Main server | API endpoints |
| `questionGeneration.py` | Questions | Presentation questions |
| `interviewQuestionGeneration.py` | Questions | Interview questions |
| `relevanceChecking.py` | Analysis | Content relevance |
| `textExtractionPDF.py` | Extraction | PDF text |
| `textExtractionPPTX.py` | Extraction | PPTX text |
| `stt.py` | Audio | Speech-to-text |
| `pitch.py` | Audio | Pitch analysis |
| `sentiment.py` | Audio | Sentiment analysis |
| `vocab_level.py` | Audio | Vocabulary analysis |
| `speechrate.py` | Audio | Speech rate |
| `textToSpeech.py` | Audio | TTS conversion |

---

## 📊 Data Flow Files

### User Input → Processing → Output

```
User Input Files:
├── PDF/PPTX (Presentation)
└── PDF Resume (Interview)
    ↓
Processing:
├── textExtractionPDF.py / textExtractionPPTX.py
├── questionGeneration.py / interviewQuestionGeneration.py
├── textToSpeech.py
└── pptx_to_png.py / pdf_to_image.py
    ↓
Output:
├── Questions (Text)
├── Question Audios (MP3)
└── Slide Images (PNG)
```

### Audio Recording → Analysis → Feedback

```
Audio Recording:
└── practice_session_screen.dart
    ↓
Processing:
├── download_file.py (Download from Firebase)
├── stt.py (Speech-to-text)
├── pitch.py (Pitch analysis)
├── sentiment.py (Sentiment analysis)
├── vocab_level.py (Vocabulary analysis)
├── speechrate.py (Speech rate)
└── relevanceChecking.py (Relevance)
    ↓
Output:
└── Complete feedback report
```

---

## 🔐 Configuration Files

### Firebase
- `android/app/google-services.json` - Android Firebase
- `ios/firebase_app_id_file.json` - iOS Firebase
- `firebase.json` - Firebase project config
- `lib/firebase_options.dart` - Flutter Firebase options

### Dependencies
- `pubspec.yaml` - Flutter packages
- `requirements.txt` - Python packages

### Platform Specific
- `android/` - Android native config
- `ios/` - iOS native config
- `web/` - Web config
- `windows/` - Windows config
- `macos/` - macOS config

---

## 🎨 UI Component Hierarchy

```
MyApp (main.dart)
└── GetMaterialApp
    └── Routes (routes.dart)
        ├── SignUpScreen
        ├── LoginScreen
        ├── IndustrySelectionScreen
        ├── ModeTypeScreen
        ├── StartSessionScreen
        ├── AudioUploadScreen
        ├── GeneratedQuestionsScreen
        ├── PracticeSessionScreen
        └── NewFeedBackScreen
```

---

## 🔄 API Flow Files

### Question Generation API
```
Flutter App
  ↓ (HTTP GET)
server.py (/api/extract)
  ↓
download_file.py → textExtractionPDF.py / textExtractionPPTX.py
  ↓
questionGeneration.py / interviewQuestionGeneration.py
  ↓
textToSpeech.py → upload_file_to_firebase()
  ↓
Firestore Update
  ↓
Response to Flutter
```

### Audio Processing API
```
Flutter App
  ↓ (HTTP POST)
server.py (/api/audio_processing)
  ↓
download_file.py → convert_audio_to_mp3()
  ↓
Audio_modules/stt.py
Audio_modules/pitch.py
Audio_modules/sentiment.py
Audio_modules/vocab_level.py
Audio_modules/speechrate.py
relevanceChecking.py
  ↓
Aggregation → Firestore Update
  ↓
Response to Flutter
```

---

Yeh complete file structure hai. Har file ka location aur purpose clearly mentioned hai!











