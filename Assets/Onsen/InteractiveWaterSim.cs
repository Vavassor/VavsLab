
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class InteractiveWaterSim : UdonSharpBehaviour
{
    public CustomRenderTexture[] renderTextures;
    public RenderTexture collisionTexture;
    public RenderTexture collisionTexturePrior;
    public CustomRenderTexture lightMesh;
    public CustomRenderTexture caustics;

    void Start()
    {
        foreach (var texture in renderTextures)
        {
            texture.Initialize();
        }

        lightMesh.Initialize();
        caustics.Initialize();
    }

    void Update()
    {
        // Update the wave sim.
        var readTextureOld = renderTextures[0];
        var readTexture = renderTextures[1];
        var writeTexture = renderTextures[2];
        VRCGraphics.Blit(readTexture, readTextureOld);
        VRCGraphics.Blit(writeTexture, readTexture);
        writeTexture.Update();
        VRCGraphics.Blit(collisionTexture, collisionTexturePrior);

        // Update the caustic sim.
        lightMesh.Update();
        caustics.Update();
    }
}
