"""
Interview Brain - Google Gemini-powered interview intelligence
Handles resume parsing, strategy generation, and scoring.
Uses Google Gemini AI for all LLM operations.
"""

import sys
import io
# Fix Windows terminal encoding (cp1252 can't handle emoji characters)
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
if sys.stderr.encoding and sys.stderr.encoding.lower() != 'utf-8':
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import json
import re
import time
from typing import Dict, List, Optional
from dataclasses import dataclass
from key import GeminiApiKey

# Gemini model fallback chain — if primary model quota is exhausted, try alternatives
_GEMINI_MODELS = [
    'gemini-2.0-flash',        # Primary — fast and capable
    'gemini-2.0-flash-lite',   # Lighter quotas
    'gemini-2.5-flash',        # Newest flash model
    'gemini-flash-latest',     # Generic latest alias
]
gemini_model = None
_genai_module = None
_active_model_name = None

try:
    import google.generativeai as genai
    _genai_module = genai
    genai.configure(api_key=GeminiApiKey)
    # Try each model until one works
    for model_name in _GEMINI_MODELS:
        try:
            gemini_model = genai.GenerativeModel(model_name)
            _active_model_name = model_name
            # Quick test to see if this model is accessible
            print(f"   Trying model: {model_name}...")
            break
        except Exception:
            continue
    if gemini_model:
        print(f"Google Gemini AI initialized with: {_active_model_name}")
    else:
        print("Gemini: no working model found")
except ImportError:
    print("google-generativeai not installed. Run: pip install google-generativeai")
    gemini_model = None
except Exception as e:
    print(f"Gemini initialization error: {e}")
    gemini_model = None


@dataclass
class ResumeContext:
    """Extracted resume context for interview"""
    name: str
    role: str
    experience_years: int
    skills: List[str]
    technical_skills: List[str]
    soft_skills: List[str]
    projects: List[Dict]
    education: List[Dict]
    achievements: List[str]
    summary: str


@dataclass
class InterviewStrategy:
    """Generated interview strategy"""
    focus_areas: List[str]
    question_types: Dict[str, int]  # type -> count
    difficulty_progression: str
    time_allocation: Dict[str, int]  # section -> minutes
    key_probing_points: List[str]
    system_prompt: str


def _call_gemini(prompt: str, system_instruction: str = "", temperature: float = 0.5) -> str:
    """
    Helper function to call Gemini API with retry and model fallback.
    Retries up to 3 times with exponential backoff.
    Falls back to alternative models if quota is exhausted.
    """
    global gemini_model, _active_model_name
    
    if gemini_model is None:
        raise Exception("Gemini model not initialized")
    
    # Build the full prompt with system instruction
    full_prompt = ""
    if system_instruction:
        full_prompt = f"[System Instruction]: {system_instruction}\n\n"
    full_prompt += prompt
    
    generation_config = _genai_module.GenerationConfig(
        temperature=temperature,
        max_output_tokens=4096,
    )
    
    last_error = None
    models_to_try = _GEMINI_MODELS.copy()
    # Put the active model first
    if _active_model_name in models_to_try:
        models_to_try.remove(_active_model_name)
        models_to_try.insert(0, _active_model_name)
    
    for model_name in models_to_try:
        current_model = _genai_module.GenerativeModel(model_name)
        
        for attempt in range(3):
            try:
                response = current_model.generate_content(
                    full_prompt,
                    generation_config=generation_config
                )
                # Success — update active model
                if model_name != _active_model_name:
                    gemini_model = current_model
                    _active_model_name = model_name
                    print(f"   Switched to model: {model_name}")
                return response.text
                
            except Exception as e:
                last_error = e
                error_str = str(e).lower()
                
                if 'quota' in error_str or 'rate' in error_str or '429' in error_str:
                    # Quota/rate limit — try next model immediately
                    print(f"   {model_name} quota exceeded, trying next model...")
                    break  # break retry loop, try next model
                elif 'retry' in error_str:
                    # Transient error — wait and retry
                    wait = (attempt + 1) * 2
                    print(f"   Gemini retry {attempt+1}/3 (waiting {wait}s)...")
                    time.sleep(wait)
                else:
                    # Unknown error — retry once then give up
                    if attempt == 0:
                        time.sleep(1)
                    else:
                        break
    
    raise Exception(f"All Gemini models failed. Last error: {last_error}")


def parse_resume_for_interview(resume_text: str) -> ResumeContext:
    """
    Parse resume text and extract structured context for interview.
    Uses Google Gemini for intelligent extraction.
    """
    
    extraction_prompt = f"""Analyze this resume and extract structured information for an interview.

RESUME:
{resume_text[:4000]}

Return a JSON object with these fields:
{{
    "name": "candidate name",
    "role": "current/target role",
    "experience_years": number,
    "skills": ["all skills"],
    "technical_skills": ["programming", "frameworks", "tools"],
    "soft_skills": ["communication", "leadership", etc],
    "projects": [
        {{"name": "project", "description": "brief", "technologies": ["tech"]}}
    ],
    "education": [
        {{"degree": "degree", "institution": "school", "year": "year"}}
    ],
    "achievements": ["key achievements"],
    "summary": "2-3 sentence professional summary"
}}

Extract accurately from the resume. If information is missing, infer reasonably or leave empty.
IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks."""

    try:
        result_text = _call_gemini(
            prompt=extraction_prompt,
            system_instruction="You are a resume parser. Return only valid JSON. No markdown, no code blocks.",
            temperature=0.3
        )
        
        # Clean response - remove markdown code blocks if present
        result_text = result_text.strip()
        if result_text.startswith("```"):
            result_text = re.sub(r'^```(?:json)?\s*', '', result_text)
            result_text = re.sub(r'\s*```$', '', result_text)
        
        # Extract JSON from response
        json_match = re.search(r'\{[\s\S]*\}', result_text)
        if json_match:
            data = json.loads(json_match.group())
            
            return ResumeContext(
                name=data.get("name", "Candidate"),
                role=data.get("role", "Software Engineer"),
                experience_years=data.get("experience_years", 0),
                skills=data.get("skills", []),
                technical_skills=data.get("technical_skills", []),
                soft_skills=data.get("soft_skills", []),
                projects=data.get("projects", []),
                education=data.get("education", []),
                achievements=data.get("achievements", []),
                summary=data.get("summary", "")
            )
    except Exception as e:
        print(f"❌ Resume parsing error: {e}")
    
    # Fallback: basic extraction
    return ResumeContext(
        name="Candidate",
        role="Professional",
        experience_years=2,
        skills=extract_skills_basic(resume_text),
        technical_skills=[],
        soft_skills=[],
        projects=[],
        education=[],
        achievements=[],
        summary=resume_text[:200]
    )


def extract_skills_basic(text: str) -> List[str]:
    """Basic skill extraction without LLM"""
    common_skills = [
        "python", "javascript", "java", "c++", "react", "angular", "vue",
        "node", "django", "flask", "flutter", "dart", "sql", "mongodb",
        "aws", "docker", "kubernetes", "git", "html", "css", "typescript"
    ]
    text_lower = text.lower()
    return [skill for skill in common_skills if skill in text_lower]


def generate_interview_strategy(
    context: ResumeContext,
    jd: str = "",
    position: str = "",
    duration_minutes: int = 20
) -> InterviewStrategy:
    """
    Generate interview strategy based on resume context.
    """
    
    # Calculate time allocation — introduction phase gets more time now
    intro_time = 4  # 2-3 introduction questions need ~4 minutes
    technical_time = int(duration_minutes * 0.45)
    behavioral_time = int(duration_minutes * 0.25)
    closing_time = duration_minutes - intro_time - technical_time - behavioral_time
    
    # Determine focus areas based on role and skills
    focus_areas = []
    if context.technical_skills:
        if isinstance(context.technical_skills, list):
            focus_areas.extend(context.technical_skills[:5])
        elif isinstance(context.technical_skills, dict):
            focus_areas.extend(list(context.technical_skills.keys())[:5])
            
    if context.projects:
        focus_areas.append("Project Experience")
        
    try:
        exp_years = float(context.experience_years) if context.experience_years else 0
        if exp_years > 3:
            focus_areas.append("Leadership & Mentoring")
    except (ValueError, TypeError):
        pass
        
    focus_areas.append("Problem Solving")
    
    # Key probing points from projects
    probing_points = []
    if context.projects:
        if isinstance(context.projects, list):
            for project in context.projects[:3]:
                if isinstance(project, dict):
                    probing_points.append(f"Deep dive into {project.get('name', 'project')}")
                elif isinstance(project, str):
                    probing_points.append(f"Deep dive into {project}")
        elif isinstance(context.projects, dict):
            probing_points.append(f"Deep dive into {context.projects.get('name', 'project')}")
    
    # Build system prompt
    system_prompt = build_system_prompt(context, jd, position, duration_minutes)
    
    return InterviewStrategy(
        focus_areas=focus_areas,
        question_types={
            "technical": 5,
            "behavioral": 3,
            "situational": 2,
            "project_deep_dive": 2
        },
        difficulty_progression="medium → hard → adaptive",
        time_allocation={
            "introduction": intro_time,
            "technical": technical_time,
            "behavioral": behavioral_time,
            "closing": closing_time
        },
        key_probing_points=probing_points,
        system_prompt=system_prompt
    )


def build_system_prompt(
    context: ResumeContext,
    jd: str = "",
    position: str = "",
    duration_minutes: int = 20
) -> str:
    """
    Build intelligent system prompt for VAPI AI interviewer.
    """
    
    # Format skills
    skills_str = ", ".join(context.technical_skills[:10]) if context.technical_skills else ", ".join(context.skills[:10])
    
    # Format projects
    projects_str = ""
    for i, proj in enumerate(context.projects[:3], 1):
        projects_str += f"\n   {i}. {proj.get('name', 'Project')}: {proj.get('description', '')[:100]}"
    
    # Position context
    role_context = position if position else context.role
    
    # JD context
    jd_section = ""
    if jd:
        jd_section = f"""
## JOB REQUIREMENTS
{jd[:500]}
"""

    system_prompt = f"""You are a professional human interviewer conducting a voice-based job interview.
Your voice is warm but professional. You speak clearly and naturally.

## ⚠️ HIGHEST PRIORITY RULE — READ THIS FIRST ⚠️
Your opening greeting (firstMessage) asked the candidate to introduce themselves.
That means you are CURRENTLY IN PHASE 1 (Introduction & Ice-Breaker).
You have asked 1 introduction question so far (the self-introduction).
You MUST ask AT LEAST 1 MORE introduction question (e.g. career motivation, future goals)
BEFORE you are allowed to mention ANYTHING from the candidate's resume, CV, projects, or skills.
Asking a CV-based question before completing Phase 1 is a VIOLATION of your instructions.

## CANDIDATE PROFILE (DO NOT reference this until Phase 2)
- Name: {context.name}
- Target Role: {role_context}
- Experience: {context.experience_years} years
- Key Skills: {skills_str}
- Projects: {projects_str if projects_str else "To be explored during interview"}

{jd_section}

## INTERVIEW STRATEGY
- Duration: {duration_minutes} minutes
- Focus Areas: {', '.join(context.technical_skills[:5]) if context.technical_skills else 'General software development'}
- Difficulty: Start with medium difficulty, adapt based on responses

## CRITICAL RULES
1. Speak clearly and professionally with natural pace
2. Ask ONLY ONE question at a time
3. WAIT for complete answer before responding (detect silence)
4. For weak/incomplete answers: Ask follow-up to probe deeper
5. For excellent answers: Brief acknowledgment, then move forward
6. Mix technical (60%) and behavioral (40%) questions
7. DO NOT explain correct answers during interview
8. DO NOT give feedback or scores during interview
9. Use natural transitions: "That's interesting...", "Building on that...", "Let's shift to..."
10. If candidate seems stuck, offer a simpler rephrasing
11. IMPORTANT: You MUST follow the interview flow below STRICTLY in the EXACT order listed. Do NOT skip any phase. Do NOT rearrange the phases.

## INTERVIEW FLOW (Follow this order strictly — DO NOT skip any phase)

### Phase 1 — Introduction & Ice-Breaker (First 2-3 questions, approximately 0-4 minutes):
Start the interview with warm, personal introduction questions to make the candidate comfortable.
These questions should NOT reference the candidate's CV/resume at all. Ask these questions ONE BY ONE:

1. FIRST QUESTION (MANDATORY — already asked in your greeting): The candidate was asked to introduce themselves.
   → You have already asked this. Now LISTEN to their answer, acknowledge it warmly, then ask question 2.
2. SECOND QUESTION (MANDATORY — ask this NEXT): Ask about their motivation for this role or career goals.
   Examples:
   - "What motivated you to pursue a career in {role_context}?"
   - "Where do you see yourself in the next few years in your career?"
   - "What motivated you to apply for this kind of role?"
3. THIRD QUESTION (OPTIONAL — ask if time permits): Ask about what excites them about this field.
   Example: "What excites you the most about working in this field?"

⚠️ CRITICAL: You MUST ask at least questions 1 AND 2 before moving to Phase 2.
Do NOT jump to CV-based questions before completing Phase 1.
Listen to their answers carefully and respond naturally (e.g. "That's great to hear!", "Interesting perspective!") before asking the next introduction question.

### Phase 2 — Resume/CV-Based Questions (Next 3-4 questions, approximately 4-{duration_minutes-8} minutes):
NOW — and ONLY NOW — you may read the candidate's resume/profile and ask specific questions about their CV:
- A specific project they worked on: "I noticed on your resume that you worked on [project name]. Can you tell me more about your role and the challenges you faced?"
- A specific technical skill from their resume: "Your resume mentions [skill]. How have you applied it in a production environment?"
- Their most recent work experience: "You were at [company] as a [role]. What was your biggest accomplishment there?"
- Their education or certifications: "I see you studied [degree] at [institution]. How has that shaped your technical approach?"

Use a natural transition when moving from introduction to CV questions, such as:
"Thank you for sharing that! Now, I've gone through your resume and I have some specific questions about your experience..."

### Phase 3 — Conversational Follow-ups (Next 2-3 questions):
Based on their answers to Phase 2, ask deeper follow-up questions. These should still relate to their resume context but probe deeper.

### Phase 4 — General Technical & Behavioral (Remaining time before closing):
- "How would you design a system for [relevant to their background]?"
- "Tell me about a time you had a deadline you couldn't meet. What happened?"
- "Describe a situation where you disagreed with a team member"
- "How do you handle feedback on your code?"

### Phase 5 — Closing (Last 2-3 minutes):
Ask if they have questions, close professionally.

## CLOSING SCRIPT
"Thank you for your time today. You've shared some great insights about your experience. 
Do you have any questions for me about the role or team? [Answer briefly if asked]
It was a pleasure speaking with you. We'll be in touch soon regarding next steps."

## FINAL REMINDER
You are a human interviewer, not an AI. Never break character.
And remember: After your greeting, the VERY NEXT thing you do is listen to their self-introduction,
acknowledge it, and then ask a motivation/career-goals question. Do NOT touch the CV yet."""

    return system_prompt


def score_interview_transcript(
    transcript: str,
    context: ResumeContext,
    duration_seconds: int = 0
) -> Dict:
    """
    Score interview transcript using Google Gemini analysis.
    """
    
    # Extract Q&A manually to force LLM to process all of them
    lines = transcript.strip().split('\n')
    extracted_qa = []
    current_q = None
    current_a = []
    
    for line in lines:
        line_lower = line.strip().lower()
        if line_lower.startswith(('assistant:', 'ai:', 'interviewer:')):
            if current_q and current_a:
                extracted_qa.append({"question": current_q, "answer": " ".join(current_a)})
            current_q = line.split(':', 1)[-1].strip() if ':' in line else line.strip()
            current_a = []
        elif line_lower.startswith(('user:', 'candidate:', 'you:')):
            a_text = line.split(':', 1)[-1].strip() if ':' in line else line.strip()
            if current_q is not None:
                current_a.append(a_text)
        elif current_q is not None and current_a:
            current_a.append(line.strip())
            
    if current_q and current_a:
        extracted_qa.append({"question": current_q, "answer": " ".join(current_a)})
        
    qa_context = ""
    if extracted_qa:
        import json
        qa_json = json.dumps(extracted_qa, indent=2)
        qa_context = f"\n\nSPECIFIC Q&A PAIRS TO ANALYZE:\n{qa_json}\n\nIMPORTANT: You MUST return a 'qa_analysis' array containing EXACTLY {len(extracted_qa)} items corresponding to the pairs above."

    scoring_prompt = f"""Analyze this interview transcript and provide detailed scoring.

CANDIDATE CONTEXT:
- Role: {context.role}
- Experience: {context.experience_years} years
- Skills: {', '.join(context.skills[:10])}

INTERVIEW TRANSCRIPT:
{transcript[:8000]}
{qa_context}

IMPORTANT INSTRUCTIONS:
1. Extract EVERY question the interviewer asked and the candidate's corresponding answer (use the SPECIFIC Q&A PAIRS if provided).
2. Score each answer's accuracy/quality from 10 to 100. NEVER give a 0 score. If an answer is fragmented, cut off, or incomplete due to transcription errors, give a baseline score of 15-25% for the attempt. Focus on the keywords present.
3. Provide brief feedback for each answer explaining why that score was given.
4. Compute an overall score that reflects the candidate's total performance.
5. Provide a voice_analysis section evaluating the candidate's confidence, tone, and sentiment based on how they speak.

Provide scores and detailed analysis in JSON format:
{{
    "overall_score": 75,
    "scores": {{
        "technical_accuracy": 80,
        "communication_clarity": 70,
        "confidence": 75,
        "problem_solving": 80,
        "cultural_fit": 85
    }},
    "voice_analysis": {{
        "pitch_tone_feedback": "Feedback on the candidate's inferred tone, pitch, and vocal confidence based on how they spoke",
        "sentiment": "Positive/Neutral/Nervous",
        "sentiment_score": 75
    }},
    "qa_analysis": [
        {{
            "question": "The exact question the interviewer asked",
            "answer": "The candidate's answer",
            "accuracy_score": 85,
            "feedback": "Brief explanation of why this score was given"
        }}
    ],
    "strengths": ["list of 3-5 strengths shown"],
    "areas_for_improvement": ["list of 3-5 areas to improve"],
    "key_moments": [
        {{"type": "strength/weakness", "moment": "description", "feedback": "specific advice"}}
    ],
    "detailed_feedback": "2-3 paragraphs of constructive feedback",
    "recommendation": "hire/consider/improve recommendation with explanation"
}}

Be constructive, specific, and actionable in feedback.
Make sure to include ALL questions and answers in qa_analysis — do not skip any.
IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks."""

    try:
        result_text = _call_gemini(
            prompt=scoring_prompt,
            system_instruction="You are an expert interview coach. Provide detailed, constructive feedback in JSON format only. No markdown, no code blocks.",
            temperature=0.5
        )
        
        # Clean response
        result_text = result_text.strip()
        if result_text.startswith("```"):
            result_text = re.sub(r'^```(?:json)?\s*', '', result_text)
            result_text = re.sub(r'\s*```$', '', result_text)
        
        # Extract JSON
        json_match = re.search(r'\{[\s\S]*\}', result_text)
        if json_match:
            scores = json.loads(json_match.group())
            scores["duration_seconds"] = duration_seconds
            return scores
            
    except Exception as e:
        print(f"Scoring error: {e}")
        import traceback
        traceback.print_exc()
    
    # Fallback: try basic analysis without LLM if transcript exists
    if transcript and len(transcript.strip()) > 50:
        return _basic_scoring(transcript, context, duration_seconds)
    
    # Minimal fallback for empty/very short transcripts
    return {
        "overall_score": 0,
        "scores": {
            "technical_accuracy": 0,
            "communication_clarity": 0,
            "confidence": 0,
            "problem_solving": 0,
            "cultural_fit": 0
        },
        "voice_analysis": {
            "pitch_tone_feedback": "Could not analyze voice tone.",
            "sentiment": "Neutral",
            "sentiment_score": 0
        },
        "qa_analysis": [],
        "strengths": [],
        "areas_for_improvement": ["Interview was too short for meaningful analysis"],
        "detailed_feedback": "The interview session was too brief to provide detailed feedback. This may be due to a connection issue. Please try again with a longer session.",
        "recommendation": "Retry — session was insufficient for evaluation",
        "duration_seconds": duration_seconds
    }

def _basic_scoring(transcript: str, context: ResumeContext, duration_seconds: int) -> Dict:
    """
    Basic keyword-based scoring when LLM is unavailable.
    Analyzes transcript using word count, technical keywords, and response patterns.
    """
    lines = transcript.strip().split('\n')
    user_lines = [l for l in lines if l.lower().startswith(('user:', 'candidate:', 'you:'))]
    ai_lines = [l for l in lines if l.lower().startswith(('assistant:', 'ai:', 'interviewer:'))]
    
    total_words = len(transcript.split())
    user_words = sum(len(l.split()) for l in user_lines) if user_lines else 0
    
    # Technical keyword detection
    tech_keywords = set(s.lower() for s in context.skills + context.technical_skills)
    transcript_lower = transcript.lower()
    tech_mentions = sum(1 for kw in tech_keywords if kw in transcript_lower)
    
    # Calculate scores based on heuristics
    # Communication: based on how much the candidate spoke vs the interviewer
    response_ratio = user_words / max(total_words, 1)
    comm_score = min(100, max(20, int(response_ratio * 200)))  # 50% ratio = 100
    
    # Technical: based on technical keyword mentions
    tech_score = min(100, max(20, int(30 + tech_mentions * 10)))
    
    # Confidence: based on average response length (longer = more confident)
    avg_response_len = user_words / max(len(user_lines), 1) if user_lines else 0
    conf_score = min(100, max(20, int(30 + avg_response_len * 2)))
    
    # Problem solving: similar to technical
    ps_score = min(100, max(20, int((tech_score + conf_score) / 2)))
    
    # Cultural fit: based on engagement (did they speak enough?)
    cf_score = min(100, max(20, int(30 + len(user_lines) * 5)))
    
    overall = int((comm_score + tech_score + conf_score + ps_score + cf_score) / 5)
    
    # Generate basic strengths/weaknesses
    strengths = []
    improvements = []
    
    if response_ratio > 0.3:
        strengths.append("Good engagement - spoke substantively during the interview")
    else:
        improvements.append("Try to provide more detailed responses to questions")
    
    if tech_mentions > 3:
        strengths.append(f"Referenced relevant technical skills ({tech_mentions} technical terms used)")
    else:
        improvements.append("Include more specific technical details in your answers")
    
    if avg_response_len > 20:
        strengths.append("Provided thorough, detailed answers")
    else:
        improvements.append("Elaborate more on your responses - aim for 2-3 sentences minimum")
    
    if duration_seconds > 120:
        strengths.append("Maintained conversation for a reasonable duration")
    else:
        improvements.append("Practice sustaining longer interview conversations")
    
    if len(user_lines) > 3:
        strengths.append("Actively participated in the dialogue")
    
    if not strengths:
        strengths = ["Completed the interview session"]
    if not improvements:
        improvements = ["Continue practicing interview skills"]
    
    # Build basic Q&A analysis from transcript lines
    qa_analysis = []
    current_question = None
    for i, line in enumerate(lines):
        line_lower = line.strip().lower()
        if line_lower.startswith(('assistant:', 'ai:', 'interviewer:')):
            # Extract question text
            q_text = line.split(':', 1)[-1].strip() if ':' in line else line.strip()
            if q_text and '?' in q_text:
                current_question = q_text
        elif line_lower.startswith(('user:', 'candidate:', 'you:')) and current_question:
            a_text = line.split(':', 1)[-1].strip() if ':' in line else line.strip()
            # Simple heuristic score based on answer length and keyword overlap
            answer_words = len(a_text.split())
            kw_hits = sum(1 for kw in tech_keywords if kw in a_text.lower())
            q_score = min(100, max(10, 30 + answer_words * 2 + kw_hits * 10))
            qa_analysis.append({
                "question": current_question,
                "answer": a_text if len(a_text) <= 300 else a_text[:300] + "...",
                "accuracy_score": q_score,
                "feedback": f"Answer length: {answer_words} words. {'Good detail provided.' if answer_words > 15 else 'Consider elaborating more.'}"
            })
            current_question = None

    return {
        "overall_score": overall,
        "scores": {
            "technical_accuracy": tech_score,
            "communication_clarity": comm_score,
            "confidence": conf_score,
            "problem_solving": ps_score,
            "cultural_fit": cf_score
        },
        "voice_analysis": {
            "pitch_tone_feedback": "Voice pitch and tone appear stable based on response length.",
            "sentiment": "Positive" if overall > 60 else "Nervous",
            "sentiment_score": overall
        },
        "qa_analysis": qa_analysis,
        "strengths": strengths[:5],
        "areas_for_improvement": improvements[:5],
        "detailed_feedback": (
            f"Based on transcript analysis: You spoke {user_words} words across {len(user_lines)} responses. "
            f"{'Your responses were detailed and engaged.' if avg_response_len > 20 else 'Consider providing more detailed answers.'} "
            f"{'You referenced relevant technical skills effectively.' if tech_mentions > 3 else 'Try to incorporate more domain-specific terminology.'} "
            f"Note: This is an automated basic analysis. For detailed AI-powered feedback, please ensure the Gemini API quota is available."
        ),
        "recommendation": (
            "Strong candidate" if overall >= 75 else
            "Shows potential, needs improvement in some areas" if overall >= 50 else
            "Needs significant preparation before next interview"
        ),
        "key_moments": [],
        "duration_seconds": duration_seconds,
        "_scoring_method": "basic_keyword_analysis"  # Flag so we know this was fallback
    }


def generate_question_pool(context: ResumeContext, count: int = 10) -> List[Dict]:
    """
    Generate a pool of relevant interview questions using Google Gemini.
    """
    
    prompt = f"""Generate {count} interview questions for this candidate:

Role: {context.role}
Experience: {context.experience_years} years
Skills: {', '.join(context.skills[:10])}
Projects: {json.dumps(context.projects[:3])}

Return JSON array:
[
    {{
        "type": "technical|behavioral|situational|project",
        "difficulty": "easy|medium|hard",
        "question": "the question",
        "follow_up": "potential follow-up question",
        "what_to_look_for": "key points in ideal answer"
    }}
]

Mix question types. Make questions specific to their background.
IMPORTANT: Return ONLY valid JSON array, no markdown formatting, no code blocks."""

    try:
        result_text = _call_gemini(
            prompt=prompt,
            system_instruction="You are an interview question generator. Return only valid JSON array. No markdown, no code blocks.",
            temperature=0.7
        )
        
        # Clean response
        result_text = result_text.strip()
        if result_text.startswith("```"):
            result_text = re.sub(r'^```(?:json)?\s*', '', result_text)
            result_text = re.sub(r'\s*```$', '', result_text)
        
        json_match = re.search(r'\[[\s\S]*\]', result_text)
        if json_match:
            return json.loads(json_match.group())
            
    except Exception as e:
        print(f"❌ Question generation error: {e}")
    
    # Fallback questions
    return [
        {"type": "behavioral", "question": "Tell me about yourself and your experience.", "difficulty": "easy"},
        {"type": "technical", "question": "What technologies are you most experienced with?", "difficulty": "medium"},
        {"type": "situational", "question": "How do you handle tight deadlines?", "difficulty": "medium"}
    ]
