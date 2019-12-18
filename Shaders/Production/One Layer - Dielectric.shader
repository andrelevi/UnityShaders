Shader "ProtoXR/Production/One Layer - Dielectric"
{
    Properties
    {
        [NoScaleOffset] _AlbedoHeight1("Albedo (RGB) Height (A)", 2D) = "white" {}
        [NoScaleOffset] _NormalOcclusionSmoothness1("Normal (GA) Unused (B) Smoothness (R)", 2D) = "white" {}
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
        Cull Back
        CGPROGRAM
        #include "UnityStandardUtils.cginc"
        #include "./ProductionShadersUtils.cginc"

        // Force BRDF3:
        // https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/CGIncludes/UnityPBSLighting.cginc
        #define UNITY_PBS_USE_BRDF3 1
        #pragma target 2.0

        #pragma surface surf Standard addshadow fullforwardshadows vertex:vertexDataFunc 

        struct Input
        {
            half2 texcoord_0;
        };

        uniform sampler2D _AlbedoHeight1;
        uniform sampler2D _NormalOcclusionSmoothness1;

        void vertexDataFunc(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.texcoord_0.xy = v.texcoord.xy;
        }

        void surf(Input i, inout SurfaceOutputStandard o)
        {
            half4 albedoHeight1 = tex2D(_AlbedoHeight1, i.texcoord_0);
            half4 normalOcclusionSmoothness1 = tex2D(_NormalOcclusionSmoothness1, i.texcoord_0);

            o.Albedo = albedoHeight1.rgb;
            o.Occlusion = normalOcclusionSmoothness1.b;
            o.Normal = decodePackedNormal(normalOcclusionSmoothness1.ga);
            o.Metallic = DIELECTRIC_CONSTANT;
            o.Smoothness = normalOcclusionSmoothness1.r;

            o.Alpha = 1;
        }
        ENDCG
    }
    
    Fallback "Diffuse"
}
