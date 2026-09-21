from pydub import AudioSegment
import speech_recognition as sr
import os
import shutil

def check_ffmpeg_available():
    """Check if ffmpeg is available in the system PATH"""
    return shutil.which("ffmpeg") is not None

def calculate_speech_rate_from_text_and_audio(text, audio_path):
    """Calculate speech rate with error handling"""
    try:
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
        if not check_ffmpeg_available():
            raise RuntimeError(
                "ffmpeg is not installed or not in PATH. "
                "Please install ffmpeg:\n"
                "Windows: Download from https://ffmpeg.org/download.html or use: choco install ffmpeg\n"
                "Or add ffmpeg to your system PATH."
            )
        
        # Load the audio file
        audio_segment = AudioSegment.from_mp3(audio_path)

        # Count the number of words in the text
        words = len(text.split())

        # Get the duration of the audio in seconds
        audio_duration_seconds = len(audio_segment.raw_data) / (audio_segment.sample_width * audio_segment.frame_rate)

        # Calculate speech rate in words per minute (WPM)
        speech_rate = (words / audio_duration_seconds) * 60

        return speech_rate
    except Exception as e:
        error_msg = f"Speech rate calculation failed: {str(e)}"
        print(f"❌ {error_msg}")
        raise RuntimeError(error_msg)

# Example usage
# audio_path = "sample_audio.mp3"  # Replace with the actual path to your audio file
# text = "Your text goes here."

# speech_rate = calculate_speech_rate_from_text_and_audio(text, audio_path)

# print(f"Speech Rate: {speech_rate:.2f} words per minute")
