Shader "Unlit/Debug Motion"
{
    Properties
    {
        _AttributeIndex("Attribute Index", float) = 0.0
        _EntryIndex("Entry Index", float) = 0.0
        _MaxValue("Max Value", float) = 1.0
        [Toggle] _Show_Magnitude("Show magnitude", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile __ _SHOW_MAGNITUDE_ON

            #include "UnityCG.cginc"
            #include "MotionLink.cginc"

            half _AttributeIndex;
            half _EntryIndex;
            float _MaxValue;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _UdonMotionLinkTexture);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float texcoord = _UdonMotionLinkTexture_TexelSize.xy * float2(_AttributeIndex, _EntryIndex);
                fixed4 col = tex2D(_UdonMotionLinkTexture, texcoord);
                col.rgb = saturate((col.rgb + _MaxValue) / (2.0 * _MaxValue));

                #ifdef _SHOW_MAGNITUDE_ON
                col.rgb = length(col.rgb);
                #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
