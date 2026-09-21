# InterPrep — Naye Features ki Detailed Explanation (Bilingual Guide)

Yeh file hamare project **InterPrep** ke naye aur update kiye gaye features ki detailed explanation dene ke liye banayi gayi hai. Isme theoretical concepts, code structure, mathematical calculations aur flows ko detail mein samjhaya gaya hai.

---

## 1. Project ki Architecture aur Working Flow (Overall Flow)

Hamara project 3 main systems par mushtamil hai:
1. **Flutter Web App (Frontend)**: Jo user interface show karta hai, user ka webcam access karta hai aur audio/video interaction handle karta hai.
2. **Python Server (Backend)**: Jo Gemini AI, MediaPipe, aur VAPI ki integrations sambhalta hai.
3. **Unity 3D Avatar (Animations)**: Jo WebGL ke zariye browser mein render hota hai aur lip-sync aur gestures ke zariye candidate ke sath interact karta hai.

### Full Sequence Flow:
1. **Secure Session Setup**: Jab user interview start karta hai, Flutter client server ko resume text send karta hai (`/api/vapi/secure-session`). Python server resume ko parse karke system prompt aur strategy banata hai, Vapi par temporary assistant register karta hai, aur client ko aik safe **JWT Token** generate karke deta hai taake humari private API keys frontend par expose na hon.
2. **Real-Time Webcam Analysis (NVC)**: Flutter side par `nvc_recorder.js` har **500ms (2 FPS)** par canvas se webcam frame ka JPEG blob capture karke server ke `/api/nvc/frame` endpoint par upload karta hai. Server MediaPipe Holistic model chala kar frame analyze karta hai aur eye contact, posture, emotion, hands detect karke real-time response wapis bhejta hai taake UI par alerts (jise slouching, no eye contact warnings) show ho sakein.
3. **Voice Interview**: Vapi WebRTC ke zariye call chalti hai. Vapi ke hooks server ke `/api/vapi/transcript-webhook` par real-time transcription chunks send karte hain jo cache hote hain.
4. **Session Completion**: Jab interview khatam hota hai (`/api/vapi/complete-session`), server Vapi se final call transcript aur recording URL fetch karta hai. Server pehle user ke bole gaye text par **VADER Sentiment Analysis** chalata hai aur phir Gemini ko poori transcript aur resume de kar score karne ko bolta hai. NVC session ko wrap-up karke report card aur **ReportLab** ke zariye 3-pages ka professional PDF generator chalta hai. Aakhir mein Firestore par session save hota hai aur temporary Vapi assistant delete kar diya jata hai.

---

## 2. Naye aur Modified Files ki Directory (Added & Modified Files)

Humne project mein niche likhi hui files add aur update ki hain:

### Backend (Python Server):
- **[server.py](file:///c:/Flutter/InterPrep/python_server/server.py)**: Central server jisme webhooks, frame ingestion, sentiment calculations, aur complete triggers likhe hain.
- **[vapi_secure_session.py](file:///c:/Flutter/InterPrep/python_server/vapi_secure_session.py)**: JWT tokens and Vapi session lifecycle management.
- **[interview_brain.py](file:///c:/Flutter/InterPrep/python_server/interview_brain.py)**: Gemini configuration, resume parsing, strategy generation, aur text scoring.
- **[NVC_modules/nvc_service.py](file:///c:/Flutter/InterPrep/python_server/NVC_modules/nvc_service.py)**: MediaPipe session orchestrator.
- **[NVC_modules/analyzers.py](file:///c:/Flutter/InterPrep/python_server/NVC_modules/analyzers.py)**: Har NVC signal (Gaze, Smile, Posture, Yaw/Pitch, Gestures) ki individual math-based check.
- **[NVC_modules/session_recorder.py](file:///c:/Flutter/InterPrep/python_server/NVC_modules/session_recorder.py)**: Frame stats aggregation aur compound stats (Confidence & Engagement).
- **[NVC_modules/report_generator.py](file:///c:/Flutter/InterPrep/python_server/NVC_modules/report_generator.py)**: PDF structure, tables, styles aur matplotlib charts.
- **[Audio_modules/sentiment.py](file:///c:/Flutter/InterPrep/python_server/Audio_modules/sentiment.py)**: VADER sentiment analysis execution.

### Frontend & Unity:
- **[nvc_recorder.js](file:///c:/Flutter/InterPrep/web/nvc_recorder.js)**: Javascript webcam frame uploader (runs under Flutter Web).
- **[vapi_service.dart](file:///c:/Flutter/InterPrep/lib/services/vapi_service.dart)**: Dart HTTP client calling secure endpoints.
- **[InterviewHandGestures.cs](file:///c:/Flutter/InterPrep/unity_scripts/InterviewHandGestures.cs)**: Avatar ke hand gestures aur 3D noise swaye animations.
- **[AvatarHeadAndEyes.cs](file:///c:/Flutter/InterPrep/unity_scripts/AvatarHeadAndEyes.cs)**: Avatar ki blinking, eye asymmetry aur agreeing nods.

---

## 3. Webcam Live Detection System (NVC Detection)

Real-time body language ko detect karne ke liye MediaPipe landmark coordinates par geometric formulas lagaye jate hain:

### A. Eye Contact (Aankhon ka rabt)
Hamara `EyeContactAnalyzer` face landmarks se left iris (473) aur right iris (468) ke coordinate checks karta hai:
- Eye corners ke darmiyan center point ($C_x, C_y$) nikala jata hai.
- Iris ka offset ($dx, dy$) eye corner width aur height ke relative calculate kiya jata hai:
  $$dx = \frac{\text{Iris}_x - C_x}{\text{EyeWidth}}, \quad dy = \frac{\text{Iris}_y - C_y}{\text{EyeHeight}}$$
- Agar horizontal aur vertical deviation pre-set limit se choti ho, to $Score$ close to $1.0$ ata hai. Agar $Score \ge 0.8$, to trigger hota hai ke user screen/camera ki taraf dekh raha hai (`is_looking = True`).

### B. Emotion (Jazbaat ki pehchan)
`EmotionApproximator` lips aur eyebrows ke distances ko monitor karta hai:
- **MAR (Mouth Aspect Ratio)** aur lips openness measure hoti hai.
- **Smile Ratio**: Mouth width ko lip vertical distance se compare karke smile check hoti hai.
- **Eyebrow Height**: Eyebrows aur eyes ke distance se furrowing (tension) check hoti hai.
- In values se dynamic linear models apply karke **Confident**, **Engaged**, **Nervous**, **Stressed**, aur **Neutral** ki probability nikali jati hai.

### C. Gesture Classifier (Hath ke ishare)
`GestureClassifier` hand landmarks (joints) ko check karta hai:
- Niche diye gaye formula se check hota hai ke ungli (finger) khuli hai ya band:
  $$\text{distance}(\text{FingerTip}, \text{MCP\_Joint}) > 1.2 \times \text{distance}(\text{PIP\_Joint}, \text{MCP\_Joint})$$
- Agar 3 ya zyada ungliyan extended hon aur thumb bhi open ho, to **Open Palm** register hota hai.
- Agar sirf index finger extended ho, to **Pointing** register hota hai.
- **Fidgeting Detection**: Agar hand movements ki velocity 150 px/sec se barh jaye bina kisi stable gesture ke, to `is_fidgeting = True` set ho jata hai jo confidence score ko kam karta hai.

### D. Posture (Baithne ka tariqa)
`PostureAnalyzer` left aur right shoulders (11, 12) aur nose (0) ke coordinates check karta hai:
- **Shoulder Angle**: Slope angle nikal kar lean check hota hai ($\arctan2(\Delta y, \Delta x)$).
- **Slouching**: Agar nose aur shoulders ka vertical gap shoulder width ke relative 30% se kam ho jaye, to **Slouching** register hoti hai.
- **Distance**: Shoulder distance se check hota hai ke user screen ke zyada kareeb (`too_close`) ya door (`too_far`) hai.

---

## 4. Scores aur Averages Kaise Calculate Hote Hain? (Math Behind Scores)

Hamare PDF report aur dashboard ke scores ko calculate karne ke mathematical formulas niche detail se diye gaye hain:

### A. Individual Questions ke Accuracy Scores ($QA_i$)
Jab interview complete hota hai, to Gemini har question ($Q$) aur candidate ke response ($A$) ko analyze karta hai aur use **0 se 100** ke darmiyan score deta hai. Isme technical terms ki correctness, answer ki detail, aur CV background ke relevance ko check kiya jata hai.

### B. PDF Report ka Total Average Q&A Score
PDF report ke andar jo **Average Accuracy** show hoti hai, wo har individual question score ka simple arithmetic mean (average) hoti hai:
$$\text{TotalAverageQA} = \frac{\sum_{i=1}^{N} QA_i}{N}$$
*Yahan $N$ total questions ki tadad hai, aur $QA_i$ har question ka score hai.*

### C. Body Language (NVC) ke Dashboard Scores (0-10 Scale)
`nvc_service.py` mein dynamic percentages ko normalized 0-10 format mein convert kiya jata hai:
- **Eye Contact Score**: $\min(10.0, \text{EyeContactPercentage} / 10.0)$
- **Posture Score**: $\min(10.0, \text{AveragePosturePercentage} / 10.0)$
- **Engagement Score**: $\min(10.0, \text{OverallEngagementScore} / 10.0)$
- **Confidence Score**: $\min(10.0, \text{OverallConfidenceScore} / 10.0)$
- **Gesture Score**: Gestures per minute ke mutabiq nikalta hai. **5 se 12 gestures/min** sabse best score (8-10) dete hain. Isse kam ya zyada hone par score penalty lagti hai:
  - Agar frequency $5$ se $12$ ke darmiyan ho:
    $$\text{BaseScore} = 8.0 + \left( \frac{\text{Freq} - 5}{7} \times 2.0 \right)$$
  - Fidgeting check karne ke baad penalty lagti hai:
    $$\text{FinalGestureScore} = \text{BaseScore} - \min\left(2.0, \frac{\text{FidgetPercentage}}{25} \times 2.0\right)$$

### D. Overall Body Language Score (0-10 Scale)
Pancho dimensions ka weighted average le kar overall body language score nikalta hai:
$$\text{OverallBodyLanguage} = (\text{Eye} \times 0.25) + (\text{Confidence} \times 0.25) + (\text{Posture} \times 0.20) + (\text{Gesture} \times 0.15) + (\text{Engagement} \times 0.15)$$

### E. Combined Overall Performance Score (0-100%)
ReportLab PDF report ke front page par jo barhi overall percentage show hoti hai, wo text accuracy aur body language ka combined weight hoti hai:
$$\text{CombinedScore} = \text{round}( (\text{OverallBodyLanguageScore} \times 10) \times 0.40 + \text{TotalAverageQA} \times 0.60, 1 )$$
- **60% Weight**: Candidate ke answers ki quality aur technical accuracy.
- **40% Weight**: Candidate ka body language presentation aur delivery level.

### F. Voice & Sentiment Score
Vapi transcript se user ke dialog lines ko extract kiya jata hai aur **NLTK VADER** module compounds value ($C \in [-1, 1]$) nikalta hai. Ise percentage mein convert kiya jata hai:
$$\text{SentimentPct} = \text{int}((C + 1.0) \times 50)$$

---

## 5. PDF Report ki Structure aur Elements

Humne dynamic, professional aur visual-rich PDF format add kiya hai jo niche likhe gaye elements par mushtamil hai:

1. **Page 1: Executive Summary**
   - **Combined Overall Score**: Aik big dynamic score circle (maslan **78%**), jo dynamic color change karta hai (Hara $\ge 70$, Pila $\ge 40$, Lal $< 40$).
   - **Metrics Overview Table**: Engagement, Confidence, Eye Contact aur Posture ke simple numeric ratings (0-100).
   - **Performance Radar Chart**: Matplotlib ke zariye polar coordinate grid par radar shape banti hai jo user ko un ki weakness/strength aik glance mein dikhati hai.
   - **Strengths & Areas for Improvement**: Bullet points list jo user ko direct feed karti hai.

2. **Page 2: Detailed Analytics**
   - **Dominant Emotion Pie Chart**: User ne poore session mein kitna time confident, neutral ya nervous feel kiya, uska share dikhata hai.
   - **Posture Distribution Bar Chart**: Upright vs slouching ka side-by-side comparison.
   - **Timeline Line Graph**: Eye contact aur posture ka frame-by-frame data over time (seconds) map kiya jata hai taake pata chale ke user kis minute mein slouch kar raha tha.
   - **Recommendations**: Detailed text coaching lines.

3. **Page 3+: Question & Answer Analysis**
   - **Q&A List**: Dynamic section jo kitne bhi questions par extend ho sakta hai. Har question block mein:
     - Har sawal ki heading.
     - User ka diya gaya jawad (Answer text).
     - Sawal ka specific accuracy percentage (e.g. **85%**).
     - Gemini ki taraf se likha gaya constructive feedback.
   - **KeepTogether Wrapper**: Humne ReportLab ka `KeepTogether` flowable use kiya hai taake individual question, answer aur feedback block hamesha aik hi page par rahein aur ajeeb page breaks na hon.

---

## 6. Secure JWT Token System (Security Layer)

Pehle client side par private API keys expose hone ka khatra tha. Use hal karne ke liye humne secure JWT flow implement kiya hai:
1. Client resume aur position parameters Python server ko posts karta hai.
2. Server backend par Vapi ke private headers se connection bana kar temporary assistant register karta hai aur aik temporary session generate karta hai.
3. Server aik payload generate karta hai jisme `session_id`, `assistant_id`, `user_id` aur `exp` (expiry time: duration + 10 mins buffer) hota hai.
4. Server is payload ko **HMAC SHA256** algorithm aur aik secret key (`SESSION_SECRET`) se sign karke **JWT Session Token** banata hai.
5. Client ko sirf yeh token aur public key milti hai, jisse client Vapi WebRTC session establish kar sakta hai par hamare credentials chura nahi sakta.
6. Har call validation backend par token signature aur expiry check karke hi data process karti hai.

---

## 7. Unity Avatar aur Animations

Avatar live interview ke doran user ke action aur states par response deta hai:

- **Conversational Hand Gestures (`InterviewHandGestures.cs`)**:
  - Avatar speaking state (`isSpeaking = true`) mein hand gestures perform karta hai.
  - continuous 3D Perlin noise use kiya jata hai collarbone, shoulders aur hand positions par taake breathing aur body sway ka realistic lagne wala effect create ho sake.
  - Cubic interpolation se movements ke transition bohat smooth hotiye hain.
- **Head & Eyes Control (`AvatarHeadAndEyes.cs`)**:
  - Avatar random interval (2 to 6 seconds) par blinks karta hai, aur bolte waqt blink rate barh jata hai.
  - Listening state mein avatar continuous slow sway karta hai aur garden ko halka tilt karta hai jaise koi attentive listener karta hai, aur bich mein agreed nodes (nods) bhi deta hai.

---

## 8. Real-Time Feedback Loop

Live interview ke doran real-time performance check karne ke liye niche diya gaya loop chalta hai:

- `nvc_recorder.js` canvas frame se photo capture karta hai aur form-data ke zariye POST call backend par bhejta hai.
- Response milte hi `CustomEvent('nvc-metrics')` dispatch hota hai.
- Flutter Web app ka event listener ise catch karke immediate warning panels render karta hai, maslan:
  - "Please sit upright" (slouching warning)
  - "Maintain eye contact with the camera" (low gaze warning)
  - "Dominant emotion: nervous" (emotional feedback overlay)

Is poori pipeline se candidate ko interview se pehle real-time coaching milti hai jisse un ka confidence aur body language behtar hoti hai.
