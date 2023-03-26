Shader "Custom/Debug Depth" {
    Properties
    {
        _DepthTexture("Depth Texture", 2D) = "white" {}
        _FarPlane("Far Plane", float) = 1000.0
        _NearPlane("Near Plane", float) = 0.3
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _FarPlane;
            float _NearPlane;
            sampler2D _DepthTexture;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                return o;
            }

            inline float linearizeDepth(float depth, float near, float far)
            {
                float ratio = far / near;
#if UNITY_REVERSED_Z == 1
                return 1.0 / ((ratio - 1.0) * depth + 1.0);
#else
                return 1.0 / ((1.0 - ratio) * depth + ratio);
#endif
            }

            half4 frag(v2f i) : SV_Target
            {
                float depth = tex2D(_DepthTexture, i.uv).r;
                float color = linearizeDepth(depth, _NearPlane, _FarPlane);
                return half4(color, color, color, 1.0);
            }
            ENDCG
        }
    }
}
