Shader "Custom/Paint"
{
    Properties
    {
        _DecayRate("Decay Rate", float) = 0.995
        _DepthTexture("Depth Texture", 2D) = "white" {}
        _FarPlane("Far Plane", float) = 1000.0
        _NearPlane("Near Plane", float) = 0.3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            sampler2D _DepthTexture;
            float4 _DepthTexture_ST;
            float _DecayRate;
            float _FarPlane;
            float _NearPlane;

            inline float linearizeDepth(float depth, float near, float far)
            {
                float ratio = far / near;
#if UNITY_REVERSED_Z == 1
                return 1.0 / ((ratio - 1.0) * depth + 1.0);
#else
                return 1.0 / ((1.0 - ratio) * depth + ratio);
#endif
            }

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float paintColor = 1.0 - linearizeDepth(tex2D(_DepthTexture, IN.localTexcoord.xy).x, _NearPlane, _FarPlane);
                fixed4 priorColor = tex2D(_SelfTexture2D, IN.localTexcoord.xy);

                priorColor.rgb *= _DecayRate;

                fixed4 color;
                color.rgb = min(priorColor.rgb + paintColor.xxx, 1.0);
                color.a = 1.0;

                return color;
            }
            ENDCG
        }
    }
}
