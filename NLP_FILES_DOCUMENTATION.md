# NLP Files Documentation - InterPrep Project

## 📋 NLP (Natural Language Processing) Files

Project mein **NLP** multiple files mein use ho raha hai. Yeh complete list hai:

---

## 🗂️ NLP Files List

### 1. **Text Extraction (Document Processing)**

#### `python_server/textExtractionPDF.py`
**Purpose**: PDF files se text extract karta hai
- **Library**: `langchain_community.document_loaders.PyPDFLoader`
- **Function**: `textExtractionPDF(path)`
- **NLP Use**: Document parsing, text extraction from PDF
- **Output**: Extracted text from PDF

#### `python_server/textExtractionPPTX.py`
**Purpose**: PPTX (PowerPoint) files se text extract karta hai
- **Library**: `langchain_community.document_loaders.UnstructuredPowerPointLoader`
- **Function**: `textExtractionPPTX(path)`
- **NLP Use**: Document parsing, text extraction from PowerPoint
- **Output**: Extracted text from PPTX

---

### 2. **Speech-to-Text (Audio Processing)**

#### `python_server/Audio_modules/stt.py`
**Purpose**: Audio se text convert karta hai (Speech-to-Text)
- **Library**: `vosk` (Vosk Speech Recognition)
- **Function**: `transcribe_audio(audio_file_path)`
- **NLP Use**: 
  - Speech recognition
  - Audio transcription
  - Natural language understanding from speech
- **Model**: Vosk model (`vosk-model-en-us-0.22`)
- **Output**: Transcribed text from audio

---

### 3. **Sentiment Analysis**

#### `python_server/Audio_modules/sentiment.py`
**Purpose**: Text ka sentiment analyze karta hai (Positive/Negative/Neutral)
- **Library**: `nltk` (Natural Language Toolkit)
  - `nltk.sentiment.SentimentIntensityAnalyzer`
  - VADER lexicon
- **Function**: `analyze_and_classify_sentiment(text)`
- **NLP Use**:
  - Sentiment analysis
  - Emotion detection
  - Text polarity scoring
- **Output**: 
  - `sentiment_score`: -1 (Negative) to +1 (Positive)
  - `sentiment_class`: "Very Positive", "Positive", "Neutral", "Negative", "Very Negative"

**Code Example**:
```python
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer

nltk.download('vader_lexicon')
sid = SentimentIntensityAnalyzer()
sentiment_scores = sid.polarity_scores(text)
```

---

### 4. **Vocabulary Analysis**

#### `python_server/Audio_modules/vocab_level.py`
**Purpose**: Text ki vocabulary difficulty analyze karta hai
- **Library**: `textstat`
  - Flesch-Kincaid Grade Level algorithm
- **Function**: `analyze_and_classify_vocabulary_difficulty(text)`
- **NLP Use**:
  - Readability analysis
  - Vocabulary complexity measurement
  - Text difficulty classification
- **Output**:
  - `grade_level`: Education level (1-12+)
  - `difficulty_class`: "Very Easy", "Easy", "Moderate", "Difficult", "Very Difficult"

**Code Example**:
```python
from textstat import flesch_kincaid_grade

grade_level = flesch_kincaid_grade(text)
```

---

### 5. **Text Formatting & Punctuation**

#### `python_server/lineSeparator.py`
**Purpose**: Transcribed text ko properly format karta hai (punctuation add karta hai)
- **Library**: OpenAI GPT-3.5-turbo
- **Function**: `lineSeparator(extractedText)`
- **NLP Use**:
  - Text normalization
  - Punctuation restoration
  - Sentence structure correction
  - Natural language understanding
- **Output**: Properly punctuated and formatted text

**Process**:
- Speech-to-text se jo text aata hai, usme punctuation nahi hota
- OpenAI GPT se punctuation add karwata hai
- Context-aware punctuation restoration

---

### 6. **Question Generation (AI-Powered NLP)**

#### `python_server/questionGeneration.py`
**Purpose**: Presentation mode ke liye questions generate karta hai
- **Library**: 
  - `langchain_openai.OpenAI`
  - `langchain_core.prompts.PromptTemplate`
- **Function**: `questionGeneration(extractedText)`
- **NLP Use**:
  - Natural language understanding
  - Content analysis
  - Question generation using AI
  - Context-aware question creation
- **Model**: GPT-3.5-turbo-instruct
- **Output**: 5 questions (text format)

**Process**:
- Slide content analyze karta hai
- AI se relevant questions generate karta hai
- Questions QA session ke liye optimize hote hain

#### `python_server/interviewQuestionGeneration.py`
**Purpose**: Interview mode ke liye questions generate karta hai
- **Library**: 
  - `langchain_openai.OpenAI`
  - `langchain_core.prompts.PromptTemplate`
- **Function**: `interviewQuestionGeneration(extractedText, formData)`
- **NLP Use**:
  - Resume content analysis
  - Job description understanding
  - Context-aware interview question generation
  - Technical HR question creation
- **Model**: GPT-3.5-turbo-instruct
- **Input**: Resume text + JD + Position + Experience
- **Output**: 5 interview questions

---

### 7. **Relevance Checking (Content Analysis)**

#### `python_server/relevanceChecking.py`
**Purpose**: Do texts ke beech relevance check karta hai
- **Library**: OpenAI GPT-3.5-turbo
- **Function**: `relevanceChecking(reference_text, spoken_text, mode, question_text=None)`
- **NLP Use**:
  - Semantic similarity analysis
  - Content alignment checking
  - Question-answer relevance
  - Context understanding
  - Natural language comparison
- **Modes**:
  - **Interview Mode**: Question vs Answer relevance
  - **Presentation Mode**: Question + Answer vs Slide content alignment
- **Output**: Detailed relevance analysis (paragraphs)

**Process**:
- Interview mode: Question aur Answer compare karta hai
- Presentation mode: Question + Answer ka slide content se alignment check karta hai
- GPT-3.5 se detailed analysis generate karta hai

---

### 8. **Question-Answer Evaluation (Optional/Unused)**

#### `python_server/questionAnswer.py`
**Purpose**: Interview answers ka evaluation feedback deta hai
- **Library**: 
  - `langchain_openai.OpenAI`
  - `langchain_core.prompts.PromptTemplate`
- **Function**: `questionAnswer(question, answer)`
- **NLP Use**:
  - Answer evaluation
  - Feedback generation
  - Natural language understanding
- **Note**: Yeh file exist karti hai lekin currently use nahi ho rahi (relevanceChecking.py use ho raha hai)

---

## 📊 NLP Usage Summary

### NLP Tasks in Project:

1. **Text Extraction** ✅
   - PDF text extraction
   - PPTX text extraction

2. **Speech Recognition** ✅
   - Audio to text conversion (Vosk)

3. **Sentiment Analysis** ✅
   - Text sentiment scoring (NLTK VADER)

4. **Vocabulary Analysis** ✅
   - Readability scoring (textstat)

5. **Text Normalization** ✅
   - Punctuation restoration (OpenAI GPT)

6. **Question Generation** ✅
   - AI-powered question creation (OpenAI GPT)

7. **Content Analysis** ✅
   - Relevance checking (OpenAI GPT)
   - Semantic similarity

---

## 🔧 NLP Libraries Used

| Library | Purpose | File(s) |
|---------|---------|---------|
| **langchain** | Document loading, AI integration | `textExtractionPDF.py`, `textExtractionPPTX.py`, `questionGeneration.py`, `interviewQuestionGeneration.py` |
| **vosk** | Speech-to-text | `Audio_modules/stt.py` |
| **nltk** | Sentiment analysis | `Audio_modules/sentiment.py` |
| **textstat** | Vocabulary/readability analysis | `Audio_modules/vocab_level.py` |
| **OpenAI GPT** | AI-powered NLP (questions, relevance, formatting) | `questionGeneration.py`, `interviewQuestionGeneration.py`, `relevanceChecking.py`, `lineSeparator.py` |

---

## 🔄 NLP Processing Flow

### Complete NLP Pipeline:

```
1. DOCUMENT UPLOAD
   ↓
2. TEXT EXTRACTION (NLP)
   ├─ PDF → textExtractionPDF.py
   └─ PPTX → textExtractionPPTX.py
   ↓
3. QUESTION GENERATION (AI NLP)
   ├─ Presentation → questionGeneration.py
   └─ Interview → interviewQuestionGeneration.py
   ↓
4. AUDIO RECORDING
   ↓
5. SPEECH-TO-TEXT (NLP)
   └─ Audio_modules/stt.py (Vosk)
   ↓
6. TEXT NORMALIZATION (NLP)
   └─ lineSeparator.py (OpenAI GPT)
   ↓
7. NLP ANALYSIS
   ├─ Sentiment Analysis → Audio_modules/sentiment.py (NLTK)
   ├─ Vocabulary Analysis → Audio_modules/vocab_level.py (textstat)
   └─ Relevance Checking → relevanceChecking.py (OpenAI GPT)
   ↓
8. FEEDBACK GENERATION
```

---

## 📍 File Locations

### Main NLP Files:
```
python_server/
├── textExtractionPDF.py              ✅ NLP: Text extraction
├── textExtractionPPTX.py              ✅ NLP: Text extraction
├── lineSeparator.py                   ✅ NLP: Text formatting
├── questionGeneration.py              ✅ NLP: AI question generation
├── interviewQuestionGeneration.py    ✅ NLP: AI interview questions
├── relevanceChecking.py               ✅ NLP: Content relevance
├── questionAnswer.py                  ⚠️ NLP: (Unused) Answer evaluation
└── Audio_modules/
    ├── stt.py                         ✅ NLP: Speech-to-text
    ├── sentiment.py                   ✅ NLP: Sentiment analysis
    └── vocab_level.py                 ✅ NLP: Vocabulary analysis
```

---

## 🎯 Key NLP Functions

### 1. Text Extraction
- **Files**: `textExtractionPDF.py`, `textExtractionPPTX.py`
- **Purpose**: Documents se text extract karna
- **Used in**: Question generation ke pehle

### 2. Speech-to-Text
- **File**: `Audio_modules/stt.py`
- **Purpose**: Audio se text convert karna
- **Used in**: Audio processing API

### 3. Sentiment Analysis
- **File**: `Audio_modules/sentiment.py`
- **Purpose**: Text ka sentiment analyze karna
- **Used in**: Feedback generation

### 4. Vocabulary Analysis
- **File**: `Audio_modules/vocab_level.py`
- **Purpose**: Vocabulary difficulty measure karna
- **Used in**: Feedback generation

### 5. Text Formatting
- **File**: `lineSeparator.py`
- **Purpose**: Transcribed text ko format karna
- **Used in**: Audio processing ke baad

### 6. Question Generation
- **Files**: `questionGeneration.py`, `interviewQuestionGeneration.py`
- **Purpose**: AI se questions generate karna
- **Used in**: Session setup ke baad

### 7. Relevance Checking
- **File**: `relevanceChecking.py`
- **Purpose**: Content relevance analyze karna
- **Used in**: Feedback generation

---

## 💡 Summary

**Total NLP Files**: 9 files
- ✅ **Active NLP Files**: 8 files
- ⚠️ **Unused NLP File**: 1 file (`questionAnswer.py`)

**NLP Technologies**:
- ✅ Langchain (Document processing)
- ✅ Vosk (Speech recognition)
- ✅ NLTK (Sentiment analysis)
- ✅ textstat (Readability analysis)
- ✅ OpenAI GPT (AI-powered NLP)

**NLP Tasks**:
1. Text extraction
2. Speech-to-text
3. Sentiment analysis
4. Vocabulary analysis
5. Text normalization
6. Question generation
7. Content relevance analysis

---

Yeh complete list hai NLP files ki. Har file ka purpose, library, aur usage clearly mentioned hai!











