// Based on Wave Equation example by Amanda Ghassaei
// https://github.com/amandaghassaei/gpu-io/tree/main/examples/wave2d
Shader "Custom/Refract Light"
{
    Properties
    {
        _HeightMap("Height", 2D) = "white" {}
        _Separation("Separation", Range(0.1, 100)) = 50
    }
    SubShader
    {
        Lighting Off
        Blend One Zero

        Pass
        {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            sampler2D _HeightMap;
            float4 _HeightMap_TexelSize;

            half _Separation;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                // Calculate a normal vector for height field.
                float2 onePxX = float2(_HeightMap_TexelSize.x, 0.0);
                float2 onePxY = float2(0.0, _HeightMap_TexelSize.y);
                float center = tex2D(_HeightMap, IN.localTexcoord).x;
                float n = tex2D(_HeightMap, IN.localTexcoord + onePxY).x;
                float s = tex2D(_HeightMap, IN.localTexcoord - onePxY).x;
                float e = tex2D(_HeightMap, IN.localTexcoord + onePxX).x;
                float w = tex2D(_HeightMap, IN.localTexcoord - onePxX).x;
                float2 normalXY = float2(w - e, s - n) / 2.0;
                // Clip normal amplitude to prevent triangle overlap / issues with triangle rendering order.
                normalXY *= min(0.0075 / length(normalXY), 1.0);
                float3 normal = normalize(float3(normalXY, 1.0));

                const float3 incident = float3(0.0, 0.0, -1.0);
                // 1 / 1.33 (0.75188) is the Air refractive index / water refractive index.
                float3 refractVector = refract(incident, normal, 0.75188);
                refractVector.xy /= abs(refractVector.z);

                // Render this out slightly smaller so we can see raw edge of caustic pattern.
                // Also add a scaling factor of 0.15 to reduce caustic distortion.
                float2 position = (0.9 * (IN.localTexcoord + refractVector.xy * _Separation * 0.15) + 0.05) * _HeightMap_TexelSize.zw;

                return float4(position.xy, 0.0, 0.0);
            }
            ENDCG
        }
    }
}
