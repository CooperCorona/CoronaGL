precision mediump float;

#define LERP float
#define Setup(pval, indexL, indexU, distL, distU)\
indexL = int(floor(pval));\
indexU = indexL + 1;\
distL = fract(pval);\
distU = distL - 1.0

//uniform highp sampler2D u_TextureInfo;
uniform highp sampler2D u_NoiseTextureInfo;
uniform sampler2D u_GradientInfo;
uniform sampler2D u_PermutationInfo;
uniform vec2 u_Offset;
uniform float u_NoiseDivisor;
uniform float u_NoiseCenter;
uniform float u_NoiseRange;
uniform float u_AttenuateAlpha;
uniform ivec2 u_Period;
//uniform float u_Alpha;
varying highp vec2 v_NoiseTexture;

int modulus(int x, int y) {
    return x - (x / y) * y;
}

LERP linearlyInterpolate(float weight, LERP low, LERP high) {
    return low * (1.0 - weight) + high * weight;
}

LERP bilinearlyInterpolate(vec2 weight, LERP lowLow, LERP highLow, LERP lowHigh, LERP highHigh) {
    
    LERP low  = linearlyInterpolate(weight.x, lowLow, highLow);
    LERP high = linearlyInterpolate(weight.x, lowHigh, highHigh);
    
    return linearlyInterpolate(weight.y, low, high);
}

LERP trilinearlyInterpolate(vec3 weight, LERP lowLowLow, LERP highLowLow, LERP lowHighLow, LERP highHighLow, LERP lowLowHigh, LERP highLowHigh, LERP lowHighHigh, LERP highHighHigh) {
    
    LERP low  = bilinearlyInterpolate(weight.xy, lowLowLow, highLowLow, lowHighLow, highHighLow);
    LERP high = bilinearlyInterpolate(weight.xy, lowLowHigh, highLowHigh, lowHighHigh, highHighHigh);
    
    return linearlyInterpolate(weight.z, low, high);
}

float getDotAtIndex(int index, vec2 offset) {
    
    float v_x = float(index) / 255.0;
    
    vec2 noiseTex = texture2D(u_NoiseTextureInfo, vec2(v_x, 0.0)).rg;
    
    return dot(offset, noiseTex * 2.0 - 1.0);
}

int permAtIndex(int index) {
    
    vec4 texVal = texture2D(u_PermutationInfo, vec2(float(index) / 255.0, 0.0));
    return int(floor(texVal.x * 255.0));
}

float noiseAt(vec2 pos) {
    
    int xIndexL, xIndexU, yIndexL, yIndexU;
    float xDistL, xDistU, yDistL, yDistU;
    
    Setup(pos.x, xIndexL, xIndexU, xDistL, xDistU);
    Setup(pos.y, yIndexL, yIndexU, yDistL, yDistU);
    xIndexL = modulus(xIndexL, u_Period.x);
    xIndexU = modulus(xIndexU, u_Period.x);
    yIndexL = modulus(yIndexL, u_Period.y);
    yIndexU = modulus(yIndexU, u_Period.y);
    
    
    int xPermIndexL = permAtIndex(xIndexL);
    int xPermIndexU = permAtIndex(xIndexU);
    
    int yPermIndexLL = permAtIndex(xPermIndexL + yIndexL);
    int yPermIndexUL = permAtIndex(xPermIndexU + yIndexL);
    int yPermIndexLU = permAtIndex(xPermIndexL + yIndexU);
    int yPermIndexUU = permAtIndex(xPermIndexU + yIndexU);
    
    
    vec2 offsetLL = vec2(xDistL, yDistL);
    vec2 offsetUL = vec2(xDistU, yDistL);
    vec2 offsetLU = vec2(xDistL, yDistU);
    vec2 offsetUU = vec2(xDistU, yDistU);
    
    
    float ll = getDotAtIndex(yPermIndexLL, offsetLL);
    float ul = getDotAtIndex(yPermIndexUL, offsetUL);
    float lu = getDotAtIndex(yPermIndexLU, offsetLU);
    float uu = getDotAtIndex(yPermIndexUU, offsetUU);
    
    vec2 weight = smoothstep(vec2(0.0), vec2(1.0), offsetLL);
    //    return trilinearlyInterpolate(weight, lll, ull, lul, uul, llu, ulu, luu, uuu);
    return bilinearlyInterpolate(weight, ll, ul, lu, uu);
}

float fractalNoiseAt(vec2 pos) {
    float noise = noiseAt(pos);
    noise += noiseAt(2.0 * pos) / 2.0;
    noise += noiseAt(4.0 * pos) / 4.0;
    noise += noiseAt(8.0 * pos) / 8.0;
    return noise;
}

void main(void) {
    
    vec2 noisePos = vec2(v_NoiseTexture.x, 0.0) + u_Offset;
    float noise = fractalNoiseAt(noisePos) / u_NoiseDivisor * u_NoiseRange;
    noise += u_NoiseCenter;
    noise = clamp(noise, 0.0, 1.0);
    if (v_NoiseTexture.y > noise) {
        discard;
    }
    
    noise = v_NoiseTexture.y / noise;
    vec4 graColor = texture2D(u_GradientInfo, vec2(noise, 0.0));
    
    
    float alpha = 1.0 - noise * noise * noise * noise * u_AttenuateAlpha;
    gl_FragColor = vec4(graColor.rgb, graColor.a * alpha);
}//main
