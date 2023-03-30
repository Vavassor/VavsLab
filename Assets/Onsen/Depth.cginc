#ifndef DEPTH_CGINC
#define DEPTH_CGINC

// From: https://github.com/cnlohr/shadertrixx/blob/main/README.md
//
// Inspired by Internal_ScreenSpaceeShadow implementation.  This was adapted by lyuma.
// This code can be found on google if you search for "computeCameraSpacePosFromDepthAndInvProjMat"
// Note: The output of this will still need to be adjusted.  It is NOT in world space units.
float GetLinearZFromZDepth_WorksWithMirrors(float zDepthFromMap, float2 screenUV)
{
	#if defined(UNITY_REVERSED_Z)
	zDepthFromMap = 1 - zDepthFromMap;
			
	// When using a mirror, the far plane is whack.  This just checks for it and aborts.
	if( zDepthFromMap >= 1.0 ) return _ProjectionParams.z;
	#endif

	float4 clipPos = float4(screenUV.xy, zDepthFromMap, 1.0);
	clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
	float4 camPos = mul(unity_CameraInvProjection, clipPos);
	return -camPos.z / camPos.w;
}

// Oblique projection fix for mirrors.
// See https://github.com/lukis101/VRCUnityStuffs/blob/master/Shaders/DJL/Overlays/WorldPosOblique.shader
#define PM UNITY_MATRIX_P

inline float4 CalculateFrustumCorrection()
{
    float x1 = -PM._31 / (PM._11 * PM._34);
    float x2 = -PM._32 / (PM._22 * PM._34);
    return float4(x1, x2, 0, PM._33 / PM._34 + x1 * PM._13 + x2 * PM._23);
}
inline float CorrectedLinearEyeDepth(float z, float B)
{
#if UNITY_REVERSED_Z
    if (z == 0.0)
        z = 0.0;
#else
    if (z == 1.0)
        z = 0.0;
#endif
    // default Unity is
    // return 1.0 / (_ZBufferParams.z * z + _ZBufferParams.w);
    return 1.0 / (z / PM._34 + B);
}

float2 getDepthUVs(float4 screenPos, float2 offset, float4 depthTextureTexelSize)
{
    float2 uv = (screenPos.xy + offset) / screenPos.w;
#if UNITY_UV_STARTS_AT_TOP
    if (depthTextureTexelSize.y < 0)
    {
        uv.y = 1 - uv.y;
    }
#endif
    return (floor(uv * depthTextureTexelSize.zw) + 0.5) * abs(depthTextureTexelSize.xy);
}

#endif // ifndef DEPTH_CGINC
