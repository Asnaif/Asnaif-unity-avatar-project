# InterPrep Project - Complete Flow aur File Documentation

## 📋 Project Overview

**InterPrep** ek Flutter-based mobile/web application hai jo communication skills improve karne ke liye banaya gaya hai. Yeh app do modes support karti hai:
1. **Presentation Mode**: Users apne slides (PDF/PPTX) upload karke presentation practice karte hain
2. **Interview Mode**: Users apna resume upload karke interview questions practice karte hain

App AI-powered feedback deti hai jo pitch, sentiment, vocabulary level, speech rate, aur relevance analyze karti hai.

---

## 🏗️ Project Architecture

### Tech Stack:
- **Frontend**: Flutter (Dart)
- **Backend**: Python Flask Server
- **Database**: Firebase Firestore
- **Storage**: Firebase Storage
- **Authentication**: Firebase Auth
- **AI/ML**: OpenAI GPT, Vosk STT, librosa, pyworld, NLTK

---

## 📁 Project Structure aur File Flow

### 1. **Entry Point - `lib/main.dart`**

**Purpose**: App ka entry point hai. Yeh file:
- Firebase initialize karti hai
- App routing setup karti hai
- Initial route set karti hai (`/signup`)
- Theme configuration load karti hai

**Flow**:
```
main() → Firebase.initializeApp() → MyApp() → GetMaterialApp() → Routes
```

---

### 2. **Routing - `lib/common/constants/routes.dart`**

**Purpose**: App ke saare routes define karta hai. Yeh file:
- GetX navigation use karta hai
- Har screen ka route define karta hai
- Screen transitions handle karta hai

**Routes**:
- `/signup` → SignUpScreen
- `/login` → LoginScreen
- `/industry_selection` → IndustrySelectionScreen
- `/mode_type` → ModeTypeScreen (Presentation/Interview)
- `/audio_upload` → AudioUploadScreen
- `/generated_questions` → GeneratedQuestionsScreen
- `/feedback` → NewFeedBackScreen
- `/practice_session` → PracticeSessionScreen
- `/start_session` → StartSessionScreen

---

### 3. **Authentication Screens**

#### `lib/screens/signup/ui_signup_screen.dart`
**Purpose**: User registration screen
- Email, password, name input leta hai
- Firebase Auth se user create karta hai
- Success par `/login` route par redirect karta hai

#### `lib/screens/login/ui_login_screen.dart`
**Purpose**: User login screen
- Email/password se login karta hai
- Success par `/industry_selection` par redirect karta hai

**Provider Files** (State Management):
- `lib/screens/signup/provider/*.dart` - Text controllers for signup form
- `lib/screens/login/provider/*.dart` - Text controllers for login form

---

### 4. **Session Creation Flow**

#### `lib/screens/start_session/widgets/industry_selection/ui_industry_selection.dart`
**Purpose**: Industry selection screen
- User ko industry select karne deta hai
- Next par `/mode_type` route par jata hai

#### `lib/screens/start_session/widgets/mode_type/ui_mode_type_screen.dart`
**Purpose**: Mode selection screen (Presentation ya Interview)
- User ko mode select karne deta hai
- Interview mode: JD, Position, Experience input leta hai
- Presentation mode: Direct file upload screen par jata hai
- Session create karta hai Firestore mein

**Flow**:
```
Mode Selection → createSession() → Firestore 'sessions' collection update
```

---

### 5. **File Upload Flow**

#### `lib/screens/start_session/ui_start_session.dart`
**Purpose**: File upload screen (Presentation mode ke liye)
- PDF/PPTX file pick karta hai
- File ko Firebase Storage mein upload karta hai
- File metadata Firestore 'files' collection mein save karta hai
- `/audio_upload` route par redirect karta hai

#### `lib/services/file_picker_service.dart`
**Purpose**: Cross-platform file picking service
- Web aur mobile dono platforms par kaam karta hai
- Web: bytes use karta hai
- Mobile: file path use karta hai

---

### 6. **Question Generation Flow**

#### `lib/screens/audio_upload/ui_audio_upload_screen.dart`
**Purpose**: File upload confirmation screen
- Uploaded file display karta hai
- "Generate Questions" button se backend API call karta hai
- `/generated_questions` route par redirect karta hai

#### `lib/screens/fetched_questions/ui_fetch_questions_screen.dart`
**Purpose**: Generated questions display screen
- Backend se questions fetch karta hai
- Questions list display karta hai
- "Start Practice" button se `/practice_session` route par jata hai

---

### 7. **Backend API - `python_server/server.py`**

**Purpose**: Main Flask server jo saare backend operations handle karta hai

#### API Endpoints:

##### 1. `/api/extract` (GET)
**Purpose**: Questions generate karta hai

**Flow**:
```
Request → Firestore se file URL fetch → File download → Text extraction
→ Question generation (OpenAI GPT) → Text-to-Speech → Firebase upload
→ Response with questions + audio URLs
```

**Process**:
1. File download (`download_file.py`)
2. Text extraction:
   - PDF: `textExtractionPDF.py` → PyPDFLoader
   - PPTX: `textExtractionPPTX.py` → UnstructuredPowerPointLoader
3. Question generation:
   - Presentation: `questionGeneration.py` → GPT-3.5-turbo-instruct
   - Interview: `interviewQuestionGeneration.py` → GPT-3.5-turbo-instruct (JD/Position/Experience ke saath)
4. Text-to-Speech: `textToSpeech.py` → Google TTS
5. Audio upload: Firebase Storage
6. Slide images (Presentation mode):
   - PPTX: `pptx_to_png.py` → All slides to PNG
   - PDF: `pdf_to_image.py` → First page to PNG

##### 2. `/api/audio_processing` (POST)
**Purpose**: User ke recorded audio ko analyze karta hai

**Flow**:
```
Request → Firestore se session data fetch → Audio download → Audio conversion (MP3)
→ Speech-to-Text → Pitch analysis → Sentiment analysis → Vocabulary analysis
→ Speech rate calculation → Relevance checking → Aggregation → Firestore update
→ Response with complete feedback
```

**Process**:
1. Audio download: Firebase Storage se
2. Audio conversion: MP3 format (ffmpeg use karta hai)
3. Speech-to-Text: `Audio_modules/stt.py` → Vosk model
4. Pitch analysis: `Audio_modules/pitch.py` → librosa + pyworld
5. Sentiment analysis: `Audio_modules/sentiment.py` → NLTK VADER
6. Vocabulary analysis: `Audio_modules/vocab_level.py` → textstat
7. Speech rate: `Audio_modules/speechrate.py` → Text + Audio duration
8. Relevance checking: `relevanceChecking.py` → OpenAI GPT
   - Interview mode: Question vs Answer
   - Presentation mode: Question + Answer vs Slide content
9. Aggregation: Saare responses ka average calculate
10. Firestore update: `reportGenerated` field mein save

---

### 8. **Practice Session Screen**

#### `lib/screens/practice_session/practice_session_screen.dart`
**Purpose**: Main practice session screen jo user ko questions practice karne deta hai

**Features**:
- Questions display (Firestore se fetch)
- Question audio playback (Firebase Storage se)
- Slide images display (Presentation mode mein)
- Audio recording (record package use karta hai)
- Recording duration timer
- Next/Previous question navigation
- Audio upload to Firebase Storage
- Response save to Firestore

**Flow**:
```
Load Session → Fetch Questions → Fetch Audio URLs → Fetch Slide Images
→ Display Question → Play Audio → Record Answer → Upload Audio
→ Save to Firestore → Next Question → Repeat
```

**State Management**:
- `currentQuestionIndex`: Current question track karta hai
- `currentSlideIndex`: Current slide track karta hai (Presentation mode)
- `isRecording`: Recording state
- `recordedAudioUrls`: Recorded audio URLs map

---

### 9. **Feedback Screen**

#### `lib/screens/feedback/ui_new_feedback_screen.dart`
**Purpose**: Complete feedback display screen

**Features**:
- Average pitch display
- Sentiment score aur classification
- Vocabulary difficulty level
- Speech rate
- Relevance analysis (detailed paragraphs)
- Individual question responses
- Visual cards for each metric

**Flow**:
```
Load Session → Check reportGenerated → Display Metrics → Show Individual Responses
```

**Widgets**:
- `lib/screens/feedback/widgets/infocard.dart`: Metric display card

---

### 10. **Python Server Modules**

#### Text Extraction:
- **`textExtractionPDF.py`**: PDF se text extract karta hai (PyPDFLoader)
- **`textExtractionPPTX.py`**: PPTX se text extract karta hai (UnstructuredPowerPointLoader)

#### Question Generation:
- **`questionGeneration.py`**: Presentation mode ke liye questions generate karta hai
  - GPT-3.5-turbo-instruct use karta hai
  - Slide content se 5 questions generate karta hai
  - QA session ke liye relevant questions

- **`interviewQuestionGeneration.py`**: Interview mode ke liye questions generate karta hai
  - Resume content + JD + Position + Experience use karta hai
  - Technical HR questions generate karta hai

#### Audio Processing:
- **`textToSpeech.py`**: Questions ko audio mein convert karta hai
  - Google TTS use karta hai
  - MP3 format mein save karta hai

#### Audio Analysis Modules (`Audio_modules/`):
- **`stt.py`**: Speech-to-Text transcription
  - Vosk model use karta hai
  - MP3/WAV se text extract karta hai

- **`pitch.py`**: Pitch analysis
  - librosa + pyworld use karta hai
  - Average pitch calculate karta hai
  - Voiced regions detect karta hai

- **`sentiment.py`**: Sentiment analysis
  - NLTK VADER use karta hai
  - Sentiment score (-1 to 1) aur classification (Positive/Neutral/Negative)

- **`vocab_level.py`**: Vocabulary difficulty analysis
  - textstat library use karta hai
  - Grade level calculate karta hai
  - Difficulty classification (Easy/Medium/Hard)

- **`speechrate.py`**: Speech rate calculation
  - Text length aur audio duration se calculate karta hai
  - Words per minute (WPM) return karta hai

#### Relevance Checking:
- **`relevanceChecking.py`**: Content relevance analysis
  - OpenAI GPT-3.5-turbo use karta hai
  - Interview mode: Question vs Answer alignment
  - Presentation mode: Question + Answer vs Slide content alignment
  - Detailed analysis paragraphs return karta hai

#### File Processing:
- **`download_file.py`**: Firebase Storage se files download karta hai
- **`pptx_to_png.py`**: PPTX slides ko PNG images mein convert karta hai
- **`pdf_to_image.py`**: PDF ke first page ko PNG image mein convert karta hai
- **`lineSeparator.py`**: Text ko properly format karta hai

#### Firebase Integration:
- **`firebase_admin_instance.py`**: Firebase Admin SDK initialize karta hai
  - Firestore instance
  - Storage bucket instance

---

### 11. **Models**

#### `lib/models/app_user.dart`
**Purpose**: User data model
- name, email, password fields

---

### 12. **Common Components**

#### `lib/common/constants/theme.dart`
**Purpose**: App theme configuration
- Light theme colors, fonts, styles

#### `lib/common/constants/styles.dart`
**Purpose**: Common UI styles
- Button styles, text styles, etc.

#### `lib/common/resources/widgets/`
**Purpose**: Reusable UI components
- **`buttons/app_text_button.dart`**: Custom text button
- **`textfields/app_text_field.dart`**: Custom text field
- **`options/optionsContainer.dart`**: Options selection container

---

### 13. **Configuration Files**

#### `pubspec.yaml`
**Purpose**: Flutter dependencies aur project configuration
- Dependencies: Firebase, GetX, Riverpod, file_picker, record, audioplayers, etc.
- Assets configuration
- App metadata

#### `requirements.txt`
**Purpose**: Python dependencies
- Flask, OpenAI, librosa, pyworld, vosk, NLTK, etc.

#### `firebase.json`
**Purpose**: Firebase project configuration

#### `android/app/google-services.json`
**Purpose**: Android Firebase configuration

---

## 🔄 Complete User Flow

### Presentation Mode Flow:
```
1. Sign Up / Login
2. Industry Selection
3. Mode Selection → Presentation
4. File Upload (PDF/PPTX)
5. File Upload Confirmation
6. Question Generation (Backend API call)
7. Generated Questions Display
8. Practice Session:
   - Question display
   - Audio playback
   - Slide images display
   - Audio recording
   - Next question
9. All Questions Complete
10. Feedback Generation (Backend API call)
11. Feedback Display
```

### Interview Mode Flow:
```
1. Sign Up / Login
2. Industry Selection
3. Mode Selection → Interview
4. Interview Details Input (JD, Position, Experience)
5. Resume Upload (PDF)
6. Question Generation (Backend API call)
7. Generated Questions Display
8. Practice Session:
   - Question display
   - Audio playback
   - Audio recording
   - Next question
9. All Questions Complete
10. Feedback Generation (Backend API call)
11. Feedback Display
```

---

## 🔧 Backend Processing Flow

### Question Generation Process:
```
1. File Download (Firebase Storage)
2. Text Extraction (PDF/PPTX)
3. OpenAI GPT Call (Question Generation)
4. Text-to-Speech (Each Question)
5. Audio Upload (Firebase Storage)
6. Slide Images Generation (Presentation mode)
7. Firestore Update (Questions + Audio URLs)
```

### Audio Processing Process:
```
1. Session Data Fetch (Firestore)
2. Audio Download (Firebase Storage)
3. Audio Conversion (MP3)
4. Speech-to-Text (Vosk)
5. Pitch Analysis (librosa + pyworld)
6. Sentiment Analysis (NLTK VADER)
7. Vocabulary Analysis (textstat)
8. Speech Rate Calculation
9. Relevance Checking (OpenAI GPT)
10. Aggregation (All responses)
11. Firestore Update (reportGenerated)
```

---

## 📊 Data Flow

### Firestore Collections:

1. **`users`**: User profiles
2. **`files`**: Uploaded files metadata
   - `url`: Firebase Storage URL
   - `userId`: User ID
   - `uploadedAt`: Timestamp
3. **`sessions`**: User practice sessions
   - `sessions[]`: Array of session objects
   - Each session contains:
     - `filePath`: File URL
     - `isPresentation`: Boolean
     - `isInterview`: Boolean
     - `questionsGenerated`: Array of questions
     - `responses`: Map of recorded responses
     - `reportGenerated`: Complete feedback report
4. **`questionAudios`**: Question audio URLs
   - `audioLinks`: Array of audio URLs
5. **`slideImages`**: Slide images (Presentation mode)
   - `imageLinks`: Array of image URLs

### Firebase Storage:
- **`QuestionAudios/`**: Question audio files
- **`responses/`**: User recorded responses
- **`files/`**: Uploaded PDF/PPTX files

---

## 🎯 Key Features

1. **Dual Mode Support**: Presentation aur Interview dono modes
2. **AI-Powered Questions**: OpenAI GPT se intelligent questions
3. **Comprehensive Audio Analysis**:
   - Pitch analysis
   - Sentiment analysis
   - Vocabulary difficulty
   - Speech rate
   - Content relevance
4. **Real-time Feedback**: Detailed analysis with suggestions
5. **Cross-platform**: Flutter se web, Android, iOS support
6. **Firebase Integration**: Secure authentication aur data storage

---

## 🔐 Security Features

- Firebase Authentication (email/password)
- Firestore security rules
- Firebase Storage access control
- User-specific data isolation

---

## 📝 Important Notes

1. **FFmpeg Required**: Audio processing ke liye FFmpeg install hona chahiye
2. **Vosk Model**: Speech-to-text ke liye Vosk model download karna padega
3. **OpenAI API Key**: `python_server/key.py` mein OpenAI API key honi chahiye
4. **Firebase Configuration**: `google-services.json` properly configured hona chahiye

---

## 🚀 Future Enhancements (Planned)

1. Performance Dashboard (Historical tracking)
2. Admin Panel (User management, analytics)
3. Production Deployment (Cloud hosting)
4. VR Integration (Original vision)
5. Advanced Analytics (Charts, graphs, trends)

---

## 📚 Documentation Files

- **`README.md`**: Project overview
- **`ANDROID_SETUP.md`**: Android setup guide
- **`TASK_DIVISION.md`**: Team member contributions
- **`MILESTONES_ACHIEVED.md`**: Completed features
- **`FUTURE_PLANS.md`**: Planned features

---

Yeh complete documentation hai InterPrep project ki. Har file ka purpose, flow, aur integration points clearly explained hain. Agar kisi specific file ya flow ke baare mein aur detail chahiye, to bataiye!











