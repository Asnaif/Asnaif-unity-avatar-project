"""
============================================================================
SESSION RECORDER — Full Body Estimation System
============================================================================
Records all detection metrics over time during a session.
Provides aggregation, summary statistics, and JSON export.

Usage:
    recorder = SessionRecorder()
    recorder.start()
    recorder.record_frame(metrics)   # Called every frame
    summary = recorder.stop()        # Returns SessionSummary
    recorder.export_json("session.json")
============================================================================
"""

import time
import json
import os
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Tuple
from collections import Counter
import numpy as np


# ════════════════════════════════════════════════════════════
# DATA MODELS
# ════════════════════════════════════════════════════════════

@dataclass
class EyeContactData:
    """Per-frame eye contact metrics."""
    is_looking: bool = False
    score: float = 0.0                  # 0.0 - 1.0
    gaze_x: float = 0.0                # Horizontal gaze (-1 to 1)
    gaze_y: float = 0.0                # Vertical gaze (-1 to 1)


@dataclass
class EmotionData:
    """Per-frame emotion approximation."""
    dominant_emotion: str = "neutral"
    confidence: float = 0.0             # 0.0 - 1.0
    scores: Dict[str, float] = field(default_factory=lambda: {
        "confident": 0.0,
        "engaged": 0.0,
        "neutral": 1.0,
        "nervous": 0.0,
        "stressed": 0.0,
    })


@dataclass
class GestureData:
    """Per-frame hand gesture data."""
    left_hand_detected: bool = False
    right_hand_detected: bool = False
    left_gesture: str = "no_hands"
    right_gesture: str = "no_hands"
    is_fidgeting: bool = False
    movement_velocity: float = 0.0      # Pixels per second


@dataclass
class PostureData:
    """Per-frame posture analysis."""
    posture: str = "upright"
    score: float = 1.0                  # 0.0 - 1.0 (1.0 = perfect)
    shoulder_angle: float = 0.0         # Degrees from horizontal
    spine_alignment: float = 1.0        # 0.0 - 1.0


@dataclass
class HeadPoseData:
    """Per-frame head pose estimation."""
    yaw: float = 0.0                    # Left/right (degrees)
    pitch: float = 0.0                  # Up/down (degrees)
    roll: float = 0.0                   # Tilt (degrees)
    is_centered: bool = True


@dataclass
class FrameMetrics:
    """Complete metrics for a single frame."""
    timestamp: float = 0.0
    eye_contact: EyeContactData = field(default_factory=EyeContactData)
    emotion: EmotionData = field(default_factory=EmotionData)
    gesture: GestureData = field(default_factory=GestureData)
    posture: PostureData = field(default_factory=PostureData)
    head_pose: HeadPoseData = field(default_factory=HeadPoseData)
    face_detected: bool = False
    hands_detected: int = 0             # 0, 1, or 2
    pose_detected: bool = False


@dataclass
class SessionSummary:
    """Aggregated summary of an entire session."""
    # Session info
    duration_seconds: float = 0.0
    total_frames: int = 0
    start_time: str = ""
    end_time: str = ""

    # Eye Contact
    eye_contact_percentage: float = 0.0
    avg_eye_contact_score: float = 0.0

    # Emotion
    dominant_emotion: str = "neutral"
    emotion_breakdown: Dict[str, float] = field(default_factory=dict)
    avg_emotion_confidence: float = 0.0

    # Posture
    avg_posture_score: float = 0.0
    posture_breakdown: Dict[str, float] = field(default_factory=dict)

    # Gestures
    gesture_count: int = 0
    gesture_frequency: float = 0.0      # Per minute
    gesture_types: Dict[str, int] = field(default_factory=dict)
    fidget_percentage: float = 0.0

    # Head Pose
    head_centered_percentage: float = 0.0
    avg_head_yaw: float = 0.0
    avg_head_pitch: float = 0.0

    # Overall
    overall_engagement_score: float = 0.0  # 0-100
    overall_confidence_score: float = 0.0  # 0-100

    # Timeline (per-second snapshots for charts)
    timeline: List[Dict] = field(default_factory=list)

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return asdict(self)


# ════════════════════════════════════════════════════════════
# SESSION RECORDER
# ════════════════════════════════════════════════════════════

class SessionRecorder:
    """
    Records per-frame detection metrics and produces aggregated summaries.
    """

    def __init__(self):
        self._frames: List[FrameMetrics] = []
        self._is_recording: bool = False
        self._start_time: float = 0.0
        self._end_time: float = 0.0
        self._last_snapshot_time: float = 0.0
        self._snapshot_interval: float = 1.0  # seconds
        self._timeline_snapshots: List[Dict] = []

        # For gesture counting (track transitions)
        self._prev_gestures: Tuple[str, str] = ("no_hands", "no_hands")
        self._gesture_transitions: int = 0

        # For fidget tracking
        self._prev_hand_positions: Optional[Dict] = None

    @property
    def is_recording(self) -> bool:
        return self._is_recording

    @property
    def frame_count(self) -> int:
        return len(self._frames)

    @property
    def elapsed_seconds(self) -> float:
        if not self._is_recording:
            return self._end_time - self._start_time if self._end_time else 0.0
        return time.time() - self._start_time

    def start(self):
        """Start a new recording session."""
        self._frames = []
        self._timeline_snapshots = []
        self._is_recording = True
        self._start_time = time.time()
        self._end_time = 0.0
        self._last_snapshot_time = self._start_time
        self._prev_gestures = ("no_hands", "no_hands")
        self._gesture_transitions = 0
        self._prev_hand_positions = None
        print("[REC] Session recording started")

    def stop(self) -> SessionSummary:
        """Stop recording and return the aggregated summary."""
        self._is_recording = False
        self._end_time = time.time()
        print(f"[REC] Session recording stopped — {len(self._frames)} frames, "
              f"{self.elapsed_seconds:.1f}s")
        return self.get_summary()

    def record_frame(self, metrics: FrameMetrics):
        """Record metrics for a single frame."""
        if not self._is_recording:
            return

        metrics.timestamp = time.time() - self._start_time
        self._frames.append(metrics)

        # Track gesture transitions for counting
        current_gestures = (metrics.gesture.left_gesture,
                            metrics.gesture.right_gesture)
        if current_gestures != self._prev_gestures:
            # Only count meaningful gestures (not no_hands transitions)
            if (current_gestures[0] != "no_hands" or
                    current_gestures[1] != "no_hands"):
                self._gesture_transitions += 1
        self._prev_gestures = current_gestures

        # Create timeline snapshot every interval
        now = time.time()
        if now - self._last_snapshot_time >= self._snapshot_interval:
            self._create_timeline_snapshot(metrics)
            self._last_snapshot_time = now

    def _create_timeline_snapshot(self, metrics: FrameMetrics):
        """Create a snapshot for the timeline chart."""
        snapshot = {
            "time": round(metrics.timestamp, 1),
            "eye_contact": metrics.eye_contact.score,
            "emotion": metrics.emotion.dominant_emotion,
            "emotion_confidence": metrics.emotion.confidence,
            "posture_score": metrics.posture.score,
            "head_centered": metrics.head_pose.is_centered,
            "hands_detected": metrics.hands_detected,
            "gesture_left": metrics.gesture.left_gesture,
            "gesture_right": metrics.gesture.right_gesture,
        }
        self._timeline_snapshots.append(snapshot)

    def get_summary(self) -> SessionSummary:
        """Generate the aggregated session summary."""
        if not self._frames:
            return SessionSummary()

        duration = self.elapsed_seconds
        total = len(self._frames)

        summary = SessionSummary()
        summary.duration_seconds = round(duration, 1)
        summary.total_frames = total
        summary.start_time = time.strftime(
            "%Y-%m-%d %H:%M:%S", time.localtime(self._start_time))
        summary.end_time = time.strftime(
            "%Y-%m-%d %H:%M:%S",
            time.localtime(self._end_time if self._end_time else time.time()))

        # ── Eye Contact ──
        looking_frames = sum(1 for f in self._frames if f.eye_contact.is_looking)
        face_frames = sum(1 for f in self._frames if f.face_detected)
        if face_frames > 0:
            summary.eye_contact_percentage = round(
                (looking_frames / face_frames) * 100, 1)
        eye_scores = [f.eye_contact.score for f in self._frames if f.face_detected]
        summary.avg_eye_contact_score = round(
            np.mean(eye_scores) if eye_scores else 0.0, 3)

        # ── Emotion ──
        emotion_counts = Counter()
        emotion_conf_sum = 0.0
        for f in self._frames:
            if f.face_detected:
                emotion_counts[f.emotion.dominant_emotion] += 1
                emotion_conf_sum += f.emotion.confidence

        if emotion_counts:
            summary.dominant_emotion = emotion_counts.most_common(1)[0][0]
            emotion_total = sum(emotion_counts.values())
            summary.emotion_breakdown = {
                k: round((v / emotion_total) * 100, 1)
                for k, v in emotion_counts.most_common()
            }
            summary.avg_emotion_confidence = round(
                emotion_conf_sum / emotion_total, 3)

        # ── Posture ──
        posture_scores = [f.posture.score for f in self._frames if f.pose_detected]
        summary.avg_posture_score = round(
            np.mean(posture_scores) * 100 if posture_scores else 0.0, 1)

        posture_counts = Counter()
        for f in self._frames:
            if f.pose_detected:
                posture_counts[f.posture.posture] += 1
        if posture_counts:
            posture_total = sum(posture_counts.values())
            summary.posture_breakdown = {
                k: round((v / posture_total) * 100, 1)
                for k, v in posture_counts.most_common()
            }

        # ── Gestures ──
        summary.gesture_count = self._gesture_transitions
        summary.gesture_frequency = round(
            (self._gesture_transitions / (duration / 60))
            if duration > 0 else 0.0, 1)

        gesture_counts = Counter()
        fidget_frames = 0
        for f in self._frames:
            if f.gesture.left_hand_detected:
                gesture_counts[f.gesture.left_gesture] += 1
            if f.gesture.right_hand_detected:
                gesture_counts[f.gesture.right_gesture] += 1
            if f.gesture.is_fidgeting:
                fidget_frames += 1

        summary.gesture_types = dict(gesture_counts.most_common())
        hand_frames = sum(1 for f in self._frames
                          if f.gesture.left_hand_detected or
                          f.gesture.right_hand_detected)
        summary.fidget_percentage = round(
            (fidget_frames / hand_frames * 100) if hand_frames > 0 else 0.0, 1)

        # ── Head Pose ──
        centered_frames = sum(1 for f in self._frames
                              if f.face_detected and f.head_pose.is_centered)
        if face_frames > 0:
            summary.head_centered_percentage = round(
                (centered_frames / face_frames) * 100, 1)

        yaws = [f.head_pose.yaw for f in self._frames if f.face_detected]
        pitches = [f.head_pose.pitch for f in self._frames if f.face_detected]
        summary.avg_head_yaw = round(np.mean(yaws) if yaws else 0.0, 1)
        summary.avg_head_pitch = round(np.mean(pitches) if pitches else 0.0, 1)

        # ── Overall Scores ──
        summary.overall_engagement_score = round(self._calc_engagement(summary), 1)
        summary.overall_confidence_score = round(self._calc_confidence(summary), 1)

        # ── Timeline ──
        summary.timeline = self._timeline_snapshots

        return summary

    def _calc_engagement(self, s: SessionSummary) -> float:
        """Calculate overall engagement score (0-100)."""
        eye_score = s.eye_contact_percentage * 0.30
        posture_score = s.avg_posture_score * 0.20
        head_score = s.head_centered_percentage * 0.20

        # Gesture engagement (moderate gesture use is good)
        gesture_rate = min(s.gesture_frequency / 10.0, 1.0) * 100
        gesture_score = gesture_rate * 0.15

        # Emotion engagement
        engaged_pct = s.emotion_breakdown.get("engaged", 0)
        confident_pct = s.emotion_breakdown.get("confident", 0)
        emotion_score = min(engaged_pct + confident_pct, 100) * 0.15

        return min(100.0, eye_score + posture_score + head_score +
                   gesture_score + emotion_score)

    def _calc_confidence(self, s: SessionSummary) -> float:
        """Calculate overall confidence score (0-100)."""
        # Eye contact is a strong confidence signal
        eye_score = s.eye_contact_percentage * 0.25

        # Good posture signals confidence
        posture_score = s.avg_posture_score * 0.20

        # Confident emotion percentage
        confident_pct = s.emotion_breakdown.get("confident", 0)
        emotion_score = confident_pct * 0.25

        # Low fidgeting signals confidence
        fidget_penalty = s.fidget_percentage * 0.15
        fidget_score = max(0, 100 - fidget_penalty * 5) * 0.15

        # Head stability
        head_score = s.head_centered_percentage * 0.15

        return min(100.0, eye_score + posture_score + emotion_score +
                   fidget_score + head_score)

    def export_json(self, filepath: str) -> str:
        """Export session data to a JSON file."""
        summary = self.get_summary()
        data = {
            "session_summary": summary.to_dict(),
            "raw_frame_count": len(self._frames),
        }

        os.makedirs(os.path.dirname(filepath) if os.path.dirname(filepath)
                     else ".", exist_ok=True)
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str)

        print(f"[REC] Session exported to: {filepath}")
        return filepath

    def reset(self):
        """Reset the recorder for a new session."""
        self._frames = []
        self._timeline_snapshots = []
        self._is_recording = False
        self._start_time = 0.0
        self._end_time = 0.0
        self._prev_gestures = ("no_hands", "no_hands")
        self._gesture_transitions = 0
        self._prev_hand_positions = None
