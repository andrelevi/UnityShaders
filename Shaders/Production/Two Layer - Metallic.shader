Shader "ProtoXR/Production/Two Layer - Metallic"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMetallic1("Albedo (RGB) Metallic (A)", 2D) = "white" {}
        [NoScaleOffset] _NormalOcclusionSmoothness1("Normal (GA) Occlusion (B) Smoothness (R)", 2D) = "white" {}
        [NoScaleOffset] _AlbedoAlpha2("Albedo (RGB) Alpha (A) - 2", 2D) = "white" {}
        [NoScaleOffset] _NormalOcclusionSmoothness2("Normal (GA) Occlusion (B) Smoothness (R)", 2D) = "white" {}
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

        uniform sampler2D _AlbedoMetallic1;
        uniform sampler2D _NormalOcclusionSmoothness1;
        uniform sampler2D _AlbedoAlpha2;
        uniform sampler2D _NormalOcclusionSmoothness2;

        void vertexDataFunc(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.texcoord_0.xy = v.texcoord.xy;
            o.texcoord_3 = v.texcoord3;
        }

        void surf(Input i , inout SurfaceOutputStandard o)
        {
            // Base PBR texture set.
            half4 albedoMetallic1 = tex2D(_AlbedoMetallic1, i.texcoord_0.xy);
            half4 normalOcclusionSmoothness1 = tex2D(_NormalOcclusionSmoothness1, i.texcoord_0.xy);

            // Secondary PBR texture set that will be blended into base textures.
            half4 albedoAlpha2 = tex2D(_AlbedoAlpha2, i.texcoord_3.xy);
            half4 normalOcclusionSmoothness2 = tex2D(_NormalOcclusionSmoothness2, i.texcoord_3.xy);

            // Second texture alpha multiplier is packed in UV3.z channel.
            half secondPaintAlpha = i.texcoord_3.z;
            // Second texture blend amount is stored in vertex color.a channel.
            half secondBlendAmount = albedoAlpha2.a * i.vertexColor.a * secondPaintAlpha;

            // Color tint is stored in vertex color.rgb.
            half3 colorTint = i.vertexColor.rgb;
            // Only tint the second texture albedo.
            albedoAlpha2.rgb *= colorTint;

            o.Albedo = lerp(albedoMetallic1.rgb, albedoAlpha2.rgb, secondBlendAmount);

            // Whether to override the base texture set's normals/occlusion/smoothness is stored in the
            // UV3.w channel. This is optional because sometimes the base texture's normals should not
            // be overriden. E.g. paint on a brick wall should only override the base albedo,
            // since we need to retain the brick wall's normals for the brick outlines.
            half secondOverrideNormalsMask = i.texcoord_3.w;

            half4 lerpedNormalOcclusionSmoothness = lerp(normalOcclusionSmoothness1, normalOcclusionSmoothness2, secondBlendAmount * secondOverrideNormalsMask);

            // Convert the packed normal.xy into a float3.
            o.Normal = decodePackedNormal(lerpedNormalOcclusionSmoothness.ga);
            o.Occlusion = lerpedNormalOcclusionSmoothness.b;
            o.Metallic = albedoMetallic1.a;
            o.Smoothness = lerpedNormalOcclusionSmoothness.r;
            o.Alpha = 1;
        }
        ENDCG
    }
    
    Fallback "Diffuse"
}
