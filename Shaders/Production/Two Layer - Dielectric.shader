Shader "ProtoXR/Production/Two Layer - Dielectric"
{
    Properties
    {
        [NoScaleOffset] _AlbedoHeight1("Albedo (RGB) Height (A)", 2D) = "white" {}
        [NoScaleOffset] _NormalOcclusionSmoothness1("Normal (GA) Occlusion (B) Smoothness (R)", 2D) = "white" {}
        [NoScaleOffset] _AlbedoAlpha2("Albedo (RGB) Alpha (A) - 2", 2D) = "white" {}
        [NoScaleOffset] _NormalOcclusionSmoothness2("Normal (GA) Occlusion (B) Smoothness (R)", 2D) = "white" {}
        [Header(Height Blend)] _HeightContrast("Height Contrast", Float) = 20
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
        Cull Back
        CGPROGRAM
        #include "UnityStandardUtils.cginc"
        #include "./ProductionShadersUtils.cginc"

        // Force BRDF3:
        // https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/2d24565fed6e5a2ac85bd69e38f583526793c437/CGIncludes/UnityPBSLighting.cginc#L18
        #define UNITY_PBS_USE_BRDF3 1
        #pragma target 2.0

        #pragma surface surf Standard addshadow fullforwardshadows vertex:vertexDataFunc

        struct Input
        {
            half2 texcoord_0;
            half4 texcoord_3;
            half4 vertexColor : COLOR;
        };

        uniform sampler2D _AlbedoHeight1;
        uniform sampler2D _NormalOcclusionSmoothness1;
        uniform sampler2D _AlbedoAlpha2;
        uniform sampler2D _NormalOcclusionSmoothness2;
        uniform half _HeightContrast;

        void vertexDataFunc(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.texcoord_0.xy = v.texcoord.xy;
            o.texcoord_3 = v.texcoord3;
        }

        void surf(Input i , inout SurfaceOutputStandard o)
        {
            half4 albedoHeight1 = tex2D(_AlbedoHeight1, i.texcoord_0.xy);
            half4 normalOcclusionSmoothness1 = tex2D(_NormalOcclusionSmoothness1, i.texcoord_0.xy);

            half4 albedoAlpha2 = tex2D(_AlbedoAlpha2, i.texcoord_3.xy);
            half4 normalOcclusionSmoothness2 = tex2D(_NormalOcclusionSmoothness2, i.texcoord_3.xy);

            // Only using height of FIRST texture to blend.
            half height = albedoHeight1.a;
            half secondHeightAndRedChannel = saturate(((height - 1.0) + (i.vertexColor.a * 2.0)));
            half secondContrast = saturate(CalculateContrastHeight(_HeightContrast, secondHeightAndRedChannel));

            half secondPaintAlpha = i.texcoord_3.z;
            half secondBlendAmount = albedoAlpha2.a * secondContrast * secondPaintAlpha;

            half3 colorTint = i.vertexColor.rgb;
            // Only tint the second texture albedo.
            albedoAlpha2.rgb *= colorTint;

            o.Albedo = lerp(albedoHeight1.rgb, albedoAlpha2.rgb, secondBlendAmount);

            half secondOverrideNormalsMask = i.texcoord_3.w;

            half4 lerpedNormalOcclusionSmoothness = lerp(normalOcclusionSmoothness1, normalOcclusionSmoothness2, secondBlendAmount * secondOverrideNormalsMask);

            o.Occlusion = lerpedNormalOcclusionSmoothness.b;
            o.Normal = decodePackedNormal(lerpedNormalOcclusionSmoothness.ga);
            o.Metallic = DIELECTRIC_CONSTANT;
            o.Smoothness = lerpedNormalOcclusionSmoothness.r;
            o.Alpha = 1;
        }

        ENDCG
    }
    
    Fallback "Diffuse"
}
