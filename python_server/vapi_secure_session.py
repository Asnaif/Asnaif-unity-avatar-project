"""
VAPI Secure Session Management
Handles secure session tokens, assistant creation, and session lifecycle.
CRITICAL: API keys never exposed to client - only tokens.
"""

import jwt
import uuid
import requests
from datetime import datetime, timedelta
from typing import Dict, Optional
from key import VapiPrivateKey, VapiPublicKey

# VAPI API
VAPI_API_BASE = "https://api.vapi.ai"

# Secret for signing session tokens (in production, use env variable)
SESSION_SECRET = "interprep_secure_session_secret_key_2024"

# Active sessions cache
_active_sessions: Dict[str, dict] = {}


def get_vapi_headers():
    """Get headers for VAPI API calls - server side only"""
    return {
        "Authorization": f"Bearer {VapiPrivateKey}",
        "Content-Type": "application/json"
    }


def generate_session_token(
    assistant_id: str,
    user_id: str,
    duration_minutes: int = 30
) -> Dict:
    """
    Generate a short-lived session token for Flutter client.
    This token is used instead of exposing API keys.
    
    Args:
        assistant_id: VAPI assistant ID
        user_id: Firebase user ID
        duration_minutes: Interview duration + buffer
    
    Returns:
        dict with session_token and metadata
    """
    
    session_id = str(uuid.uuid4())
    expiry = datetime.utcnow() + timedelta(minutes=duration_minutes + 10)
    
    # Token payload
    payload = {
        "session_id": session_id,
        "assistant_id": assistant_id,
        "user_id": user_id,
        "public_key": VapiPublicKey,  # Safe to include - it's public
        "exp": expiry.timestamp(),
        "iat": datetime.utcnow().timestamp(),
        "permissions": ["voice", "transcript"]
    }
    
    # Sign token
    token = jwt.encode(payload, SESSION_SECRET, algorithm="HS256")
    
    # Cache session
    _active_sessions[session_id] = {
        "assistant_id": assistant_id,
        "user_id": user_id,
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": expiry.isoformat(),
        "status": "created",
        "call_id": None,
        "transcript_chunks": []
    }
    
    print(f"✅ Session token generated: {session_id[:8]}...")
    
    return {
        "session_token": token,
        "session_id": session_id,
        "assistant_id": assistant_id,
        "public_key": VapiPublicKey,
        "expires_at": expiry.isoformat()
    }


def validate_session_token(token: str) -> Optional[Dict]:
    """
    Validate a session token.
    
    Args:
        token: JWT session token
        
    Returns:
        Token payload if valid, None if invalid/expired
    """
    
    try:
        payload = jwt.decode(token, SESSION_SECRET, algorithms=["HS256"])
        
        # Check if session still active
        session_id = payload.get("session_id")
        if session_id not in _active_sessions:
            print(f"⚠️ Session not found: {session_id[:8]}...")
            return None
        
        return payload
        
    except jwt.ExpiredSignatureError:
        print("⚠️ Token expired")
        return None
    except jwt.InvalidTokenError as e:
        print(f"⚠️ Invalid token: {e}")
        return None


def create_secure_assistant(
    system_prompt: str,
    first_message: str,
    voice_id: str = "Savannah",  # VAPI active voice - Female, American
    duration_minutes: int = 20
) -> Dict:
    """
    Create VAPI assistant server-side with given configuration.
    
    Args:
        system_prompt: Full system prompt for interviewer
        first_message: Opening message
        voice_id: VAPI built-in voice name (default: Lily)
        duration_minutes: Max interview duration
    
    Returns:
        dict with assistant_id or error
    """
    
    assistant_config = {
        "name": f"InterPrep Interviewer - {datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "model": {
            "provider": "openai",
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "system",
                    "content": system_prompt
                }
            ],
            "temperature": 0.7
        },
        "voice": {
            "provider": "vapi",
            "voiceId": voice_id  # VAPI built-in voice (use parameter)
        },
        "firstMessage": first_message,
        "transcriber": {
            "provider": "deepgram",
            "model": "nova-2",
            "language": "en"
        },
        "silenceTimeoutSeconds": 120,
        "customerJoinTimeoutSeconds": 120,
        "maxDurationSeconds": duration_minutes * 60,
        "endCallFunctionEnabled": True,
        "endCallMessage": "Thank you so much for taking the time to interview with us today. You've provided some great insights about your experience. We'll be in touch soon regarding next steps. Have a wonderful day!",
        "recordingEnabled": True,
        "hipaaEnabled": False,
        "clientMessages": [
            "transcript",
            "hang",
            "function-call",
            "speech-update",
            "metadata",
            "conversation-update"
        ],
        "serverMessages": [
            "end-of-call-report",
            "status-update",
            "hang",
            "function-call"
        ]
    }
    
    try:
        response = requests.post(
            f"{VAPI_API_BASE}/assistant",
            headers=get_vapi_headers(),
            json=assistant_config
        )
        
        if response.status_code in [200, 201]:
            data = response.json()
            print(f"✅ Secure assistant created: {data.get('id')}")
            return {
                "success": True,
                "assistant_id": data.get("id"),
                "assistant_name": data.get("name")
            }
        else:
            print(f"❌ Assistant creation failed: {response.status_code}")
            print(f"   Response: {response.text[:500]}")
            return {
                "success": False,
                "error": response.text
            }
            
    except Exception as e:
        print(f"❌ Assistant creation error: {e}")
        return {
            "success": False,
            "error": str(e)
        }


def update_session_call_id(session_id: str, call_id: str) -> bool:
    """
    Update session with VAPI call ID when call starts.
    """
    if session_id in _active_sessions:
        _active_sessions[session_id]["call_id"] = call_id
        _active_sessions[session_id]["status"] = "active"
        print(f"✅ Session {session_id[:8]} linked to call {call_id[:8]}")
        return True
    return False


def append_transcript_chunk(session_id: str, chunk: Dict) -> bool:
    """
    Append transcript chunk to session from webhook.
    """
    if session_id in _active_sessions:
        _active_sessions[session_id]["transcript_chunks"].append({
            "timestamp": datetime.utcnow().isoformat(),
            **chunk
        })
        return True
    return False


def get_session_data(session_id: str) -> Optional[Dict]:
    """
    Get session data including transcript chunks.
    """
    return _active_sessions.get(session_id)


def end_session(session_id: str) -> Dict:
    """
    End session and get final data.
    """
    if session_id in _active_sessions:
        session = _active_sessions[session_id]
        session["status"] = "completed"
        session["ended_at"] = datetime.utcnow().isoformat()
        return session
    return {}


def cleanup_expired_sessions():
    """
    Clean up expired sessions from cache.
    Call periodically to prevent memory leaks.
    """
    now = datetime.utcnow()
    expired = []
    
    for session_id, session in _active_sessions.items():
        expires_at = datetime.fromisoformat(session.get("expires_at", now.isoformat()))
        if now > expires_at:
            expired.append(session_id)
    
    for session_id in expired:
        del _active_sessions[session_id]
        print(f"🧹 Cleaned up expired session: {session_id[:8]}")
    
    return len(expired)


def delete_assistant(assistant_id: str) -> bool:
    """
    Delete assistant after interview ends.
    """
    try:
        response = requests.delete(
            f"{VAPI_API_BASE}/assistant/{assistant_id}",
            headers=get_vapi_headers()
        )
        if response.status_code in [200, 204]:
            print(f"✅ Assistant deleted: {assistant_id[:8]}")
            return True
        return False
    except Exception as e:
        print(f"❌ Delete assistant error: {e}")
        return False


def get_call_transcript(call_id: str) -> Dict:
    """
    Get full transcript from VAPI call.
    """
    try:
        response = requests.get(
            f"{VAPI_API_BASE}/call/{call_id}",
            headers=get_vapi_headers()
        )
        
        if response.status_code == 200:
            data = response.json()
            return {
                "success": True,
                "transcript": data.get("transcript", ""),
                "messages": data.get("messages", []),
                "duration": data.get("endedAt", 0),
                "recording_url": data.get("recordingUrl"),
                "status": data.get("status")
            }
        else:
            return {"success": False, "error": response.text}
            
    except Exception as e:
        return {"success": False, "error": str(e)}
