Shader "Unlit/Caustics Projection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Strength ("Strength", Range(0, 1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
        Blend DstColor One
        Cull Front
        ZTest Always
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Depth.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float2 screenPosition : TEXCOORD2;
            };

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Strength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // Save the clip space position so we can use it later.
                // This also handles situations where the Y is flipped.
                float2 suv = o.vertex * float2(0.5, 0.5 * _ProjectionParams.x);

                // Tricky, constants like the 0.5 and the second paramter
                // need to be premultiplied by o.vertex.w.
                o.screenPosition = TransformStereoScreenSpaceTex(suv + 0.5 * o.vertex.w, o.vertex.w);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 fullVectorFromEyeToGeometry = i.worldPos - _WorldSpaceCameraPos;
                float3 worldSpaceDirection = normalize(i.worldPos - _WorldSpaceCameraPos);

                // Compute projective scaling factor.
                // perspectiveFactor is 1.0 for the center of the screen, and goes above 1.0 toward the edges,
                // as the frustum extent is further away than if the zfar in the center of the screen
                // went to the edges.
                float perspectiveDivide = 1.0f / i.vertex.w;
                float perspectiveFactor = length(fullVectorFromEyeToGeometry * perspectiveDivide);

                // Calculate our UV within the screen (for reading depth buffer)
                float2 screenUV = i.screenPosition.xy * perspectiveDivide;
                float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                float eyeDepthWorld = GetLinearZFromZDepth_WorksWithMirrors(depthSample, screenUV) * perspectiveFactor;

                float3 worldPosEyeHitInDepthTexture = _WorldSpaceCameraPos + eyeDepthWorld * worldSpaceDirection;
                float3 positionOS = mul(unity_WorldToObject, float4(worldPosEyeHitInDepthTexture, 1.0)).xyz;
                float boundingBoxMask = all(step(positionOS, 0.5) * (1.0 - step(positionOS, -0.5)));

                fixed4 caustics = tex2D(_MainTex, frac(positionOS.xz + 0.5));

                fixed4 col = fixed4(_Strength * caustics * boundingBoxMask.xxx, 1.0);

                return col;
            }
            ENDCG
        }
    }
}
