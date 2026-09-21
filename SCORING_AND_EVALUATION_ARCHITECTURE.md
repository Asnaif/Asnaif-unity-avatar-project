# InterPrep Evaluation and Scoring Architecture
**A Comprehensive Guide to Our Custom Calculation Algorithms**

This document outlines the detailed architecture and logical flows developed by our team to evaluate interview performance, calculate percentage accuracies, extract voice metrics, and dynamically generate comprehensive PDF reports. Our system relies on a sophisticated, multi-layered processing engine built into our Python backend.

---

## 1. Core Question & Answer Accuracy Calculation Engine

To generate the specific percentages attached to individual Question and Answer pairs, we developed a Custom Semantic Evaluation Engine. We moved beyond simple keyword matching and built a contextual analysis pipeline.

### Step 1.1: Transcript Parsing and Strict Mapping
During an interview session, audio is continuously transcribed. When the session ends, our backend script (`interview_brain.py`) executes a parsing algorithm.
* **Speaker Separation:** The algorithm strictly separates interviewer prompts from candidate responses.
* **Data Pairing:** It maps every `Interviewer Question` string to the exact subsequent `Candidate Answer` string.
* **Error Handling:** If the candidate pauses or speaks in multiple chunks, our logic concatenates these segments to ensure the full answer is evaluated without data loss.

### Step 1.2: Contextual Cross-Referencing
Before assigning a score, the system injects the candidate’s personal context.
* We parse the candidate’s uploaded Resume (PDF/PPTX) and extract technical skills, job roles, and years of experience.
* The evaluation algorithm uses this context as a "ground truth" to measure the candidate's answers against their claimed expertise.

### Step 1.3: The Four-Pillar Scoring Rubric
Our Natural Language Processing (NLP) scoring module evaluates the Q&A pairs based on four strict parameters:
1. **Relevance (30% weight):** Does the text of the answer directly address the core intent of the question?
2. **Completeness (30% weight):** Are all expected technical aspects of the question satisfied?
3. **Specificity (20% weight):** Does the algorithm detect concrete examples and technical terminology, or are the statements vague and generalized?
4. **Context Matching (20% weight):** Does the answer successfully align with the specific skills extracted from the resume?

### Step 1.4: Output Generation
Based on this rubric, our algorithm calculates an exact `accuracy_score` (from `0 to 100`) for that specific question. Simultaneously, our semantic engine generates a brief, context-aware feedback string explaining exactly *why* marks were deducted (e.g., "Good technical explanation, but lacked a real-world example").

---

## 2. Overall Interview Score Calculation

The "Final Score" (e.g., 75% or 8/10) shown on the user dashboard and the PDF is not an arbitrary number. It is a strictly calculated mathematical weighted average executed by our `server.py` engine.

### The Algorithm Formula
```python
final_interview_score = round((communication_score * 0.5) + (relevance_score * 0.5), 2)
```

### Breakdown of the Components
* **Relevance Score (50% Weight):** 
  This is the aggregated average of all the individual Q&A accuracy scores calculated in Phase 1. It mathematically represents how technically accurate and relevant the candidate's answers were overall.
* **Communication Score (50% Weight):** 
  Our text processing modules evaluate the candidate's speaking ability. It analyzes sentence structure, grammatical correctness, and articulation clarity. 

By applying a 50/50 weighted average, our system ensures the final score is a highly balanced reflection of **what** the candidate said (Technical Relevance) and **how** they said it (Communication Skills).

---

## 3. Calculation of Advanced Voice & Sentiment Metrics

For the advanced statistics (Radar charts, performance bars) shown in our PDF, we engineered dedicated audio and sentiment extraction modules.

### 3.1 Sentiment & Confidence Score
We implemented an NLP sentiment analyzer that processes the transcribed text to map the emotional tone.
* **Lexical Analysis:** The algorithm scans for confident, assertive vocabulary versus hesitant, filler words (e.g., "umm", "like", "maybe").
* **Output:** It categorizes the overall tone into specific classes (Positive, Neutral, Nervous) and outputs a precise confidence percentage based on the ratio of confident to hesitant language.

### 3.2 Pitch (Hz) and Speech Rate (WPM)
This is handled mathematically by our dedicated audio processing modules (`Audio_modules`).
* **Vocal Pitch (Hz):** Our system reads the raw `.wav` audio files directly. It calculates the fundamental frequency of the audio waveform to determine if the user's voice was steady or fluctuating, indicating nervousness.
* **Speech Rate (WPM):** Our algorithm simply counts the total number of words successfully transcribed and divides it by the exact duration of the audio in minutes. This calculates highly accurate Words Per Minute (WPM) to check if the candidate is speaking too fast or too slow.

### 3.3 Categorized Sub-Scores
We structured our evaluation engine to break down the overall performance into granular sub-categories based on industry-standard HR rubrics. Our system outputs distinct scores out of 100 for:
* `technical_accuracy`
* `communication_clarity`
* `problem_solving`
* `cultural_fit`

---

## 4. Dynamic PDF Report Generation Architecture

To present all this complex data to the user, we built a dynamic reporting architecture using the `ReportLab` library within our Python backend (`report_generator.py`).

### Step 4.1: Data Bundling
Once our algorithms calculate all the mathematical averages, voice metrics, and contextual feedbacks, the data is bundled into a structured JSON payload.

### Step 4.2: Visual Rendering (Page 1)
Our custom PDF generator dynamically draws a professional, 2-page report. On Page 1, it executes rendering functions to draw:
* Circular charts mapping the Overall Score.
* Radar charts plotting the categorized sub-scores (Technical vs. Cultural fit).
* Timeline graphs mapping performance trends based on historical session data fetched from the database.

### Step 4.3: Q&A Mapping (Page 2)
On Page 2, our PDF engine loops through the JSON payload to systematically print every individual Q&A pair. It dynamically inserts the calculated accuracy percentage and the custom-generated feedback string right next to the corresponding question, providing the user with a highly detailed, personalized performance review.
