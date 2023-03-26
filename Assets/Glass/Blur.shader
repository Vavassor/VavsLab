Shader "Custom/Blur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Lighting Off
        Blend One Zero

        Pass
        {
            Name "HorizontalBlur"

            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0
            
            #include "Blur.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                return blur(_MainTex, _MainTex_TexelSize.xy, float2(1.0, 0.0), IN.localTexcoord.xy);
            }
            ENDCG
        }

        Pass
        {
            Name "VerticalBlur"

            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            #include "Blur.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                return blur(_MainTex, _MainTex_TexelSize.xy, float2(0.0, 1.0), IN.localTexcoord.xy);
            }
            ENDCG
        }
    }
}
