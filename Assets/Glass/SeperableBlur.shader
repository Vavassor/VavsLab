// Based on the blur from this blog post.
// https://blogs.unity3d.com/2015/02/06/extending-unity-5-rendering-pipeline-command-buffers/
Shader "CustomRenderTexture/SeparableBlur"
{
    Properties
    {
        _MainTex("InputTex", 2D) = "white" {}
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

            sampler2D _MainTex;

            float4 _Offsets;

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
                float2 uv = IN.localTexcoord.xy;
                float4 uv01 = IN.localTexcoord.xyxy + _Offsets.xyxy * float4(1.0, 1.0, -1.0, -1.0);
                float4 uv23 = IN.localTexcoord.xyxy + _Offsets.xyxy * float4(1.0, 1.0, -1.0, -1.0) * 2.0;
                float4 uv45 = IN.localTexcoord.xyxy + _Offsets.xyxy * float4(1.0, 1.0, -1.0, -1.0) * 3.0;

                half4 color = half4(0.0, 0.0, 0.0, 0.0);

                color += 0.4 * tex2D(_MainTex, uv);
                color += 0.15 * tex2D(_MainTex, uv01.xy);
                color += 0.15 * tex2D(_MainTex, uv01.zw);
                color += 0.1 * tex2D(_MainTex, uv23.xy);
                color += 0.1 * tex2D(_MainTex, uv23.zw);
                color += 0.05 * tex2D(_MainTex, uv45.xy);
                color += 0.05 * tex2D(_MainTex, uv45.zw);

                return color;
            }
            ENDCG
        }
    }
}