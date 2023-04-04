
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Motor : UdonSharpBehaviour
{
    public float minVelocity = 450.0f;
    public float velocityRange = 200.0f;

    private HingeJoint hingeJoint;
    private JointMotor jointMotor;

    void Start()
    {
        hingeJoint = GetComponent<HingeJoint>();
        jointMotor = hingeJoint.motor;
    }

    void Update()
    {
        var waveNorm = 0.5f * Mathf.Sin(0.4f * Time.time) + 0.5f;
        jointMotor.targetVelocity = velocityRange * waveNorm + minVelocity;
        hingeJoint.motor = jointMotor;
    }
}
