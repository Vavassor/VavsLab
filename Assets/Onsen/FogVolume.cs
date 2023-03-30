
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class FogVolume : UdonSharpBehaviour
{
    public Color fogColor;
    public float fogDensity;
    public GameObject fogIndicator;

    private Collider triggerCollider;
    private int frameCount;
    private int lastFrameInTrigger;
    private bool isInVolume;
    private readonly int triggerResetThreshold = 2;

    public override void OnPlayerTriggerStay(VRCPlayerApi playerApi)
    {
        if (playerApi.IsValid() && playerApi.isLocal)
        {
            Vector3 playerHeadPosition = playerApi.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
            if (triggerCollider.bounds.Contains(playerHeadPosition))
            {
                if (!isInVolume)
                {
                    OnVolumeEnter();
                }

                lastFrameInTrigger++;
            }
            else if (isInVolume)
            {
                OnVolumeExit();
            }
        }
    }

    void Start()
    {
        triggerCollider = GetComponent<BoxCollider>();
    }

    void Update()
    {
        frameCount++;
        int framesSinceLastTrigger = frameCount - lastFrameInTrigger;

        if (isInVolume && framesSinceLastTrigger > triggerResetThreshold)
        {
            OnVolumeExit();
        }
    }

    private void OnVolumeEnter()
    {
        isInVolume = true;
        fogIndicator.SetActive(true);
        RenderSettings.fog = true;
        RenderSettings.fogColor = fogColor;
        RenderSettings.fogDensity = fogDensity;
    }

    private void OnVolumeExit()
    {
        isInVolume = false;
        fogIndicator.SetActive(false);
        RenderSettings.fog = false;
        lastFrameInTrigger = frameCount;
    }
}
