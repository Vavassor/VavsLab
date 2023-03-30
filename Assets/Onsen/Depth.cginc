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

#endif // ifndef DEPTH_CGINC
