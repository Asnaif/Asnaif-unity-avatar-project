"""
VAPI Integration Module for Real-Time Interview
Handles creating AI interviewer assistants and managing interview sessions.
"""

import requests
import json
from datetime import datetime
from key import VapiPrivateKey, VapiPublicKey, OpenApikey
from firebase_admin_instance import get_firestore_instance

# VAPI API Base URL
VAPI_API_BASE = "https://api.vapi.ai"

# Headers for VAPI API calls
def get_vapi_headers():
    return {
        "Authorization": f"Bearer {VapiPrivateKey}",
        "Content-Type": "application/json"
    }


def create_interview_assistant(resume_text: str, jd: str = "", position: str = "", experience: str = "") -> dict:
    """
    Create a VAPI assistant configured for interview based on resume.
    
    Args:
        resume_text: Extracted text from resume
        jd: Job description (optional)
        position: Position applying for (optional)
        experience: Years of experience (optional)
    
    Returns:
        dict with assistant_id and status
    """
    
    # Build context for the interviewer
    context_parts = [f"Candidate's Resume:\n{resume_text}"]
    if jd:
        context_parts.append(f"Job Description:\n{jd}")
    if position:
        context_parts.append(f"Position: {position}")
    if experience:
        context_parts.append(f"Experience: {experience} years")
    
    full_context = "\n\n".join(context_parts)
    
    # System prompt for the AI interviewer
    system_prompt = f"""You are a professional HR interviewer conducting a real-time interview. 

Your behavior:
1. Be conversational and natural - this is a real interview, not a Q&A session
2. Ask follow-up questions based on the candidate's answers
3. IMPORTANT: Start by asking about specific details from their resume/CV - a project, skill, or work experience. Do NOT ask them to "introduce yourself" or "tell me about yourself"
4. Your first 3-4 questions MUST be directly based on the candidate's resume content
5. Cover both technical and behavioral questions relevant to their resume
6. Give encouraging responses when appropriate
7. If an answer is unclear, ask for clarification
8. Keep the interview flowing naturally for about 20 minutes
9. At the end, thank them and let them know the interview is complete

Candidate Information:
{full_context}

Important: 
- Don't read the resume out loud, but use it to ask relevant questions
- Ask about specific projects/experiences mentioned in the resume FIRST
- Start with resume-specific questions, then transition to broader questions
- Evaluate their communication skills, technical knowledge, and cultural fit
- Be professional but friendly"""

    # Create assistant payload
    assistant_config = {
        "name": f"InterPrep Interviewer - {datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "model": {
            "provider": "openai",
            "model": "gpt-4-turbo-preview",
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
            "voiceId": "Savannah"  # VAPI active voice - Female, American
        },
        "firstMessage": "Hello! Thank you for joining this interview session today. I've reviewed your resume carefully and I'm excited to discuss your experience. Let me start by asking about something specific from your background.",
        "transcriber": {
            "provider": "deepgram",
            "model": "nova-2"
        },
        "silenceTimeoutSeconds": 30,
        "customerJoinTimeoutSeconds": 45,
        "maxDurationSeconds": 1200,  # 20 minutes max
        "endCallMessage": "Thank you so much for taking the time to interview with us today. You've provided some great insights about your experience. We'll be in touch soon regarding next steps. Have a wonderful day!"
    }
    
    try:
        response = requests.post(
            f"{VAPI_API_BASE}/assistant",
            headers=get_vapi_headers(),
            json=assistant_config
        )
        
        if response.status_code == 201 or response.status_code == 200:
            assistant_data = response.json()
            print(f"✅ VAPI Assistant created: {assistant_data.get('id')}")
            return {
                "success": True,
                "assistant_id": assistant_data.get("id"),
                "assistant_name": assistant_data.get("name"),
                "data": assistant_data
            }
        else:
            print(f"❌ Failed to create VAPI assistant: {response.status_code}")
            print(f"   Response: {response.text}")
            return {
                "success": False,
                "error": response.text,
                "status_code": response.status_code
            }
            
    except Exception as e:
        print(f"❌ VAPI assistant creation error: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }


def start_web_call(assistant_id: str, user_id: str) -> dict:
    """
    Start a web-based VAPI call (for browser usage).
    Returns config needed for frontend to connect.
    
    Args:
        assistant_id: VAPI assistant ID
        user_id: Firebase user ID for tracking
    
    Returns:
        dict with call configuration for frontend
    """
    
    try:
        # For web calls, we just return the config - the actual WebRTC 
        # connection is established by the frontend using VAPI Web SDK
        return {
            "success": True,
            "assistant_id": assistant_id,
            "public_key": VapiPublicKey,
            "user_id": user_id,
            "config": {
                "assistantId": assistant_id,
                "apiKey": VapiPublicKey
            }
        }
        
    except Exception as e:
        print(f"❌ Error starting web call: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }


def get_call_details(call_id: str) -> dict:
    """
    Get details of a VAPI call including transcript.
    
    Args:
        call_id: VAPI call ID
    
    Returns:
        dict with call details and transcript
    """
    
    try:
        response = requests.get(
            f"{VAPI_API_BASE}/call/{call_id}",
            headers=get_vapi_headers()
        )
        
        if response.status_code == 200:
            call_data = response.json()
            return {
                "success": True,
                "data": call_data,
                "transcript": call_data.get("transcript", ""),
                "duration": call_data.get("duration"),
                "status": call_data.get("status"),
                "recording_url": call_data.get("recordingUrl")
            }
        else:
            return {
                "success": False,
                "error": response.text,
                "status_code": response.status_code
            }
            
    except Exception as e:
        print(f"❌ Error getting call details: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }


def analyze_interview_transcript(transcript: str, resume_text: str) -> dict:
    """
    Analyze the interview transcript to generate feedback.
    Uses OpenAI to evaluate the interview performance.
    
    Args:
        transcript: Full conversation transcript
        resume_text: Original resume text
    
    Returns:
        dict with comprehensive feedback
    """
    import openai
    openai.api_key = OpenApikey
    
    analysis_prompt = f"""Analyze this interview transcript and provide comprehensive feedback.

Resume:
{resume_text[:2000]}  # Limit resume text

Interview Transcript:
{transcript}

Provide feedback in the following JSON format:
{{
    "overall_score": 0-100,
    "communication_score": 0-100,
    "technical_score": 0-100,
    "confidence_score": 0-100,
    "strengths": ["list", "of", "strengths"],
    "areas_for_improvement": ["list", "of", "areas"],
    "detailed_feedback": "Paragraph with detailed feedback",
    "key_moments": [
        {{"timestamp": "approx", "moment": "description", "feedback": "what was good/bad"}}
    ],
    "recommendation": "Overall recommendation for the candidate"
}}

Be constructive and specific in your feedback."""

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are an expert interview coach providing detailed, constructive feedback."},
                {"role": "user", "content": analysis_prompt}
            ],
            temperature=0.7
        )
        
        feedback_text = response.choices[0].message.content
        
        # Try to parse as JSON
        try:
            # Find JSON in response
            import re
            json_match = re.search(r'\{[\s\S]*\}', feedback_text)
            if json_match:
                feedback_data = json.loads(json_match.group())
                return {
                    "success": True,
                    "feedback": feedback_data
                }
        except json.JSONDecodeError:
            pass
        
        # If JSON parsing fails, return as detailed_feedback
        return {
            "success": True,
            "feedback": {
                "detailed_feedback": feedback_text,
                "overall_score": 75  # Default score
            }
        }
        
    except Exception as e:
        print(f"❌ Error analyzing transcript: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }


def save_interview_session(user_id: str, session_data: dict) -> bool:
    """
    Save interview session data to Firestore.
    
    Args:
        user_id: Firebase user ID
        session_data: Complete session data including transcript and feedback
    
    Returns:
        bool indicating success
    """
    
    try:
        db = get_firestore_instance()
        sessions_ref = db.collection("sessions").document(user_id)
        
        # Get existing sessions
        doc = sessions_ref.get()
        if doc.exists:
            existing_data = doc.to_dict()
            sessions = existing_data.get("sessions", [])
        else:
            sessions = []
        
        # Add new VAPI session
        vapi_session = {
            "type": "vapi_realtime_interview",
            "timestamp": datetime.now().isoformat(),
            "assistant_id": session_data.get("assistant_id"),
            "call_id": session_data.get("call_id"),
            "duration": session_data.get("duration"),
            "transcript": session_data.get("transcript"),
            "feedback": session_data.get("feedback"),
            "recording_url": session_data.get("recording_url")
        }
        
        sessions.append(vapi_session)
        sessions_ref.set({"sessions": sessions}, merge=True)
        
        print(f"✅ VAPI interview session saved for user: {user_id}")
        return True
        
    except Exception as e:
        print(f"❌ Error saving session: {str(e)}")
        return False


def delete_assistant(assistant_id: str) -> bool:
    """
    Delete a VAPI assistant after use.
    
    Args:
        assistant_id: VAPI assistant ID to delete
    
    Returns:
        bool indicating success
    """
    
    try:
        response = requests.delete(
            f"{VAPI_API_BASE}/assistant/{assistant_id}",
            headers=get_vapi_headers()
        )
        
        if response.status_code in [200, 204]:
            print(f"✅ VAPI Assistant deleted: {assistant_id}")
            return True
        else:
            print(f"⚠️ Could not delete assistant: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error deleting assistant: {str(e)}")
        return False
