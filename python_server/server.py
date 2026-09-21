import sys
import io
# Fix Windows terminal encoding (cp1252 can't handle emoji characters)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from pptx_to_png import pptx_to_pngs_and_upload
from pdf_to_image import pdf_first_page_to_image, pdf_all_pages_to_images
from interviewQuestionGeneration import interviewQuestionGeneration
from textToSpeech import textToSpeech
from textExtractionPDF import textExtractionPDF
from textExtractionPPTX import textExtractionPPTX
from download_file import download_file
from Audio_modules.pitch import get_average_pitch_from_mp3
from Audio_modules.stt import transcribe_audio
from Audio_modules.sentiment import analyze_and_classify_sentiment
from Audio_modules.vocab_level import analyze_and_classify_vocabulary_difficulty
from Audio_modules.speechrate import calculate_speech_rate_from_text_and_audio
from Audio_modules.stt import transcribe_audio, initialize_vosk_model
try:
    from Audio_modules.communication_scorer import (
        extract_communication_features,
        get_communication_score,
        is_model_loaded as is_comm_model_loaded
    )
    COMM_MODEL_AVAILABLE = True
except ImportError as e:
    print(f"⚠️ Communication scorer not available: {e}")
    COMM_MODEL_AVAILABLE = False

from questionGeneration import questionGeneration
from relevanceChecking import relevanceChecking
from lineSeparator import lineSeparator
from firebase_admin_instance import get_firestore_instance, get_storage_bucket
from Audio_modules.coaching_engine import analyze_realtime_audio, generate_improvement_tips
try:
    from Audio_modules.voice_cloning import generate_interviewer_voice, get_available_voices, simulate_conversation
except ImportError:
    # Fallback if voice_cloning module not available
    def generate_interviewer_voice(text, voice_type='professional_male', accent='american'):
        from textToSpeech import textToSpeech
        return textToSpeech(text)
    
    def get_available_voices():
        return []
    
    def simulate_conversation(questions, voice_config=None):
        return []


# NVC (Non-Verbal Communication) Body Language Module
NVC_AVAILABLE = False
try:
    from NVC_modules.nvc_service import (
        start_nvc_session, process_nvc_frame,
        complete_nvc_session, get_nvc_status
    )
    NVC_AVAILABLE = True
    print("✅ NVC body language module loaded")
except ImportError as e:
    print(f"⚠️ NVC module not available: {e}")

from pydub import AudioSegment
import os
import subprocess
import shutil

# Resolve ffmpeg/ffprobe paths from common install locations (Winget/Manual/Chocolatey)
def _resolve_ffmpeg_paths():
    user_profile = os.environ.get("USERPROFILE", r"C:\Users\Default")
    candidates = [
        shutil.which("ffmpeg"),
        r"C:\Program Files\FFmpeg\bin\ffmpeg.exe",
        r"C:\Program Files (x86)\FFmpeg\bin\ffmpeg.exe",
        r"C:\ffmpeg\bin\ffmpeg.exe",
        r"C:\ProgramData\chocolatey\bin\ffmpeg.exe",
        os.path.join(
            user_profile,
            r"AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe",
        ),
    ]
    for path in candidates:
        if path and os.path.exists(path):
            return path
    return None


FFMPEG_BIN = _resolve_ffmpeg_paths()
FFPROBE_BIN = None
if FFMPEG_BIN:
    ff_dir = os.path.dirname(FFMPEG_BIN)
    FFPROBE_BIN = os.path.join(ff_dir, "ffprobe.exe")
    # Ensure PATH has ffmpeg/ffprobe for subprocess calls
    if ff_dir not in os.environ.get("PATH", ""):
        os.environ["PATH"] = ff_dir + os.pathsep + os.environ.get("PATH", "")
    # Tell pydub explicitly
    AudioSegment.converter = FFMPEG_BIN
    if os.path.exists(FFPROBE_BIN):
        AudioSegment.ffprobe = FFPROBE_BIN
    print(f"✅ ffmpeg detected at: {FFMPEG_BIN}")
    if os.path.exists(FFPROBE_BIN):
        print(f"✅ ffprobe detected at: {FFPROBE_BIN}")
else:
    print("⚠️ ffmpeg not detected; will report install instructions if used.")

app = Flask(__name__)

def check_ffmpeg_available():
    """Check if ffmpeg is available in the system PATH"""
    return FFMPEG_BIN is not None or shutil.which("ffmpeg") is not None

def convert_audio_to_mp3(input_path, output_path):
    """
    Convert audio file to MP3 format.
    Handles ffmpeg availability and provides better error messages.
    Supports: .opus, .wav, .ogg, .m4a, .aac, and other formats.
    """
    try:
        # Check if input file exists
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Audio file not found: {input_path}")
        
        # Check if file is already MP3
        if input_path.lower().endswith('.mp3'):
            # If already MP3, just copy it
            import shutil
            shutil.copy2(input_path, output_path)
            return output_path
        
        # Check if ffmpeg is available
        if not check_ffmpeg_available():
            error_instructions = (
                "❌ ffmpeg is not installed or not in PATH.\n\n"
                "📥 Quick Installation Options:\n\n"
                "1. Run installation helper script:\n"
                "   .\\python_server\\install_ffmpeg.ps1\n\n"
                "2. Using Winget (Easiest):\n"
                "   winget install ffmpeg\n\n"
                "3. Manual Download (Recommended if others fail):\n"
                "   - Download: https://www.gyan.dev/ffmpeg/builds/\n"
                "   - Extract to C:\\ffmpeg\\\n"
                "   - Add C:\\ffmpeg\\bin to System PATH\n\n"
                "4. Fix Chocolatey Permission Issue (Run PowerShell as Admin):\n"
                "   Remove-Item 'C:\\ProgramData\\chocolatey\\lib\\c00565a56f0e64a50f2ea5badcb97694d43e0755' -Force\n"
                "   choco install ffmpeg -y\n\n"
                "📖 See python_server/INSTALL_FFMPEG.md for detailed instructions.\n"
                "⚠️  After installation, RESTART your terminal and try again."
            )
            raise RuntimeError(error_instructions)
        
        # Convert using pydub (which uses ffmpeg). If we resolved a binary, set it.
        if FFMPEG_BIN:
            AudioSegment.converter = FFMPEG_BIN
            if FFPROBE_BIN and os.path.exists(FFPROBE_BIN):
                AudioSegment.ffprobe = FFPROBE_BIN

        audio = AudioSegment.from_file(input_path)
        audio.export(output_path, format="mp3")
        return output_path
        
    except Exception as e:
        error_msg = f"Audio conversion failed: {str(e)}"
        print(f"❌ {error_msg}")
        raise RuntimeError(error_msg)
# Allow all localhost/127.0.0.1 with any port
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:*", "http://127.0.0.1:*"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type"]
    }
})

# Use Firestore instance
db = get_firestore_instance()
bucket = get_storage_bucket()

def make_file_public(file_path):
    blob = bucket.blob(file_path)
    blob.make_public()
    return blob.public_url 

def upload_file_to_firebase(file_path):
    blob = bucket.blob(f"QuestionAudios/{file_path.name}")
    blob.upload_from_filename(file_path)
    blob.make_public()
    return blob.public_url

@app.route("/api/audio_processing", methods=["POST"])
def audio_processing():
    try:
        extracted_text = ""
        data = request.json
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
            
        audio_Path = data.get("audioFilePath")
        user_id = data.get("userId")
        
        if not audio_Path or not user_id:
            return jsonify({"error": "Missing required fields: audioFilePath or userId"}), 400

        print(f"📥 Processing audio for user: {user_id}")
        print(f"📁 Audio path: {audio_Path}")

        # Getting filePath from firebase
        sessions_ref = db.collection("sessions").document(user_id)
        sessions_doc = sessions_ref.get()
        
        if not sessions_doc.exists:
            return jsonify({"error": "User session not found"}), 404
            
        sessions_data = sessions_doc.to_dict()
        if not sessions_data or "sessions" not in sessions_data:
            return jsonify({"error": "No sessions found for user"}), 404
            
        sessions = sessions_data["sessions"]
        
        if not sessions or len(sessions) == 0:
            return jsonify({"error": "No sessions available"}), 404

        import re
        match = re.search(r'q(\d+)_', audio_Path)
        question_index = int(match.group(1)) if match else 0
        last_session = sessions[-1]

        # Check if this is interview mode
        # First check isInterview field, if not present, check isPresentation
        if "isInterview" in last_session:
            is_interview = last_session.get("isInterview", False)
        else:
            # If isInterview not present, check isPresentation
            # isPresentation == False means it's interview mode
            is_interview = last_session.get("isPresentation", True) == False
        
        print(f"🔍 Detected mode - isInterview: {is_interview}, isPresentation: {last_session.get('isPresentation', 'not set')}")

        # Check if questionsGenerated exists
        if "questionsGenerated" not in last_session or not last_session["questionsGenerated"]:
            return jsonify({"error": "No questions generated for this session"}), 400
            
        if question_index >= len(last_session["questionsGenerated"]):
            return jsonify({"error": f"Question index {question_index} out of range"}), 400
            
        question_text = last_session["questionsGenerated"][question_index]
        file_path = last_session.get("filePath")
        
        # Initialize extracted_text (for presentation mode)
        # IMPORTANT: Only extract text if NOT in interview mode
        extracted_text = ""
        
        # Only download and extract file content if in presentation mode
        if not is_interview and file_path:
            local_file_path, file_extension = download_file(file_path)
            if local_file_path:
                if file_extension == "pdf":
                    extracted_text = textExtractionPDF(local_file_path)
                elif file_extension == "pptx":
                    extracted_text = textExtractionPPTX(local_file_path)
                else:
                    print(f"⚠️ Unsupported file type: {file_extension}")
            else:
                print(f"⚠️ Failed to download file: {file_path}")

        # Build list of responses to process (all answers if present; else fallback to provided audio_Path)
        responses = last_session.get("responses", {})
        to_process = []
        if responses:
            for key, val in responses.items():
                if not isinstance(val, dict):
                    continue
                audio_url = val.get("audio_url")
                if audio_url:
                    try:
                        idx = int(str(key).replace("q", ""))
                    except Exception:
                        idx = 0
                    to_process.append((idx, audio_url))
            to_process.sort(key=lambda x: x[0])
        else:
            to_process.append((question_index, audio_Path))

        # Ensure extracted_text is defined (for presentation mode)
        if not extracted_text:
            extracted_text = ""

        def process_audio(q_idx, audio_url):
            q_text = last_session["questionsGenerated"][q_idx] if q_idx < len(last_session["questionsGenerated"]) else ""
            print(f"⬇️ Downloading audio q{q_idx} from: {audio_url}")
            print(f"📋 Question: {q_text[:100]}..." if len(q_text) > 100 else f"📋 Question: {q_text}")
            print(f"🔍 Interview mode: {is_interview}")
            audio_local_file_path, audio_file_extension = download_file(audio_url)
            if not audio_local_file_path:
                raise RuntimeError("Failed to download audio file from Firebase")
            print(f"✅ Audio downloaded: {audio_local_file_path} (format: {audio_file_extension})")

            # Convert to MP3
            if audio_local_file_path.lower().endswith('.mp3'):
                mp3_file_path = audio_local_file_path
                print("✅ Audio already in MP3 format")
            else:
                mp3_file_path = audio_local_file_path.rsplit('.', 1)[0] + '.mp3'
                print(f"🔄 Converting {audio_file_extension} to MP3...")
                convert_audio_to_mp3(audio_local_file_path, mp3_file_path)
                print(f"✅ Conversion successful: {mp3_file_path}")

            # Pitch
            try:
                average_pitch = get_average_pitch_from_mp3(mp3_file_path, frame_size_ms=20, hop_size_ms=10)
            except Exception:
                average_pitch = 0.0

            # STT with fallback
            try:
                text_local = transcribe_audio(mp3_file_path)
            except Exception:
                text_local = ""
            if not text_local or len(text_local.strip()) == 0:
                try:
                    temp_wav_path = mp3_file_path + ".tmp.wav"
                    audio_seg = AudioSegment.from_file(mp3_file_path).set_channels(1).set_frame_rate(16000)
                    audio_seg.export(temp_wav_path, format="wav")
                    text_local = transcribe_audio(temp_wav_path)
                    os.remove(temp_wav_path)
                except Exception:
                    text_local = ""
            if not text_local or len(text_local.strip()) == 0:
                text_local = "No speech detected in the provided audio."

            text_local = lineSeparator(text_local)

            # Relevance - IMPORTANT: For interview mode, use question text; for presentation, use extracted_text
            try:
                print(f"🔍 Mode check - is_interview: {is_interview}, q_text length: {len(q_text) if q_text else 0}, extracted_text length: {len(extracted_text) if extracted_text else 0}")
                
                if is_interview:
                    # Interview mode: Compare question with answer
                    print(f"✅ Interview mode: Comparing question with answer")
                    print(f"   Question: {q_text[:100]}..." if len(q_text) > 100 else f"   Question: {q_text}")
                    print(f"   Answer: {text_local[:100]}..." if len(text_local) > 100 else f"   Answer: {text_local}")
                    rel = relevanceChecking(q_text, text_local, mode="interview")
                else:
                    # Presentation mode: Question + Answer ka slide content se alignment check
                    # Kyunki questions slide content se generate hote hain, toh relevance check should verify:
                    # Question + Answer combination ka slide content se kitna alignment hai
                    print(f"✅ Presentation mode: Comparing Question + Answer with slide content")
                    print(f"   Question: {q_text[:100]}..." if q_text and len(q_text) > 100 else f"   Question: {q_text}")
                    print(f"   Answer: {text_local[:100]}..." if len(text_local) > 100 else f"   Answer: {text_local}")
                    print(f"   Slide content length: {len(extracted_text)}")
                    rel = relevanceChecking(extracted_text, text_local, mode="presentation", question_text=q_text)
            except Exception as e:
                print(f"❌ Relevance analysis failed: {str(e)}")
                import traceback
                traceback.print_exc()
                rel = "Relevance analysis unavailable."

            # Sentiment
            try:
                sentiment_score, sentiment_class = analyze_and_classify_sentiment(text_local)
            except Exception:
                sentiment_score, sentiment_class = 0.0, "Neutral"

            # Vocab
            try:
                grade_level, difficulty_class = analyze_and_classify_vocabulary_difficulty(text_local)
            except Exception:
                grade_level, difficulty_class = 0, "Medium"

        # Speech rate
            try:
                speech_rate = calculate_speech_rate_from_text_and_audio(text_local, mp3_file_path)
            except Exception:
                speech_rate = 0.0

            # Communication Score (ML Model)
            communication_score = 5.0  # Default
            try:
                if COMM_MODEL_AVAILABLE:
                    comm_features = extract_communication_features(mp3_file_path, text_local)
                    communication_score = get_communication_score(comm_features)
                    print(f"🤖 Communication Score: {communication_score}/10")
                else:
                    print("⚠️ Communication model not available, using default score")
            except Exception as comm_err:
                print(f"⚠️ Communication scoring failed: {comm_err}")
                communication_score = 5.0

            # Extract numerical relevance score from GPT relevance text
            relevance_score = 5.0  # Default
            try:
                import re as _re
                # Try to find score patterns like "7/10", "Score: 8", etc.
                score_patterns = _re.findall(r'(\d+(?:\.\d+)?)\s*/\s*10', str(rel))
                if score_patterns:
                    relevance_score = float(score_patterns[0])
                else:
                    # Try "Score: X" pattern
                    score_patterns = _re.findall(r'[Ss]core[:\s]+(\d+(?:\.\d+)?)', str(rel))
                    if score_patterns:
                        relevance_score = float(score_patterns[0])
                relevance_score = max(0.0, min(10.0, relevance_score))
            except Exception:
                relevance_score = 5.0

            # Final Interview Score (weighted average)
            final_interview_score = round(
                (communication_score * 0.5) + (relevance_score * 0.5), 2
            )
            print(f"📊 Scores → Communication: {communication_score}, Relevance: {relevance_score}, Final: {final_interview_score}")

            # Cleanup
            try:
                if os.path.exists(mp3_file_path):
                    os.remove(mp3_file_path)
                if os.path.exists(audio_local_file_path):
                    os.remove(audio_local_file_path)
            except Exception:
                pass

            return {
                "average_pitch": average_pitch,
                "text": text_local,
                "sentiment_score": sentiment_score,
                "sentiment_class": sentiment_class,
                "grade_level": grade_level,
                "difficulty_class": difficulty_class,
                "speech_rate": speech_rate,
                "relevance": rel,
                "communication_score": communication_score,
                "relevance_score": relevance_score,
                "final_interview_score": final_interview_score,
            }

        results = []
        for q_idx, a_url in to_process:
            try:
                results.append(process_audio(q_idx, a_url))
            except Exception as e:
                print(f"❌ Processing q{q_idx} failed: {e}")

        if not results:
            return jsonify({"error": "Failed to process any responses"}), 500

        # Aggregate averages
        avg_pitch = sum(r["average_pitch"] for r in results) / len(results)
        avg_sentiment = sum(r["sentiment_score"] for r in results) / len(results)
        avg_grade = sum(r["grade_level"] for r in results) / len(results)
        avg_speech_rate = sum(r["speech_rate"] for r in results) / len(results)

        # Majority/representative categorical values
        def mode_or_first(values, default):
            if not values:
                return default
            from collections import Counter
            return Counter(values).most_common(1)[0][0]

        sentiment_class_final = mode_or_first([r["sentiment_class"] for r in results], "Neutral")
        difficulty_class_final = mode_or_first([r["difficulty_class"] for r in results], "Medium")

        combined_text = "\n\n".join(r["text"] for r in results if r.get("text"))
        combined_relevance = "\n\n".join(r["relevance"] for r in results if r.get("relevance"))

        # Aggregate communication scores
        avg_communication = sum(r.get("communication_score", 5.0) for r in results) / len(results)
        avg_relevance_score = sum(r.get("relevance_score", 5.0) for r in results) / len(results)
        avg_final_score = round((avg_communication * 0.5) + (avg_relevance_score * 0.5), 2)

        last_session["reportGenerated"] = {
            "average_pitch": avg_pitch,
            "text": combined_text,
            "sentiment_score": avg_sentiment,
            "sentiment_class": sentiment_class_final,
            "grade_level": avg_grade,
            "difficulty_class": difficulty_class_final,
            "speech_rate": avg_speech_rate,
            "relevance": combined_relevance,
            "communication_score": round(avg_communication, 2),
            "relevance_score": round(avg_relevance_score, 2),
            "final_interview_score": avg_final_score,
            "details": results,
        }

        # Update Firestore document
        sessions_ref.update({"sessions": sessions})

        return jsonify(last_session["reportGenerated"])

    except KeyError as e:
        error_msg = f"Missing required data in session: {str(e)}"
        print(f"❌ {error_msg}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": error_msg}), 400
    except Exception as e:
        error_msg = f"Internal server error: {str(e)}"
        print(f"❌ {error_msg}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": error_msg, "details": str(e)}), 500


@app.route("/api/coaching", methods=["POST"])
def realtime_coaching():
    """Real-time coaching endpoint for live feedback during recording"""
    try:
        data = request.get_json()
        audio_url = data.get('audioUrl')
        user_id = data.get('userId')
        previous_metrics = data.get('previousMetrics')
        
        if not audio_url or not user_id:
            return jsonify({"error": "Missing audioUrl or userId"}), 400
        
        # Download audio
        local_file_path, _ = download_file(audio_url)
        if not local_file_path:
            return jsonify({"error": "Failed to download audio"}), 400
        
        # Analyze audio
        coaching_result = analyze_realtime_audio(local_file_path, previous_metrics)
        
        return jsonify(coaching_result), 200
    except Exception as e:
        print(f"Error in coaching endpoint: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/improvement_tips", methods=["GET"])
def get_improvement_tips():
    """Get personalized improvement tips based on user history"""
    try:
        user_id = request.args.get('userId')
        if not user_id:
            return jsonify({"error": "Missing userId"}), 400
        
        # Get user session history
        db = get_firestore_instance()
        sessions_ref = db.collection('sessions').document(user_id)
        snapshot = sessions_ref.get()
        
        if not snapshot.exists:
            return jsonify({"tips": generate_improvement_tips([])}), 200
        
        sessions = snapshot.to_dict().get('sessions', [])
        completed_sessions = [
            s for s in sessions 
            if s.get('status') == 'completed' and s.get('reportGenerated')
        ]
        
        # Extract metrics from history
        user_history = []
        for session in completed_sessions:
            report = session.get('reportGenerated', {})
            user_history.append({
                'pitch': report.get('averagePitch', 0),
                'speech_rate': report.get('averageSpeechRate', 0),
                'sentiment': report.get('averageSentiment', 0),
            })
        
        tips = generate_improvement_tips(user_history)
        return jsonify({"tips": tips}), 200
    except Exception as e:
        print(f"Error getting improvement tips: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/voice_cloning", methods=["POST"])
def voice_cloning():
    """Generate interviewer voice with voice cloning"""
    try:
        data = request.get_json()
        text = data.get('text')
        voice_type = data.get('voiceType', 'professional_male')
        accent = data.get('accent', 'american')
        
        if not text:
            return jsonify({"error": "Missing text"}), 400
        
        audio_url = generate_interviewer_voice(text, voice_type, accent)
        return jsonify({"audioUrl": audio_url}), 200
    except Exception as e:
        print(f"Error in voice cloning: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/available_voices", methods=["GET"])
def available_voices():
    """Get list of available voice options"""
    try:
        voices = get_available_voices()
        return jsonify({"voices": voices}), 200
    except Exception as e:
        print(f"Error getting available voices: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/extract", methods=["GET"])
def extract_questions():
    try:
        document_id = request.args.get("id")
        user_id = request.args.get("userId")
        is_interview = request.args.get("isInterview", "false").lower() == "true"
        jd = request.args.get("jd", "")
        position = request.args.get("position", "")
        experience = request.args.get("experience", "")

        # Get model type from request (default to openai)
        model_type = request.args.get("model", "openai")

        doc_ref = db.collection("files").document(document_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({"error": "No such document"}), 400

        file_url = doc.to_dict().get("url")
        if not file_url:
            return jsonify({"error": "No URL provided"}), 400

        local_file_path, file_extension = download_file(file_url)
        if not local_file_path:
            return jsonify({"error": "Failed to download the file"}), 500
        
        import os
        print(f"DEBUG: Downloaded file path: {local_file_path}")
        print(f"DEBUG: Does file exist? {os.path.exists(local_file_path)}")

        if file_extension in ["pdf", "pptx"]:
            extracted_text = (
                textExtractionPDF(local_file_path)
                if file_extension == "pdf"
                else textExtractionPPTX(local_file_path)
            )
            # Generate slide images for presentation mode
            if not is_interview:
                output_dir = r"D:\projects\FYP\interprep\python_server\temp"
                try:
                    if file_extension == "pptx":
                        # Convert all PPTX slides to PNG images
                        print(f"🔄 Converting PPTX to PNG images for user: {user_id}")
                        pptx_to_pngs_and_upload(local_file_path, output_dir, user_id)
                        print(f"✅ PPTX slides converted successfully")
                    elif file_extension == "pdf":
                        # Convert all PDF pages to PNG images
                        print(f"🔄 Converting PDF pages to images for user: {user_id}")
                        result = pdf_all_pages_to_images(local_file_path, output_dir, user_id)
                        if result:
                            print(f"✅ PDF {len(result)} pages converted successfully")
                        else:
                            print(f"⚠️ PDF image conversion failed (poppler not installed or error occurred)")
                            print(f"   Questions will still be generated, but slide images won't be available")
                except Exception as slide_error:
                    print(f"⚠️ Warning: Slide generation failed: {str(slide_error)}")
                    print(f"   Questions will still be generated, but slides won't be available")
                    # Continue with question generation even if slide conversion fails

            if is_interview:
                formData = {"jd": jd, "position": position, "experience": experience}
                questions = interviewQuestionGeneration(extracted_text, formData, model_type=model_type)
            else:
                questions = questionGeneration(extracted_text, model_type=model_type)


            if not isinstance(questions, str):
                print(f"ERROR: OpenAI response is not a string: {questions}")
                return jsonify({"error": "Failed to generate questions (Non-string response)"}), 500
            convertedQuestions = [q.strip() for q in questions.split('\n') if q.strip()]
            audio_urls = []
            for idx, question in enumerate(convertedQuestions):
                audio_path = textToSpeech(question, f"{user_id}_question_{idx}.mp3")
                audio_url = upload_file_to_firebase(audio_path)
                os.remove(audio_path)
                audio_urls.append(audio_url)

            audio_docs_ref = db.collection("questionAudios").document(user_id)
            audio_docs_ref.set({"audioLinks": audio_urls}, merge=False)

            return jsonify(
                {
                    "generated_questions": questions,
                    "extracted_text": extracted_text,
                    "audio_urls": audio_urls,
                }
            )
        else:
            return jsonify({"error": "Unsupported file type"}), 400
    except Exception as api_e:
            # Print the specific error that caused the crash
            print(f"--- FATAL API CRASH --- Error details: {api_e}") 
            return jsonify({"error": f"OpenAI/Generation Failed: {str(api_e)}"}), 500


# ============================================================
# VAPI Real-Time Interview Endpoints
# ============================================================

from vapi_integration import (
    create_interview_assistant,
    start_web_call,
    get_call_details,
    analyze_interview_transcript,
    save_interview_session,
    delete_assistant
)

@app.route("/api/vapi/create-assistant", methods=["POST"])
def vapi_create_assistant():
    """Create a VAPI assistant for real-time interview based on resume."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        resume_text = data.get("resumeText", "")
        jd = data.get("jd", "")
        position = data.get("position", "")
        experience = data.get("experience", "")
        
        if not resume_text:
            return jsonify({"error": "Resume text is required"}), 400
        
        print(f"🎤 Creating VAPI interview assistant...")
        print(f"   Position: {position}")
        print(f"   Experience: {experience}")
        
        result = create_interview_assistant(resume_text, jd, position, experience)
        
        if result.get("success"):
            return jsonify({
                "success": True,
                "assistantId": result.get("assistant_id"),
                "assistantName": result.get("assistant_name")
            }), 200
        else:
            return jsonify({
                "success": False,
                "error": result.get("error")
            }), 500
            
    except Exception as e:
        print(f"❌ Error in vapi_create_assistant: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/start-session", methods=["POST"])
def vapi_start_session():
    """Start a VAPI interview session - returns config for frontend."""
    try:
        data = request.get_json()
        
        assistant_id = data.get("assistantId")
        user_id = data.get("userId")
        
        if not assistant_id or not user_id:
            return jsonify({"error": "assistantId and userId are required"}), 400
        
        print(f"🎙️ Starting VAPI session for user: {user_id}")
        
        result = start_web_call(assistant_id, user_id)
        
        if result.get("success"):
            return jsonify({
                "success": True,
                "config": result.get("config"),
                "publicKey": result.get("public_key")
            }), 200
        else:
            return jsonify({
                "success": False,
                "error": result.get("error")
            }), 500
            
    except Exception as e:
        print(f"❌ Error in vapi_start_session: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/end-session", methods=["POST"])
def vapi_end_session():
    """End VAPI session and process feedback."""
    try:
        data = request.get_json()
        
        call_id = data.get("callId")
        user_id = data.get("userId")
        assistant_id = data.get("assistantId")
        resume_text = data.get("resumeText", "")
        
        if not call_id or not user_id:
            return jsonify({"error": "callId and userId are required"}), 400
        
        print(f"📞 Ending VAPI session: {call_id}")
        
        # Get call details including transcript
        call_details = get_call_details(call_id)
        
        if not call_details.get("success"):
            return jsonify({
                "success": False,
                "error": "Could not retrieve call details"
            }), 500
        
        transcript = call_details.get("transcript", "")
        duration = call_details.get("duration", 0)
        recording_url = call_details.get("recording_url")
        
        print(f"📝 Transcript length: {len(transcript)} chars")
        print(f"⏱️ Duration: {duration} seconds")
        
        # Analyze transcript for feedback
        feedback_result = analyze_interview_transcript(transcript, resume_text)
        
        # Save session to Firestore
        session_data = {
            "call_id": call_id,
            "assistant_id": assistant_id,
            "duration": duration,
            "transcript": transcript,
            "recording_url": recording_url,
            "feedback": feedback_result.get("feedback", {})
        }
        
        save_interview_session(user_id, session_data)
        
        # Optionally delete the assistant after use
        if assistant_id:
            delete_assistant(assistant_id)
        
        return jsonify({
            "success": True,
            "transcript": transcript,
            "duration": duration,
            "recordingUrl": recording_url,
            "feedback": feedback_result.get("feedback", {})
        }), 200
        
    except Exception as e:
        print(f"❌ Error in vapi_end_session: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/webhook", methods=["POST"])
def vapi_webhook():
    """Handle VAPI webhooks for real-time events."""
    try:
        data = request.get_json()
        event_type = data.get("type")
        
        print(f"📡 VAPI Webhook received: {event_type}")
        
        # Handle different event types
        if event_type == "call-started":
            print(f"   Call started: {data.get('call', {}).get('id')}")
        elif event_type == "call-ended":
            print(f"   Call ended: {data.get('call', {}).get('id')}")
        elif event_type == "transcript":
            print(f"   Transcript update received")
        elif event_type == "speech-update":
            print(f"   Speech update: {data.get('role')} - {data.get('status')}")
        
        return jsonify({"received": True}), 200
        
    except Exception as e:
        print(f"❌ Webhook error: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/get-feedback/<session_id>", methods=["GET"])
def vapi_get_feedback(session_id):
    """Get feedback for a specific VAPI interview session."""
    try:
        user_id = request.args.get("userId")
        
        if not user_id:
            return jsonify({"error": "userId is required"}), 400
        
        # Get session from Firestore
        sessions_ref = db.collection("sessions").document(user_id)
        doc = sessions_ref.get()
        
        if not doc.exists:
            return jsonify({"error": "No sessions found"}), 404
        
        sessions = doc.to_dict().get("sessions", [])
        
        # Find the VAPI session with matching call_id
        for session in sessions:
            if session.get("call_id") == session_id:
                return jsonify({
                    "success": True,
                    "feedback": session.get("feedback", {}),
                    "transcript": session.get("transcript", ""),
                    "duration": session.get("duration", 0),
                    "recordingUrl": session.get("recording_url")
                }), 200
        
        return jsonify({"error": "Session not found"}), 404
        
    except Exception as e:
        print(f"❌ Error getting feedback: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ============================================================
# Enhanced Secure VAPI Endpoints (Phase 2)
# ============================================================

# Import secure session and interview brain modules
try:
    from vapi_secure_session import (
        generate_session_token,
        validate_session_token,
        create_secure_assistant,
        update_session_call_id,
        append_transcript_chunk,
        get_session_data,
        end_session as secure_end_session,
        get_call_transcript,
        delete_assistant as secure_delete_assistant
    )
    from interview_brain import (
        parse_resume_for_interview,
        generate_interview_strategy,
        build_system_prompt,
        score_interview_transcript
    )
    SECURE_VAPI_AVAILABLE = True
    print("✅ Secure VAPI modules loaded")
except ImportError as e:
    print(f"⚠️ Secure VAPI modules not available: {e}")
    import traceback
    traceback.print_exc()
    SECURE_VAPI_AVAILABLE = False


@app.route("/api/vapi/health", methods=["GET"])
def vapi_health_check():
    """
    Diagnostic endpoint to check what's working/broken.
    Hit http://127.0.0.1:5000/api/vapi/health in browser.
    """
    status = {
        "secure_vapi_modules": SECURE_VAPI_AVAILABLE,
        "gemini_model": None,
        "gemini_test": None,
        "vapi_keys": None,
    }
    
    # Check Gemini
    try:
        from interview_brain import gemini_model as gm, _active_model_name
        status["gemini_model"] = _active_model_name if gm else "NOT INITIALIZED"
        
        if gm:
            # Quick test call
            try:
                test_resp = gm.generate_content("Say hello in 3 words.")
                status["gemini_test"] = f"OK: {test_resp.text[:50]}"
            except Exception as ge:
                status["gemini_test"] = f"FAILED: {str(ge)[:200]}"
        else:
            status["gemini_test"] = "SKIPPED (model is None)"
    except Exception as e:
        status["gemini_model"] = f"IMPORT ERROR: {str(e)}"
    
    # Check VAPI keys
    try:
        from key import VapiPrivateKey, VapiPublicKey
        status["vapi_keys"] = {
            "private_key_set": bool(VapiPrivateKey and len(VapiPrivateKey) > 10),
            "public_key_set": bool(VapiPublicKey and len(VapiPublicKey) > 10),
            "private_key_preview": VapiPrivateKey[:8] + "..." if VapiPrivateKey else "MISSING",
        }
        
        # Quick VAPI API test
        import requests as req
        try:
            resp = req.get(
                "https://api.vapi.ai/assistant",
                headers={
                    "Authorization": f"Bearer {VapiPrivateKey}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            status["vapi_api_test"] = f"HTTP {resp.status_code}"
            if resp.status_code != 200:
                status["vapi_api_error"] = resp.text[:300]
        except Exception as ve:
            status["vapi_api_test"] = f"FAILED: {str(ve)[:200]}"
    except Exception as e:
        status["vapi_keys"] = f"IMPORT ERROR: {str(e)}"
    
    # Check JWT
    try:
        import jwt
        status["jwt_available"] = True
    except ImportError:
        status["jwt_available"] = False
    
    return jsonify(status), 200

@app.route("/api/vapi/secure-session", methods=["POST"])
def vapi_secure_session():
    """
    Create a secure VAPI session with server-generated token.
    NO API KEYS are exposed to client - only short-lived tokens.
    """
    
    if not SECURE_VAPI_AVAILABLE:
        print("❌ SECURE_VAPI_AVAILABLE is False — modules failed to import at startup")
        return jsonify({
            "success": False,
            "error": "Secure VAPI modules not loaded. Check server startup logs for import errors."
        }), 500
    
    current_step = "initialization"
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"success": False, "error": "No JSON body provided"}), 400
        
        # Required fields
        resume_text = data.get("resumeText", "")
        user_id = data.get("userId", "")
        
        # Optional fields
        jd = data.get("jd", "")
        position = data.get("position", "Software Engineer")
        experience = data.get("experience", "")
        duration_minutes = data.get("durationMinutes", 15)  # 10-20 min
        
        if not resume_text:
            return jsonify({"success": False, "error": "resumeText is required"}), 400
        if not user_id:
            return jsonify({"success": False, "error": "userId is required"}), 400
        
        print(f"🔒 Creating secure VAPI session for user: {user_id[:8]}...")
        print(f"   Position: {position}")
        print(f"   Duration: {duration_minutes} minutes")
        print(f"   Resume length: {len(resume_text)} chars")
        
        # Step 1: Parse resume with LLM brain
        current_step = "resume_parsing"
        print("   📄 Step 1: Parsing resume context...")
        try:
            resume_context = parse_resume_for_interview(resume_text)
            print(f"   ✅ Resume parsed: name={resume_context.name}, skills={len(resume_context.skills)}, projects={len(resume_context.projects)}")
        except Exception as parse_err:
            print(f"   ❌ Resume parsing failed: {parse_err}")
            import traceback
            traceback.print_exc()
            # Fallback: create minimal context so we can still proceed
            from interview_brain import ResumeContext, extract_skills_basic
            resume_context = ResumeContext(
                name="Candidate",
                role=position or "Professional",
                experience_years=2,
                skills=extract_skills_basic(resume_text),
                technical_skills=[],
                soft_skills=[],
                projects=[],
                education=[],
                achievements=[],
                summary=resume_text[:200]
            )
            print(f"   ⚠️ Using fallback resume context (basic extraction)")
        
        # Step 2: Generate interview strategy
        current_step = "strategy_generation"
        print("   🧠 Step 2: Generating interview strategy...")
        try:
            strategy = generate_interview_strategy(
                context=resume_context,
                jd=jd,
                position=position,
                duration_minutes=duration_minutes
            )
            print(f"   ✅ Strategy generated: focus_areas={strategy.focus_areas[:3]}")
        except Exception as strat_err:
            print(f"   ❌ Strategy generation failed: {strat_err}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False,
                "error": f"Interview strategy generation failed: {str(strat_err)}"
            }), 500
        
        # Step 3: Create VAPI assistant with intelligent prompt
        current_step = "vapi_assistant_creation"
        # Build first message as a warm introduction / ice-breaker.
        # IMPORTANT: The firstMessage must NOT ask CV-based questions.
        # The system prompt instructs the AI to follow a strict 5-phase flow:
        #   Phase 1 (Introduction) → Phase 2 (CV questions) → Phase 3 → ...
        # If we put a CV question in firstMessage, the AI skips Phase 1 entirely
        # because it thinks the interview has already started at Phase 2.
        # So firstMessage must be a simple greeting + "introduce yourself" question.
        candidate_name = resume_context.name if resume_context.name and resume_context.name != "Candidate" else ""
        
        greeting = (
            f"Hello{' ' + candidate_name if candidate_name else ''}! "
            f"Welcome to the interview. Thank you so much for joining today. "
            f"I'm really looking forward to learning more about you. "
            f"Let's start by getting to know you a little. "
            f"Can you please introduce yourself and tell me a bit about your background?"
        )
        first_message = greeting
        
        print("   🤖 Step 3: Creating VAPI assistant...")
        try:
            assistant_result = create_secure_assistant(
                system_prompt=strategy.system_prompt,
                first_message=first_message,
                voice_id="Savannah",  # VAPI active voice - Female, American
                duration_minutes=duration_minutes
            )
        except Exception as vapi_err:
            print(f"   ❌ VAPI assistant creation exception: {vapi_err}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False,
                "error": f"VAPI assistant creation failed: {str(vapi_err)}"
            }), 500
        
        if not assistant_result.get("success"):
            error_detail = assistant_result.get("error", "Failed to create assistant")
            print(f"   ❌ VAPI returned error: {error_detail[:300]}")
            return jsonify({
                "success": False,
                "error": f"VAPI assistant creation failed: {error_detail[:500]}"
            }), 500
        
        assistant_id = assistant_result.get("assistant_id")
        print(f"   ✅ VAPI assistant created: {assistant_id}")
        
        # Step 4: Generate secure session token
        current_step = "token_generation"
        print("   🔐 Step 4: Generating session token...")
        try:
            token_data = generate_session_token(
                assistant_id=assistant_id,
                user_id=user_id,
                duration_minutes=duration_minutes
            )
        except Exception as token_err:
            print(f"   ❌ Token generation failed: {token_err}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False,
                "error": f"Session token generation failed: {str(token_err)}"
            }), 500
        
        print(f"✅ Secure session created: {token_data.get('session_id', '')[:8]}...")
        
        # Save resume context to session for later scoring
        session_id = token_data.get("session_id")
        if session_id:
            session = get_session_data(session_id)
            if session:
                session["resume_context"] = {
                    "name": resume_context.name,
                    "role": resume_context.role,
                    "experience_years": resume_context.experience_years,
                    "skills": resume_context.skills[:20],
                    "technical_skills": resume_context.technical_skills[:15]
                }
        
        return jsonify({
            "success": True,
            "sessionToken": token_data.get("session_token"),
            "sessionId": token_data.get("session_id"),
            "assistantId": assistant_id,
            "publicKey": token_data.get("public_key"),
            "expiresAt": token_data.get("expires_at"),
            "durationMinutes": duration_minutes,
            "interviewStrategy": {
                "focusAreas": strategy.focus_areas[:5],
                "timeAllocation": strategy.time_allocation
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Secure session error at step [{current_step}]: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "error": f"Secure session failed at step '{current_step}': {str(e)}"
        }), 500



@app.route("/api/vapi/validate-token", methods=["POST"])
def vapi_validate_token():
    """Validate a session token."""
    
    if not SECURE_VAPI_AVAILABLE:
        return jsonify({"error": "Secure VAPI not available"}), 500
    
    try:
        data = request.get_json()
        token = data.get("token", "")
        
        payload = validate_session_token(token)
        
        if payload:
            return jsonify({
                "valid": True,
                "sessionId": payload.get("session_id"),
                "assistantId": payload.get("assistant_id")
            }), 200
        else:
            return jsonify({"valid": False}), 401
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/transcript-webhook", methods=["POST"])
def vapi_transcript_webhook():
    """
    Webhook to receive transcript chunks in real-time.
    Stores to Firebase for live transcript display.
    """
    
    if not SECURE_VAPI_AVAILABLE:
        return jsonify({"error": "Secure VAPI not available"}), 500
    
    try:
        data = request.get_json()
        
        event_type = data.get("type")
        call_data = data.get("call", {})
        call_id = call_data.get("id")
        
        print(f"📡 Transcript webhook: {event_type}")
        
        # Find session by call_id
        session_id = data.get("metadata", {}).get("session_id")
        
        if event_type == "transcript":
            transcript_chunk = {
                "role": data.get("role", "unknown"),
                "text": data.get("transcript", ""),
                "isFinal": data.get("isFinal", False)
            }
            
            if session_id:
                append_transcript_chunk(session_id, transcript_chunk)
            
            # Also store to Firebase
            try:
                db = get_firestore_instance()
                if call_id:
                    transcript_ref = db.collection("vapi_transcripts").document(call_id)
                    transcript_ref.set({
                        "chunks": firestore.ArrayUnion([transcript_chunk]),
                        "updatedAt": datetime.now().isoformat()
                    }, merge=True)
            except:
                pass  # Non-critical
        
        elif event_type == "end-of-call-report":
            # Full transcript available
            print(f"   📝 End of call report received")
            
            # Get full transcript
            transcript = data.get("artifact", {}).get("transcript", "")
            recording_url = data.get("artifact", {}).get("recordingUrl")
            
            if call_id:
                try:
                    db = get_firestore_instance()
                    transcript_ref = db.collection("vapi_transcripts").document(call_id)
                    transcript_ref.set({
                        "fullTranscript": transcript,
                        "recordingUrl": recording_url,
                        "completedAt": datetime.now().isoformat()
                    }, merge=True)
                except:
                    pass
        
        return jsonify({"received": True}), 200
        
    except Exception as e:
        print(f"❌ Transcript webhook error: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ════════════════════════════════════════════════════════════
# NVC BODY LANGUAGE ENDPOINTS
# ════════════════════════════════════════════════════════════

@app.route("/api/nvc/start", methods=["POST"])
def nvc_start():
    """Start NVC analysis when interview begins."""
    if not NVC_AVAILABLE:
        return jsonify({"success": False, "error": "NVC module not available"}), 200
    data = request.get_json()
    session_id = data.get("sessionId", "")
    if not session_id:
        return jsonify({"success": False, "error": "sessionId required"}), 400
    result = start_nvc_session(session_id)
    return jsonify(result), 200


@app.route("/api/nvc/frame", methods=["POST"])
def nvc_frame():
    """Receive a webcam frame for NVC analysis."""
    if not NVC_AVAILABLE:
        return jsonify({"success": False}), 200
    session_id = request.form.get("sessionId", "")
    frame_file = request.files.get("frame")
    if not session_id or not frame_file:
        return jsonify({"success": False, "error": "sessionId and frame required"}), 400
    frame_bytes = frame_file.read()
    result = process_nvc_frame(session_id, frame_bytes)
    return jsonify(result), 200


@app.route("/api/nvc/status/<session_id>", methods=["GET"])
def nvc_status(session_id):
    """Get NVC session status."""
    if not NVC_AVAILABLE:
        return jsonify({"active": False}), 200
    return jsonify(get_nvc_status(session_id)), 200


@app.route("/api/vapi/complete-session", methods=["POST"])
def vapi_complete_session():
    """
    Complete interview session and generate comprehensive feedback.
    Uses LLM brain for scoring.
    """
    
    if not SECURE_VAPI_AVAILABLE:
        return jsonify({"error": "Secure VAPI not available"}), 500
    
    try:
        data = request.get_json()
        
        session_id = data.get("sessionId")
        call_id = data.get("callId")
        user_id = data.get("userId")
        duration_seconds = data.get("durationSeconds", 0)
        
        if not session_id or not user_id:
            return jsonify({"error": "sessionId and userId required"}), 400
        
        print(f"🏁 Completing session: {session_id[:8]}...")
        
        # Get session data
        session_data = get_session_data(session_id)
        
        if not session_data:
            return jsonify({"error": "Session not found"}), 404
        
        assistant_id = session_data.get("assistant_id")
        resume_context_dict = session_data.get("resume_context", {})
        
        # Get transcript from VAPI
        transcript = ""
        recording_url = None
        
        if call_id:
            print("   📥 Fetching transcript from VAPI...")
            call_data = get_call_transcript(call_id)
            if call_data.get("success"):
                transcript = call_data.get("transcript", "")
                recording_url = call_data.get("recording_url")
        
        # Fallback: get transcript chunks from session or local UI transcript
        if not transcript:
            local_transcript = data.get("localTranscript", "")
            if local_transcript:
                print("   📥 Using local transcript from Flutter UI...")
                transcript = local_transcript
            elif session_data.get("transcript_chunks"):
                transcript = "\n".join([
                    f"{chunk.get('role', 'unknown')}: {chunk.get('text', '')}"
                    for chunk in session_data.get("transcript_chunks", [])
                ])
        
        print(f"   📝 Transcript length: {len(transcript)} chars")
        
        # Reconstruct resume context
        from interview_brain import ResumeContext
        resume_context = ResumeContext(
            name=resume_context_dict.get("name", "Candidate"),
            role=resume_context_dict.get("role", "Professional"),
            experience_years=resume_context_dict.get("experience_years", 0),
            skills=resume_context_dict.get("skills", []),
            technical_skills=resume_context_dict.get("technical_skills", []),
            soft_skills=[],
            projects=[],
            education=[],
            achievements=[],
            summary=""
        )
        
        # Score with LLM brain
        print("   🧠 Analyzing with LLM brain...")
        scores = score_interview_transcript(
            transcript=transcript,
            context=resume_context,
            duration_seconds=duration_seconds
        )
        
        # NVC Body Language Analysis
        nvc_scores = {}
        nvc_report_path = None
        
        # Build interview_data dict to pass Q&A analysis to the PDF report
        interview_data = {
            "overall_score": scores.get("overall_score", 0),
            "qa_analysis": scores.get("qa_analysis", []),
            "voice_analysis": scores.get("voice_analysis", {
                "pitch_tone_feedback": "Not available",
                "sentiment": "Neutral",
                "sentiment_score": 0
            }),
            "scores": scores.get("scores", {}),
            "strengths": scores.get("strengths", []),
            "areas_for_improvement": scores.get("areas_for_improvement", []),
            "detailed_feedback": scores.get("detailed_feedback", ""),
            "recommendation": scores.get("recommendation", ""),
        }
        
        # ── Real Voice/Sentiment Analysis from transcript ──
        # The LLM sometimes returns 0 for voice_analysis because it can't
        # truly analyze audio. Use NLTK VADER on the candidate's spoken
        # words to get actual sentiment scores.
        try:
            from Audio_modules.sentiment import analyze_and_classify_sentiment
            # Extract only user/candidate lines from transcript
            user_lines = []
            for line in transcript.split('\n'):
                l = line.strip().lower()
                if l.startswith(('user:', 'candidate:', 'you:')):
                    text = line.split(':', 1)[-1].strip() if ':' in line else line.strip()
                    if text:
                        user_lines.append(text)
            
            candidate_text = ' '.join(user_lines)
            
            if candidate_text and len(candidate_text.strip()) > 10:
                sentiment_score_raw, sentiment_class = analyze_and_classify_sentiment(candidate_text)
                # Convert VADER compound score (-1 to 1) to 0-100 scale
                sentiment_pct = int(max(0, min(100, (sentiment_score_raw + 1) * 50)))
                
                # Calculate speech engagement metrics
                word_count = len(candidate_text.split())
                avg_words_per_response = word_count / max(len(user_lines), 1)
                
                # Build informative pitch/tone feedback
                if sentiment_pct >= 70:
                    tone_feedback = f"Your tone was confident and positive throughout the interview. You spoke {word_count} words across {len(user_lines)} responses (avg {avg_words_per_response:.0f} words/response), showing strong engagement and articulation."
                elif sentiment_pct >= 40:
                    tone_feedback = f"Your tone was mostly neutral and steady. You spoke {word_count} words across {len(user_lines)} responses (avg {avg_words_per_response:.0f} words/response). Try to add more enthusiasm to convey confidence."
                else:
                    tone_feedback = f"Your tone appeared nervous or hesitant. You spoke {word_count} words across {len(user_lines)} responses (avg {avg_words_per_response:.0f} words/response). Practice speaking with more energy and conviction."
                
                # Only override LLM voice_analysis if it returned 0 or empty
                llm_voice = interview_data.get("voice_analysis", {})
                if not llm_voice.get("sentiment_score") or llm_voice.get("sentiment_score") == 0:
                    interview_data["voice_analysis"] = {
                        "pitch_tone_feedback": tone_feedback,
                        "sentiment": sentiment_class,
                        "sentiment_score": sentiment_pct
                    }
                    print(f"   🎤 Voice analysis (VADER): {sentiment_class} ({sentiment_pct}%)")
                else:
                    print(f"   🎤 Voice analysis (LLM): {llm_voice.get('sentiment')} ({llm_voice.get('sentiment_score')}%)")
            else:
                print("   ⚠️ Not enough candidate speech for voice analysis")
        except Exception as e:
            print(f"   ⚠️ Voice sentiment analysis error: {e}")
        
        if NVC_AVAILABLE:
            try:
                print("   👁️ Analyzing body language (NVC)...")
                nvc_result = complete_nvc_session(
                    session_id,
                    candidate_name=resume_context.name,
                    position=resume_context.role,
                    interview_data=interview_data
                )
                if nvc_result.get("success"):
                    nvc_scores = nvc_result.get("scores", {})
                    nvc_report_path = nvc_result.get("report_path")
                    print(f"   ✅ NVC score: {nvc_scores.get('overall_body_language_score', 'N/A')}/10")
                else:
                    print(f"   ⚠️ NVC: {nvc_result.get('error', 'no data')}")
            except Exception as e:
                print(f"   ⚠️ NVC analysis error: {e}")
        
        # Save complete session to Firebase
        print("   💾 Saving to Firebase...")
        db = get_firestore_instance()
        interview_doc = {
            "userId": user_id,
            "sessionId": session_id,
            "callId": call_id,
            "assistantId": assistant_id,
            "transcript": transcript[:50000],  # Limit size
            "recordingUrl": recording_url,
            "durationSeconds": duration_seconds,
            "scores": scores,
            "nvcScores": nvc_scores,
            "nvcReportPath": nvc_report_path,
            "resumeContext": resume_context_dict,
            "createdAt": session_data.get("created_at"),
            "completedAt": datetime.now().isoformat(),
            "status": "completed"
        }
        
        # Save to vapi_interviews collection
        interviews_ref = db.collection("vapi_interviews").document(session_id)
        interviews_ref.set(interview_doc)
        
        # Also add to user's sessions
        user_sessions_ref = db.collection("sessions").document(user_id)
        user_sessions_ref.set({
            "vapiInterviews": firestore.ArrayUnion([{
                "sessionId": session_id,
                "completedAt": datetime.now().isoformat(),
                "overallScore": scores.get("overall_score", 0)
            }])
        }, merge=True)
        
        # Clean up: delete assistant
        if assistant_id:
            secure_delete_assistant(assistant_id)
        
        # Mark session as completed
        secure_end_session(session_id)
        
        print(f"✅ Session completed with score: {scores.get('overall_score', 'N/A')}")
        
        return jsonify({
            "success": True,
            "sessionId": session_id,
            "transcript": transcript,
            "recordingUrl": recording_url,
            "durationSeconds": duration_seconds,
            "feedback": {
                "overall_score": scores.get("overall_score", 0),
                "communication_score": scores.get("scores", {}).get("communication_clarity", 0),
                "technical_score": scores.get("scores", {}).get("technical_accuracy", 0),
                "confidence_score": scores.get("scores", {}).get("confidence", 0),
                "problem_solving_score": scores.get("scores", {}).get("problem_solving", 0),
                "cultural_fit_score": scores.get("scores", {}).get("cultural_fit", 0),
                "scores": scores.get("scores", {}),
                "strengths": scores.get("strengths", []),
                "areas_for_improvement": scores.get("areas_for_improvement", []),
                "detailed_feedback": scores.get("detailed_feedback", ""),
                "key_moments": scores.get("key_moments", []),
                "recommendation": scores.get("recommendation", ""),
                "nvc_scores": nvc_scores,
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Complete session error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/vapi/session/<session_id>/transcript", methods=["GET"])
def vapi_get_live_transcript(session_id):
    """Get live transcript for a session (for real-time UI updates)."""
    
    if not SECURE_VAPI_AVAILABLE:
        return jsonify({"error": "Secure VAPI not available"}), 500
    
    try:
        session_data = get_session_data(session_id)
        
        if not session_data:
            return jsonify({"error": "Session not found"}), 404
        
        chunks = session_data.get("transcript_chunks", [])
        
        return jsonify({
            "success": True,
            "chunks": chunks,
            "status": session_data.get("status", "unknown")
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Add firestore import for ArrayUnion
try:
    from google.cloud import firestore
except ImportError:
    firestore = None


if __name__ == "__main__":
        # Pre-load Vosk model at server startup
    print("\n" + "="*50)
    print("🚀 Starting InterPrep Server...")
    print("="*50)
    initialize_vosk_model()
    print("="*50 + "\n")
    app.run(host="0.0.0.0", debug=True)

