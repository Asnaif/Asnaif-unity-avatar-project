from vosk import Model, KaldiRecognizer
from pydub import AudioSegment
import json
import os
import shutil
import threading

# Global model cache - load once, reuse many times
_loaded_model = None
_model_lock = threading.Lock()
_model_path = "D:/vosk_models/vosk-model-small-en-us-0.15"

def initialize_vosk_model():
    """Pre-load Vosk model when server starts"""
    global _loaded_model
    if _loaded_model is None:
        with _model_lock:
            if _loaded_model is None:
                print("🔄 Pre-loading Vosk model at server startup...")
                try:
                    _loaded_model = Model(model_path=_model_path)
                    print("✅ Vosk model pre-loaded and ready!")
                except Exception as e:
                    print(f"⚠️ Failed to pre-load Vosk model: {e}")
                    print("   Model will be loaded on first use instead.")
    return _loaded_model

def _get_model():
    """Get cached model (load if not already loaded)"""
    global _loaded_model
    if _loaded_model is None:
        with _model_lock:
            # Double-check after acquiring lock (thread-safe pattern)
            if _loaded_model is None:
                print("🔄 Loading Vosk model (lazy load)...")
                _loaded_model = Model(model_path=_model_path)
                print("✅ Vosk model loaded and cached")
    return _loaded_model

def check_ffmpeg_available():
    """Check if ffmpeg is available in the system PATH"""
    return shutil.which("ffmpeg") is not None

def transcribe_audio(audio_file_path):
    FRAME_RATE = 16000
    CHANNELS = 1

    try:
        if not os.path.exists(audio_file_path):
            raise FileNotFoundError(f"Audio file not found: {audio_file_path}")
        
        if not check_ffmpeg_available():
            raise RuntimeError(
                "ffmpeg is not installed or not in PATH. "
                "Please install ffmpeg:\n"
                "Windows: Download from https://ffmpeg.org/download.html or use: choco install ffmpeg\n"
                "Or add ffmpeg to your system PATH."
            )

        # Use cached model instead of loading every time
        model = _get_model()
        rec = KaldiRecognizer(model, FRAME_RATE)
        rec.SetWords(True)

        mp3 = AudioSegment.from_mp3(audio_file_path)
        mp3 = mp3.set_channels(CHANNELS)
        mp3 = mp3.set_frame_rate(FRAME_RATE)
        
        rec.AcceptWaveform(mp3.raw_data)
        result = rec.Result()
        
        text = json.loads(result)["text"]
        return text
    except Exception as e:
        error_msg = f"Audio transcription failed: {str(e)}"
        print(f"❌ {error_msg}")
        raise RuntimeError(error_msg)