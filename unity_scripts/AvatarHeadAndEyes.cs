using UnityEngine;

/// <summary>
/// Natural head movement and eye blinking for interview avatar.
/// Attach to the SAME GameObject as SimpleLipSync.
/// 
/// Features:
///   HEAD:
///   - Speaking: gentle nods (agreement), subtle tilts, small turns
///   - Listening: slower, wider head sway, occasional nods
///   - Idle: very subtle drift and breathing-driven micro-motion
///   - Smooth cubic interpolation between all poses
///
///   EYES:
///   - Random blinking every 2–6 seconds (natural human range)
///   - Occasional double-blinks (~20% chance)
///   - Faster blink rate while speaking
///   - Smooth eyelid close/open with asymmetric timing
///   - Supports separate Left/Right blend shapes or a single unified one
///   - AUTO-DETECTS blend shape indices if configured indices are invalid
/// </summary>
public class AvatarHeadAndEyes : MonoBehaviour
{
    // ================================================================
    //  BONE REFERENCES
    // ================================================================

    [Header("=== Head / Neck Bones ===")]
    [Tooltip("Drag the Head bone from Hierarchy (e.g. Armature > Hips > Spine > Chest > Neck > Head)")]
    public Transform headBone;

    [Tooltip("Optional: Neck bone for more natural two-joint head motion")]
    public Transform neckBone;

    // ================================================================
    //  EYE BLINK REFERENCES
    // ================================================================

    [Header("=== Eye Blink (Blend Shapes) ===")]
    [Tooltip("SkinnedMeshRenderer that has the eye blink blend shapes (usually the face/body mesh)")]
    public SkinnedMeshRenderer faceMesh;

    [Tooltip("Blend shape index for LEFT eye blink (set to -1 if not available)")]
    public int leftEyeBlinkIndex = -1;

    [Tooltip("Blend shape index for RIGHT eye blink (set to -1 if not available)")]
    public int rightEyeBlinkIndex = -1;

    [Tooltip("If your model has a SINGLE 'blink both eyes' blend shape, set its index here (set to -1 if using separate L/R)")]
    public int bothEyesBlinkIndex = -1;

    // ================================================================
    //  TUNING
    // ================================================================

    [Header("=== Head Motion Tuning ===")]
    [Range(0.1f, 1.5f)]
    [Tooltip("Overall intensity of head movement")]
    public float headIntensity = 0.7f;

    [Range(0.5f, 3f)]
    [Tooltip("Speed multiplier for head gestures")]
    public float headSpeed = 1.0f;

    [Header("=== Eye Blink Tuning ===")]
    [Range(1f, 8f)]
    [Tooltip("Minimum seconds between blinks")]
    public float minBlinkInterval = 2.0f;

    [Range(3f, 10f)]
    [Tooltip("Maximum seconds between blinks")]
    public float maxBlinkInterval = 5.5f;

    [Range(0.05f, 0.2f)]
    [Tooltip("How fast the eyelids close (seconds)")]
    public float blinkCloseSpeed = 0.07f;

    [Range(0.08f, 0.3f)]
    [Tooltip("How fast the eyelids open (seconds)")]
    public float blinkOpenSpeed = 0.14f;

    // ================================================================
    //  STATE (auto-driven by SimpleLipSync via SetAvatarState)
    // ================================================================

    [Header("=== State (Auto-driven) ===")]
    public bool isSpeaking = false;
    public bool isListening = false;

    // ─── Rest poses ───
    private Quaternion restHead;
    private Quaternion restNeck;

    // ─── Head motion state ───
    private float globalTime;
    private float phaseNodX;    // nod (pitch)
    private float phaseTiltZ;   // tilt (roll)
    private float phaseTurnY;   // turn (yaw)
    private float phaseExtra;   // extra organic variation

    // Speaking-specific: nod timing for emphasis
    private float nodTimer;
    private float nextNodTime;
    private float nodStrength;
    private float currentNodImpulse;

    // ─── Blink state ───
    private float blinkTimer;
    private float nextBlinkAt;
    private bool isBlinking;
    private float blinkPhase; // 0..1 for close, 1..2 for open
    private bool doDoubleBlink;
    private int doubleBlinkCount;
    private float currentBlinkWeight; // 0=open, 100=closed

    // ─── Speaking tracking ───
    private bool wasSpeaking;
    private float speakingDuration;

    // ─── Auto-detected valid indices ───
    private int validLeftBlinkIndex = -1;
    private int validRightBlinkIndex = -1;
    private int validBothBlinkIndex = -1;
    private bool blinkIndicesValidated = false;

    // ================================================================
    //  LIFECYCLE
    // ================================================================

    void Start()
    {
        CaptureRestPoses();
        RandomizePhases();
        ScheduleNextBlink();
        ValidateBlinkIndices();
    }

    void CaptureRestPoses()
    {
        if (headBone) restHead = headBone.localRotation;
        if (neckBone) restNeck = neckBone.localRotation;
    }

    void RandomizePhases()
    {
        phaseNodX = Random.Range(0f, Mathf.PI * 2f);
        phaseTiltZ = Random.Range(0f, Mathf.PI * 2f);
        phaseTurnY = Random.Range(0f, Mathf.PI * 2f);
        phaseExtra = Random.Range(0f, Mathf.PI * 2f);
    }

    void ScheduleNextBlink()
    {
        // Speaking = more frequent blinks (humans blink more while talking)
        float min = isSpeaking ? minBlinkInterval * 0.6f : minBlinkInterval;
        float max = isSpeaking ? maxBlinkInterval * 0.7f : maxBlinkInterval;
        nextBlinkAt = Random.Range(min, max);
        blinkTimer = 0f;
    }

    /// <summary>
    /// Auto-detect and validate blink blend shape indices.
    /// If configured indices are out of bounds, search by name.
    /// </summary>
    void ValidateBlinkIndices()
    {
        if (faceMesh == null || faceMesh.sharedMesh == null)
        {
            Debug.Log("[AvatarHeadAndEyes] No faceMesh assigned. Eye blinks disabled.");
            blinkIndicesValidated = true;
            return;
        }

        int count = faceMesh.sharedMesh.blendShapeCount;
        Debug.Log("[AvatarHeadAndEyes] Face mesh has " + count + " blend shapes.");

        // Log all blend shape names
        for (int i = 0; i < count; i++)
        {
            Debug.Log("[AvatarHeadAndEyes]   BlendShape[" + i + "] = " + faceMesh.sharedMesh.GetBlendShapeName(i));
        }

        // Validate configured indices
        validLeftBlinkIndex = IsValidIndex(leftEyeBlinkIndex, count) ? leftEyeBlinkIndex : -1;
        validRightBlinkIndex = IsValidIndex(rightEyeBlinkIndex, count) ? rightEyeBlinkIndex : -1;
        validBothBlinkIndex = IsValidIndex(bothEyesBlinkIndex, count) ? bothEyesBlinkIndex : -1;

        // If none are valid, try auto-detecting by name
        if (validLeftBlinkIndex < 0 && validRightBlinkIndex < 0 && validBothBlinkIndex < 0)
        {
            Debug.Log("[AvatarHeadAndEyes] No valid blink indices. Auto-detecting...");
            AutoDetectBlinkIndices(count);
        }

        Debug.Log("[AvatarHeadAndEyes] Final blink indices — L:" + validLeftBlinkIndex +
                  " R:" + validRightBlinkIndex + " Both:" + validBothBlinkIndex);

        blinkIndicesValidated = true;
    }

    void AutoDetectBlinkIndices(int count)
    {
        for (int i = 0; i < count; i++)
        {
            string name = faceMesh.sharedMesh.GetBlendShapeName(i).ToLower();

            // Check for "both eyes" blink
            if (name.Contains("blink") && !name.Contains("left") && !name.Contains("right") &&
                !name.Contains("_l") && !name.Contains("_r"))
            {
                validBothBlinkIndex = i;
                Debug.Log("[AvatarHeadAndEyes] AUTO-DETECTED both-eyes blink: [" + i + "] " +
                          faceMesh.sharedMesh.GetBlendShapeName(i));
            }
            // Check for left eye blink
            else if (name.Contains("blink") && (name.Contains("left") || name.Contains("_l")))
            {
                validLeftBlinkIndex = i;
                Debug.Log("[AvatarHeadAndEyes] AUTO-DETECTED left blink: [" + i + "] " +
                          faceMesh.sharedMesh.GetBlendShapeName(i));
            }
            // Check for right eye blink
            else if (name.Contains("blink") && (name.Contains("right") || name.Contains("_r")))
            {
                validRightBlinkIndex = i;
                Debug.Log("[AvatarHeadAndEyes] AUTO-DETECTED right blink: [" + i + "] " +
                          faceMesh.sharedMesh.GetBlendShapeName(i));
            }
            // Broader search: "eye" + "close"
            else if (name.Contains("eye") && name.Contains("close"))
            {
                if (validBothBlinkIndex < 0)
                {
                    validBothBlinkIndex = i;
                    Debug.Log("[AvatarHeadAndEyes] AUTO-DETECTED eye close: [" + i + "] " +
                              faceMesh.sharedMesh.GetBlendShapeName(i));
                }
            }
        }
    }

    bool IsValidIndex(int index, int count)
    {
        return index >= 0 && index < count;
    }

    // ================================================================
    //  PUBLIC API — called from SimpleLipSync.SetAvatarState()
    // ================================================================

    /// <summary>
    /// Called by Unity SendMessage from JS bridge (same as other scripts).
    /// </summary>
    public void SetAvatarState(string state)
    {
        isSpeaking = (state == "speaking");
        isListening = (state == "listening");
    }

    public void SetSpeaking(bool speaking)
    {
        isSpeaking = speaking;
        isListening = !speaking;
    }

    /// <summary>
    /// Receives audio level data — could be used for volume-reactive head bobs.
    /// </summary>
    public void ReceiveAudioLevel(string jsonData)
    {
        // Future: parse volume to drive head bob intensity
    }

    // ================================================================
    //  UPDATE
    // ================================================================

    void Update()
    {
        float dt = Time.deltaTime;
        globalTime += dt;

        HandleSpeakingStateChange();
        UpdateHeadMotion(dt);
        UpdateEyeBlink(dt);
    }

    void HandleSpeakingStateChange()
    {
        if (isSpeaking && !wasSpeaking)
        {
            // Just started speaking — trigger an initial nod
            speakingDuration = 0f;
            nodTimer = 0f;
            nextNodTime = Random.Range(0.5f, 1.2f);
            nodStrength = Random.Range(3f, 6f);
            currentNodImpulse = nodStrength;
        }
        else if (!isSpeaking && wasSpeaking)
        {
            // Stopped speaking
            speakingDuration = 0f;
            currentNodImpulse = 0f;
        }

        if (isSpeaking)
        {
            speakingDuration += Time.deltaTime;
        }

        wasSpeaking = isSpeaking;
    }

    // ================================================================
    //  HEAD MOTION
    // ================================================================

    void UpdateHeadMotion(float dt)
    {
        if (!headBone) return;

        float intensity = headIntensity;
        float speed = headSpeed;

        // Advance organic phases at different rates for non-repetitive motion
        phaseNodX += dt * 1.1f * speed;
        phaseTiltZ += dt * 0.8f * speed;
        phaseTurnY += dt * 0.65f * speed;
        phaseExtra += dt * 1.4f * speed;

        float nodX = 0f;    // pitch: +down, -up (nod)
        float tiltZ = 0f;   // roll: side tilt
        float turnY = 0f;   // yaw: left/right turn

        if (isSpeaking)
        {
            // ─── SPEAKING: Active head movement ───
            // Continuous organic sway
            nodX = Mathf.Sin(phaseNodX) * 3.5f * intensity;
            nodX += Mathf.Sin(phaseNodX * 2.3f) * 1.8f * intensity; // harmonic
            tiltZ = Mathf.Sin(phaseTiltZ) * 2.8f * intensity;
            tiltZ += Mathf.Sin(phaseTiltZ * 1.7f + 0.5f) * 1.2f * intensity;
            turnY = Mathf.Sin(phaseTurnY) * 3.2f * intensity;
            turnY += Mathf.Sin(phaseTurnY * 2.1f + 1.0f) * 1.5f * intensity;

            // Emphatic nods — periodic downward head dips
            nodTimer += dt * speed;
            if (nodTimer >= nextNodTime)
            {
                nodTimer = 0f;
                nextNodTime = Random.Range(0.8f, 2.5f);
                nodStrength = Random.Range(4f, 8f) * intensity;
                currentNodImpulse = nodStrength;
            }
            // Decay the nod impulse smoothly
            currentNodImpulse = Mathf.Lerp(currentNodImpulse, 0f, dt * 4f);
            nodX += currentNodImpulse;

            // Slight forward lean while speaking (engagement)
            nodX += 1.5f * intensity;
        }
        else if (isListening)
        {
            // ─── LISTENING: Slower, attentive movement ───
            // Gentle slow sway — "I'm paying attention"
            nodX = Mathf.Sin(phaseNodX * 0.5f) * 2.0f * intensity;
            tiltZ = Mathf.Sin(phaseTiltZ * 0.4f) * 2.5f * intensity;
            turnY = Mathf.Sin(phaseTurnY * 0.35f) * 1.8f * intensity;

            // Occasional agreeing nod (small periodic dips)
            float listenNod = Mathf.Sin(globalTime * 0.7f);
            if (listenNod > 0.85f) // brief nod peaks
            {
                nodX += 3.0f * intensity * (listenNod - 0.85f) / 0.15f;
            }

            // Slight head tilt to one side (attentive posture)
            tiltZ += 1.5f * intensity * Mathf.Sin(globalTime * 0.15f);
        }
        else
        {
            // ─── IDLE: Very subtle drift ───
            nodX = Mathf.Sin(phaseNodX * 0.25f) * 0.8f * intensity;
            tiltZ = Mathf.Sin(phaseTiltZ * 0.2f) * 0.6f * intensity;
            turnY = Mathf.Sin(phaseTurnY * 0.15f) * 0.5f * intensity;

            // Breathing-driven micro bob
            float breathBob = Mathf.Sin(globalTime * 0.7f) * 0.4f * intensity;
            nodX += breathBob;
        }

        // ─── Apply to HEAD bone ───
        // Head gets ~70% of the motion
        float headShare = 0.7f;
        Quaternion headTarget = restHead * Quaternion.Euler(
            nodX * headShare,
            turnY * headShare,
            tiltZ * headShare
        );
        headBone.localRotation = Quaternion.Slerp(
            headBone.localRotation,
            headTarget,
            dt * 5f * speed
        );

        // ─── Apply to NECK bone (if assigned) ───
        // Neck gets ~30% for a natural two-joint look
        if (neckBone)
        {
            float neckShare = 0.3f;
            Quaternion neckTarget = restNeck * Quaternion.Euler(
                nodX * neckShare,
                turnY * neckShare,
                tiltZ * neckShare
            );
            neckBone.localRotation = Quaternion.Slerp(
                neckBone.localRotation,
                neckTarget,
                dt * 4f * speed
            );
        }
    }

    // ================================================================
    //  EYE BLINK
    // ================================================================

    void UpdateEyeBlink(float dt)
    {
        // Lazy validation
        if (!blinkIndicesValidated)
        {
            ValidateBlinkIndices();
        }

        // Check if we have any VALID blink blend shapes
        bool hasBlinkShapes = faceMesh != null && faceMesh.sharedMesh != null &&
            (validLeftBlinkIndex >= 0 || validRightBlinkIndex >= 0 || validBothBlinkIndex >= 0);

        if (!hasBlinkShapes) return;

        if (!isBlinking)
        {
            // ─── Waiting for next blink ───
            blinkTimer += dt;
            if (blinkTimer >= nextBlinkAt)
            {
                StartBlink();
            }
        }
        else
        {
            // ─── Currently blinking ───
            UpdateBlinkAnimation(dt);
        }

        // Apply blink weight to blend shapes
        ApplyBlinkWeight(currentBlinkWeight);
    }

    void StartBlink()
    {
        isBlinking = true;
        blinkPhase = 0f;
        doubleBlinkCount = 0;

        // ~20% chance of double-blink (very natural human behavior)
        doDoubleBlink = Random.value < 0.20f;
    }

    void UpdateBlinkAnimation(float dt)
    {
        // Phase 0→1: closing
        // Phase 1→2: opening
        if (blinkPhase < 1f)
        {
            // CLOSING — fast snap shut
            blinkPhase += dt / blinkCloseSpeed;
            if (blinkPhase >= 1f)
            {
                blinkPhase = 1f;
                // Snap to fully closed, then start opening
            }
            // Ease-in curve for natural closing (accelerates)
            float t = blinkPhase;
            float easedClose = t * t; // quadratic ease-in
            currentBlinkWeight = easedClose * 100f;
        }
        else
        {
            // OPENING — slightly slower ease-out
            blinkPhase += dt / blinkOpenSpeed;
            if (blinkPhase >= 2f)
            {
                blinkPhase = 2f;

                // Check for double-blink
                if (doDoubleBlink && doubleBlinkCount < 1)
                {
                    doubleBlinkCount++;
                    blinkPhase = 0f; // restart blink
                    return;
                }

                // Blink complete
                isBlinking = false;
                currentBlinkWeight = 0f;
                ScheduleNextBlink();
                return;
            }
            // Ease-out curve for natural opening (decelerates)
            float t = blinkPhase - 1f; // 0→1
            float easedOpen = 1f - (1f - t) * (1f - t); // quadratic ease-out
            currentBlinkWeight = (1f - easedOpen) * 100f;
        }
    }

    void ApplyBlinkWeight(float weight)
    {
        if (faceMesh == null || faceMesh.sharedMesh == null) return;

        // Clamp weight
        weight = Mathf.Clamp(weight, 0f, 100f);

        // Apply to unified blink shape (using VALIDATED index)
        if (validBothBlinkIndex >= 0)
        {
            faceMesh.SetBlendShapeWeight(validBothBlinkIndex, weight);
        }

        // Apply to individual eye shapes (using VALIDATED indices)
        if (validLeftBlinkIndex >= 0)
        {
            faceMesh.SetBlendShapeWeight(validLeftBlinkIndex, weight);
        }
        if (validRightBlinkIndex >= 0)
        {
            // Tiny asymmetry for realism — right eye closes ~5% faster
            float rightWeight = Mathf.Min(100f, weight * 1.05f);
            faceMesh.SetBlendShapeWeight(validRightBlinkIndex, rightWeight);
        }
    }
}
