Shader "Custom/Interactive Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _DisplacementAmount("Displacement Amount", Range(0, 1)) = 0.2
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _TangentMultiplier ("Tangent Multiplier", Range(0.001, 50.0)) = 0.1
        _WaterSizeX("Water Size Y", float) = 4.0
        _WaterSizeY("Water Size X", float) = 8.0
        _WaveTexture("Wave Texture (RG)", 2D) = "black" {}
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert alpha:auto

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _WaveTexture;
        float4 _WaveTexture_TexelSize;
        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        fixed4 _Color;
        half _DisplacementAmount;
        half _Glossiness;
        half _Metallic;
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
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
