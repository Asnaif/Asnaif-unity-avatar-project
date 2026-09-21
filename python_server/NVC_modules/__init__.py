"""
NVC_modules — Non-Verbal Communication Analysis
Body language detection using MediaPipe Holistic for InterPrep interviews.
"""
from .session_recorder import (
    SessionRecorder, SessionSummary, FrameMetrics,
    EyeContactData, EmotionData, GestureData, PostureData, HeadPoseData
)
from .analyzers import (
    EyeContactAnalyzer, EmotionApproximator, GestureClassifier,
    PostureAnalyzer, HeadPoseEstimator
)
