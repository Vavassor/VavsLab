Shader "Custom/Glass3"
{
    Properties
    {
        _BrightnessIncrease("Brightness Increase", float) = 0.2
        _DistortionTexture("Distortion", 2D) = "white" {}
        _Factor("Factor", Range(0, 5)) = 1.0
        _Glossiness("Smoothness", Range(0,1)) = 0.5
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

            sampler2D _DistortionTexture;
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

                float mask = 1.0 - tex2D(_MaskTexture, i.texcoord).x;
                float distortion = 0.9 + tex2D(_DistortionTexture, i.texcoord).x;
                pixelCol.a = max(saturate(mask * distortion), 0.05);

                return pixelCol;
            }
            ENDCG
        }

        GrabPass { }

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha:auto vertex:vert
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float4 grabTexcoord;
        };

            half _BrightnessIncrease;
        sampler2D _DistortionTexture;
        sampler2D _GrabTexture;
        sampler2D _MaskTexture;
        float4 _GrabTexture_TexelSize;
        float4 _MaskTexture_ST;
        float _Factor;
        half _Glossiness;

        inline float linearizeDepth(float depth, float near, float far)
        {
            float ratio = far / near;
            return 1.0 / ((1.0 - ratio) * depth + ratio);
        }

        void vert(inout appdata_full v, out Input data) {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.grabTexcoord = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 pixelCol = fixed4(0, 0, 0, 1);
            float4 uv = IN.grabTexcoord;

            #define ADDPIXEL(weight,kernelY) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(uv.x, uv.y + _GrabTexture_TexelSize.y * kernelY * _Factor, uv.z, uv.w))) * weight

            pixelCol += ADDPIXEL(0.05, 4.0);
            pixelCol += ADDPIXEL(0.09, 3.0);
            pixelCol += ADDPIXEL(0.12, 2.0);
            pixelCol += ADDPIXEL(0.15, 1.0);
            pixelCol += ADDPIXEL(0.18, 0.0);
            pixelCol += ADDPIXEL(0.15, -1.0);
            pixelCol += ADDPIXEL(0.12, -2.0);
            pixelCol += ADDPIXEL(0.09, -3.0);
            pixelCol += ADDPIXEL(0.05, -4.0);

            float mask = 1.0 - tex2D(_MaskTexture, IN.uv_MainTex).x;
            float distortion = 0.9 + tex2D(_DistortionTexture, IN.uv_MainTex).x;
            pixelCol.a = saturate(mask * distortion);
            
            o.Albedo = pixelCol.rgb + _BrightnessIncrease;
            o.Alpha = max(pixelCol.a, 0.05);
            o.Smoothness = _Glossiness;
        }

        ENDCG

        /*
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

            sampler2D _DistortionTexture;
            sampler2D _GrabTexture;
            sampler2D _MaskTexture;
            float4 _GrabTexture_TexelSize;
            float4 _MaskTexture_ST;
            float _Factor;

            inline float linearizeDepth(float depth, float near, float far)
            {
                float ratio = far / near;
                return 1.0 / ((1.0 - ratio) * depth + ratio);
            }

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

                float mask = 1.0 - tex2D(_MaskTexture, i.texcoord).x;
                float distortion = 0.9 + tex2D(_DistortionTexture, i.texcoord).x;
                pixelCol.a = saturate(mask * distortion);
                pixelCol.rgb += 0.05;

                return pixelCol;
            }
            ENDCG
        }
        */
    }
}