// Generated using Nikita Lisitsa's Two-pass Gaussian blur coefficients generator.
// https://lisyarus.github.io/blog/graphics/2023/02/24/blur-coefficients-generator.html

static const int SAMPLE_COUNT = 16;

static const float OFFSETS[16] = {
    -14.455411751633205,
    -12.461535827914018,
    -10.46767127864531,
    -8.473816318234265,
    -6.479969366444332,
    -4.486128941894109,
    -2.4922929486601455,
    -0.49845722881655474,
    1.4953752517922876,
    3.4892105931983437,
    5.4830484388316485,
    7.4768919324809096,
    9.47074270360747,
    11.464602247430793,
    13.458472249788604,
    15.0
};

static const float WEIGHTS[16] = {
    0.0265501705449451,
    0.03700307562898811,
    0.04909634629822514,
    0.06201579497966834,
    0.07457574715831752,
    0.08537569090389455,
    0.09304880580451849,
    0.09654512293096357,
    0.09536514925762853,
    0.08967936760011742,
    0.08028526732521593,
    0.06842577344572129,
    0.05551949089775868,
    0.04288578153330197,
    0.031537156016701325,
    0.012091259674033801
};

// blurDirection is:
//     float2(1, 0) for horizontal pass
//     float2(0, 1) for vertical pass
// The sourceTexture to be blurred MUST use linear filtering!
// pixelCoord is in [0..1]
float4 blur(sampler2D sourceTexture, float2 texelSize, float2 blurDirection, float2 pixelCoord)
{
    float4 result = float4(0.0, 0.0, 0.0, 0.0);

    for (int i = 0; i < SAMPLE_COUNT; ++i)
    {
        float2 offset = blurDirection * OFFSETS[i] * texelSize;
        float weight = WEIGHTS[i];
        result += weight * tex2D(sourceTexture, pixelCoord + offset);
    }

    return result;
}
