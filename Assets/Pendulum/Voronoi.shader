
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// I've not seen anybody out there computing correct cell interior distances for Voronoi
// patterns yet. That's why they cannot shade the cell interior correctly, and why you've
// never seen cell boundaries rendered correctly. 
//
// However, here's how you do mathematically correct distances (note the equidistant and non
// degenerated grey isolines inside the cells) and hence edges (in yellow):
//
// https://iquilezles.org/articles/voronoilines
//
// More Voronoi shaders:
//
// Exact edges:  https://www.shadertoy.com/view/ldl3W8
// Hierarchical: https://www.shadertoy.com/view/Xll3zX
// Smooth:       https://www.shadertoy.com/view/ldB3zc
// Voronoise:    https://www.shadertoy.com/view/Xd23Dh
Shader "Unlit/Voronoi"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            #include "UnityCG.cginc"

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

            float _AnimationTime;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _PulseTime;

            float2 hash2(float2 p)
            {
                // texture based white noise
                // return textureLod(iChannel0, (p + 0.5) / 256.0, 0.0).xy;

                // procedural white noise	
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p, float2(269.5,183.3))))*43758.5453);
            }

            float3 voronoi(float2 x, float t)
            {
                float2 n = floor(x);
                float2 f = frac(x);

                //----------------------------------
                // first pass: regular voronoi
                //----------------------------------
                float2 mg;
                float2 mr;

                float md = 8.0;
                int j;
                for (j = -1; j <= 1; j++)
                {
                    for (int i = -1; i <= 1; i++)
                    {
                        float2 g = float2(float(i), float(j));
                        float2 o = hash2(n + g);

                        o = 0.5 + 0.5 * sin(t + 6.2831 * o);

                        float2 r = g + o - f;
                        float d = dot(r, r);

                        if (d < md)
                        {
                            md = d;
                            mr = r;
                            mg = g;
                        }
                    }
                }

                //----------------------------------
                // second pass: distance to borders
                //----------------------------------
                md = 8.0;
                for (j = -2; j <= 2; j++)
                {
                    for (int i = -2; i <= 2; i++)
                    {
                        float2 g = mg + float2(float(i), float(j));
                        float2 o = hash2(n + g);

                        o = 0.5 + 0.5 * sin(t + 6.2831 * o);

                        float2 r = g + o - f;

                        if (dot(mr - r, mr - r) > 0.00001)
                        {
                            md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
                        }
                    }
                }

                return float3(md, mr);
            }

            float cubicPulse(float c, float w, float x)
            {
                x = abs(x - c);
                if (x > w) return 0.0;
                x /= w;
                return 1.0 - x * x * (3.0 - 2.0 * x);
            }

            float ripple(float2 center, float2 texcoord, float time)
            {
                float2 radialDirection = texcoord - center;
                float dist = length(radialDirection);
                float circle = lerp(1.0, 0.1, min(2.5 * time, 1.0)) * cubicPulse(time, time * 0.5, dist);

                return circle;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 c = voronoi(8.0 * i.uv, _AnimationTime);

                float a = 1.0 - smoothstep(0.07, 0.1, c.x);
                float3 col = a * (1.0 - c.x);
                float r = ripple(float2(0.5, 0.5), i.uv, _PulseTime);
                col = saturate(lerp(r * col, col, 0.02));

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
