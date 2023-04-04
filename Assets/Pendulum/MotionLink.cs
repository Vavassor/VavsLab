
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public enum TriggerType
{
    Acceleration,
    Velocity,
}

public enum TargetType
{
    Player = 0,
    TrackingDataHead = 1,
    TrackingDataLeftHand = 2,
    TrackingDataRightHand = 3
}

public class MotionLink : UdonSharpBehaviour
{
    public float accelerationThreshold = 200.0f;
    public float emissionDurationSeconds = 0.2f;
    public TriggerType triggerType = TriggerType.Acceleration;
    public float velocityThreshold = 7.0f;
    public UdonBehaviour[] triggerTargets;

    private readonly Vector3[] points = new Vector3[3];
    private float priorDeltaTime = 0.016f;
    private float secondsSinceTrigger = 0.0f;
    private bool wasTriggerActive = false;

    void Start()
    {
        for (var i = 0; i < points.Length; i++)
        {
            points[i] = transform.position;
        }
    }

    void Update()
    {
        points[2] = points[1];
        points[1] = points[0];
        points[0] = transform.position;

        bool isTriggerActive = wasTriggerActive;

        if (Time.deltaTime != 0.0f && priorDeltaTime != 0.0f)
        {
            var velocity = (points[1] - points[0]).magnitude / Time.deltaTime;
            var priorVelocity = (points[2] - points[1]).magnitude / priorDeltaTime;
            var acceleration = Mathf.Abs(velocity - priorVelocity) / Time.deltaTime;
            isTriggerActive = IsTriggerActive(acceleration, velocity);
        }

        if (isTriggerActive)
        {
            if (!wasTriggerActive)
            {
                SendEventsToTargets("OnMotionStart");
                wasTriggerActive = true;
            }

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
        }


        priorDeltaTime = Time.deltaTime;
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
}
