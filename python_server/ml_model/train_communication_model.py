"""
============================================================================
COMMUNICATION SCORING MODEL - GPU ACCELERATED TRAINING (Kaggle)
============================================================================
InterPrep Project - ML Model for Interview Communication Assessment

DATASET: ChaLearn First Impressions V2
LABEL: "interview" column (0 to 1 scale)
MODEL: XGBoost Regressor (GPU accelerated)

OPTIMIZATIONS:
  1. XGBoost GPU (tree_method='gpu_hist') — 10-50x faster than CPU Random Forest
  2. Parallel feature extraction (joblib) — uses all CPU cores
  3. Optimized audio pipeline — reduced redundant librosa calls

KAGGLE SETUP:
  - Enable GPU: Settings → Accelerator → GPU T4 x2
  - Dataset auto-mounted at /kaggle/input/
============================================================================
"""

import os
import sys
import pickle
import glob
import numpy as np
import pandas as pd
import librosa
import soundfile as sf
import joblib
import textstat
import nltk
import warnings
import time
import subprocess
from scipy.stats import pearsonr
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import r2_score, mean_absolute_error
import matplotlib.pyplot as plt

warnings.filterwarnings('ignore')

# ============================================================
# STEP 0: GPU CHECK
# ============================================================
print("=" * 60)
print("🔍 CHECKING GPU AVAILABILITY")
print("=" * 60)

GPU_AVAILABLE = False
try:
    result = subprocess.run(['nvidia-smi'], capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        GPU_AVAILABLE = True
        print("✅ NVIDIA GPU detected!")
        # Print GPU name
        for line in result.stdout.split('\n'):
            if 'Tesla' in line or 'T4' in line or 'P100' in line or 'V100' in line:
                print(f"   {line.strip()}")
    else:
        print("⚠️ No GPU found. Will use CPU mode.")
except Exception:
    print("⚠️ nvidia-smi not found. Will use CPU mode.")

# Install XGBoost if not available
try:
    import xgboost as xgb
    print(f"✅ XGBoost version: {xgb.__version__}")
    if GPU_AVAILABLE:
        print("   🚀 XGBoost will use GPU acceleration!")
except ImportError:
    print("📦 Installing XGBoost...")
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'xgboost', '-q'], check=True)
    import xgboost as xgb
    print(f"✅ XGBoost installed: {xgb.__version__}")

# Check CPU cores for parallel processing
import multiprocessing
N_CORES = multiprocessing.cpu_count()
print(f"✅ CPU cores available: {N_CORES}")
print()

# ============================================================
# STEP 1: CONFIGURATION - KAGGLE PATHS
# ============================================================
INPUT_DIR = "/kaggle/input/datasets/muhammadasnaifasim/my-interview/dataset"
ANNOTATION_DIR_DIRECT = os.path.join(INPUT_DIR, "annotation")
VIDEO_DIR_DIRECT = os.path.join(INPUT_DIR, "videos")
TRANSCRIPTION_DIR_DIRECT = os.path.join(INPUT_DIR, "transcription")

OUTPUT_DIR = "/kaggle/working/output"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# STEP 1.5: AUTO-DETECT DATASET STRUCTURE
# ============================================================
def auto_detect_paths(input_dir):
    """Auto-detect annotation, videos, and transcription folders."""
    print("🔍 Auto-detecting dataset structure...")
    print(f"   Input directory: {input_dir}")

    if os.path.exists(input_dir):
        contents = os.listdir(input_dir)
        print(f"   Top-level contents: {contents[:20]}")
    else:
        print(f"   ❌ Input directory not found: {input_dir}")
        sys.exit(1)

    # Try direct known paths first
    annotation_dir = ANNOTATION_DIR_DIRECT if os.path.exists(ANNOTATION_DIR_DIRECT) else None
    video_dir = VIDEO_DIR_DIRECT if os.path.exists(VIDEO_DIR_DIRECT) else None
    transcription_dir = TRANSCRIPTION_DIR_DIRECT if os.path.exists(TRANSCRIPTION_DIR_DIRECT) else None

    if annotation_dir:
        pkl_count = len([f for f in os.listdir(annotation_dir) if f.endswith('.pkl')])
        print(f"   ✅ Annotation folder: {annotation_dir} ({pkl_count} pkl files)")
    if video_dir:
        subfolder_count = len([d for d in os.listdir(video_dir) if os.path.isdir(os.path.join(video_dir, d))])
        print(f"   ✅ Videos folder: {video_dir} ({subfolder_count} subfolders)")
    if transcription_dir:
        pkl_count = len([f for f in os.listdir(transcription_dir) if f.endswith('.pkl')])
        print(f"   ✅ Transcription folder: {transcription_dir} ({pkl_count} pkl files)")

    if annotation_dir and video_dir:
        return annotation_dir, video_dir, transcription_dir

    # Fallback: recursive search
    print("   🔄 Scanning recursively...")
    for root, dirs, files in os.walk(input_dir):
        folder_name = os.path.basename(root).lower()
        if folder_name == 'annotation' and annotation_dir is None:
            if any(f.endswith('.pkl') for f in files):
                annotation_dir = root
                print(f"   ✅ Annotation folder: {root}")
        if folder_name == 'transcription' and transcription_dir is None:
            if any(f.endswith('.pkl') for f in files):
                transcription_dir = root
                print(f"   ✅ Transcription folder: {root}")
        if folder_name == 'videos' and video_dir is None:
            if dirs:
                video_dir = root
                print(f"   ✅ Videos folder: {root}")

    if annotation_dir is None:
        print("\n❌ Could not find annotation files!")
        sys.exit(1)

    return annotation_dir, video_dir, transcription_dir


ANNOTATION_DIR, VIDEO_DIR, TRANSCRIPTION_DIR = auto_detect_paths(INPUT_DIR)

print("\n" + "=" * 60)
print("COMMUNICATION SCORING MODEL - GPU ACCELERATED PIPELINE")
print("=" * 60)
print(f"📁 Input:           {INPUT_DIR}")
print(f"📁 Annotations:     {ANNOTATION_DIR}")
print(f"📁 Videos:          {VIDEO_DIR}")
print(f"📁 Transcriptions:  {TRANSCRIPTION_DIR}")
print(f"📁 Output:          {OUTPUT_DIR}")
print(f"🖥️  GPU:             {'✅ Enabled' if GPU_AVAILABLE else '❌ CPU mode'}")
print(f"⚡ Parallel cores:  {N_CORES}")
print()


# ============================================================
# STEP 2: LOAD ANNOTATIONS
# ============================================================
def load_annotations(annotation_dir):
    """Load ChaLearn annotation pickle files (trait-based format)."""
    print("📋 Loading annotations...")
    annotations = {}

    pickle_files = glob.glob(os.path.join(annotation_dir, "*.pkl"))
    if not pickle_files:
        pickle_files = glob.glob(os.path.join(annotation_dir, "*.pickle"))
    if not pickle_files:
        print("❌ No annotation pickle files found!")
        sys.exit(1)

    for pkl_file in pickle_files:
        basename = os.path.basename(pkl_file)
        print(f"   Loading: {basename}")
        try:
            with open(pkl_file, 'rb') as f:
                data = pickle.load(f, encoding='latin1')

            if not isinstance(data, dict):
                continue

            print(f"     Top-level keys: {list(data.keys())}")
            count_before = len(annotations)

            # FORMAT A: Trait-based {trait_name: {video: score}}
            if 'interview' in data:
                interview_data = data['interview']
                if isinstance(interview_data, dict):
                    for video_name, score in interview_data.items():
                        try:
                            annotations[str(video_name)] = float(score)
                        except (TypeError, ValueError):
                            pass
                    added = len(annotations) - count_before
                    print(f"     ✅ 'interview' trait -> {added} annotations")
                    continue

            # FORMAT B: Flat {video: score}
            first_value = next(iter(data.values()), None)
            if isinstance(first_value, (int, float)):
                for video_name, score in data.items():
                    try:
                        annotations[str(video_name)] = float(score)
                    except (TypeError, ValueError):
                        pass
                added = len(annotations) - count_before
                print(f"     ✅ Flat format -> {added} annotations")
                continue

            # FORMAT C: Nested {video: {trait: score}}
            if isinstance(first_value, dict):
                for video_name, traits in data.items():
                    if isinstance(traits, dict) and 'interview' in traits:
                        try:
                            annotations[str(video_name)] = float(traits['interview'])
                        except (TypeError, ValueError):
                            pass
                added = len(annotations) - count_before
                print(f"     ✅ Nested format -> {added} annotations")

        except Exception as e:
            print(f"   ⚠️ Error: {e}")

    print(f"\n✅ Total annotations: {len(annotations)}")
    if annotations:
        scores = list(annotations.values())
        print(f"   Range: {min(scores):.3f} to {max(scores):.3f} | Mean: {np.mean(scores):.3f}")
    else:
        print("   ❌ NO ANNOTATIONS!")
        sys.exit(1)
    return annotations


# ============================================================
# STEP 3: LOAD TRANSCRIPTIONS
# ============================================================
def load_transcriptions(transcription_dir):
    """Load ChaLearn transcription pickle files."""
    print("\n📝 Loading transcriptions...")
    transcriptions = {}

    if transcription_dir is None:
        print("   ⚠️ No transcription folder. Proceeding without text features.")
        return transcriptions

    pickle_files = glob.glob(os.path.join(transcription_dir, "*.pkl"))
    if not pickle_files:
        pickle_files = glob.glob(os.path.join(transcription_dir, "*.pickle"))
    if not pickle_files:
        print("   ⚠️ No transcription files found.")
        return transcriptions

    for pkl_file in pickle_files:
        basename = os.path.basename(pkl_file)
        print(f"   Loading: {basename}")
        try:
            with open(pkl_file, 'rb') as f:
                data = pickle.load(f, encoding='latin1')
            if isinstance(data, dict):
                count_before = len(transcriptions)
                for name, text in data.items():
                    if isinstance(text, bytes):
                        text = text.decode('utf-8', errors='ignore')
                    transcriptions[name] = str(text)
                print(f"     ✅ {len(transcriptions) - count_before} transcriptions")
        except Exception as e:
            print(f"   ⚠️ Error: {e}")

    print(f"   Total: {len(transcriptions)}")
    return transcriptions


# ============================================================
# STEP 4: FIND VIDEO FILES
# ============================================================
def find_video_files(video_dir):
    """Find all .mp4 video files recursively."""
    print("\n🎬 Scanning for video files...")
    if video_dir is None:
        print("❌ No video directory!")
        sys.exit(1)

    video_files = []
    for ext in ['*.mp4', '*.avi', '*.webm']:
        video_files.extend(glob.glob(os.path.join(video_dir, '**', ext), recursive=True))

    print(f"   Found {len(video_files)} total video files")

    if not video_files:
        print("❌ No video files found!")
        sys.exit(1)

    training_count = sum(1 for vf in video_files if 'training' in vf.lower())
    validation_count = sum(1 for vf in video_files if 'validation' in vf.lower())
    test_count = sum(1 for vf in video_files if 'test' in vf.lower())
    print(f"   Training: {training_count} | Validation: {validation_count} | Test: {test_count}")

    return video_files


# ============================================================
# STEP 5: AUDIO EXTRACTION (ffmpeg)
# ============================================================
def extract_audio_from_video(video_path, output_audio_path):
    """Extract audio using ffmpeg (pre-installed on Kaggle)."""
    try:
        cmd = [
            'ffmpeg', '-i', video_path,
            '-vn', '-acodec', 'pcm_s16le',
            '-ar', '16000', '-ac', '1',
            '-y', output_audio_path
        ]
        subprocess.run(cmd, capture_output=True, check=True, timeout=30)
        return output_audio_path
    except Exception:
        return None


# ============================================================
# STEP 6: FEATURE EXTRACTION (Optimized)
# ============================================================
print("🤖 Loading NLTK VADER sentiment analyzer...")
try:
    nltk.download('vader_lexicon', quiet=True)
    from nltk.sentiment import SentimentIntensityAnalyzer
    sentiment_analyzer = SentimentIntensityAnalyzer()
    print("✅ VADER loaded")
except Exception:
    sentiment_analyzer = None


def extract_features_from_audio(audio_path, transcribed_text=None):
    """Extract 14 audio/text features (FAST - no pyin)."""
    try:
        y, sr = librosa.load(audio_path, sr=16000, mono=True)
        duration = librosa.get_duration(y=y, sr=sr)
        if duration < 0.5:
            return None

        features = {}

        # RMS Energy (compute once, reuse for pause rate)
        rms = librosa.feature.rms(y=y)[0]
        features['energy_mean'] = float(np.mean(rms))
        features['energy_std'] = float(np.std(rms))

        # Pitch proxy: Spectral Centroid (100x faster than pyin, similar info)
        # High centroid = bright/energetic voice, Low = dull/monotone
        try:
            cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
            features['pitch_mean'] = float(np.mean(cent))
            features['pitch_std'] = float(np.std(cent))
        except Exception:
            features['pitch_mean'] = 0.0
            features['pitch_std'] = 0.0

        # MFCC (first 5)
        try:
            mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=5)
            for i in range(5):
                features[f'mfcc_{i+1}'] = float(np.mean(mfccs[i]))
        except Exception:
            for i in range(5):
                features[f'mfcc_{i+1}'] = 0.0

        # Speech Rate
        if transcribed_text and len(transcribed_text.strip()) > 0:
            features['speech_rate'] = len(transcribed_text.split()) / duration if duration > 0 else 0.0
        else:
            features['speech_rate'] = 0.0

        # Pause Rate (reuse rms)
        try:
            threshold = np.mean(rms) * 0.3
            is_silent = rms < threshold
            silence_starts = sum(1 for i in range(1, len(is_silent)) if is_silent[i] and not is_silent[i-1])
            features['pause_rate'] = silence_starts / duration if duration > 0 else 0.0
        except Exception:
            features['pause_rate'] = 0.0

        # Sentiment (VADER - instant)
        if transcribed_text and len(transcribed_text.strip()) > 0 and sentiment_analyzer:
            try:
                scores = sentiment_analyzer.polarity_scores(transcribed_text)
                features['sentiment_score'] = float(scores['compound'])
            except Exception:
                features['sentiment_score'] = 0.0
        else:
            features['sentiment_score'] = 0.0

        # Vocabulary Score
        if transcribed_text and len(transcribed_text.strip()) > 0:
            try:
                features['vocab_score'] = float(textstat.flesch_kincaid_grade(transcribed_text))
            except Exception:
                features['vocab_score'] = 0.0
        else:
            features['vocab_score'] = 0.0

        # Word Count
        features['word_count'] = len(transcribed_text.split()) if transcribed_text else 0

        return features
    except Exception:
        return None


# ============================================================
# STEP 6.5: PARALLEL WORKER FUNCTION
# ============================================================
def process_single_video(args):
    """Process a single video - used by parallel workers."""
    video_path, annotations, transcriptions, temp_dir = args
    video_filename = os.path.basename(video_path)
    video_name_no_ext = os.path.splitext(video_filename)[0]

    # Match annotation
    interview_score = None
    for key in [video_filename, video_name_no_ext, video_name_no_ext + '.mp4']:
        if key in annotations:
            interview_score = annotations[key]
            break
    if interview_score is None:
        return {'status': 'no_ann'}

    # Extract audio
    audio_path = os.path.join(temp_dir, f"{video_name_no_ext}.wav")
    result = extract_audio_from_video(video_path, audio_path)
    if result is None:
        return {'status': 'audio_fail'}

    # Get transcription
    text = ""
    for key in [video_filename, video_name_no_ext, video_name_no_ext + '.mp4']:
        if key in transcriptions:
            text = transcriptions[key]
            break

    # Extract features
    features = extract_features_from_audio(audio_path, text)

    # Cleanup
    try:
        if os.path.exists(audio_path):
            os.remove(audio_path)
    except Exception:
        pass

    if features is not None:
        features['interview_score'] = interview_score
        features['video_name'] = video_filename
        features['split'] = 'training' if 'training' in video_path.lower() else \
                           ('validation' if 'validation' in video_path.lower() else 'test')
        return {'status': 'ok', 'features': features}
    else:
        return {'status': 'feat_fail'}


# ============================================================
# STEP 7: BUILD DATASET (PARALLEL PROCESSING)
# ============================================================
def build_feature_dataset(annotations, video_files, transcriptions, output_dir):
    """Process all videos using parallel workers for speed."""
    print("\n" + "=" * 60)
    print("⚡ PARALLEL FEATURE EXTRACTION PIPELINE")
    print("=" * 60)

    temp_dir = os.path.join(output_dir, "temp_audio")
    os.makedirs(temp_dir, exist_ok=True)

    total = len(video_files)
    print(f"📊 Processing {total} video files...")
    print(f"📋 Annotations: {len(annotations)} | Transcriptions: {len(transcriptions)}")
    print(f"⚡ Using {N_CORES} parallel workers")
    print()

    # Prepare args for parallel processing
    args_list = [(vf, annotations, transcriptions, temp_dir) for vf in video_files]

    all_features = []
    processed = 0
    skipped_no_ann = 0
    skipped_audio = 0
    skipped_feat = 0

    start_time = time.time()

    # Process in batches with progress reporting
    BATCH_SIZE = 200
    for batch_start in range(0, total, BATCH_SIZE):
        batch_end = min(batch_start + BATCH_SIZE, total)
        batch_args = args_list[batch_start:batch_end]

        # Parallel processing using joblib
        results = joblib.Parallel(n_jobs=N_CORES, backend='loky', prefer='processes')(
            joblib.delayed(process_single_video)(args) for args in batch_args
        )

        # Collect results
        for r in results:
            if r['status'] == 'ok':
                all_features.append(r['features'])
                processed += 1
            elif r['status'] == 'no_ann':
                skipped_no_ann += 1
            elif r['status'] == 'audio_fail':
                skipped_audio += 1
            elif r['status'] == 'feat_fail':
                skipped_feat += 1

        elapsed = time.time() - start_time
        speed = (batch_end) / elapsed if elapsed > 0 else 0
        eta = (total - batch_end) / speed if speed > 0 else 0
        print(f"   📊 {batch_end}/{total} | ✅ {processed} | ⏭️ {skipped_no_ann} no ann | "
              f"❌ {skipped_audio} audio | ❌ {skipped_feat} feat | "
              f"⚡ {speed:.0f} vid/s | ETA: {eta/60:.1f} min")

    total_time = time.time() - start_time
    print(f"\n{'=' * 40}")
    print(f"✅ Feature extraction complete in {total_time/60:.1f} minutes!")
    print(f"   Processed: {processed} | No ann: {skipped_no_ann} | Audio fail: {skipped_audio} | Feat fail: {skipped_feat}")

    if not all_features:
        print("❌ No features extracted!")
        sys.exit(1)

    df = pd.DataFrame(all_features)
    csv_path = os.path.join(output_dir, "chalearn_features.csv")
    df.to_csv(csv_path, index=False)
    print(f"\n💾 Features saved: {csv_path} ({df.shape[0]} samples, {df.shape[1]} columns)")

    for split in ['training', 'validation', 'test']:
        count = len(df[df['split'] == split])
        if count > 0:
            print(f"   {split}: {count}")

    # Cleanup
    try:
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)
    except Exception:
        pass

    return df


# ============================================================
# STEP 8: TRAIN MODEL (GPU ACCELERATED)
# ============================================================
def train_model(df, output_dir):
    """Train XGBoost Regressor with GPU acceleration."""
    print("\n" + "=" * 60)
    print("🚀 GPU MODEL TRAINING (XGBoost)")
    print("=" * 60)

    feature_columns = [
        'pitch_mean', 'pitch_std', 'energy_mean', 'energy_std',
        'mfcc_1', 'mfcc_2', 'mfcc_3', 'mfcc_4', 'mfcc_5',
        'speech_rate', 'pause_rate', 'sentiment_score', 'vocab_score', 'word_count'
    ]

    X = df[feature_columns].fillna(0).values
    y = df['interview_score'].values

    print(f"📊 Dataset: {X.shape[0]} samples, {X.shape[1]} features")
    print(f"🎯 Target: {y.min():.3f} to {y.max():.3f} (mean: {y.mean():.3f})")

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)
    print(f"📏 Train: {X_train.shape[0]} | Test: {X_test.shape[0]}")

    # ===== XGBoost with GPU =====
    xgb_params = {
        'n_estimators': 500,
        'max_depth': 8,
        'learning_rate': 0.05,
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'min_child_weight': 3,
        'reg_alpha': 0.1,
        'reg_lambda': 1.0,
        'random_state': 42,
        'verbosity': 1,
    }

    if GPU_AVAILABLE:
        xgb_params['tree_method'] = 'hist'
        xgb_params['device'] = 'cuda'
        print("\n🚀 Training XGBoost with GPU acceleration...")
    else:
        xgb_params['tree_method'] = 'hist'
        xgb_params['n_jobs'] = -1
        print("\n🌲 Training XGBoost on CPU...")

    train_start = time.time()
    model = xgb.XGBRegressor(**xgb_params)
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=50
    )
    train_time = time.time() - train_start
    print(f"✅ Model trained in {train_time:.1f} seconds!")

    # Evaluate
    y_pred = model.predict(X_test)
    r2 = r2_score(y_test, y_pred)
    mae = mean_absolute_error(y_test, y_pred)
    pearson_corr, pearson_p = pearsonr(y_test, y_pred)

    print(f"\n{'='*40}")
    print(f"📊 EVALUATION RESULTS")
    print(f"{'='*40}")
    print(f"   R² Score:            {r2:.4f}")
    print(f"   MAE:                 {mae:.4f}")
    print(f"   Pearson Correlation: {pearson_corr:.4f} (p={pearson_p:.6f})")
    print(f"   Training Time:       {train_time:.1f}s {'(GPU)' if GPU_AVAILABLE else '(CPU)'}")

    # Cross Validation
    print("\n🔄 5-Fold Cross Validation...")
    # Use CPU for CV (faster for small datasets)
    cv_model = xgb.XGBRegressor(
        n_estimators=500, max_depth=8, learning_rate=0.05,
        tree_method='hist', n_jobs=-1, random_state=42, verbosity=0
    )
    cv_r2 = cross_val_score(cv_model, X_scaled, y, cv=5, scoring='r2')
    cv_mae = cross_val_score(cv_model, X_scaled, y, cv=5, scoring='neg_mean_absolute_error')
    print(f"   CV R²:  {cv_r2.mean():.4f} ± {cv_r2.std():.4f}")
    print(f"   CV MAE: {-cv_mae.mean():.4f} ± {cv_mae.std():.4f}")

    # Feature Importance Plot
    importances = model.feature_importances_
    indices = np.argsort(importances)[::-1]

    plt.figure(figsize=(12, 6))
    plt.title("Feature Importance - Communication Scoring Model (XGBoost GPU)", fontsize=14, fontweight='bold')
    colors = ['#4CAF50' if GPU_AVAILABLE else '#2196F3'] * len(feature_columns)
    plt.bar(range(len(feature_columns)), importances[indices], color=colors, edgecolor='#1B5E20', alpha=0.85)
    plt.xticks(range(len(feature_columns)), [feature_columns[i] for i in indices], rotation=45, ha='right')
    plt.ylabel("Importance Score")
    plt.xlabel("Features")
    plt.tight_layout()
    plot_path = os.path.join(output_dir, "feature_importance.png")
    plt.savefig(plot_path, dpi=150, bbox_inches='tight')
    plt.show()
    print(f"💾 Plot saved: {plot_path}")

    print("\n🏆 Feature Ranking:")
    for rank, idx_val in enumerate(indices, 1):
        print(f"   {rank}. {feature_columns[idx_val]:20s} → {importances[idx_val]:.4f}")

    # Save model, scaler, metadata
    model_path = os.path.join(output_dir, "communication_model.pkl")
    scaler_path = os.path.join(output_dir, "communication_scaler.pkl")
    joblib.dump(model, model_path)
    joblib.dump(scaler, scaler_path)

    meta = {
        'model_type': 'XGBoost',
        'gpu_used': GPU_AVAILABLE,
        'feature_columns': feature_columns,
        'r2_score': r2, 'mae': mae,
        'pearson_correlation': pearson_corr,
        'cv_mean_r2': float(cv_r2.mean()),
        'training_samples': X_train.shape[0],
        'test_samples': X_test.shape[0],
        'total_samples': X.shape[0],
        'training_time_seconds': train_time,
    }
    meta_path = os.path.join(output_dir, "model_metadata.pkl")
    joblib.dump(meta, meta_path)

    print(f"\n💾 Model saved:    {model_path}")
    print(f"💾 Scaler saved:   {scaler_path}")
    print(f"💾 Metadata saved: {meta_path}")

    return model, scaler


# ============================================================
# STEP 9: RUN PIPELINE
# ============================================================
if __name__ == "__main__":
    pipeline_start = time.time()
    print("\n🚀 Starting GPU Accelerated Training Pipeline\n")

    annotations = load_annotations(ANNOTATION_DIR)
    transcriptions = load_transcriptions(TRANSCRIPTION_DIR)
    video_files = find_video_files(VIDEO_DIR)
    df = build_feature_dataset(annotations, video_files, transcriptions, OUTPUT_DIR)
    model, scaler = train_model(df, OUTPUT_DIR)

    # ============================================================
    # STEP 10: PACKAGE OUTPUT FOR DOWNLOAD
    # ============================================================
    print("\n" + "=" * 60)
    print("📦 PACKAGING OUTPUT FOR DOWNLOAD")
    print("=" * 60)

    import shutil
    import zipfile

    kaggle_working = "/kaggle/working"
    output_files = [
        "communication_model.pkl",
        "communication_scaler.pkl",
        "chalearn_features.csv",
        "feature_importance.png",
        "model_metadata.pkl"
    ]

    for filename in output_files:
        src = os.path.join(OUTPUT_DIR, filename)
        dst = os.path.join(kaggle_working, filename)
        if os.path.exists(src):
            shutil.copy2(src, dst)
            file_size = os.path.getsize(dst)
            size_str = f"{file_size/1024:.1f} KB" if file_size < 1024*1024 else f"{file_size/(1024*1024):.1f} MB"
            print(f"   ✅ Copied: {filename} ({size_str})")

    # Create ZIP
    zip_path = os.path.join(kaggle_working, "communication_model_output.zip")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for filename in output_files:
            src = os.path.join(OUTPUT_DIR, filename)
            if os.path.exists(src):
                zf.write(src, filename)
    zip_size = os.path.getsize(zip_path)
    zip_str = f"{zip_size/1024:.1f} KB" if zip_size < 1024*1024 else f"{zip_size/(1024*1024):.1f} MB"
    print(f"\n   📦 ZIP: communication_model_output.zip ({zip_str})")

    # List all files
    print(f"\n📂 All files in {kaggle_working}/:")
    for f in sorted(os.listdir(kaggle_working)):
        fpath = os.path.join(kaggle_working, f)
        if os.path.isfile(fpath):
            fsize = os.path.getsize(fpath)
            s = f"{fsize/1024:.1f} KB" if fsize < 1024*1024 else f"{fsize/(1024*1024):.1f} MB"
            print(f"   📄 {f} ({s})")

    total_time = time.time() - pipeline_start
    print("\n" + "=" * 60)
    print("🎉 TRAINING COMPLETE!")
    print("=" * 60)
    print(f"\n⏱️  Total pipeline time: {total_time/60:.1f} minutes")
    print(f"🖥️  Mode: {'GPU (XGBoost gpu_hist)' if GPU_AVAILABLE else 'CPU (XGBoost hist)'}")
    print("\n📋 HOW TO DOWNLOAD:")
    print("   1. Click 'Save Version' → 'Save & Run All (Commit)'")
    print("   2. Go to Output tab → Download files")
    print("\n📋 AFTER DOWNLOAD:")
    print("   1. Place communication_model.pkl in python_server/ml_model/")
    print("   2. Place communication_scaler.pkl in python_server/ml_model/")
    print("   3. Start Flask server → model auto-loads! 🚀")
