// #if UNITY_EDITOR
// using UnityEngine;
// using UnityEditor;
// using UnityEngine.Animations.Rigging;

// /// <summary>
// /// Editor utility to automatically set up the Animation Rigging hierarchy 
// /// required by the new InterviewHandGestures system.
// /// </summary>
// public class InterviewGestureSetup : EditorWindow
// {
//     private GameObject avatarRoot;

//     [MenuItem("Tools/InterPrep/Auto Setup Gesture Rig")]
//     public static void ShowWindow()
//     {
//         GetWindow<InterviewGestureSetup>("Gesture Rig Setup");
//     }

//     void OnGUI()
//     {
//         GUILayout.Label("Animation Rigging Auto-Setup", EditorStyles.boldLabel);
//         GUILayout.Space(10);
//         GUILayout.Label("Select your Avatar's root GameObject (the one with the Animator).");

//         avatarRoot = (GameObject)EditorGUILayout.ObjectField("Avatar Root", avatarRoot, typeof(GameObject), true);

//         GUILayout.Space(20);

//         if (GUILayout.Button("Generate IK Rig", GUILayout.Height(40)))
//         {
//             if (avatarRoot == null)
//             {
//                 EditorUtility.DisplayDialog("Error", "Please assign the Avatar Root first.", "OK");
//                 return;
//             }

//             SetupRig(avatarRoot);
//         }
//     }

//     private void SetupRig(GameObject root)
//     {
//         Animator animator = root.GetComponent<Animator>();
//         if (animator == null || !animator.isHuman)
//         {
//             EditorUtility.DisplayDialog("Error", "The Avatar Root must have a Humanoid Animator component.", "OK");
//             return;
//         }

//         Undo.RegisterFullObjectHierarchyUndo(root, "Setup Gesture Rig");

//         // 1. Ensure RigBuilder exists
//         RigBuilder rigBuilder = root.GetComponent<RigBuilder>();
//         if (rigBuilder == null)
//         {
//             rigBuilder = root.AddComponent<RigBuilder>();
//         }

//         // 2. Create the Rig object
//         Transform existingRig = root.transform.Find("InterviewGestureRig");
//         GameObject rigObject;
//         if (existingRig != null)
//         {
//             rigObject = existingRig.gameObject;
//         }
//         else
//         {
//             rigObject = new GameObject("InterviewGestureRig");
//             rigObject.transform.SetParent(root.transform);
//             rigObject.transform.localPosition = Vector3.zero;
//             rigObject.transform.localRotation = Quaternion.identity;
//         }

//         Rig rig = rigObject.GetComponent<Rig>();
//         if (rig == null) rig = rigObject.AddComponent<Rig>();

//         // 3. Create Left Arm IK
//         Transform leftShoulder = animator.GetBoneTransform(HumanBodyBones.LeftShoulder);
//         Transform leftUpperArm = animator.GetBoneTransform(HumanBodyBones.LeftUpperArm);
//         Transform leftLowerArm = animator.GetBoneTransform(HumanBodyBones.LeftLowerArm);
//         Transform leftHand = animator.GetBoneTransform(HumanBodyBones.LeftHand);
        
//         SetupArmIK(rigObject.transform, "LeftArmIK", leftUpperArm, leftLowerArm, leftHand, out Transform leftTarget, out Transform leftHint);

//         // 4. Create Right Arm IK
//         Transform rightShoulder = animator.GetBoneTransform(HumanBodyBones.RightShoulder);
//         Transform rightUpperArm = animator.GetBoneTransform(HumanBodyBones.RightUpperArm);
//         Transform rightLowerArm = animator.GetBoneTransform(HumanBodyBones.RightLowerArm);
//         Transform rightHand = animator.GetBoneTransform(HumanBodyBones.RightHand);

//         SetupArmIK(rigObject.transform, "RightArmIK", rightUpperArm, rightLowerArm, rightHand, out Transform rightTarget, out Transform rightHint);

//         // 5. Add Rig to RigBuilder
//         bool rigExists = false;
//         foreach (var rigLayer in rigBuilder.layers)
//         {
//             if (rigLayer.rig == rig) rigExists = true;
//         }
//         if (!rigExists)
//         {
//             rigBuilder.layers.Add(new RigLayer(rig));
//         }

//         // 6. Setup InterviewHandGestures script
//         InterviewHandGestures gestures = root.GetComponent<InterviewHandGestures>();
//         if (gestures == null) gestures = root.AddComponent<InterviewHandGestures>();

//         gestures.gestureRig = rig;
//         gestures.leftHandTarget = leftTarget;
//         gestures.leftElbowHint = leftHint;
//         gestures.rightHandTarget = rightTarget;
//         gestures.rightElbowHint = rightHint;
//         gestures.avatarRoot = root.transform;
//         gestures.leftShoulderRef = leftShoulder;
//         gestures.rightShoulderRef = rightShoulder;

//         EditorUtility.SetDirty(root);
//         EditorUtility.DisplayDialog("Success", "Gesture Rig successfully generated and configured! You can now tweak the values on the InterviewHandGestures script.", "OK");
//     }

//     private void SetupArmIK(Transform parentRig, string name, Transform upper, Transform lower, Transform hand, out Transform target, out Transform hint)
//     {
//         // Find or create the IK node
//         Transform ikNode = parentRig.Find(name);
//         if (ikNode == null)
//         {
//             ikNode = new GameObject(name).transform;
//             ikNode.SetParent(parentRig);
//             ikNode.localPosition = Vector3.zero;
//         }

//         TwoBoneIKConstraint constraint = ikNode.GetComponent<TwoBoneIKConstraint>();
//         if (constraint == null) constraint = ikNode.gameObject.AddComponent<TwoBoneIKConstraint>();

//         // Find or create Target and Hint
//         target = ikNode.Find(name + "_Target");
//         if (target == null)
//         {
//             target = new GameObject(name + "_Target").transform;
//             target.SetParent(ikNode);
//             // Snap target to current hand pose
//             target.position = hand.position;
//             target.rotation = hand.rotation;
//         }

//         hint = ikNode.Find(name + "_Hint");
//         if (hint == null)
//         {
//             hint = new GameObject(name + "_Hint").transform;
//             hint.SetParent(ikNode);
//             // Snap hint roughly behind the elbow
//             Vector3 elbowDir = (lower.position - upper.position).normalized + (lower.position - hand.position).normalized;
//             hint.position = lower.position + elbowDir.normalized * 0.5f;
//         }

//         // Assign to constraint
//         constraint.data.root = upper;
//         constraint.data.mid = lower;
//         constraint.data.tip = hand;
//         constraint.data.target = target;
//         constraint.data.hint = hint;
//     }
// }
// #endif
