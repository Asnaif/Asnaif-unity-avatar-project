// using UnityEngine;
// using UnityEngine.Animations.Rigging;
// using System.Collections;

// /// <summary>
// /// PRODUCTION REWRITE — Interview Hand Gestures (IK Architecture)
// /// 
// /// This script manages professional conversational gestures for an avatar
// /// using Unity's Animation Rigging package. It completely replaces the flawed
// /// Euler-bone-rotation approach with a biomechanically stable IK solver.
// /// 
// /// Core Principles:
// /// - No direct bone manipulation. Uses TwoBoneIK constraints.
// /// - Interpolation via SmoothDamp (no Zeno's paradox decay).
// /// - Single layer of interpolation.
// /// - Smooth transition in/out of Animator base states via Rig Weight.
// /// - Gestures are defined as root-space coordinates, preventing wrist twisting.
// /// - 100% independent of SimpleLipSync (no facial bones touched).
// /// </summary>
// [RequireComponent(typeof(Animator))]
// public class InterviewHandGestures : MonoBehaviour
// {
//     [Header("=== Rigging Infrastructure ===")]
//     [Tooltip("The Rig component managing the arm IK constraints.")]
//     public Rig gestureRig;
    
//     [Tooltip("The IK Target for the Left Hand.")]
//     public Transform leftHandTarget;
//     [Tooltip("The IK Hint for the Left Elbow.")]
//     public Transform leftElbowHint;
    
//     [Tooltip("The IK Target for the Right Hand.")]
//     public Transform rightHandTarget;
//     [Tooltip("The IK Hint for the Right Elbow.")]
//     public Transform rightElbowHint;

//     [Tooltip("The root of the avatar, used as the coordinate reference frame.")]
//     public Transform avatarRoot;

//     [Header("=== Biomechanics & Proportion References ===")]
//     [Tooltip("Used to calculate scale-agnostic gesture positions.")]
//     public Transform leftShoulderRef;
//     public Transform rightShoulderRef;

//     [Header("=== Tuning & Dynamics ===")]
//     [Range(0.1f, 2f)] 
//     [Tooltip("Time in seconds to complete a gesture transition. Lower is faster.")]
//     public float transitionTime = 0.5f;
    
//     [Range(0f, 2f)]
//     [Tooltip("Scale of procedural micro-movements to simulate breathing/aliveness.")]
//     public float microMovementScale = 0.5f;

//     [Header("=== Runtime State (Auto-Driven) ===")]
//     public bool isSpeaking = false;

//     // --- State Machine ---
//     private enum GestureState
//     {
//         Rest,
//         OpenPalm,
//         Explanation,
//         SmallEmphasis,
//         Point,
//         HandsTogether
//     }

//     private GestureState currentState = GestureState.Rest;
//     private bool wasSpeaking = false;
//     private float gestureTimer = 0f;
//     private float nextGestureDuration = 0f;

//     // --- Rig Blending ---
//     private float targetRigWeight = 0f;
//     private float rigWeightVelocity;

//     // --- Interpolation Targets ---
//     private Vector3 targetLeftPos, targetRightPos;
//     private Quaternion targetLeftRot, targetRightRot;
//     private Vector3 targetLeftElbow, targetRightElbow;

//     // --- Interpolation State (SmoothDamp) ---
//     private Vector3 leftPosVel, rightPosVel;
//     private Vector3 leftElbowVel, rightElbowVel;
//     // Quaternion SmoothDamp requires custom implementation
//     private float rotTransitionT = 1f;
//     private Quaternion startLeftRot, startRightRot;
//     private Quaternion destLeftRot, destRightRot;

//     // --- Base Offsets (Calculated from Shoulders) ---
//     private Vector3 shoulderCenter;
//     private float shoulderWidth;

//     // ========================================================================
//     // PUBLIC API (Called by VAPI Bridge or SimpleLipSync)
//     // ========================================================================

//     /// <summary>
//     /// Triggered via SendMessage from JS WebGL bridge.
//     /// Must match exact signature.
//     /// </summary>
//     public void SetAvatarState(string state)
//     {
//         SetSpeaking(state == "speaking");
//     }

//     public void SetSpeaking(bool speaking)
//     {
//         isSpeaking = speaking;
//     }

//     /// <summary>
//     /// Received from VAPI/JS Bridge. 
//     /// This script ignores audio levels to prevent interference with SimpleLipSync,
//     /// but must accept the message to prevent SendMessage errors.
//     /// </summary>
//     public void ReceiveAudioLevel(string jsonData)
//     {
//         // Intentionally empty. Lip sync logic remains solely in SimpleLipSync.cs.
//     }

//     // ========================================================================
//     // INITIALIZATION
//     // ========================================================================

//     void Start()
//     {
//         if (avatarRoot == null) avatarRoot = transform;
//         if (gestureRig != null) gestureRig.weight = 0f; // Start fully Animator-driven

//         CalculateProportions();
//         SetTargetPose(GestureState.Rest);
        
//         // Snap to initial pose
//         leftHandTarget.position = avatarRoot.TransformPoint(targetLeftPos);
//         rightHandTarget.position = avatarRoot.TransformPoint(targetRightPos);
//         leftHandTarget.rotation = avatarRoot.rotation * targetLeftRot;
//         rightHandTarget.rotation = avatarRoot.rotation * targetRightRot;
//     }

//     /// <summary>
//     /// Analyzes the avatar's bone structure to generate scale-agnostic gesture coordinates.
//     /// This prevents poses from breaking on characters with different heights or arm lengths.
//     /// </summary>
//     private void CalculateProportions()
//     {
//         if (leftShoulderRef != null && rightShoulderRef != null)
//         {
//             Vector3 lLocal = avatarRoot.InverseTransformPoint(leftShoulderRef.position);
//             Vector3 rLocal = avatarRoot.InverseTransformPoint(rightShoulderRef.position);
//             shoulderCenter = (lLocal + rLocal) / 2f;
//             shoulderWidth = Vector3.Distance(lLocal, rLocal);
//         }
//         else
//         {
//             // Standard humanoid fallback (in meters)
//             shoulderCenter = new Vector3(0f, 1.3f, 0f);
//             shoulderWidth = 0.4f;
//         }
//     }

//     // ========================================================================
//     // MAIN LOOP
//     // ========================================================================

//     void Update()
//     {
//         if (gestureRig == null || leftHandTarget == null || rightHandTarget == null) return;

//         HandleSpeakingStateMachine();
//         UpdateRigWeight();
//         UpdateIKTargets();
//     }

//     private void HandleSpeakingStateMachine()
//     {
//         if (isSpeaking && !wasSpeaking)
//         {
//             // Started speaking
//             targetRigWeight = 1f;
//             PickNextGesture();
//         }
//         else if (!isSpeaking && wasSpeaking)
//         {
//             // Stopped speaking
//             TransitionTo(GestureState.Rest);
//             targetRigWeight = 0f; // Hand control back to Animator
//         }

//         if (isSpeaking)
//         {
//             gestureTimer += Time.deltaTime;
//             if (gestureTimer >= nextGestureDuration)
//             {
//                 PickNextGesture();
//             }
//         }

//         wasSpeaking = isSpeaking;
//     }

//     private void UpdateRigWeight()
//     {
//         // Smoothly blend the entire IK rig in and out.
//         // When weight is 0, the base Animator (idle/breathing) has 100% control.
//         gestureRig.weight = Mathf.SmoothDamp(gestureRig.weight, targetRigWeight, ref rigWeightVelocity, 0.4f);
//     }

//     private void PickNextGesture()
//     {
//         gestureTimer = 0f;
//         nextGestureDuration = Random.Range(3f, 6f); // Professional rhythm: 3-6 seconds per gesture

//         // Gesture Probability Model for Professional Interviewer
//         float roll = Random.value;
//         GestureState nextState;

//         if (roll < 0.60f) nextState = GestureState.SmallEmphasis;
//         else if (roll < 0.80f) nextState = GestureState.OpenPalm;
//         else if (roll < 0.90f) nextState = GestureState.Explanation;
//         else if (roll < 0.95f) nextState = GestureState.HandsTogether;
//         else nextState = GestureState.Point;

//         // Prevent repeating the exact same extreme gesture
//         if (nextState == currentState && nextState != GestureState.SmallEmphasis)
//         {
//             nextState = GestureState.Rest;
//         }

//         TransitionTo(nextState);
//     }

//     // ========================================================================
//     // KINEMATIC SOLVER & INTERPOLATION
//     // ========================================================================

//     private void TransitionTo(GestureState newState)
//     {
//         currentState = newState;
//         SetTargetPose(newState);

//         // Reset rotation interpolation timer
//         rotTransitionT = 0f;
//         startLeftRot = leftHandTarget.localRotation;
//         startRightRot = rightHandTarget.localRotation;
        
//         destLeftRot = targetLeftRot;
//         destRightRot = targetRightRot;
//     }

//     private void UpdateIKTargets()
//     {
//         // 1. Procedural Micro-Movement (Alive-ness)
//         // Replaces excessive Perlin noise with calm, sinusoidal breathing mechanics
//         float time = Time.time;
//         Vector3 microOffsetL = new Vector3(
//             Mathf.Sin(time * 0.8f) * 0.01f,
//             Mathf.Sin(time * 1.1f) * 0.015f,
//             Mathf.Cos(time * 0.9f) * 0.01f
//         ) * microMovementScale;

//         Vector3 microOffsetR = new Vector3(
//             Mathf.Cos(time * 0.85f) * 0.01f,
//             Mathf.Cos(time * 1.15f) * 0.015f,
//             Mathf.Sin(time * 0.95f) * 0.01f
//         ) * microMovementScale;

//         // Calculate absolute target positions in root space
//         Vector3 finalLeftPos = targetLeftPos + microOffsetL;
//         Vector3 finalRightPos = targetRightPos + microOffsetR;

//         // 2. Position Interpolation (Vector3.SmoothDamp eliminates Zeno's Paradox)
//         Vector3 currentLocalL = avatarRoot.InverseTransformPoint(leftHandTarget.position);
//         Vector3 currentLocalR = avatarRoot.InverseTransformPoint(rightHandTarget.position);
        
//         Vector3 nextLocalL = Vector3.SmoothDamp(currentLocalL, finalLeftPos, ref leftPosVel, transitionTime);
//         Vector3 nextLocalR = Vector3.SmoothDamp(currentLocalR, finalRightPos, ref rightPosVel, transitionTime);

//         leftHandTarget.position = avatarRoot.TransformPoint(nextLocalL);
//         rightHandTarget.position = avatarRoot.TransformPoint(nextLocalR);

//         // 3. Elbow Hint Interpolation
//         Vector3 currentElbowL = avatarRoot.InverseTransformPoint(leftElbowHint.position);
//         Vector3 currentElbowR = avatarRoot.InverseTransformPoint(rightElbowHint.position);

//         Vector3 nextElbowL = Vector3.SmoothDamp(currentElbowL, targetLeftElbow, ref leftElbowVel, transitionTime * 1.2f);
//         Vector3 nextElbowR = Vector3.SmoothDamp(currentElbowR, targetRightElbow, ref rightElbowVel, transitionTime * 1.2f);

//         leftElbowHint.position = avatarRoot.TransformPoint(nextElbowL);
//         rightElbowHint.position = avatarRoot.TransformPoint(nextElbowR);

//         // 4. Rotation Interpolation (Smoothstep Slerp)
//         if (rotTransitionT < 1f)
//         {
//             // We use a custom smoothstep speed based on the transition time parameter
//             rotTransitionT += (Time.deltaTime / transitionTime);
//             if (rotTransitionT > 1f) rotTransitionT = 1f;

//             // EaseInOut cubic formula
//             float easeT = rotTransitionT * rotTransitionT * (3f - 2f * rotTransitionT);

//             leftHandTarget.localRotation = Quaternion.Slerp(startLeftRot, destLeftRot, easeT);
//             rightHandTarget.localRotation = Quaternion.Slerp(startRightRot, destRightRot, easeT);
//         }
//     }

//     // ========================================================================
//     // BIOMECHANICAL GESTURE DEFINITIONS
//     // ========================================================================

//     /// <summary>
//     /// Generates local-space (relative to avatarRoot) positions and rotations 
//     /// for a given gesture. This completely bypasses Euler bone twisting.
//     /// </summary>
//     private void SetTargetPose(GestureState state)
//     {
//         // --- Base Reference Coordinates ---
//         // Lap/Desk height (sitting)
//         float restY = shoulderCenter.y - 0.5f; 
//         float chestY = shoulderCenter.y - 0.25f;
//         float forwardZ = 0.3f; // Distance from chest
        
//         // Base Elbow hints (out and down)
//         targetLeftElbow = new Vector3(-shoulderWidth, shoulderCenter.y - 0.4f, -0.1f);
//         targetRightElbow = new Vector3(shoulderWidth, shoulderCenter.y - 0.4f, -0.1f);

//         switch (state)
//         {
//             case GestureState.Rest:
//                 // Hands resting in lap / on armrests
//                 targetLeftPos = new Vector3(-shoulderWidth * 0.6f, restY, forwardZ * 0.8f);
//                 targetRightPos = new Vector3(shoulderWidth * 0.6f, restY, forwardZ * 0.8f);
                
//                 // Palms facing inward/downward (relaxed)
//                 targetLeftRot = Quaternion.Euler(0, 90, -45);
//                 targetRightRot = Quaternion.Euler(0, -90, 45);
//                 break;

//             case GestureState.SmallEmphasis:
//                 // One hand slightly raised to emphasize a point, other resting
//                 targetLeftPos = new Vector3(-shoulderWidth * 0.5f, chestY - 0.1f, forwardZ);
//                 targetRightPos = new Vector3(shoulderWidth * 0.6f, restY, forwardZ * 0.8f); // Right rests
                
//                 // Left palm facing inward (gentle chop/bounce)
//                 targetLeftRot = Quaternion.Euler(0, 90, 0);
//                 targetRightRot = Quaternion.Euler(0, -90, 45);
//                 break;

//             case GestureState.OpenPalm:
//                 // Both hands slightly outward, palms up (welcoming/explaining)
//                 targetLeftPos = new Vector3(-shoulderWidth * 0.7f, chestY - 0.15f, forwardZ * 1.1f);
//                 targetRightPos = new Vector3(shoulderWidth * 0.7f, chestY - 0.15f, forwardZ * 1.1f);
                
//                 // Palms up
//                 targetLeftRot = Quaternion.Euler(-20, 45, -90);
//                 targetRightRot = Quaternion.Euler(-20, -45, 90);
                
//                 // Elbows tuck slightly in
//                 targetLeftElbow.x += 0.1f;
//                 targetRightElbow.x -= 0.1f;
//                 break;

//             case GestureState.Explanation:
//                 // Hands raised near chest level, palms facing each other (framing an idea)
//                 targetLeftPos = new Vector3(-shoulderWidth * 0.4f, chestY, forwardZ * 1.2f);
//                 targetRightPos = new Vector3(shoulderWidth * 0.4f, chestY, forwardZ * 1.2f);
                
//                 targetLeftRot = Quaternion.Euler(0, 90, 0);
//                 targetRightRot = Quaternion.Euler(0, -90, 0);
//                 break;

//             case GestureState.HandsTogether:
//                 // Hands brought together in front of the lower chest (contemplative)
//                 targetLeftPos = new Vector3(-0.05f, chestY - 0.15f, forwardZ);
//                 targetRightPos = new Vector3(0.05f, chestY - 0.15f, forwardZ);
                
//                 // Hands angled together
//                 targetLeftRot = Quaternion.Euler(0, 45, 0);
//                 targetRightRot = Quaternion.Euler(0, -45, 0);
                
//                 // Elbows flare out slightly
//                 targetLeftElbow.x -= 0.1f;
//                 targetRightElbow.x += 0.1f;
//                 break;

//             case GestureState.Point:
//                 // Subtle pointing/directing gesture (Right hand leads)
//                 targetLeftPos = new Vector3(-shoulderWidth * 0.6f, restY, forwardZ * 0.8f); // Left rests
//                 targetRightPos = new Vector3(0.1f, chestY, forwardZ * 1.4f); // Right extends
                
//                 targetLeftRot = Quaternion.Euler(0, 90, -45);
//                 targetRightRot = Quaternion.Euler(0, -90, 0); // Straight palm
//                 break;
//         }
//     }

//     // ========================================================================
//     // VALIDATION & DEBUG
//     // ========================================================================

//     void OnValidate()
//     {
//         if (Application.isPlaying) return;
        
//         // Warn the user in the inspector if rig components are missing
//         if (gestureRig == null) Debug.LogWarning("[InterviewHandGestures] Missing Rig reference. Use the Editor Setup tool.");
//         if (leftHandTarget == null || rightHandTarget == null) Debug.LogWarning("[InterviewHandGestures] Missing IK Targets.");
//     }
// }
