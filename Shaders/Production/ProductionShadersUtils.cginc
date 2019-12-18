// https://forum.unity.com/threads/gamma-space-and-linear-space-with-shader.243793/
inline float4 GammaToLinear(float value)
{
    return pow(value, 2.2);
}

inline float4 LinearToGamma(float value)
{
    return pow(value, 0.454545);
}

inline float CalculateContrastHeight(float contrastValue, float colorTarget)
{
    float t = 0.5 * (1.0 - contrastValue);
    return colorTarget * (contrastValue + t);
}

inline float4 CalculateContrast(float contrastValue, float4 colorTarget)
{
    float t = 0.5 * (1.0 - contrastValue);
    return mul(float4x4(contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1), colorTarget);
}

// http://aras-p.info/texts/CompactNormalStorage.html
inline half4 decodePackedNormal(half2 encodedXY)
{
    half4 n;
    
    n.xy = encodedXY * 2 - 1;
    // Cheaper z calculation, but may result in artifacts.
    n.z = 1;
    n.w = 1;
    
    return n;
}

inline half4 decodePackedNormalHighQuality(half2 encodedXY)
{
    half4 n;
    
    n.xy = encodedXY * 2 - 1;
    n.z = sqrt(1 - saturate(dot(n.xy, n.xy)));
    n.w = 1;
    
    return n;
}

// https://www.garagegames.com/community/forums/viewthread/134634
inline float4 blendByWeightAndDepthMap(float4 texture1, float weight1, float height1, float4 texture2, float weight2, float height2)  
{  
    // Where the alpha channel of texture1 and texture2 is a depth map.
    // Is the height map the same thing as a depth map?
    float depth = 0.2;  
    float ma = max(height1 + weight1, height2 + weight2) - depth;  
  
    float b1 = max(height1 + weight1 - ma, 0);  
    float b2 = max(height2 + weight2 - ma, 0);  
  
    return (texture1.rgba * b1 + texture2.rgba * b2) / (b1 + b2);  
}  

// Taken from:
// http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.161.8979&rep=rep1&type=pdf
inline float3 crossFilterNormal(sampler2D heightMap, float2 uv, float texelSize, float texelAspect)
{
    float4 h;
    h[0] = tex2Dlod(heightMap, float4(uv.xy + texelSize * float2( 0,-1), 0, 0)).r * texelAspect;
    h[1] = tex2Dlod(heightMap, float4(uv.xy + texelSize * float2(-1, 0), 0, 0)).r * texelAspect;
    h[2] = tex2Dlod(heightMap, float4(uv.xy + texelSize * float2( 1, 0), 0, 0)).r * texelAspect;
    h[3] = tex2Dlod(heightMap, float4(uv.xy + texelSize * float2( 0, 1), 0, 0)).r * texelAspect;

    float3 n;

    // Need to flip these in Unity.
    // Original:
    // n.z = h[0] - h[3];
    // n.x = h[1] - h[2];
    n.z = h[3] - h[0];
    n.x = h[2] - h[1];

    n.y = 2;

    return normalize(n);
} 

// Taken from:
// http://theorangeduck.com/page/avoiding-shader-conditionals
inline float isEqual(float x, float y) {
    return 1.0 - abs(sign(x - y));
}

inline float isNotEqual(float x, float y) {
    return abs(sign(x - y));
}

inline float isGreaterThan(float x, float y) {
    return max(sign(x - y), 0.0);
}

inline float isLessThan(float x, float y) {
    return max(sign(y - x), 0.0);
}

inline float isGreaterThanOrEqualTo(float x, float y) {
    return 1.0 - isLessThan(x, y);
}

inline float isLessThanOrEqualTo(float x, float y) {
    return 1.0 - isGreaterThan(x, y);
}

inline float and(float a, float b) {
    return a * b;
}

inline float or(float a, float b) {
    return min(a + b, 1.0);
}

inline float xor(float a, float b) {
    return (a + b) % 2.0;
}

inline float not(float a) {
    return 1.0 - a;
}

// https://stackoverflow.com/questions/17638800/storing-two-float-values-in-a-single-float-variable
inline float2 UnpackTwoFloatsFromOne(float input) {
    float2 output;

    float precision = 4096;
    float precisionMinus1 = 4095;

    output.y = input % precision;
    output.x = floor(input / precision);

    return output / precisionMinus1;
}

static const fixed4 DIELECTRIC_CONSTANT = 0.02;

// WARNING:
// May need to add an offset and floor() due to floating point precision errors.
// But see if can get away without floor() for now.
inline fixed decodeTextureArrayIndex(fixed input) {
    // Should probably stick to powers of two.
   return input * 16;
}
