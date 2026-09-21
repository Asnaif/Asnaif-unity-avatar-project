# InterPrep - Quick Flow Summary (Urdu/Hindi)

## 🎯 Project Ka Maqsad

InterPrep ek **communication skills practice app** hai jo:
- **Presentation practice** karne mein madad karti hai (slides upload karke)
- **Interview practice** karne mein madad karti hai (resume upload karke)
- **AI-powered feedback** deti hai (pitch, sentiment, vocabulary, speech rate, relevance)

---

## 📱 App Flow (Simple)

### Step 1: Authentication
```
Sign Up → Email/Password → Firebase Auth → Login
```

### Step 2: Session Setup
```
Industry Selection → Mode Selection (Presentation/Interview)
```

### Step 3: File Upload
```
Presentation Mode: PDF/PPTX Upload
Interview Mode: Resume (PDF) Upload + JD/Position/Experience
```

### Step 4: Question Generation
```
Backend API Call → Text Extraction → OpenAI GPT → Questions Generate
→ Text-to-Speech → Audio Upload → Questions Display
```

### Step 5: Practice Session
```
Question Display → Audio Play → Record Answer → Upload Audio
→ Next Question → Repeat (5 questions)
```

### Step 6: Feedback
```
Backend API Call → Audio Analysis → Feedback Generate → Display Results
```

---

## 🗂️ Main Files aur Unka Kaam

### Flutter App (Frontend)

| File | Kaam |
|------|------|
| `lib/main.dart` | App start karta hai, Firebase initialize karta hai |
| `lib/common/constants/routes.dart` | Saare screens ke routes define karta hai |
| `lib/screens/signup/ui_signup_screen.dart` | User registration |
| `lib/screens/login/ui_login_screen.dart` | User login |
| `lib/screens/start_session/ui_start_session.dart` | File upload screen |
| `lib/screens/practice_session/practice_session_screen.dart` | Practice session (questions, recording) |
| `lib/screens/feedback/ui_new_feedback_screen.dart` | Feedback display |
| `lib/services/file_picker_service.dart` | File pick karta hai (web/mobile) |

### Python Server (Backend)

| File | Kaam |
|------|------|
| `python_server/server.py` | Main Flask server, APIs handle karta hai |
| `python_server/questionGeneration.py` | Presentation questions generate karta hai |
| `python_server/interviewQuestionGeneration.py` | Interview questions generate karta hai |
| `python_server/relevanceChecking.py` | Content relevance check karta hai |
| `python_server/textExtractionPDF.py` | PDF se text extract karta hai |
| `python_server/textExtractionPPTX.py` | PPTX se text extract karta hai |
| `python_server/Audio_modules/stt.py` | Speech-to-text (audio se text) |
| `python_server/Audio_modules/pitch.py` | Pitch analysis (voice ka pitch) |
| `python_server/Audio_modules/sentiment.py` | Sentiment analysis (positive/negative) |
| `python_server/Audio_modules/vocab_level.py` | Vocabulary difficulty check |
| `python_server/Audio_modules/speechrate.py` | Speech rate calculate (words per minute) |

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER JOURNEY                            │
└─────────────────────────────────────────────────────────────┘

1. SIGN UP / LOGIN
   ├─ lib/screens/signup/ui_signup_screen.dart
   └─ lib/screens/login/ui_login_screen.dart
        ↓
2. INDUSTRY SELECTION
   └─ lib/screens/start_session/widgets/industry_selection/
        ↓
3. MODE SELECTION
   ├─ Presentation Mode
   │   └─ lib/screens/start_session/widgets/mode_type/
   │        ↓
   │   4. FILE UPLOAD (PDF/PPTX)
   │      └─ lib/screens/start_session/ui_start_session.dart
   │           └─ Firebase Storage Upload
   │                ↓
   │   5. QUESTION GENERATION
   │      └─ Backend API: /api/extract
   │           ├─ Text Extraction (PDF/PPTX)
   │           ├─ OpenAI GPT (Questions)
   │           ├─ Text-to-Speech
   │           └─ Firebase Upload
   │                ↓
   │   6. PRACTICE SESSION
   │      └─ lib/screens/practice_session/practice_session_screen.dart
   │           ├─ Questions Display
   │           ├─ Audio Playback
   │           ├─ Slide Images (Presentation)
   │           ├─ Audio Recording
   │           └─ Firebase Upload
   │                ↓
   │   7. FEEDBACK GENERATION
   │      └─ Backend API: /api/audio_processing
   │           ├─ Speech-to-Text
   │           ├─ Pitch Analysis
   │           ├─ Sentiment Analysis
   │           ├─ Vocabulary Analysis
   │           ├─ Speech Rate
   │           └─ Relevance Checking
   │                ↓
   │   8. FEEDBACK DISPLAY
   │      └─ lib/screens/feedback/ui_new_feedback_screen.dart
   │
   └─ Interview Mode
       └─ lib/screens/start_session/widgets/mode_type/
            ↓
        4. INTERVIEW DETAILS (JD, Position, Experience)
            ↓
        5. RESUME UPLOAD (PDF)
           └─ Firebase Storage Upload
                ↓
        6. QUESTION GENERATION
           └─ Backend API: /api/extract
                ├─ Text Extraction (PDF)
                ├─ OpenAI GPT (Interview Questions)
                ├─ Text-to-Speech
                └─ Firebase Upload
                     ↓
        7. PRACTICE SESSION
           └─ lib/screens/practice_session/practice_session_screen.dart
                ├─ Questions Display
                ├─ Audio Playback
                ├─ Audio Recording
                └─ Firebase Upload
                     ↓
        8. FEEDBACK GENERATION
           └─ Backend API: /api/audio_processing
                ├─ Speech-to-Text
                ├─ Pitch Analysis
                ├─ Sentiment Analysis
                ├─ Vocabulary Analysis
                ├─ Speech Rate
                └─ Relevance Checking (Question vs Answer)
                     ↓
        9. FEEDBACK DISPLAY
           └─ lib/screens/feedback/ui_new_feedback_screen.dart
```

---

## 🔌 Backend API Endpoints

### 1. `/api/extract` (GET)
**Input**: File ID, User ID, Mode (Interview/Presentation), Interview details (optional)
**Process**:
- File download (Firebase Storage)
- Text extraction (PDF/PPTX)
- Question generation (OpenAI GPT)
- Text-to-speech (Google TTS)
- Audio upload (Firebase Storage)
- Slide images (Presentation mode)

**Output**: Questions list, Audio URLs, Extracted text

### 2. `/api/audio_processing` (POST)
**Input**: Audio file path, User ID
**Process**:
- Session data fetch (Firestore)
- Audio download (Firebase Storage)
- Audio conversion (MP3)
- Speech-to-text (Vosk)
- Pitch analysis (librosa + pyworld)
- Sentiment analysis (NLTK VADER)
- Vocabulary analysis (textstat)
- Speech rate calculation
- Relevance checking (OpenAI GPT)
- Aggregation (all responses)

**Output**: Complete feedback report (pitch, sentiment, vocabulary, speech rate, relevance)

---

## 💾 Data Storage

### Firebase Firestore Collections:

1. **`users`**: User profiles
2. **`files`**: Uploaded files metadata
3. **`sessions`**: Practice sessions
   - Questions generated
   - Recorded responses
   - Feedback reports
4. **`questionAudios`**: Question audio URLs
5. **`slideImages`**: Slide images (Presentation mode)

### Firebase Storage:
- **`QuestionAudios/`**: Question audio files
- **`responses/`**: User recorded audio
- **`files/`**: Uploaded PDF/PPTX files

---

## 🎨 UI Components

### Screens:
- Sign Up / Login
- Industry Selection
- Mode Selection
- File Upload
- Question Display
- Practice Session
- Feedback Display

### Reusable Widgets:
- `app_text_button.dart`: Custom buttons
- `app_text_field.dart`: Custom text fields
- `optionsContainer.dart`: Options selection
- `infocard.dart`: Metric display cards

---

## 🔧 Technologies Used

### Frontend:
- Flutter (Dart)
- GetX (Navigation)
- Riverpod (State Management)
- Firebase (Auth, Firestore, Storage)
- record (Audio Recording)
- audioplayers (Audio Playback)
- file_picker (File Selection)

### Backend:
- Python Flask
- OpenAI GPT-3.5
- Vosk (Speech-to-Text)
- librosa + pyworld (Audio Analysis)
- NLTK (Sentiment Analysis)
- textstat (Vocabulary Analysis)
- Firebase Admin SDK

---

## ⚙️ Setup Requirements

1. **Flutter SDK** installed
2. **Python 3.x** with virtual environment
3. **FFmpeg** installed (audio processing ke liye)
4. **Vosk Model** downloaded (speech-to-text ke liye)
5. **OpenAI API Key** (`python_server/key.py` mein)
6. **Firebase Project** configured
7. **Google Services JSON** (Android ke liye)

---

## 📊 Feedback Metrics

1. **Average Pitch**: Voice ka average pitch (Hz)
2. **Sentiment Score**: -1 (Negative) to +1 (Positive)
3. **Sentiment Class**: Positive / Neutral / Negative
4. **Vocabulary Grade Level**: Education level (1-12)
5. **Difficulty Class**: Easy / Medium / Hard
6. **Speech Rate**: Words per minute (WPM)
7. **Relevance Analysis**: Detailed paragraphs about content relevance

---

## 🎯 Key Features

✅ Dual Mode (Presentation + Interview)
✅ AI-Powered Question Generation
✅ Real-time Audio Recording
✅ Comprehensive Audio Analysis
✅ Detailed Feedback Reports
✅ Cross-platform Support (Web, Android, iOS)
✅ Firebase Integration
✅ Secure Authentication

---

Yeh quick summary hai. Detailed documentation ke liye `PROJECT_FLOW_DOCUMENTATION.md` file dekhiye!











