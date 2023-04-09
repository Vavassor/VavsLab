
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class Trail : UdonSharpBehaviour
{
    public GameObject motionSensorObject;
    public AudioClip swing;
    public Toggle enablePlayerTrailToggle;

    private AudioSource audioSource;
    private MotionSensor motionSensor;
    private TrailRenderer[] trailRenderers;

    void Start()
    {
        if (motionSensorObject == null)
        {
            motionSensorObject = gameObject;
        }

        audioSource = GetComponent<AudioSource>();
        trailRenderers = GetComponentsInChildren<TrailRenderer>();
        motionSensor = motionSensorObject.GetComponent<MotionSensor>();

        foreach (var trailRenderer in trailRenderers)
        {
            trailRenderer.emitting = false;
        }
    }

    public void OnMotionEnd()
    {
        foreach (var trailRenderer in trailRenderers)
        {
            trailRenderer.emitting = false;
        }
    }

    public void OnMotionStart()
    {
        foreach (var trailRenderer in trailRenderers)
        {
            trailRenderer.emitting = true;
        }

        if (audioSource != null)
        {
            audioSource.PlayOneShot(swing);
        }
    }

    public void OnMotionUpdate()
    {
        var position = (Vector3) motionSensor.GetProgramVariable("currentPosition");
        var rotation = (Quaternion) motionSensor.GetProgramVariable("currentRotation");
        transform.SetPositionAndRotation(position, rotation);
    }

    public void OnEnablePlayerTrailChanged()
    {
        if (enablePlayerTrailToggle.isOn)
        {
            motionSensor.targetType = TargetType.TrackingDataRightHand;
        }
        else
        {
            motionSensor.targetType = TargetType.Object;
        }
    }
}
