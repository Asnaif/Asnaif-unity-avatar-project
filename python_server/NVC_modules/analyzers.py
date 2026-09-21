"""
Analyzers for eye contact, emotion, gestures, posture, and head pose.
Uses MediaPipe landmark data to compute metrics.
"""
import math
import numpy as np
from typing import Dict, List, Optional, Tuple
from .session_recorder import (
    EyeContactData, EmotionData, GestureData, PostureData, HeadPoseData
)
from . import config


def _dist(p1, p2) -> float:
    return math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)


def _dist3d(p1, p2) -> float:
    return math.sqrt((p1.x-p2.x)**2 + (p1.y-p2.y)**2 + (p1.z-p2.z)**2)


# ═══════════════════════════════════════════════════════════
# EYE CONTACT ANALYZER
# ═══════════════════════════════════════════════════════════
class EyeContactAnalyzer:
    # MediaPipe Face Mesh landmark indices
    # Right eye: inner corner 362, outer corner 263
    # Left eye: inner corner 133, outer corner 33
    # Right iris center: 468, Left iris center: 473
    RIGHT_EYE_INNER = 362
    RIGHT_EYE_OUTER = 263
    RIGHT_EYE_TOP = 386
    RIGHT_EYE_BOTTOM = 374
    LEFT_EYE_INNER = 133
    LEFT_EYE_OUTER = 33
    LEFT_EYE_TOP = 159
    LEFT_EYE_BOTTOM = 145
    RIGHT_IRIS = 468
    LEFT_IRIS = 473

    def analyze(self, face_landmarks) -> EyeContactData:
        if not face_landmarks:
            return EyeContactData()
        lm = face_landmarks.landmark
        if len(lm) < 474:
            return EyeContactData()
        try:
            # Right eye iris position relative to eye corners
            r_inner = lm[self.RIGHT_EYE_INNER]
            r_outer = lm[self.RIGHT_EYE_OUTER]
            r_iris = lm[self.RIGHT_IRIS]
            r_top = lm[self.RIGHT_EYE_TOP]
            r_bot = lm[self.RIGHT_EYE_BOTTOM]

            r_width = _dist(r_inner, r_outer)
            r_height = _dist(r_top, r_bot)
            if r_width < 1e-6:
                return EyeContactData()

            r_cx = (r_inner.x + r_outer.x) / 2
            r_cy = (r_top.y + r_bot.y) / 2
            r_dx = (r_iris.x - r_cx) / r_width
            r_dy = (r_iris.y - r_cy) / max(r_height, 1e-6)

            # Left eye
            l_inner = lm[self.LEFT_EYE_INNER]
            l_outer = lm[self.LEFT_EYE_OUTER]
            l_iris = lm[self.LEFT_IRIS]
            l_top = lm[self.LEFT_EYE_TOP]
            l_bot = lm[self.LEFT_EYE_BOTTOM]

            l_width = _dist(l_inner, l_outer)
            l_height = _dist(l_top, l_bot)
            if l_width < 1e-6:
                return EyeContactData()

            l_cx = (l_inner.x + l_outer.x) / 2
            l_cy = (l_top.y + l_bot.y) / 2
            l_dx = (l_iris.x - l_cx) / l_width
            l_dy = (l_iris.y - l_cy) / max(l_height, 1e-6)

            gaze_x = (r_dx + l_dx) / 2
            gaze_y = (r_dy + l_dy) / 2

            h_dev = abs(gaze_x) / config.EYE_CONTACT_HORIZONTAL_THRESHOLD
            v_dev = abs(gaze_y) / config.EYE_CONTACT_VERTICAL_THRESHOLD
            score = max(0.0, 1.0 - max(h_dev, v_dev))
            is_looking = score >= config.EYE_CONTACT_SCORE_THRESHOLD

            return EyeContactData(
                is_looking=is_looking, score=round(score, 3),
                gaze_x=round(gaze_x, 3), gaze_y=round(gaze_y, 3)
            )
        except Exception:
            return EyeContactData()


# ═══════════════════════════════════════════════════════════
# EMOTION APPROXIMATOR
# ═══════════════════════════════════════════════════════════
class EmotionApproximator:
    # Mouth landmarks
    MOUTH_LEFT = 61
    MOUTH_RIGHT = 291
    MOUTH_TOP = 13
    MOUTH_BOTTOM = 14
    UPPER_LIP = 82
    LOWER_LIP = 87

    # Eyebrow landmarks
    LEFT_BROW_TOP = 105
    LEFT_BROW_BOT = 66
    RIGHT_BROW_TOP = 334
    RIGHT_BROW_BOT = 296
    LEFT_EYE_TOP = 159
    LEFT_EYE_BOT = 145
    RIGHT_EYE_TOP = 386
    RIGHT_EYE_BOT = 374

    def analyze(self, face_landmarks) -> EmotionData:
        if not face_landmarks:
            return EmotionData()
        lm = face_landmarks.landmark
        try:
            # Mouth aspect ratio
            m_width = _dist(lm[self.MOUTH_LEFT], lm[self.MOUTH_RIGHT])
            m_height = _dist(lm[self.MOUTH_TOP], lm[self.MOUTH_BOTTOM])
            mar = m_height / max(m_width, 1e-6)

            # Mouth openness
            lip_dist = _dist(lm[self.UPPER_LIP], lm[self.LOWER_LIP])
            mouth_open = lip_dist / max(m_width, 1e-6)

            # Smile ratio (wider mouth relative to height = smile)
            smile_ratio = m_width / max(m_height, 1e-6)

            # Eye openness
            l_eye_h = _dist(lm[self.LEFT_EYE_TOP], lm[self.LEFT_EYE_BOT])
            r_eye_h = _dist(lm[self.RIGHT_EYE_TOP], lm[self.RIGHT_EYE_BOT])
            eye_open = (l_eye_h + r_eye_h) / 2

            # Brow height relative to eyes
            l_brow_h = abs(lm[self.LEFT_BROW_TOP].y - lm[self.LEFT_EYE_TOP].y)
            r_brow_h = abs(lm[self.RIGHT_BROW_TOP].y - lm[self.RIGHT_EYE_TOP].y)
            brow_height = (l_brow_h + r_brow_h) / 2

            # Score each emotion
            scores = {}
            # Confident: slight smile, relaxed brow, normal eyes
            scores["confident"] = min(1.0, max(0.0,
                (smile_ratio - 1.5) * 0.5 +
                (0.3 - abs(brow_height - 0.025)) * 5 +
                (eye_open - 0.015) * 10
            ) / 3)

            # Engaged: alert eyes, responsive face
            scores["engaged"] = min(1.0, max(0.0,
                eye_open * 15 +
                (brow_height - 0.02) * 10 +
                smile_ratio * 0.1
            ) / 3)

            # Nervous: tense, forced expressions
            scores["nervous"] = min(1.0, max(0.0,
                mouth_open * 2 +
                abs(smile_ratio - 2.0) * 0.3 +
                (0.03 - brow_height) * 10
            ) / 3)

            # Stressed: furrowed brows, tight lips
            scores["stressed"] = min(1.0, max(0.0,
                (0.02 - brow_height) * 15 +
                (0.3 - eye_open * 10) * 0.5 +
                (1.5 - smile_ratio) * 0.3
            ) / 3)

            # Neutral: baseline
            scores["neutral"] = max(0.0, 1.0 - sum(scores.values()))

            # Normalize
            total = sum(scores.values())
            if total > 0:
                scores = {k: round(v/total, 3) for k, v in scores.items()}

            dominant = max(scores, key=scores.get)
            confidence = scores[dominant]

            return EmotionData(
                dominant_emotion=dominant,
                confidence=round(confidence, 3),
                scores=scores
            )
        except Exception:
            return EmotionData()


# ═══════════════════════════════════════════════════════════
# GESTURE CLASSIFIER
# ═══════════════════════════════════════════════════════════
class GestureClassifier:
    WRIST = 0
    THUMB_TIP = 4; INDEX_TIP = 8; MIDDLE_TIP = 12
    RING_TIP = 16; PINKY_TIP = 20
    THUMB_MCP = 2; INDEX_MCP = 5; MIDDLE_MCP = 9
    RING_MCP = 13; PINKY_MCP = 17
    INDEX_PIP = 6; MIDDLE_PIP = 10; RING_PIP = 14; PINKY_PIP = 18

    def __init__(self):
        self._prev_positions: Dict[str, Tuple[float, float]] = {}
        self._prev_time: float = 0

    def _is_finger_extended(self, lm, tip, pip, mcp) -> bool:
        tip_to_mcp = _dist(lm[tip], lm[mcp])
        pip_to_mcp = _dist(lm[pip], lm[mcp])
        return tip_to_mcp > pip_to_mcp * 1.2

    def _classify_hand(self, hand_landmarks) -> str:
        lm = hand_landmarks.landmark
        fingers = [
            self._is_finger_extended(lm, self.INDEX_TIP, self.INDEX_PIP, self.INDEX_MCP),
            self._is_finger_extended(lm, self.MIDDLE_TIP, self.MIDDLE_PIP, self.MIDDLE_MCP),
            self._is_finger_extended(lm, self.RING_TIP, self.RING_PIP, self.RING_MCP),
            self._is_finger_extended(lm, self.PINKY_TIP, self.PINKY_PIP, self.PINKY_MCP),
        ]
        # Thumb
        thumb_ext = _dist(lm[self.THUMB_TIP], lm[self.WRIST]) > \
                    _dist(lm[self.THUMB_MCP], lm[self.WRIST]) * 1.2

        ext_count = sum(fingers)
        if ext_count >= 3 and thumb_ext:
            return "open_palm"
        elif fingers[0] and not fingers[1] and not fingers[2] and not fingers[3]:
            return "pointing"
        elif fingers[0] and fingers[1] and not fingers[2] and not fingers[3]:
            return "peace_sign"
        elif thumb_ext and ext_count == 0:
            return "thumbs_up"
        elif ext_count == 0 and not thumb_ext:
            return "fist"
        else:
            return "open_palm"

    def _check_fidgeting(self, hand_landmarks, hand_id: str, current_time: float) -> Tuple[bool, float]:
        lm = hand_landmarks.landmark
        cx = sum(l.x for l in lm) / len(lm)
        cy = sum(l.y for l in lm) / len(lm)

        velocity = 0.0
        is_fidget = False

        if hand_id in self._prev_positions and self._prev_time > 0:
            dt = current_time - self._prev_time
            if dt > 0:
                px, py = self._prev_positions[hand_id]
                dx = (cx - px) * 640  # Approximate pixel scale
                dy = (cy - py) * 480
                velocity = math.sqrt(dx*dx + dy*dy) / dt
                is_fidget = velocity > config.FIDGET_VELOCITY_THRESHOLD

        self._prev_positions[hand_id] = (cx, cy)
        self._prev_time = current_time
        return is_fidget, velocity

    def analyze(self, left_hand, right_hand, current_time: float) -> GestureData:
        data = GestureData()
        max_velocity = 0.0
        any_fidget = False

        if left_hand:
            data.left_hand_detected = True
            data.left_gesture = self._classify_hand(left_hand)
            fid, vel = self._check_fidgeting(left_hand, "left", current_time)
            any_fidget = any_fidget or fid
            max_velocity = max(max_velocity, vel)

        if right_hand:
            data.right_hand_detected = True
            data.right_gesture = self._classify_hand(right_hand)
            fid, vel = self._check_fidgeting(right_hand, "right", current_time)
            any_fidget = any_fidget or fid
            max_velocity = max(max_velocity, vel)

        data.is_fidgeting = any_fidget
        data.movement_velocity = round(max_velocity, 1)
        return data


# ═══════════════════════════════════════════════════════════
# POSTURE ANALYZER
# ═══════════════════════════════════════════════════════════
class PostureAnalyzer:
    LEFT_SHOULDER = 11; RIGHT_SHOULDER = 12
    LEFT_HIP = 23; RIGHT_HIP = 24
    NOSE = 0

    def analyze(self, pose_landmarks, frame_width: int) -> PostureData:
        if not pose_landmarks:
            return PostureData()
        lm = pose_landmarks.landmark
        try:
            ls = lm[self.LEFT_SHOULDER]
            rs = lm[self.RIGHT_SHOULDER]
            nose = lm[self.NOSE]

            # Shoulder angle
            dy = (ls.y - rs.y)
            dx = (ls.x - rs.x)
            angle = math.degrees(math.atan2(dy, dx))
            shoulder_angle = abs(angle)

            # Shoulder midpoint
            mid_x = (ls.x + rs.x) / 2
            mid_y = (ls.y + rs.y) / 2

            # Spine alignment (nose should be above shoulder midpoint)
            spine_offset_x = abs(nose.x - mid_x)
            spine_offset_y = nose.y - mid_y  # negative = nose above shoulders (good)

            # Determine posture
            score = 1.0
            posture = "upright"

            if shoulder_angle > config.SHOULDER_TILT_THRESHOLD + 10:
                if ls.y > rs.y:
                    posture = "leaning_left"
                else:
                    posture = "leaning_right"
                score -= 0.3

            if spine_offset_x > config.LEAN_THRESHOLD:
                if nose.x < mid_x:
                    posture = "leaning_left"
                else:
                    posture = "leaning_right"
                score -= 0.2

            # Slouch detection: if nose is too close to shoulders vertically
            shoulder_width = _dist(ls, rs)
            nose_to_shoulder_y = abs(nose.y - mid_y)
            if nose_to_shoulder_y < shoulder_width * 0.3:
                posture = "slouching"
                score -= 0.4

            # Distance check (face size in frame)
            face_width_ratio = shoulder_width
            if face_width_ratio > config.TOO_CLOSE_THRESHOLD:
                posture = "too_close"
                score -= 0.2
            elif face_width_ratio < config.TOO_FAR_THRESHOLD:
                posture = "too_far"
                score -= 0.2

            score = max(0.0, min(1.0, score))

            return PostureData(
                posture=posture, score=round(score, 3),
                shoulder_angle=round(shoulder_angle, 1),
                spine_alignment=round(1.0 - spine_offset_x * 5, 3)
            )
        except Exception:
            return PostureData()


# ═══════════════════════════════════════════════════════════
# HEAD POSE ESTIMATOR
# ═══════════════════════════════════════════════════════════
class HeadPoseEstimator:
    NOSE_TIP = 1; CHIN = 199
    LEFT_EYE = 33; RIGHT_EYE = 263
    LEFT_MOUTH = 61; RIGHT_MOUTH = 291

    def analyze(self, face_landmarks) -> HeadPoseData:
        if not face_landmarks:
            return HeadPoseData()
        lm = face_landmarks.landmark
        try:
            nose = lm[self.NOSE_TIP]
            chin = lm[self.CHIN]
            l_eye = lm[self.LEFT_EYE]
            r_eye = lm[self.RIGHT_EYE]

            # Yaw: horizontal asymmetry of nose relative to eyes
            eye_cx = (l_eye.x + r_eye.x) / 2
            yaw = (nose.x - eye_cx) * 200  # Scale to degrees approx

            # Pitch: vertical position of nose relative to eyes and chin
            eye_cy = (l_eye.y + r_eye.y) / 2
            face_h = abs(chin.y - eye_cy)
            nose_ratio = (nose.y - eye_cy) / max(face_h, 1e-6)
            pitch = (nose_ratio - 0.4) * 100  # Centered around typical ratio

            # Roll: eye line angle
            roll = math.degrees(math.atan2(r_eye.y - l_eye.y, r_eye.x - l_eye.x))

            is_centered = (abs(yaw) < config.HEAD_YAW_THRESHOLD and
                          abs(pitch) < config.HEAD_PITCH_THRESHOLD and
                          abs(roll) < config.HEAD_ROLL_THRESHOLD)

            return HeadPoseData(
                yaw=round(yaw, 1), pitch=round(pitch, 1),
                roll=round(roll, 1), is_centered=is_centered
            )
        except Exception:
            return HeadPoseData()
