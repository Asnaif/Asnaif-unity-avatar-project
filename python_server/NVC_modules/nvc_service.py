"""
============================================================================
NVC SERVICE — InterPrep Server Integration
============================================================================
Manages NVC (Non-Verbal Communication) analysis sessions.
Called by server.py to start/process/complete body language analysis.

Usage from server.py:
    from NVC_modules.nvc_service import start_nvc_session, process_nvc_frame, complete_nvc_session
============================================================================
"""

import os
import time
import threading
import numpy as np
import cv2
from typing import Dict, Optional

from .session_recorder import SessionRecorder, FrameMetrics
from .analyzers import (
    EyeContactAnalyzer, EmotionApproximator, GestureClassifier,
    PostureAnalyzer, HeadPoseEstimator
)
from . import config

# Try to import mediapipe
try:
    import mediapipe as mp
    MP_AVAILABLE = True
except ImportError:
    MP_AVAILABLE = False
    print("[NVC] WARNING: mediapipe not installed")


# ════════════════════════════════════════════════════════════
# Active NVC Sessions
# ════════════════════════════════════════════════════════════
_active_sessions: Dict[str, dict] = {}
_sessions_lock = threading.Lock()


def start_nvc_session(session_id: str) -> Dict:
    """
    Start a new NVC analysis session.
    Called when interview starts.
    
    Returns:
        dict with success status and session info
    """
    if not MP_AVAILABLE:
        return {"success": False, "error": "mediapipe not installed"}

    with _sessions_lock:
        if session_id in _active_sessions:
            return {"success": True, "message": "Session already active"}

        # Initialize analyzers for this session
        _active_sessions[session_id] = {
            "recorder": SessionRecorder(),
            "eye_analyzer": EyeContactAnalyzer(),
            "emotion_analyzer": EmotionApproximator(),
            "gesture_classifier": GestureClassifier(),
            "posture_analyzer": PostureAnalyzer(),
            "head_pose_estimator": HeadPoseEstimator(),
            "holistic": mp.solutions.holistic.Holistic(
                min_detection_confidence=config.MEDIAPIPE_DETECTION_CONFIDENCE,
                min_tracking_confidence=config.MEDIAPIPE_TRACKING_CONFIDENCE,
                model_complexity=1,
                refine_face_landmarks=True
            ),
            "frame_count": 0,
            "started_at": time.time(),
        }
        _active_sessions[session_id]["recorder"].start()

    print(f"[NVC] Session started: {session_id[:8]}...")
    return {"success": True, "session_id": session_id}


def process_nvc_frame(session_id: str, frame_bytes: bytes) -> Dict:
    """
    Process a single webcam frame for NVC analysis.
    Called by the /api/nvc/frame endpoint.
    
    Args:
        session_id: Active session ID
        frame_bytes: JPEG/PNG image bytes from webcam
    
    Returns:
        dict with real-time metrics for the frame
    """
    with _sessions_lock:
        session = _active_sessions.get(session_id)

    if not session:
        return {"success": False, "error": "Session not found"}

    try:
        # Decode image bytes to numpy array
        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            return {"success": False, "error": "Could not decode frame"}

        h, w = frame.shape[:2]
        current_time = time.time()

        # Convert BGR -> RGB for MediaPipe
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = session["holistic"].process(rgb)

        # Build frame metrics
        metrics = FrameMetrics()
        metrics.face_detected = results.face_landmarks is not None
        metrics.pose_detected = results.pose_landmarks is not None
        metrics.hands_detected = sum([
            results.left_hand_landmarks is not None,
            results.right_hand_landmarks is not None
        ])

        # Run analyzers
        if results.face_landmarks:
            metrics.eye_contact = session["eye_analyzer"].analyze(results.face_landmarks)
            metrics.emotion = session["emotion_analyzer"].analyze(results.face_landmarks)
            metrics.head_pose = session["head_pose_estimator"].analyze(results.face_landmarks)

        metrics.gesture = session["gesture_classifier"].analyze(
            results.left_hand_landmarks,
            results.right_hand_landmarks,
            current_time
        )

        if results.pose_landmarks:
            metrics.posture = session["posture_analyzer"].analyze(results.pose_landmarks, w)

        # Record frame
        session["recorder"].record_frame(metrics)
        session["frame_count"] += 1

        # Return real-time data for UI overlay
        return {
            "success": True,
            "frame_number": session["frame_count"],
            "face_detected": metrics.face_detected,
            "eye_contact": metrics.eye_contact.is_looking,
            "eye_score": metrics.eye_contact.score,
            "emotion": metrics.emotion.dominant_emotion,
            "posture": metrics.posture.posture,
            "posture_score": metrics.posture.score,
            "hands_detected": metrics.hands_detected,
            "head_centered": metrics.head_pose.is_centered,
        }

    except Exception as e:
        print(f"[NVC] Frame processing error: {e}")
        return {"success": False, "error": str(e)}


def complete_nvc_session(session_id: str,
                         candidate_name: str = "Candidate",
                         position: str = "Interview",
                         interview_data: Optional[Dict] = None) -> Dict:
    """
    Complete an NVC session, generate scores and PDF report.
    Called when interview ends.
    
    Args:
        session_id: Active NVC session ID
        candidate_name: Name of the candidate
        position: Job position
        interview_data: Optional dict containing Q&A analysis and interview scores
            from the LLM brain (keys: overall_score, qa_analysis, scores, etc.)
    
    Returns:
        dict with normalized scores (0-10) and report path
    """
    with _sessions_lock:
        session = _active_sessions.pop(session_id, None)

    if not session:
        return {"success": False, "scores": _default_scores(), "error": "Session not found"}

    try:
        # Stop recording and get summary
        summary = session["recorder"].stop()

        # Close MediaPipe holistic
        session["holistic"].close()

        # Calculate normalized scores (0-10)
        scores = _calculate_scores(summary)

        # Calculate combined overall score (0-100) merging NVC + Interview
        nvc_score_100 = min(100.0, scores.get("overall_body_language_score", 5.0) * 10)
        interview_score_100 = 0
        if interview_data and interview_data.get("overall_score"):
            try:
                score_str = str(interview_data["overall_score"]).replace('%', '').strip()
                interview_score_100 = float(score_str)
            except (ValueError, TypeError):
                interview_score_100 = 0
        
        # Weighted average: 40% body language + 60% interview Q&A accuracy
        if interview_score_100 > 0:
            combined_score = round(nvc_score_100 * 0.4 + interview_score_100 * 0.6, 1)
        else:
            combined_score = round(nvc_score_100, 1)

        # Generate PDF report
        report_path = None
        try:
            from .report_generator import ReportGenerator
            reports_dir = os.path.join(os.path.dirname(__file__), "..", "reports")
            os.makedirs(reports_dir, exist_ok=True)
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            report_path = os.path.join(reports_dir, f"nvc_report_{session_id[:8]}_{timestamp}.pdf")
            
            generator = ReportGenerator()
            generator.generate(
                summary, report_path, candidate_name, position,
                interview_data=interview_data,
                combined_score=combined_score
            )
            print(f"[NVC] Report generated: {report_path}")
        except Exception as e:
            print(f"[NVC] Report generation failed: {e}")
            import traceback
            traceback.print_exc()

        print(f"[NVC] Session completed: {session_id[:8]} — "
              f"{summary.total_frames} frames, "
              f"Overall: {scores['overall_body_language_score']}/10, "
              f"Combined: {combined_score}%")

        return {
            "success": True,
            "scores": scores,
            "combined_score": combined_score,
            "report_path": report_path,
            "summary": {
                "duration_seconds": summary.duration_seconds,
                "total_frames": summary.total_frames,
                "eye_contact_pct": summary.eye_contact_percentage,
                "dominant_emotion": summary.dominant_emotion,
                "avg_posture_score": summary.avg_posture_score,
                "gesture_frequency": summary.gesture_frequency,
                "fidget_percentage": summary.fidget_percentage,
                "head_centered_pct": summary.head_centered_percentage,
                "engagement_score": summary.overall_engagement_score,
                "confidence_score": summary.overall_confidence_score,
            }
        }

    except Exception as e:
        print(f"[NVC] Session completion error: {e}")
        import traceback
        traceback.print_exc()
        return {"success": False, "scores": _default_scores(), "error": str(e)}


def get_nvc_status(session_id: str) -> Dict:
    """Get current status of an NVC session."""
    with _sessions_lock:
        session = _active_sessions.get(session_id)
    
    if not session:
        return {"active": False}
    
    return {
        "active": True,
        "frame_count": session["frame_count"],
        "elapsed_seconds": round(time.time() - session["started_at"], 1),
    }


def _calculate_scores(summary) -> Dict:
    """Convert SessionSummary to normalized 0-10 scores."""
    eye = min(10.0, summary.eye_contact_percentage / 10.0)
    confidence = min(10.0, summary.overall_confidence_score / 10.0)
    posture = min(10.0, summary.avg_posture_score / 10.0)
    engagement = min(10.0, summary.overall_engagement_score / 10.0)

    # Gesture score: moderate use is best (5-12/min optimal)
    g_freq = summary.gesture_frequency
    if 5 <= g_freq <= 12:
        gesture = 8.0 + min(2.0, (g_freq - 5) / 7.0 * 2.0)
    elif g_freq < 5:
        gesture = max(3.0, g_freq / 5.0 * 7.0)
    else:
        gesture = max(4.0, 10.0 - (g_freq - 12) * 0.5)

    # Fidget penalty
    fidget_penalty = min(2.0, summary.fidget_percentage / 25.0 * 2.0)
    gesture = max(0, gesture - fidget_penalty)

    overall = round(
        eye * 0.25 + confidence * 0.25 + posture * 0.20 +
        gesture * 0.15 + engagement * 0.15, 2
    )

    return {
        "eye_contact_score": round(eye, 2),
        "confidence_score": round(confidence, 2),
        "posture_score": round(posture, 2),
        "gesture_score": round(gesture, 2),
        "engagement_score": round(engagement, 2),
        "overall_body_language_score": round(overall, 2),
        "dominant_emotion": summary.dominant_emotion,
        "emotion_breakdown": summary.emotion_breakdown,
        "gesture_frequency": summary.gesture_frequency,
        "fidget_percentage": summary.fidget_percentage,
        "head_centered_percentage": summary.head_centered_percentage,
    }


def _default_scores() -> Dict:
    """Return default scores when analysis is unavailable."""
    return {
        "eye_contact_score": 5.0,
        "confidence_score": 5.0,
        "posture_score": 5.0,
        "gesture_score": 5.0,
        "engagement_score": 5.0,
        "overall_body_language_score": 5.0,
        "dominant_emotion": "neutral",
        "emotion_breakdown": {},
        "gesture_frequency": 0,
        "fidget_percentage": 0,
        "head_centered_percentage": 0,
    }
