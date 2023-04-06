
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Pulse : UdonSharpBehaviour
{
    public Material material;

    private float animationTime = 0.0f;
    private float pulseTime = 0.0f;
    private float secondsSinceMotionStart = 0.0f;

    public void OnMotionStart()
    {
        pulseTime = 0.0f;
        secondsSinceMotionStart = 0.0f;
    }

    void Start()
    {

    }

    void Update()
    {
        material.SetFloat("_AnimationTime", animationTime);
        material.SetFloat("_PulseTime", pulseTime);

        animationTime += Time.deltaTime + (secondsSinceMotionStart < 0.3f ? 0.1f : 0f);
        pulseTime += Time.deltaTime + (secondsSinceMotionStart < 0.3f ? 0.02f : 0f);
        secondsSinceMotionStart += Time.deltaTime;
    }
}
