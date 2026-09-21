using UnityEngine;
using System.Linq;

public class SimpleLipSync : MonoBehaviour
{
    [Header("Face")]
    public SkinnedMeshRenderer skinnedMesh;
    public SkinnedMeshRenderer teethMesh;
    public AudioSource audioSource;
    public int mouthBlendShapeIndex = 0;

    [Header("Lip Sync Tuning")]
    public float maxMouthOpen = 100f;
    public float volumeSensitivity = 15f;

    private float currentAudioLevel;

    // External audio mode (from JavaScript/VAPI)
    private bool useExternalAudio = false;
    private float externalVolume = 0f;

    [System.Serializable]
    public class AudioData
    {
        public float volume;
        public float hf;
        public float lf;
        public float mf;
        public bool isSpeaking;
    }

    public void ReceiveAudioLevel(string jsonData)
    {
        useExternalAudio = true;
        AudioData data = JsonUtility.FromJson<AudioData>(jsonData);
        externalVolume = data.volume;
    }

    public void SetAvatarState(string state)
    {
        Debug.Log("[Avatar] State: " + state);
        // Drive hand gestures via InterviewHandGestures script
        var gestures = GetComponent<InterviewHandGestures>();
        if (gestures != null)
            gestures.SetSpeaking(state == "speaking");
    }

    void Start()
    {
        #if UNITY_WEBGL && !UNITY_EDITOR
        if (audioSource != null)
        {
            audioSource.playOnAwake = false;
            audioSource.Stop();
        }
        #endif
    }

    void Update()
    {
        if (skinnedMesh == null) return;

        float targetAudioLevel = 0f;

        if (useExternalAudio)
        {
            targetAudioLevel = Mathf.Clamp01(externalVolume * volumeSensitivity);
        }
        else
        {
            if (audioSource == null) return;
            if (audioSource.isPlaying)
            {
                float[] samples = new float[256];
                try
                {
                    audioSource.GetOutputData(samples, 0);
                    float loudness = samples.Select(Mathf.Abs).Average();
                    targetAudioLevel = Mathf.Clamp01(loudness * volumeSensitivity);
                }
                catch { return; }
            }
        }

        if (targetAudioLevel > currentAudioLevel)
            currentAudioLevel = Mathf.Lerp(currentAudioLevel, targetAudioLevel, Time.deltaTime * 25f);
        else
            currentAudioLevel = Mathf.Lerp(currentAudioLevel, targetAudioLevel, Time.deltaTime * 8f);

        // Only lip sync — arm gestures handled by InterviewHandGestures
        AnimateMouth(currentAudioLevel);
    }

    void AnimateMouth(float audioLevel)
    {
        float mouthTarget = audioLevel * maxMouthOpen;
        float smoothMouth = Mathf.Lerp(
            skinnedMesh.GetBlendShapeWeight(mouthBlendShapeIndex),
            mouthTarget, Time.deltaTime * 15f);
        skinnedMesh.SetBlendShapeWeight(mouthBlendShapeIndex, smoothMouth);
        if (teethMesh != null)
            teethMesh.SetBlendShapeWeight(mouthBlendShapeIndex, smoothMouth);
    }
}
