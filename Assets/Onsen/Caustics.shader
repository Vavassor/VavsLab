// Based on Wave Equation example by Amanda Ghassaei
// https://github.com/amandaghassaei/gpu-io/tree/main/examples/wave2d
Shader "Custom/Caustics"
{
    Properties
    {
        _LightMesh("Light Mesh", 2D) = "white" {}
        _ScalingFactor("Scaling Factor", Range(0, 1)) = 0.2
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

            sampler2D _LightMesh;
            float4 _LightMesh_TexelSize;
            half _ScalingFactor;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                // Calculate change in area.
                // https://medium.com/@evanwallace/rendering-realtime-caustics-in-webgl-2a99a29a0b2c
                float2 texcoord = IN.localTexcoord;
                texcoord.y = 1.0 - texcoord.y;
                float2 position = tex2D(_LightMesh, texcoord).xy;
                float2 priorPosition = texcoord * _LightMesh_TexelSize.zw;
                float oldArea = length(ddx(position)) * length(ddy(position));
                float newArea = length(ddx(priorPosition)) * length(ddy(priorPosition));
                float amplitude = oldArea / newArea * _ScalingFactor;
                return float4(amplitude.xxx, 1);
            }
            ENDCG
        }
    }
}
