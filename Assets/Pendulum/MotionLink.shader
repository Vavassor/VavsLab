Shader "Custom/MotionLink"
{
    Properties
    {
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

            #include "MotionLink.cginc"

            cbuffer MotionDataBuffer {
                float _MotionData[1008];
            };

            float4 _Version;

            inline float4 readVector(int index)
            {
                float4 v;
                v.x = _MotionData[index];
                v.y = _MotionData[index + 1];
                v.z = _MotionData[index + 2];
                v.w = _MotionData[index + 3];
                return v;
            }

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                uint x = IN.localTexcoord.x * _UdonMotionLinkTexture_TexelSize.z;
                uint y = IN.localTexcoord.y * _UdonMotionLinkTexture_TexelSize.w;
                if (x > 3 || y > 3) {
                    return float4(0.0, 0.0, 0.0, 1.0);
                }
                uint index = 4 * 4 * y + 4 * x;
                return readVector(index);
            }
            ENDCG
        }
    }
}
