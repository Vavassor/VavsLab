Shader "Custom/Caustics"
{
    Properties
    {
        _LightMesh("Light Mesh", 2D) = "white" {}
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
                float amplitude = oldArea / newArea * 0.2;
                return float4(amplitude.xxx, 1);
            }
            ENDCG
        }
    }
}
