from pathlib import Path
from openai import OpenAI
from key import OpenApikey

client = OpenAI(api_key=OpenApikey)
import random

voices = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer']

# FIXED: Now properly handles MP3 format (web-compatible)
def textToSpeech(text, path):
    """
    Generate speech from text using OpenAI TTS API.
    
    Args:
        text: The text to convert to speech
        path: Desired filename (extension will be changed to .mp3)
    
    Returns:
        Path to the generated audio file (always .mp3)
    """
    voice = random.choice(voices)
    
    # FIXED: Force MP3 extension (OpenAI TTS outputs MP3)
    # Convert any .wav extension to .mp3
    path_str = str(path)
    if path_str.endswith('.wav'):
        path_str = path_str.replace('.wav', '.mp3')
    elif not path_str.endswith('.mp3'):
        path_str += '.mp3'
    
    speech_file_path = Path(__file__).parent / path_str
    
    # OpenAI TTS generates MP3 by default (web-compatible format)
    response = client.audio.speech.create(
        model="tts-1",
        voice=voice,
        input=text,
        response_format="mp3"  # Explicitly set to MP3
    )
    
    response.stream_to_file(speech_file_path)
    
    print(f"✅ Generated audio: {speech_file_path.name} (voice: {voice})")
    
    return speech_file_path
