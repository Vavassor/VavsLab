Shader "Custom/Interactive Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 2
        _DisplacementAmount("Displacement Amount", Range(0, 1)) = 0.2
        _FogColor("Fog Color", Color) = (1,1,1,1)
        _FogThreshold("Fog threshold", float) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _TangentMultiplier ("Tangent Multiplier", Range(0.001, 50.0)) = 0.1
        _WaterSizeX("Water Size Y", float) = 4.0
        _WaterSizeY("Water Size X", float) = 8.0
        _WaveTexture("Wave Texture (RG)", 2D) = "black" {}
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent"  "IgnoreProjector" = "True" }
        LOD 200
        Cull [_CullMode]

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert alpha:auto fullforwardshadows addshadow 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
        sampler2D _WaveTexture;
        float4 _WaveTexture_TexelSize;

        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
            half VFace : VFACE;
        };

        fixed4 _Color;
        half _DisplacementAmount;
        fixed4 _FogColor;
        half _FogThreshold;
        half _Glossiness;
        half _TangentMultiplier;
        half _WaterSizeX;
        half _WaterSizeY;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float getOffset(float3 position)
        {
            float2 texelSize = float2(1.0 / _WaterSizeX, 1.0 / _WaterSizeY);
            float4 texcoord = float4(texelSize * -position.xz, 0.0, 0.0);
            texcoord.xy = 1.0 - texcoord.yx;
            float2 wave = tex2Dlod(_WaveTexture, texcoord).xy;
            return _DisplacementAmount * (wave.x - wave.y);
        }

        // From: https://github.com/cnlohr/shadertrixx/blob/main/README.md
        inline bool isInMirror()
        {
            return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
        }

        void vert(inout appdata_full v)
        {
            v.vertex.y = getOffset(v.vertex);

            float3 posPlusTangent = v.vertex + v.tangent * _TangentMultiplier;
            posPlusTangent.y = getOffset(posPlusTangent);
            float3 bitangent = cross(v.normal, v.tangent);

            float3 posPlusBitangent = v.vertex + bitangent * _TangentMultiplier;
            posPlusBitangent.y = getOffset(posPlusBitangent);

            float3 modifiedTangent = posPlusTangent - v.vertex;
            float3 modifiedBitangent = posPlusBitangent - v.vertex;
            float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
            v.normal = normalize(modifiedNormal);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float depth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            depth = LinearEyeDepth(depth);
            float surfaceDepth = isInMirror() ? 1.0 : UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z);

            float fogFade = saturate(exp2(-_FogThreshold * (depth - surfaceDepth)));
            fogFade = saturate(IN.VFace + 1.5) * fogFade;
            fixed4 c = lerp(_FogColor, _Color, fogFade);

            o.Albedo = c.rgb;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
