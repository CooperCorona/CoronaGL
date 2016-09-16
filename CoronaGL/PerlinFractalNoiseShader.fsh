precision mediump float;
#define LERP float
#define Setup(pval, indexL, indexU, distL, distU)\
indexL = int(floor(pval));\
indexU = indexL + 1;\
distL = fract(pval);\
distU = distL - 1.0

uniform highp sampler2D u_TextureInfo;
uniform highp sampler2D u_NoiseTextureInfo;
uniform sampler2D u_GradientInfo;
uniform sampler2D u_PermutationInfo;
uniform vec3 u_Offset;
uniform float u_NoiseDivisor;
uniform float u_Alpha;
uniform ivec3 u_Period;

varying vec2 v_Texture;
varying highp vec3 v_NoiseTexture;

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

float getDotAtIndex(int index, vec3 offset) {
    
    float v_x = float(index) / 255.0;
    
    vec3 noiseTex = texture2D(u_NoiseTextureInfo, vec2(v_x, 0.0)).rgb;
    
    return dot(offset, noiseTex * 2.0 - 1.0);
}

int permAtIndex(int index) {
    
    vec4 texVal = texture2D(u_PermutationInfo, vec2(float(index) / 255.0, 0.0));
    return int(texVal.x * 255.0);
}

float noiseAt(vec3 pos, int periodFactor) {
    
    int xIndexL, xIndexU, yIndexL, yIndexU, zIndexL, zIndexU;
    float xDistL, xDistU, yDistL, yDistU, zDistL, zDistU;
    
    Setup(pos.x, xIndexL, xIndexU, xDistL, xDistU);
    Setup(pos.y, yIndexL, yIndexU, yDistL, yDistU);
    Setup(pos.z, zIndexL, zIndexU, zDistL, zDistU);
    xIndexL = modulus(xIndexL, u_Period.x * periodFactor);
    xIndexU = modulus(xIndexU, u_Period.x * periodFactor);
    yIndexL = modulus(yIndexL, u_Period.y * periodFactor);
    yIndexU = modulus(yIndexU, u_Period.y * periodFactor);
    zIndexL = modulus(zIndexL, u_Period.z * periodFactor);
    zIndexU = modulus(zIndexU, u_Period.z * periodFactor);
    
    int xPermIndexL = permAtIndex(xIndexL);
    int xPermIndexU = permAtIndex(xIndexU);
    
    int yPermIndexLL = permAtIndex(xPermIndexL + yIndexL);
    int yPermIndexUL = permAtIndex(xPermIndexU + yIndexL);
    int yPermIndexLU = permAtIndex(xPermIndexL + yIndexU);
    int yPermIndexUU = permAtIndex(xPermIndexU + yIndexU);
    
    int zPermIndexLLL = permAtIndex(yPermIndexLL + zIndexL);
    int zPermIndexULL = permAtIndex(yPermIndexUL + zIndexL);
    int zPermIndexLUL = permAtIndex(yPermIndexLU + zIndexL);
    int zPermIndexUUL = permAtIndex(yPermIndexUU + zIndexL);
    int zPermIndexLLU = permAtIndex(yPermIndexLL + zIndexU);
    int zPermIndexULU = permAtIndex(yPermIndexUL + zIndexU);
    int zPermIndexLUU = permAtIndex(yPermIndexLU + zIndexU);
    int zPermIndexUUU = permAtIndex(yPermIndexUU + zIndexU);
    
    
    vec3 offsetLLL = vec3(xDistL, yDistL, zDistL);
    vec3 offsetULL = vec3(xDistU, yDistL, zDistL);
    vec3 offsetLUL = vec3(xDistL, yDistU, zDistL);
    vec3 offsetUUL = vec3(xDistU, yDistU, zDistL);
    vec3 offsetLLU = vec3(xDistL, yDistL, zDistU);
    vec3 offsetULU = vec3(xDistU, yDistL, zDistU);
    vec3 offsetLUU = vec3(xDistL, yDistU, zDistU);
    vec3 offsetUUU = vec3(xDistU, yDistU, zDistU);
    
    
    float lll = getDotAtIndex(zPermIndexLLL, offsetLLL);
    float ull = getDotAtIndex(zPermIndexULL, offsetULL);
    float lul = getDotAtIndex(zPermIndexLUL, offsetLUL);
    float uul = getDotAtIndex(zPermIndexUUL, offsetUUL);
    float llu = getDotAtIndex(zPermIndexLLU, offsetLLU);
    float ulu = getDotAtIndex(zPermIndexULU, offsetULU);
    float luu = getDotAtIndex(zPermIndexLUU, offsetLUU);
    float uuu = getDotAtIndex(zPermIndexUUU, offsetUUU);
    
    vec3 weight = smoothstep(vec3(0.0), vec3(1.0), offsetLLL);
    
    return trilinearlyInterpolate(weight, lll, ull, lul, uul, llu, ulu, luu, uuu);
}

float fractalNoiseAt(vec3 pos) {
    
    float noise = noiseAt(pos, 1);
    noise += noiseAt(2.0 * pos, 2) / 2.0;
    noise += noiseAt(4.0 * pos, 4) / 4.0;
    noise += noiseAt(8.0 * pos, 8) / 8.0;
    
    return noise;
}

void main(void) {
    
    vec4 texColor = texture2D(u_TextureInfo, v_Texture);
    
    float noise = fractalNoiseAt(v_NoiseTexture + u_Offset) / 2.0 / u_NoiseDivisor + 0.5;
    vec4 graColor = texture2D(u_GradientInfo, vec2(noise, 0.0));
    
    graColor.rgb = mix(vec3(1.0, 1.0, 1.0), graColor.rgb, u_Alpha);
    gl_FragColor = vec4(graColor.rgb * texColor.rgb, graColor.a * texColor.a);
}//main
