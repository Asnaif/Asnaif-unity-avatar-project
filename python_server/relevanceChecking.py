# from langchain_openai import OpenAI
# from langchain_core.prompts import PromptTemplate
# from key import OpenApikey

# def relevanceChecking(extractedText, spokenText):

#     templateRelevance = """I am making an app in which user will upload presentation slides and then record his speech. Now we need to measure relevance between the contexts of slides content and his speech content, basically to determine is he doing presentation in accordance with context of the content. I have extracted text from powerpoint slides given by user and providing it as content below. I have converted speech to text and providing it as well. Now you need to show relevance or irrelevance between the two texts in form of a paragraph highlighting ups and downs if there are any. (ignore any irrelevant data including profile data as I have extracted data from the pptx file and speech so there can be some data which doesnt make any sense. So just focus on the data.)".

#     Content: {slide}

#     Spoken Speech Text: {spoken}

#     Answer: """


#     # create a prompt template for QA
#     promptTemplateRelevance = PromptTemplate(
#         input_variables=["slide", "spoken"],
#         template=templateRelevance
#     )

#     slideContent = extractedText
#     spokenContent = spokenText

#     formattedTemplateRelevance = promptTemplateRelevance.format(
#             slide = slideContent, spoken = spokenContent
#         )


#     # initialize the models
#     openai = OpenAI(
#         model_name="gpt-3.5-turbo-instruct",
#         openai_api_key=OpenApikey,
#         temperature=1
#     )

#     # New/Correct Call:
#     return openai.invoke(formattedTemplateRelevance)



from openai import OpenAI
from key import OpenApikey

"""
================================================================================
RELEVANCE CHECKING MODULE - FLOW EXPLANATION
================================================================================

PURPOSE:
--------
Yeh module do texts ke beech relevance check karta hai:
1. INTERVIEW MODE: Question aur Answer ke beech relevance
2. PRESENTATION MODE: Question + Answer ka slide content se alignment

IMPORTANT - PRESENTATION MODE LOGIC:
------------------------------------
Presentation mode mein:
- Questions slide content se generate hote hain
- User questions ke answers deta hai
- Toh relevance check: Question + Answer ka slide content se alignment verify karta hai
- Yeh better approach hai kyunki:
  * Question already slide se related hai
  * Answer question ka hai
  * Complete picture (Question + Answer) ka slide content se alignment check hota hai

FLOW:
-----
1. Function Call:
   - `relevanceChecking(reference_text, spoken_text, mode, question_text=None)`
   - reference_text: Interview mode = Question, Presentation mode = Slide content
   - spoken_text: Dono modes mein = User ka recorded speech (transcribed)
   - mode: "interview" ya "presentation"
   - question_text: (Optional) Presentation mode mein question text

2. Mode Detection:
   - Agar mode == "interview": Interview-specific prompt use hota hai
   - Agar mode == "presentation": Presentation-specific prompt use hota hai

3. Prompt Generation:
   - Interview Mode:
     * Question ko reference_text se liya jata hai
     * Answer ko spoken_text se liya jata hai
     * Prompt focus karta hai: Relevance, Completeness, Quality, Specificity
     * IMPORTANT: Slides/presentations ka mention nahi hota
   
   - Presentation Mode:
     * Slide content ko reference_text se liya jata hai
     * Question ko question_text se liya jata hai (agar available)
     * Answer ko spoken_text se liya jata hai
     * Prompt focus karta hai: Question + Answer ka slide content se alignment
     * Evaluates: Question-Slide alignment, Answer-Question alignment, Answer-Slide alignment

4. OpenAI API Call:
   - GPT-3.5-turbo model use hota hai
   - System message set hota hai (mode ke according)
   - User prompt bheja jata hai
   - Temperature = 0.7 (balanced creativity)

5. Response:
   - Analysis paragraph format mein return hota hai
   - Interview mode: 2-3 detailed paragraphs
   - Presentation mode: 1 detailed paragraph

EXAMPLE USAGE:
--------------
# Interview Mode:
relevance = relevanceChecking(
    reference_text="What is machine learning?",
    spoken_text="Machine learning is a subset of AI...",
    mode="interview"
)

# Presentation Mode (with question):
relevance = relevanceChecking(
    reference_text="Slide 1: Introduction to AI...",
    spoken_text="Machine learning is a subset of AI...",
    mode="presentation",
    question_text="What is machine learning and how does it relate to AI?"
)

================================================================================
"""

def relevanceChecking(reference_text, spoken_text, mode="presentation", question_text=None):
    """
    Parameters:
    - reference_text: Interview mode = Question, Presentation mode = Slide content
    - spoken_text: User ka recorded speech (transcribed)
    - mode: "interview" or "presentation"
    - question_text: (Optional) Presentation mode mein question text (slide se generate hua)
    
    FLOW:
    1. OpenAI client initialize karta hai
    2. Mode check karta hai (interview ya presentation)
    3. Mode ke according prompt generate karta hai
    4. System message set karta hai
    5. OpenAI API call karta hai
    6. Analysis text return karta hai
    """
    
    # Step 1: OpenAI client initialize
    client = OpenAI(api_key=OpenApikey)
    
    # Step 2: Mode check aur prompt generation
    if mode == "interview":
        # INTERVIEW MODE FLOW:
        # - reference_text = Interview Question
        # - spoken_text = Candidate ka Answer (transcribed)
        # - Focus: Question-Answer alignment, completeness, quality
        prompt = f"""You are an interview evaluation expert. Analyze how well the candidate's answer addresses the interview question.

INTERVIEW QUESTION:
{reference_text}

CANDIDATE'S ANSWER:
{spoken_text}

EVALUATION TASK:
Provide a comprehensive analysis focusing on:
1. **Relevance to Question**: Does the answer directly address what was asked? How well does it relate to the question's intent?
2. **Completeness**: Are all aspects of the question covered? What important points might be missing?
3. **Answer Quality**: Is the answer structured, clear, and professional? Does it demonstrate the candidate's knowledge and experience?
4. **Specificity**: Does the answer include concrete examples, details, or evidence, or is it too vague?
5. **Strengths**: What did the candidate do well in their response?
6. **Areas for Improvement**: What could make this answer stronger or more relevant to the question?

IMPORTANT: 
- Focus ONLY on question-answer alignment, NOT on slides or presentations
- Do NOT mention slides, presentations, or visual content
- Evaluate the answer's relevance to the INTERVIEW QUESTION only
- Provide constructive feedback that helps the candidate improve their interview responses

Provide your analysis as 2-3 detailed paragraphs that are helpful for interview preparation."""
    
    else:  # presentation mode
        # PRESENTATION MODE FLOW:
        # - reference_text = Slide content (extracted from PPTX/PDF)
        # - spoken_text = User ka answer (transcribed) - jo question ka answer hai
        # - question_text = Question jo slide content se generate hua hai
        # - Focus: Question + Answer ka slide content se alignment
        
        if question_text:
            # Agar question available hai, toh Question + Answer ka slide content se relevance check karo
            prompt = f"""I am evaluating a presentation practice session. The user uploaded slides, and questions were generated from the slide content. The user answered one of those questions. Evaluate how well the question and answer together relate to the slide content.

SLIDE CONTENT (Reference):
{reference_text}

QUESTION (Generated from slide content):
{question_text}

USER'S ANSWER (Response to the question):
{spoken_text}

EVALUATION TASK:
Analyze the relevance and alignment:
1. **Question-Slide Alignment**: Does the question accurately reflect the slide content? Is it relevant to what's in the slides?
2. **Answer-Question Alignment**: Does the answer directly address the question asked?
3. **Answer-Slide Alignment**: Does the answer demonstrate understanding of the slide content? How well does it connect to the slide material?
4. **Overall Coherence**: How well do the question, answer, and slide content work together? Are there any gaps or misalignments?
5. **Strengths**: What did the user do well in connecting their answer to both the question and slide content?
6. **Areas for Improvement**: What could make the answer more aligned with the slide content or more relevant to the question?

IMPORTANT:
- Remember: Questions are generated FROM the slide content, so they should be relevant to slides
- The answer should address the question AND demonstrate understanding of slide content
- Evaluate how well the complete picture (Question + Answer) aligns with slide content

Provide your analysis as 2-3 detailed paragraphs that help the user improve their presentation skills."""
        else:
            # Fallback: Agar question nahi hai, toh sirf slide vs answer compare karo
            prompt = f"""I am evaluating a presentation. The user uploaded slides and recorded their speech. Measure the relevance between the slide content and their spoken presentation to determine if they're presenting in accordance with the slides.

Slide Content: {reference_text}

Spoken Presentation: {spoken_text}

Task: Show relevance or gaps between the slide content and spoken words. Highlight strengths and areas for improvement. Ignore any irrelevant metadata.

Provide your analysis as a detailed paragraph."""

    # Step 3: System message set karta hai (mode ke according)
    if mode == "interview":
        system_message = "You are an expert interview evaluator specializing in assessing candidate responses. Focus on question-answer alignment, answer quality, and interview-specific feedback. Do NOT mention slides, presentations, or visual content."
    else:
        system_message = "You are a presentation evaluation assistant specializing in assessing alignment between slide content and spoken presentations."
    
    # Step 4: OpenAI API call
    # - Model: GPT-3.5-turbo (fast aur cost-effective)
    # - Messages: System message + User prompt
    # - Temperature: 0.7 (balanced - thoda creative but focused)
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": system_message},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7
    )
    
    # Step 5: Response extract karke return karta hai
    # Response format: Text analysis (paragraphs)
    return response.choices[0].message.content