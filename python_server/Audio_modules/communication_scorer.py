"""
============================================================================
COMMUNICATION SCORER MODULE
============================================================================
Loads the trained ML model and provides communication scoring functionality.
Integrates with the existing InterPrep Flask server.

Usage:
    from Audio_modules.communication_scorer import get_communication_score, extract_communication_features
    
    features = extract_communication_features(audio_path, transcribed_text)
    score = get_communication_score(features)  # Returns 0-10
============================================================================
"""

import sys
import io
# Fix Windows terminal encoding
if hasattr(sys.stdout, 'buffer'):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import os
import numpy as np
import joblib
import warnings

warnings.filterwarnings('ignore')

# ============================================================
# MODEL LOADING
# ============================================================

# Path to trained model files (relative to python_server/)
_MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml_model")
_MODEL_PATH = os.path.join(_MODEL_DIR, "communication_model.pkl")
_SCALER_PATH = os.path.join(_MODEL_DIR, "communication_scaler.pkl")
_META_PATH = os.path.join(_MODEL_DIR, "model_metadata.pkl")

# Global model variables
_model = None
_scaler = None
_feature_columns = None
_model_loaded = False


def _load_model():
    """Load the trained communication model and scaler at startup."""
    global _model, _scaler, _feature_columns, _model_loaded

    try:
        if not os.path.exists(_MODEL_PATH):
            print(f"[WARN] Communication model not found at: {_MODEL_PATH}")
            print(f"   Server will use default scoring (5.0/10)")
            print(f"   To enable ML scoring, train the model and place files in: {_MODEL_DIR}")
            _model_loaded = False
            return

        if not os.path.exists(_SCALER_PATH):
            print(f"[WARN] Communication scaler not found at: {_SCALER_PATH}")
            _model_loaded = False
            return

        # Load model and scaler
        _model = joblib.load(_MODEL_PATH)
        _scaler = joblib.load(_SCALER_PATH)

        # Load feature column names
        if os.path.exists(_META_PATH):
            meta = joblib.load(_META_PATH)
            _feature_columns = meta.get('feature_columns', _get_default_feature_columns())
            r2 = meta.get('r2_score', 'N/A')
            print(f"[OK] Communication model loaded (R2={r2:.4f})")
        else:
            _feature_columns = _get_default_feature_columns()
            print(f"[OK] Communication model loaded successfully")

        _model_loaded = True

    except Exception as e:
        print(f"[ERROR] Failed to load communication model: {e}")
        _model_loaded = False


def _get_default_feature_columns():
    """Default feature column order (must match training)."""
    return [
        'pitch_mean', 'pitch_std',
        'energy_mean', 'energy_std',
        'mfcc_1', 'mfcc_2', 'mfcc_3', 'mfcc_4', 'mfcc_5',
        'speech_rate', 'pause_rate',
        'sentiment_score', 'vocab_score', 'word_count'
    ]


# Load model when this module is imported
_load_model()


# ============================================================
# FEATURE EXTRACTION (for live audio during interview)
# ============================================================
def extract_communication_features(audio_path, transcribed_text=""):
    """
    Extract communication features from an audio file.
    This is used during live interview processing in server.py.

    Parameters:
    - audio_path: Path to audio file (.mp3 or .wav)
    - transcribed_text: The transcribed text from STT

    Returns:
    - dict with all feature values
    """
    try:
        import librosa
        import textstat

        # Load audio
        y, sr = librosa.load(audio_path, sr=16000, mono=True)
        duration = librosa.get_duration(y=y, sr=sr)

        if duration < 0.1:
            return _get_default_features()

        features = {}

        # Pitch proxy: Spectral Centroid (must match training script!)
        # Training used spectral_centroid NOT pyin
        try:
            cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
            features['pitch_mean'] = float(np.mean(cent))
            features['pitch_std'] = float(np.std(cent))
        except Exception:
            features['pitch_mean'] = 0.0
            features['pitch_std'] = 0.0

        # Energy (RMS)
        try:
            rms = librosa.feature.rms(y=y)[0]
            features['energy_mean'] = float(np.mean(rms))
            features['energy_std'] = float(np.std(rms))
        except Exception:
            features['energy_mean'] = 0.0
            features['energy_std'] = 0.0

        # MFCC (first 5)
        try:
            mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=5)
            for i in range(5):
                features[f'mfcc_{i+1}'] = float(np.mean(mfccs[i]))
        except Exception:
            for i in range(5):
                features[f'mfcc_{i+1}'] = 0.0

        # Speech Rate
        try:
            if transcribed_text and len(transcribed_text.strip()) > 0:
                word_count = len(transcribed_text.split())
                features['speech_rate'] = word_count / duration if duration > 0 else 0.0
            else:
                features['speech_rate'] = 0.0
        except Exception:
            features['speech_rate'] = 0.0

        # Pause Rate
        try:
            rms_values = librosa.feature.rms(y=y)[0]
            threshold = np.mean(rms_values) * 0.3
            is_silent = rms_values < threshold
            silence_starts = 0
            for i in range(1, len(is_silent)):
                if is_silent[i] and not is_silent[i - 1]:
                    silence_starts += 1
            features['pause_rate'] = silence_starts / duration if duration > 0 else 0.0
        except Exception:
            features['pause_rate'] = 0.0

        # Sentiment Score (using NLTK VADER - already available in project)
        try:
            from nltk.sentiment import SentimentIntensityAnalyzer
            sid = SentimentIntensityAnalyzer()
            scores = sid.polarity_scores(transcribed_text if transcribed_text else "")
            features['sentiment_score'] = float(scores['compound'])
        except Exception:
            features['sentiment_score'] = 0.0

        # Vocab Score
        try:
            if transcribed_text and len(transcribed_text.strip()) > 0:
                features['vocab_score'] = float(textstat.flesch_kincaid_grade(transcribed_text))
            else:
                features['vocab_score'] = 0.0
        except Exception:
            features['vocab_score'] = 0.0

        # Word Count
        try:
            features['word_count'] = len(transcribed_text.split()) if transcribed_text else 0
        except Exception:
            features['word_count'] = 0

        return features

    except Exception as e:
        print(f"[ERROR] Communication feature extraction failed: {e}")
        return _get_default_features()


def _get_default_features():
    """Return default feature values when extraction fails."""
    return {
        'pitch_mean': 0.0, 'pitch_std': 0.0,
        'energy_mean': 0.0, 'energy_std': 0.0,
        'mfcc_1': 0.0, 'mfcc_2': 0.0, 'mfcc_3': 0.0, 'mfcc_4': 0.0, 'mfcc_5': 0.0,
        'speech_rate': 0.0, 'pause_rate': 0.0,
        'sentiment_score': 0.0, 'vocab_score': 0.0,
        'word_count': 0
    }


# ============================================================
# SCORING FUNCTION
# ============================================================
def get_communication_score(audio_features):
    """
    Get communication score from extracted audio features.
    Uses the trained ML model to predict a score.

    Parameters:
    - audio_features: dict with keys matching feature_columns
      (output of extract_communication_features)

    Returns:
    - float: Communication score from 0 to 10
    """
    try:
        if not _model_loaded or _model is None or _scaler is None:
            # Model not available - return default mid score
            print("[WARN] Communication model not loaded, using default score")
            return 5.0

        # Build feature vector in correct order
        columns = _feature_columns or _get_default_feature_columns()
        feature_vector = []
        for col in columns:
            feature_vector.append(float(audio_features.get(col, 0.0)))

        # Reshape for prediction
        X = np.array(feature_vector).reshape(1, -1)

        # Scale features
        X_scaled = _scaler.transform(X)

        # Predict (model outputs 0-1 scale)
        prediction = _model.predict(X_scaled)[0]

        # Clamp to valid range and convert to 0-10 scale
        prediction = max(0.0, min(1.0, prediction))
        score_0_to_10 = round(prediction * 10, 2)

        return score_0_to_10

    except Exception as e:
        print(f"[ERROR] Communication scoring failed: {e}")
        return 5.0  # Default fallback score


def is_model_loaded():
    """Check if the ML model is loaded and ready."""
    return _model_loaded
