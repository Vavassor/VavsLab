Shader "Custom/Glass2"
{
    Properties
    {
        _Factor("Factor", Range(0, 5)) = 1.0
        _MaskTexture("Mask", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite off

        GrabPass { }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 texcoord : TEXCOORD1;
            };

            sampler2D _GrabTexture;
            sampler2D _MaskTexture;
            float4 _GrabTexture_TexelSize;
            float4 _MaskTexture_ST;
            float _Factor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.pos);
                o.texcoord = TRANSFORM_TEX(v.uv, _MaskTexture);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {

                half4 pixelCol = half4(0, 0, 0, 0);

                #define ADDPIXEL(weight,kernelX) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.uv.x + _GrabTexture_TexelSize.x * kernelX * _Factor, i.uv.y, i.uv.z, i.uv.w))) * weight

                pixelCol += ADDPIXEL(0.05, 4.0);
                pixelCol += ADDPIXEL(0.09, 3.0);
                pixelCol += ADDPIXEL(0.12, 2.0);
                pixelCol += ADDPIXEL(0.15, 1.0);
                pixelCol += ADDPIXEL(0.18, 0.0);
                pixelCol += ADDPIXEL(0.15, -1.0);
                pixelCol += ADDPIXEL(0.12, -2.0);
                pixelCol += ADDPIXEL(0.09, -3.0);
                pixelCol += ADDPIXEL(0.05, -4.0);

                float mask = tex2D(_MaskTexture, i.texcoord).x;
                pixelCol.a = mask;

                return pixelCol;
            }
            ENDCG
        }

        GrabPass { }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 texcoord : TEXCOORD1;
            };

            sampler2D _GrabTexture;
            sampler2D _MaskTexture;
            float4 _GrabTexture_TexelSize;
            float4 _MaskTexture_ST;
            float _Factor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeGrabScreenPos(o.pos);
                o.texcoord = TRANSFORM_TEX(v.uv, _MaskTexture);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 pixelCol = fixed4(0, 0, 0, 1);

                #define ADDPIXEL(weight,kernelY) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.uv.x, i.uv.y + _GrabTexture_TexelSize.y * kernelY * _Factor, i.uv.z, i.uv.w))) * weight

                pixelCol += ADDPIXEL(0.05, 4.0);
                pixelCol += ADDPIXEL(0.09, 3.0);
                pixelCol += ADDPIXEL(0.12, 2.0);
                pixelCol += ADDPIXEL(0.15, 1.0);
                pixelCol += ADDPIXEL(0.18, 0.0);
                pixelCol += ADDPIXEL(0.15, -1.0);
                pixelCol += ADDPIXEL(0.12, -2.0);
                pixelCol += ADDPIXEL(0.09, -3.0);
                pixelCol += ADDPIXEL(0.05, -4.0);

                float mask = tex2D(_MaskTexture, i.texcoord).x;
                pixelCol.a *= mask;
                pixelCol.rgb += 0.05;

                return pixelCol;
            }
            ENDCG
        }
    }
}