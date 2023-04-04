
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Trail : UdonSharpBehaviour
{
    public AudioClip swing;

    private AudioSource audioSource;
    private TrailRenderer trailRenderer;

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        trailRenderer = GetComponent<TrailRenderer>();
    }

    public void OnMotionEnd()
    {
        trailRenderer.emitting = false;
    }

    public void OnMotionStart()
    {
        trailRenderer.emitting = true;

        if (audioSource != null)
        {
            audioSource.PlayOneShot(swing);
        }
    }
}
