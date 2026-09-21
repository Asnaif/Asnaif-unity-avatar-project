"""
============================================================================
CONFIGURATION — Full Body Estimation System
============================================================================
Centralized configuration for MediaPipe Holistic body estimation,
gesture classification, emotion approximation, and report generation.

Designed for integration with InterPrep Avatar Interview System.
============================================================================
"""

# ────────────────────────────────────────────────────────────
# MediaPipe Detection Settings
# ────────────────────────────────────────────────────────────
MEDIAPIPE_DETECTION_CONFIDENCE = 0.5
MEDIAPIPE_TRACKING_CONFIDENCE = 0.5

# Processing frame rate (lower = less CPU, higher = more accurate)
# 5-10 FPS is optimal for real-time analysis without lag
DETECTION_FPS = 8

# ────────────────────────────────────────────────────────────
# Eye Contact Thresholds
# ────────────────────────────────────────────────────────────
# Iris position thresholds (how far iris is from center of eye)
EYE_CONTACT_HORIZONTAL_THRESHOLD = 0.35  # Left/right deviation
EYE_CONTACT_VERTICAL_THRESHOLD = 0.40    # Up/down deviation

# If gaze score > this, consider it "looking at camera"
EYE_CONTACT_SCORE_THRESHOLD = 0.55

# ────────────────────────────────────────────────────────────
# Emotion Approximation Thresholds
# ────────────────────────────────────────────────────────────
# Mouth Aspect Ratio thresholds
SMILE_THRESHOLD = 0.45           # Mouth width/height ratio for smile
MOUTH_OPEN_THRESHOLD = 0.6      # Mouth openness for surprise/speaking

# Eyebrow thresholds (relative to eye height)
BROW_RAISE_THRESHOLD = 0.28     # Raised eyebrows → surprise
BROW_FURROW_THRESHOLD = 0.18    # Furrowed brows → stress/concentration

# Eye openness
EYE_WIDE_THRESHOLD = 0.35       # Wide eyes → surprise/alert
EYE_SQUINT_THRESHOLD = 0.18     # Squinting → stress/focus

# Emotion labels mapped to interview context
EMOTION_LABELS = [
    "confident",    # Relaxed face, slight smile, good eye contact
    "engaged",      # Alert eyes, responsive expressions
    "neutral",      # Baseline expression
    "nervous",      # Tense jaw, darting eyes, forced smile
    "stressed",     # Furrowed brows, tight lips, squinting
]

# ────────────────────────────────────────────────────────────
# Hand Gesture Classification
# ────────────────────────────────────────────────────────────
# Finger extension thresholds (angle-based)
FINGER_EXTENDED_THRESHOLD = 160   # Degrees — finger is "straight"
FINGER_CURLED_THRESHOLD = 90      # Degrees — finger is "curled"

# Movement velocity threshold for fidgeting (pixels/second)
FIDGET_VELOCITY_THRESHOLD = 150
FIDGET_MIN_DURATION = 0.5  # Seconds of continuous fast movement

# Gesture labels
GESTURE_LABELS = [
    "open_palm",    # All fingers extended
    "pointing",     # Index finger extended, others curled
    "thumbs_up",    # Thumb extended, others curled
    "fist",         # All fingers curled
    "peace_sign",   # Index + middle extended
    "no_hands",     # No hands detected
]

# ────────────────────────────────────────────────────────────
# Posture Analysis
# ────────────────────────────────────────────────────────────
# Shoulder alignment angle threshold (degrees from horizontal)
SHOULDER_TILT_THRESHOLD = 10      # Degrees of acceptable tilt
SLOUCH_THRESHOLD = 0.15           # Vertical drop ratio for slouching
LEAN_THRESHOLD = 0.08             # Horizontal offset ratio for leaning

# Distance thresholds (face size relative to frame)
TOO_CLOSE_THRESHOLD = 0.45       # Face width > 45% of frame
TOO_FAR_THRESHOLD = 0.12         # Face width < 12% of frame

# Posture labels
POSTURE_LABELS = [
    "upright",          # Good posture
    "slouching",        # Shoulders dropped
    "leaning_left",     # Leaning to the left
    "leaning_right",    # Leaning to the right
    "too_close",        # Too close to camera
    "too_far",          # Too far from camera
]

# ────────────────────────────────────────────────────────────
# Head Pose Estimation
# ────────────────────────────────────────────────────────────
HEAD_YAW_THRESHOLD = 20          # Degrees left/right before "looking away"
HEAD_PITCH_THRESHOLD = 15        # Degrees up/down before "looking away"
HEAD_ROLL_THRESHOLD = 20         # Degrees tilt before flagging

# ────────────────────────────────────────────────────────────
# Visualization Colors (BGR format for OpenCV)
# ────────────────────────────────────────────────────────────
COLORS = {
    # Landmark drawing colors
    "face_landmark": (80, 110, 10),
    "face_connection": (80, 256, 121),
    "right_hand_landmark": (80, 22, 10),
    "right_hand_connection": (80, 44, 121),
    "left_hand_landmark": (121, 22, 76),
    "left_hand_connection": (121, 44, 250),
    "pose_landmark": (245, 117, 66),
    "pose_connection": (245, 66, 230),

    # Dashboard overlay colors
    "dashboard_bg": (30, 30, 30),
    "dashboard_text": (255, 255, 255),
    "score_good": (0, 200, 0),
    "score_medium": (0, 200, 255),
    "score_bad": (0, 0, 255),

    # Eye contact indicator
    "eye_contact_on": (0, 255, 0),
    "eye_contact_off": (0, 0, 255),

    # Posture indicator
    "posture_good": (0, 200, 0),
    "posture_bad": (0, 100, 255),
}

# Drawing specifications
FACE_LANDMARK_SPEC = {"color": (80, 110, 10), "thickness": 1, "circle_radius": 1}
FACE_CONNECTION_SPEC = {"color": (80, 256, 121), "thickness": 1, "circle_radius": 1}
RIGHT_HAND_LANDMARK_SPEC = {"color": (80, 22, 10), "thickness": 2, "circle_radius": 4}
RIGHT_HAND_CONNECTION_SPEC = {"color": (80, 44, 121), "thickness": 2, "circle_radius": 2}
LEFT_HAND_LANDMARK_SPEC = {"color": (121, 22, 76), "thickness": 2, "circle_radius": 4}
LEFT_HAND_CONNECTION_SPEC = {"color": (121, 44, 250), "thickness": 2, "circle_radius": 2}
POSE_LANDMARK_SPEC = {"color": (245, 117, 66), "thickness": 2, "circle_radius": 4}
POSE_CONNECTION_SPEC = {"color": (245, 66, 230), "thickness": 2, "circle_radius": 2}

# ────────────────────────────────────────────────────────────
# PDF Report Settings
# ────────────────────────────────────────────────────────────
PDF_TITLE = "Interview Body Language Analysis Report"
PDF_SUBTITLE = "Full-Body Estimation using MediaPipe Holistic"

# Color palette for PDF (RGB 0-1 floats for ReportLab)
PDF_COLORS = {
    "primary": (0.11, 0.14, 0.27),       # Dark navy
    "secondary": (0.20, 0.40, 0.80),     # Blue accent
    "accent": (0.96, 0.65, 0.14),        # Gold/amber
    "success": (0.18, 0.75, 0.38),       # Green
    "warning": (0.95, 0.55, 0.15),       # Orange
    "danger": (0.90, 0.25, 0.20),        # Red
    "text_dark": (0.15, 0.15, 0.15),     # Near black
    "text_light": (0.95, 0.95, 0.95),    # Near white
    "bg_light": (0.96, 0.97, 0.98),      # Light gray
}

# Radar chart categories
RADAR_CATEGORIES = [
    "Eye Contact",
    "Confidence",
    "Posture",
    "Gestures",
    "Engagement",
]

# ────────────────────────────────────────────────────────────
# Session Recording
# ────────────────────────────────────────────────────────────
# How often to record a snapshot (in seconds)
SNAPSHOT_INTERVAL = 1.0

# Maximum session duration (seconds) — safety limit
MAX_SESSION_DURATION = 3600  # 1 hour

# Output directory for reports
REPORTS_DIR = "reports"

# ────────────────────────────────────────────────────────────
# Keyboard Controls
# ────────────────────────────────────────────────────────────
KEY_QUIT = ord('q')
KEY_TOGGLE_RECORDING = ord('r')
KEY_TOGGLE_DASHBOARD = ord('d')
KEY_GENERATE_REPORT = ord('p')
KEY_TOGGLE_LANDMARKS = ord('l')
