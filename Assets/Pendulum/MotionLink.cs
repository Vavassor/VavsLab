
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public enum TriggerType
{
    Acceleration,
    Velocity,
}

public enum EntryType
{
    Player = 0,
    TrackingDataHead = 1,
    TrackingDataLeftHand = 2,
    TrackingDataRightHand = 3
}

public class MotionLink : UdonSharpBehaviour
{
    private const float motionLinkVersion = 1.0f;

    public float accelerationThreshold = 200.0f;
    public float emissionDurationSeconds = 0.2f;
    public Material motionLinkMaterial;
    public CustomRenderTexture motionLinkTexture;
    public TriggerType triggerType = TriggerType.Acceleration;
    public float velocityThreshold = 7.0f;
    public UdonBehaviour[] triggerTargets;

    private bool arePropIdsInitialized = false;
    private readonly Vector3[] points = new Vector3[3];
    private float priorDeltaTime = 0.016f;
    private float secondsSinceTrigger = 0.0f;
    private bool wasTriggerActive = false;

    private Vector3[] priorPositions = new Vector3[4];
    private Quaternion[] priorRotations = new Quaternion[4];
    private Vector3[] priorVelocities = new Vector3[4];
    private VRCPlayerApi playerApi;
    private readonly float[] motionData = new float[4 * 4 * 63];

    private int motionDataPropId;
    private int motionTexturePropId;
    private int versionPropId;

    void OnDisable()
    {
        motionLinkTexture.updateMode = CustomRenderTextureUpdateMode.OnDemand;
        VRCShader.SetGlobalTexture(motionTexturePropId, null);
    }

    void OnEnable()
    {
        InitializePropIds();
        motionLinkTexture.updateMode = CustomRenderTextureUpdateMode.Realtime;
        VRCShader.SetGlobalTexture(motionTexturePropId, motionLinkTexture);
    }

    void Start()
    {
        for (var i = 0; i < points.Length; i++)
        {
            points[i] = transform.position;
        }

        playerApi = Networking.LocalPlayer;
    }

    void Update()
    {
        UpdateTrigger();
        UpdateEntries();
        SendMotionData();

        priorDeltaTime = Time.deltaTime;
    }

    private Vector3 GetAngularVelocity(Quaternion q0, Quaternion q1, float deltaTime)
    {
        var qw = q1 * Quaternion.Inverse(q0);
        float angle = 0.0f;
        Vector3 axis = Vector3.zero;
        qw.ToAngleAxis(out angle, out axis);
        var w = (angle / deltaTime) * axis;
        return w;
    }

    private VRCPlayerApi.TrackingDataType GetTrackingDataType(EntryType entryType)
    {
        switch (entryType)
        {
            default:
            case EntryType.TrackingDataHead:
                return VRCPlayerApi.TrackingDataType.Head;
            case EntryType.TrackingDataLeftHand:
                return VRCPlayerApi.TrackingDataType.LeftHand;
            case EntryType.TrackingDataRightHand:
                return VRCPlayerApi.TrackingDataType.RightHand;
        }
    }

    private void InitializePropIds()
    {
        if (arePropIdsInitialized)
        {
            return;
        }

        motionDataPropId = VRCShader.PropertyToID("_MotionData");
        motionTexturePropId = VRCShader.PropertyToID("_UdonMotionLinkTexture");
        versionPropId = VRCShader.PropertyToID("_Version");

        arePropIdsInitialized = true;
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

    private void SendMotionData()
    {
        motionLinkMaterial.SetVector(versionPropId, new Vector4(motionLinkVersion, 0.0f, 0.0f, 0.0f));
        motionLinkMaterial.SetFloatArray(motionDataPropId, motionData);
    }

    private void UpdateEntry(EntryType entryType, Vector3 position, Quaternion rotation)
    {
        var entryIndex = (int) entryType;
        var priorPosition = priorPositions[entryIndex];
        var priorRotation = priorRotations[entryIndex];
        var priorVelocity = priorVelocities[entryIndex];

        var velocity = (position - priorPosition) / Time.deltaTime;
        var angularVelocity = GetAngularVelocity(rotation, priorRotation, Time.deltaTime);
        var acceleration = (velocity - priorVelocity) / Time.deltaTime;

        SetMotionData(entryIndex, 0, position);
        SetMotionData(entryIndex, 1, velocity);
        SetMotionData(entryIndex, 2, acceleration);
        SetMotionData(entryIndex, 3, angularVelocity);

        priorPositions[entryIndex] = position;
        priorRotations[entryIndex] = rotation;
        priorVelocities[entryIndex] = velocity;
    }

    private void SetMotionData(int entryIndex, int texelIndex, Vector3 value)
    {
        int index = 4 * 4 * texelIndex + 4 * entryIndex;
        motionData[index] = value.x;
        motionData[index + 1] = value.y;
        motionData[index + 2] = value.z;
        motionData[index + 3] = 0.0f;
    }

    private void UpdateEntries()
    {
        UpdatePlayerEntry();
        UpdateTrackingDataEntry(EntryType.TrackingDataHead);
        UpdateTrackingDataEntry(EntryType.TrackingDataLeftHand);
        UpdateTrackingDataEntry(EntryType.TrackingDataRightHand);
    }

    private void UpdatePlayerEntry()
    {
        var position = playerApi.GetPosition();
        var rotation = playerApi.GetRotation();
        UpdateEntry(EntryType.Player, position, rotation);
    }

    private void UpdateTrackingDataEntry(EntryType entryType)
    {
        var trackingDataType = GetTrackingDataType(entryType);
        var trackingData = playerApi.GetTrackingData(trackingDataType);
        UpdateEntry(entryType, trackingData.position, trackingData.rotation);
    }

    private void UpdateTrigger()
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
    }
}
