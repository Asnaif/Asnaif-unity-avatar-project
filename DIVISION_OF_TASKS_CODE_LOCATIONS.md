# Division of Tasks - Code Locations (हिंदी/English)

Yeh document aapke division of tasks ke har point ko codebase mein locate karta hai.

---

## 📋 Task 1: Flutter-Flask API Integration with RESTful Endpoints

### ✅ Completed: Flutter-Flask API integration with RESTful endpoints for audio processing and question extraction

### Code Locations:

#### **Backend API Endpoints (Flask Server):**

1. **`/api/audio_processing` (POST)** - Audio Processing Endpoint
   - **File**: `python_server/server.py`
   - **Line**: 149-413
   - **Function**: `audio_processing()`
   - **Purpose**: User ke recorded audio ko analyze karta hai
   - **Process**:
     - Audio download from Firebase Storage
     - Audio conversion (MP3)
     - Speech-to-Text transcription
     - Pitch analysis
     - Sentiment analysis
     - Vocabulary analysis
     - Speech rate calculation
     - Relevance checking
   - **Returns**: Complete feedback report with all metrics

2. **`/api/extract` (GET)** - Question Extraction Endpoint
   - **File**: `python_server/server.py`
   - **Line**: 416-506
   - **Function**: `extract_questions()`
   - **Purpose**: PDF/PPTX files se questions generate karta hai
   - **Process**:
     - File download from Firebase Storage
     - Text extraction (PDF/PPTX)
     - Question generation (OpenAI GPT)
     - Text-to-Speech conversion
     - Audio upload to Firebase Storage
     - Slide images generation (Presentation mode)
   - **Returns**: Generated questions, audio URLs, slide images

#### **Flutter API Calls (Frontend):**

1. **Question Extraction API Call**
   - **File**: `lib/screens/fetched_questions/ui_fetch_questions_screen.dart`
   - **Line**: 34-88
   - **Function**: `fetchData()`
   - **API URL**: `http://127.0.0.1:5000/api/extract?id=$documentId&userId=$userId`
   - **Method**: GET
   - **Usage**: Questions generate karne ke liye

2. **Audio Processing API Call**
   - **File**: `lib/screens/practice_session/practice_session_screen.dart`
   - **Line**: 1377-1384
   - **Function**: Session complete hone par call hota hai
   - **API URL**: `http://127.0.0.1:5000/api/audio_processing`
   - **Method**: POST
   - **Request Body**: 
     ```json
     {
       "audioFilePath": "...",
       "userId": "..."
     }
     ```
   - **Usage**: Session complete hone par feedback generate karne ke liye
   - **Response Handling**: Line 1386-1410 (approximately)

#### **CORS Configuration:**
   - **File**: `python_server/server.py`
   - **Line**: 126-132
   - **Purpose**: Flutter app se API calls allow karne ke liye
   - **Configuration**: Localhost aur 127.0.0.1 ke liye CORS enabled

---

## 📋 Task 2: Firebase Configuration

### ✅ Completed: Configured Firebase Authentication, Firestore, and Storage for secure data management

### Code Locations:

#### **1. Firebase Initialization (Flutter Side):**

1. **Main Firebase Setup**
   - **File**: `lib/main.dart`
   - **Line**: 14-16
   - **Code**:
     ```dart
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     ```

2. **Firebase Options Configuration**
   - **File**: `lib/firebase_options.dart`
   - **Line**: 1-89
   - **Purpose**: Platform-specific Firebase configuration
   - **Platforms**: Web, Android, iOS, macOS, Windows
   - **Contains**: API keys, project IDs, storage buckets, auth domains

#### **2. Firebase Authentication:**

1. **Sign Up Screen**
   - **File**: `lib/screens/signup/ui_signup_screen.dart`
   - **Usage**: User registration with Firebase Auth
   - **Features**: Email/password authentication

2. **Login Screen**
   - **File**: `lib/screens/login/ui_login_screen.dart`
   - **Usage**: User login with Firebase Auth
   - **Features**: Email/password authentication

3. **Firebase Auth Package**
   - **File**: `pubspec.yaml`
   - **Line**: 27
   - **Package**: `firebase_auth: ^5.0.0`

#### **3. Firebase Firestore (Database):**

1. **Firestore Usage Examples:**
   - **File**: `lib/screens/practice_session/practice_session_screen.dart`
   - **Usage**: Sessions, questions, responses store karta hai
   - **Collections**:
     - `sessions` - User sessions data
     - `files` - Uploaded files metadata
     - `questionAudios` - Question audio URLs
     - `slideImages` - Slide images (Presentation mode)

2. **Firestore Package**
   - **File**: `pubspec.yaml`
   - **Line**: 29
   - **Package**: `cloud_firestore: ^5.0.0`

3. **Firestore Instance (Backend)**
   - **File**: `python_server/firebase_admin_instance.py`
   - **Line**: 8-9
   - **Function**: `get_firestore_instance()`
   - **Usage**: Python backend se Firestore access

#### **4. Firebase Storage:**

1. **Storage Usage (Flutter):**
   - **File**: `lib/screens/practice_session/practice_session_screen.dart`
   - **Line**: 1262-1270 (approximately)
   - **Usage**: Audio files upload karta hai
   - **Path**: `responses/$userId/q${questionIndex}_$timestamp.opus`

2. **Storage Usage (Backend):**
   - **File**: `python_server/firebase_admin_instance.py`
   - **Line**: 11-13
   - **Function**: `get_storage_bucket()`
   - **Bucket**: `interprep-585db.firebasestorage.app`

3. **Storage Package**
   - **File**: `pubspec.yaml`
   - **Line**: 28
   - **Package**: `firebase_storage: ^12.0.0`

4. **Storage Upload Functions:**
   - **File**: `python_server/server.py`
   - **Line**: 143-147
   - **Function**: `upload_file_to_firebase()`
   - **Purpose**: Question audio files upload karta hai

#### **5. Firebase Configuration Files:**

1. **Android Configuration**
   - **File**: `android/app/google-services.json`
   - **Purpose**: Android app ke liye Firebase config

2. **iOS Configuration**
   - **File**: `ios/Runner/GoogleService-Info.plist`
   - **Purpose**: iOS app ke liye Firebase config

3. **Web Configuration**
   - **File**: `lib/firebase_options.dart` (web section)
   - **Line**: 43-51
   - **Purpose**: Web app ke liye Firebase config

---

## 📋 Task 3: Error Handling & Audio File Conversion

### ✅ Completed: Implemented error handling, and audio file conversion workflows

### Code Locations:

#### **1. Error Handling:**

##### **Backend Error Handling (Flask):**

1. **API Endpoint Error Handling**
   - **File**: `python_server/server.py`
   - **Line**: 149-413 (`audio_processing()` function)
   - **Error Handling**:
     - Line 155-156: No data provided check
     - Line 161-162: Missing required fields check
     - Line 171-172: User session not found (404)
     - Line 175-176: No sessions found (404)
     - Line 180-181: No sessions available (404)
     - Line 200-201: No questions generated (400)
     - Line 203-204: Question index out of range (400)
     - Line 254-255: Audio download failure
     - Line 269-272: Pitch analysis try-catch
     - Line 275-288: Speech-to-Text try-catch with fallback
     - Line 294-316: Relevance checking try-catch
     - Line 319-322: Sentiment analysis try-catch
   - **Final Error Handling**:
     - Line: 402-413
     - **KeyError** handling (400)
     - **Exception** handling (500)
     - Detailed error messages with traceback

2. **Audio Conversion Error Handling**
   - **File**: `python_server/server.py`
   - **Line**: 72-124 (`convert_audio_to_mp3()` function)
   - **Error Checks**:
     - Line 79-81: File existence check
     - Line 91-109: FFmpeg availability check with detailed instructions
     - Line 121-124: Exception handling with error messages

3. **Module-Level Error Handling:**
   - **File**: `python_server/Audio_modules/pitch.py`
   - **Line**: 12-31 (`convert_mp3_to_wav()` function)
   - **Error Handling**: File not found, FFmpeg not available
   
   - **File**: `python_server/Audio_modules/stt.py`
   - **Line**: 11-44 (`transcribe_audio()` function)
   - **Error Handling**: File not found, FFmpeg not available, transcription failures

   - **File**: `python_server/Audio_modules/speechrate.py`
   - **Line**: 10-40 (`calculate_speech_rate_from_text_and_audio()` function)
   - **Error Handling**: File not found, FFmpeg not available

##### **Frontend Error Handling (Flutter):**

1. **API Call Error Handling**
   - **File**: `lib/screens/fetched_questions/ui_fetch_questions_screen.dart`
   - **Line**: 83-88
   - **Try-Catch**: API call failures handle karta hai
   - **Error Display**: User ko error message dikhata hai

2. **File Upload Error Handling**
   - **File**: `lib/screens/audio_upload/ui_audio_upload_screen.dart`
   - **Line**: 76-94 (`showErrorDialog()` function)
   - **Line**: 128-131 (Upload error handling)
   - **Purpose**: File upload failures handle karta hai

3. **Audio Recording Error Handling**
   - **File**: `lib/screens/practice_session/practice_session_screen.dart`
   - **Line**: Multiple locations
   - **Error Handling**: Recording start/stop failures handle karta hai

#### **2. Audio File Conversion Workflows:**

##### **Backend Audio Conversion:**

1. **Main Audio Conversion Function**
   - **File**: `python_server/server.py`
   - **Line**: 72-124
   - **Function**: `convert_audio_to_mp3()`
   - **Supported Formats**: .opus, .wav, .ogg, .m4a, .aac, and other formats
   - **Process**:
     - Input file check
     - Already MP3 check (copy if yes)
     - FFmpeg availability check
     - Audio conversion using pydub (which uses ffmpeg)
     - Error handling with detailed messages

2. **Audio Conversion in Processing Pipeline**
   - **File**: `python_server/server.py`
   - **Line**: 258-266 (`process_audio()` function inside `audio_processing()`)
   - **Process**:
     ```python
     # Convert to MP3
     if audio_local_file_path.lower().endswith('.mp3'):
         mp3_file_path = audio_local_file_path
         print("✅ Audio already in MP3 format")
     else:
         mp3_file_path = audio_local_file_path.rsplit('.', 1)[0] + '.mp3'
         print(f"🔄 Converting {audio_file_extension} to MP3...")
         convert_audio_to_mp3(audio_local_file_path, mp3_file_path)
         print(f"✅ Conversion successful: {mp3_file_path}")
     ```

3. **MP3 to WAV Conversion (for Pitch Analysis)**
   - **File**: `python_server/Audio_modules/pitch.py`
   - **Line**: 12-31
   - **Function**: `convert_mp3_to_wav()`
   - **Purpose**: Pitch analysis ke liye WAV format chahiye
   - **Uses**: pydub with ffmpeg

4. **Audio Format Conversion for STT**
   - **File**: `python_server/server.py`
   - **Line**: 280-286
   - **Process**: MP3 ko WAV mein convert karta hai agar STT fail ho jaye
   - **Format**: 16kHz, mono channel

##### **FFmpeg Setup & Detection:**

1. **FFmpeg Path Resolution**
   - **File**: `python_server/server.py`
   - **Line**: 29-45
   - **Function**: `_resolve_ffmpeg_paths()`
   - **Purpose**: System mein FFmpeg ko detect karta hai
   - **Locations Checked**:
     - System PATH
     - `C:\Program Files\FFmpeg\bin\ffmpeg.exe`
     - `C:\Program Files (x86)\FFmpeg\bin\ffmpeg.exe`
     - `C:\ffmpeg\bin\ffmpeg.exe`
     - Chocolatey installation
     - Winget installation

2. **FFmpeg Availability Check**
   - **File**: `python_server/server.py`
   - **Line**: 68-70
   - **Function**: `check_ffmpeg_available()`
   - **Purpose**: FFmpeg available hai ya nahi check karta hai

3. **FFmpeg Configuration**
   - **File**: `python_server/server.py`
   - **Line**: 48-64
   - **Purpose**: FFmpeg paths set karta hai for pydub
   - **Configuration**: AudioSegment.converter aur AudioSegment.ffprobe set karta hai

---

## 📋 Task 4: Backend Server Setup

### ✅ Completed: Managed backend server setup

### Code Locations:

#### **1. Flask Server Setup:**

1. **Main Server File**
   - **File**: `python_server/server.py`
   - **Line**: 66
   - **Code**: `app = Flask(__name__)`
   - **Purpose**: Flask application instance create karta hai

2. **CORS Configuration**
   - **File**: `python_server/server.py`
   - **Line**: 126-132
   - **Purpose**: Cross-Origin Resource Sharing enable karta hai
   - **Configuration**: Localhost aur 127.0.0.1 ke liye allowed

3. **Firebase Admin Setup**
   - **File**: `python_server/firebase_admin_instance.py`
   - **Line**: 1-13
   - **Purpose**: Firebase Admin SDK initialize karta hai
   - **Components**:
     - Firestore instance
     - Storage bucket instance
   - **Credentials**: `./file.json` (service account key)

#### **2. Server Dependencies:**

1. **Python Requirements**
   - **File**: `requirements.txt` (if exists)
   - **Key Packages**:
     - Flask
     - flask-cors
     - firebase-admin
     - pydub
     - librosa
     - pyworld
     - vosk
     - nltk
     - openai
     - textstat

2. **Server Modules Structure:**
   ```
   python_server/
   ├── server.py                    # Main Flask server
   ├── firebase_admin_instance.py   # Firebase setup
   ├── download_file.py             # File download utility
   ├── Audio_modules/               # Audio processing modules
   │   ├── pitch.py
   │   ├── stt.py
   │   ├── sentiment.py
   │   ├── vocab_level.py
   │   └── speechrate.py
   ├── textExtractionPDF.py
   ├── textExtractionPPTX.py
   ├── questionGeneration.py
   ├── interviewQuestionGeneration.py
   ├── textToSpeech.py
   └── relevanceChecking.py
   ```

#### **3. Server Endpoints Summary:**

| Endpoint | Method | File | Line | Purpose |
|----------|--------|------|------|---------|
| `/api/audio_processing` | POST | `server.py` | 149 | Audio analysis & feedback |
| `/api/extract` | GET | `server.py` | 416 | Question generation |

#### **4. Server Configuration:**

1. **Port Configuration**
   - **Default**: 5000 (Flask default)
   - **URL**: `http://127.0.0.1:5000`
   - **Usage**: Flutter app se API calls

2. **Environment Setup**
   - **FFmpeg**: Required for audio processing
   - **Vosk Model**: Required for Speech-to-Text
   - **OpenAI API Key**: Required for question generation
   - **Firebase Credentials**: Required for Firebase access

---

## 📊 Summary Table

| Task | Component | Main Files | Key Functions |
|------|-----------|------------|---------------|
| **1. API Integration** | Backend Endpoints | `python_server/server.py` | `audio_processing()`, `extract_questions()` |
| | Frontend Calls | `lib/screens/fetched_questions/`, `lib/screens/practice_session/` | `fetchData()`, API POST calls |
| **2. Firebase Setup** | Authentication | `lib/screens/signup/`, `lib/screens/login/` | Sign up, Login |
| | Firestore | `lib/screens/practice_session/`, `python_server/firebase_admin_instance.py` | Data storage, retrieval |
| | Storage | `lib/screens/practice_session/`, `python_server/server.py` | File upload, download |
| **3. Error Handling** | Backend | `python_server/server.py` | Try-catch blocks, error responses |
| | Frontend | `lib/screens/*/` | Error dialogs, try-catch |
| **4. Audio Conversion** | Conversion | `python_server/server.py` | `convert_audio_to_mp3()` |
| | FFmpeg Setup | `python_server/server.py` | `_resolve_ffmpeg_paths()`, `check_ffmpeg_available()` |
| **5. Server Setup** | Flask App | `python_server/server.py` | Flask initialization, CORS |
| | Firebase Admin | `python_server/firebase_admin_instance.py` | Firebase initialization |

---

## 🔍 Quick Reference: File Locations

### Backend Files:
- **Main Server**: `python_server/server.py`
- **Firebase Setup**: `python_server/firebase_admin_instance.py`
- **Audio Modules**: `python_server/Audio_modules/*.py`
- **File Processing**: `python_server/download_file.py`

### Frontend Files:
- **Main App**: `lib/main.dart`
- **Firebase Config**: `lib/firebase_options.dart`
- **API Calls**: `lib/screens/fetched_questions/ui_fetch_questions_screen.dart`
- **Audio Processing**: `lib/screens/practice_session/practice_session_screen.dart`
- **Authentication**: `lib/screens/signup/`, `lib/screens/login/`

### Configuration Files:
- **Dependencies**: `pubspec.yaml` (Flutter), `requirements.txt` (Python)
- **Firebase**: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`

---

*Yeh document codebase analysis ke basis par banaya gaya hai. Har task ke implementation details clearly marked hain.*











