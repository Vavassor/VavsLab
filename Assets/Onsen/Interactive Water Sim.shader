Shader "Custom/Interactive Water Sim"
{
    Properties
    {
        _Alpha("Alpha", float) = 0.5
        _Amplitude("Amplitude", float) = 0.5
        _CollisionTexturePrior("Collision Texture Prior", 2D) = "white" {}
        _CollisionTexture("Collision Texture", 2D) = "white" {}
        _WaveTexturePrior("Wave Texture Prior", 2D) = "white" {}
        _WaveTexture("Wave Texture", 2D) = "white" {}
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

            half _Alpha;
            half _Amplitude;
            uniform sampler2D _CollisionTexture;
            uniform sampler2D _CollisionTexturePrior;
            uniform sampler2D _WaveTexture;
            uniform sampler2D _WaveTexturePrior;
            float4 _WaveTexture_TexelSize;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float4 z = _Alpha * (tex2D(_WaveTexture, IN.localTexcoord + float2(_WaveTexture_TexelSize.x, 0.0))
                    + tex2D(_WaveTexture, IN.localTexcoord - float2(_WaveTexture_TexelSize.x, 0.0))
                    + tex2D(_WaveTexture, IN.localTexcoord + float2(0.0, _WaveTexture_TexelSize.y))
                    + tex2D(_WaveTexture, IN.localTexcoord - float2(0.0, _WaveTexture_TexelSize.y)))
                    + (2.0 - 4.0 * _Alpha) * tex2D(_WaveTexture, IN.localTexcoord) - tex2D(_WaveTexturePrior, IN.localTexcoord);

                float zNewPos = z.r;
                float zNewNeg = z.g;

                float collisionStatePrior = tex2D(_CollisionTexturePrior, IN.localTexcoord).x;
                float collisionState = tex2D(_CollisionTexture, IN.localTexcoord).x;

                if (collisionState > 0.0f && collisionStatePrior == 0.0f)
                {
                    zNewPos = _Amplitude * collisionState;
                }
                else if (collisionState == 0.0f && collisionStatePrior > 0.0f)
                {
                    zNewNeg = _Amplitude * collisionStatePrior;
                }

                return float4(zNewPos, zNewNeg, 0.0, 0.0);
            }
            ENDCG
        }
    }
}
