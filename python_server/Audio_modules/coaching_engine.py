"""
Real-time coaching engine for providing live feedback during practice sessions.
"""

def analyze_realtime_audio(audio_chunk, previous_metrics=None):
    """
    Analyze audio chunk in real-time and provide coaching suggestions.
    
    Args:
        audio_chunk: Audio data chunk (bytes or file path)
        previous_metrics: Previous analysis metrics for comparison
        
    Returns:
        dict: Coaching suggestions and warnings
    """
    import librosa
    import numpy as np
    
    try:
        # Load audio (if path) or process chunk
        if isinstance(audio_chunk, str):
            y, sr = librosa.load(audio_chunk, sr=22050)
        else:
            # For real-time, would need to handle audio stream
            # This is a simplified version
            return {
                'warnings': [],
                'suggestions': [],
                'confidence_score': 0.5,
            }
        
        # Calculate pitch
        pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
        pitch_values = []
        for t in range(pitches.shape[1]):
            index = magnitudes[:, t].argmax()
            pitch = pitches[index, t]
            if pitch > 0:
                pitch_values.append(pitch)
        
        avg_pitch = np.mean(pitch_values) if pitch_values else 0
        
        # Calculate speech rate (simplified)
        # In real implementation, would use STT for word count
        duration = len(y) / sr
        estimated_words = duration * 2  # Rough estimate
        speech_rate = (estimated_words / duration) * 60 if duration > 0 else 0
        
        warnings = []
        suggestions = []
        
        # Pitch analysis
        if avg_pitch > 0:
            if avg_pitch < 100:
                warnings.append('pitch_low')
                suggestions.append('Try speaking with more energy and enthusiasm')
            elif avg_pitch > 200:
                warnings.append('pitch_high')
                suggestions.append('Try to speak more calmly and lower your pitch')
            elif 120 <= avg_pitch <= 180:
                suggestions.append('Great pitch! Keep it up')
        
        # Speech rate analysis
        if speech_rate > 0:
            if speech_rate < 100:
                warnings.append('pace_slow')
                suggestions.append('Try speaking a bit faster for better engagement')
            elif speech_rate > 180:
                warnings.append('pace_fast')
                suggestions.append('Slow down a bit for better clarity')
            elif 120 <= speech_rate <= 150:
                suggestions.append('Perfect pace! Maintain this speed')
        
        # Compare with previous metrics
        if previous_metrics:
            if 'pitch' in previous_metrics:
                pitch_change = avg_pitch - previous_metrics['pitch']
                if abs(pitch_change) > 20:
                    if pitch_change > 0:
                        suggestions.append('Your pitch has increased - try to maintain consistency')
                    else:
                        suggestions.append('Your pitch has decreased - add more energy')
        
        # Calculate confidence score (simplified)
        confidence_score = 0.7
        if warnings:
            confidence_score -= len(warnings) * 0.1
        confidence_score = max(0.0, min(1.0, confidence_score))
        
        return {
            'warnings': warnings,
            'suggestions': suggestions,
            'confidence_score': confidence_score,
            'current_pitch': avg_pitch,
            'current_speech_rate': speech_rate,
        }
    except Exception as e:
        print(f'Error in real-time coaching: {e}')
        return {
            'warnings': [],
            'suggestions': [],
            'confidence_score': 0.5,
            'error': str(e),
        }


def detect_pauses(audio_data, sr=22050, min_pause_duration=0.5):
    """
    Detect pauses in speech.
    
    Args:
        audio_data: Audio signal
        sr: Sample rate
        min_pause_duration: Minimum pause duration in seconds
        
    Returns:
        list: List of pause intervals [(start, end), ...]
    """
    import librosa
    import numpy as np
    
    try:
        # Calculate energy
        frame_length = 2048
        hop_length = 512
        energy = librosa.feature.rms(y=audio_data, frame_length=frame_length, hop_length=hop_length)[0]
        
        # Threshold for silence
        threshold = np.percentile(energy, 20)
        
        # Find silence regions
        is_silence = energy < threshold
        pauses = []
        
        in_pause = False
        pause_start = 0
        
        for i, silent in enumerate(is_silence):
            if silent and not in_pause:
                pause_start = i * hop_length / sr
                in_pause = True
            elif not silent and in_pause:
                pause_end = i * hop_length / sr
                pause_duration = pause_end - pause_start
                if pause_duration >= min_pause_duration:
                    pauses.append((pause_start, pause_end))
                in_pause = False
        
        return pauses
    except Exception as e:
        print(f'Error detecting pauses: {e}')
        return []


def generate_improvement_tips(user_history):
    """
    Generate personalized improvement tips based on user's practice history.
    
    Args:
        user_history: List of previous session metrics
        
    Returns:
        list: Personalized tips
    """
    if not user_history:
        return [
            'Start practicing regularly to build confidence',
            'Focus on speaking clearly and at a steady pace',
            'Practice in a quiet environment for better results',
        ]
    
    tips = []
    
    # Analyze pitch trends
    pitches = [h.get('pitch', 0) for h in user_history if 'pitch' in h]
    if pitches:
        avg_pitch = sum(pitches) / len(pitches)
        if avg_pitch < 120:
            tips.append('Your average pitch is low - practice speaking with more energy')
        elif avg_pitch > 180:
            tips.append('Your average pitch is high - try to speak more calmly')
    
    # Analyze speech rate trends
    speech_rates = [h.get('speech_rate', 0) for h in user_history if 'speech_rate' in h]
    if speech_rates:
        avg_rate = sum(speech_rates) / len(speech_rates)
        if avg_rate < 120:
            tips.append('Practice speaking faster to improve engagement')
        elif avg_rate > 180:
            tips.append('Slow down your speech for better clarity')
    
    # Analyze sentiment trends
    sentiments = [h.get('sentiment', 0) for h in user_history if 'sentiment' in h]
    if sentiments:
        avg_sentiment = sum(sentiments) / len(sentiments)
        if avg_sentiment < 0:
            tips.append('Work on maintaining a more positive tone')
    
    if not tips:
        tips.append('Great progress! Keep practicing to maintain your skills')
    
    return tips








