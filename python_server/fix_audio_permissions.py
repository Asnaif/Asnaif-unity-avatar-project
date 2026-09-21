#!/usr/bin/env python3
"""
Fix Audio Permissions Script
Makes all existing audio files in Firebase Storage public.
Run this once to fix CORS issues with existing files.
"""

from firebase_admin_instance import get_storage_bucket

def make_all_audio_public():
    """Make all QuestionAudios files public"""
    
    print("🔧 Starting to fix audio file permissions...")
    
    bucket = get_storage_bucket()
    
    # List all audio files
    blobs = bucket.list_blobs(prefix='QuestionAudios/')
    
    count = 0
    for blob in blobs:
        try:
            blob.make_public()
            print(f"✅ Made public: {blob.name}")
            count += 1
        except Exception as e:
            print(f"❌ Failed for {blob.name}: {e}")
    
    print(f"\n🎉 Done! Made {count} files public.")
    print("\nNow test your audio playback in the app!")

if __name__ == "__main__":
    make_all_audio_public()