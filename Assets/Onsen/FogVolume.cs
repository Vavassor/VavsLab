
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class FogVolume : UdonSharpBehaviour
{
    public Color fogColor;
    public float fogDensity;

    private Collider triggerCollider;
    private bool isInVolume;

    public override void OnPlayerTriggerStay(VRCPlayerApi playerApi)
    {
        Vector3 playerHeadPosition = playerApi.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
        if (triggerCollider.bounds.Contains(playerHeadPosition))
        {
            isInVolume = true;
        }
    }

    void Start()
    {
        triggerCollider = GetComponent<BoxCollider>();
    }

    void Update()
    {
        if (isInVolume)
        {
            RenderSettings.fog = true;
            RenderSettings.fogColor = fogColor;
            RenderSettings.fogDensity = fogDensity;
        }
        else
        {
            RenderSettings.fog = false;
        }

        isInVolume = false;
    }
}
