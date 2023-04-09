
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public enum TargetType
{
    Object = 0,
    Player = 1,
    TrackingDataHead = 2,
    TrackingDataLeftHand = 3,
    TrackingDataRightHand = 4,
}

public enum TriggerType
{
    Acceleration,
    Velocity,
}

public class MotionSensor : UdonSharpBehaviour
{
    public float accelerationThreshold = 200.0f;
    public float emissionDurationSeconds = 0.2f;
    public Vector3 currentPosition;
    public Quaternion currentRotation;
    public GameObject targetObject;
    public TargetType targetType = TargetType.Object;
    public UdonBehaviour[] triggerTargets;
    public TriggerType triggerType = TriggerType.Acceleration;
    public float velocityThreshold = 7.0f;

    private VRCPlayerApi localPlayer;
    private Vector3 priorPosition;
    private Quaternion priorRotation;
    private Vector3 priorVelocity;
    private float secondsSinceTrigger = 0.0f;
    private bool wasTriggerActive = false;

    void Start()
    {
        GetTransform(out Vector3 position, out Quaternion rotation);
        priorPosition = position;
        priorRotation = rotation;
        priorVelocity = Vector3.zero;

        localPlayer = Networking.LocalPlayer;
    }

    void Update()
    {
        UpdateTrigger();
    }

    private void GetTransform(out Vector3 position, out Quaternion rotation)
    {
        switch (targetType)
        {
            default:
            case TargetType.Object:
            {
                position = targetObject.transform.position;
                rotation = targetObject.transform.rotation;
                break;
            }
            case TargetType.Player:
            {
                position = localPlayer.GetPosition();
                rotation = localPlayer.GetRotation();
                break;
            }
            case TargetType.TrackingDataHead:
            {
                var trackingData = localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head);
                position = trackingData.position;
                rotation = trackingData.rotation;
                break;
            }
            case TargetType.TrackingDataLeftHand:
            {
                var trackingData = localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.LeftHand);
                position = trackingData.position;
                rotation = trackingData.rotation;
                break;
            }
            case TargetType.TrackingDataRightHand:
            {
                var trackingData = localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.RightHand);
                position = trackingData.position;
                rotation = trackingData.rotation;
                break;
            }
        }
    }

    private bool IsTriggerActive(float acceleration, float velocity)
    {
        switch (triggerType)
        {
            default:
            case TriggerType.Acceleration:
                return acceleration >= accelerationThreshold;
            case TriggerType.Velocity:
                return velocity >= velocityThreshold;
        }
    }

    private void SendEventsToTargets(string eventName)
    {
        if (triggerTargets != null)
        {
            foreach (var target in triggerTargets)
            {
                target.SendCustomEvent(eventName);
            }
        }
    }

    private void UpdateTrigger()
    {
        GetTransform(out currentPosition, out currentRotation);

        bool isTriggerActive = wasTriggerActive;

        if (Time.deltaTime != 0.0f)
        {
            var velocity = (priorPosition - currentPosition) / Time.deltaTime;
            var acceleration = (velocity - priorVelocity) / Time.deltaTime;
            isTriggerActive = IsTriggerActive(acceleration.magnitude, velocity.magnitude);

            priorPosition = currentPosition;
            priorRotation = currentRotation;
            priorVelocity = velocity;
        }

        if (isTriggerActive)
        {
            if (!wasTriggerActive)
            {
                SendEventsToTargets("OnMotionStart");
                wasTriggerActive = true;
            }

            SendEventsToTargets("OnMotionUpdate");

            secondsSinceTrigger = emissionDurationSeconds;
        }
        else
        {
            secondsSinceTrigger -= Time.deltaTime;

            if (wasTriggerActive && secondsSinceTrigger <= 0.0f)
            {
                SendEventsToTargets("OnMotionEnd");
                wasTriggerActive = false;
            }
            else
            {
                SendEventsToTargets("OnMotionUpdate");
            }
        }
    }
}
