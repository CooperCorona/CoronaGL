#extension GL_EXT_draw_instanced : enable
#define cc_InstanceID gl_InstanceIDEXT

uniform mat4 u_Projection;

attribute vec2 a_Position;
attribute vec2 a_Texture;
attribute vec3 a_NoiseTexture;

varying vec2 v_Texture;
varying vec3 v_NoiseTexture;

uniform vec2 u_Size;
uniform vec2 u_TextureSize;
uniform vec2 u_InstanceOffsets[256];

uniform sampler2D u_PermutationInfo;
uniform vec3 u_NoiseOffset;

varying vec2 indexLLL;
varying vec2 indexULL;
varying vec2 indexLUL;
varying vec2 indexUUL;
varying vec2 indexLLU;
varying vec2 indexULU;
varying vec2 indexLUU;
varying vec2 indexUUU;

varying vec2 indexLLL_2;
varying vec2 indexULL_2;
varying vec2 indexLUL_2;
varying vec2 indexUUL_2;
varying vec2 indexLLU_2;
varying vec2 indexULU_2;
varying vec2 indexLUU_2;
varying vec2 indexUUU_2;

struct PermutationIndices {
    vec2 lll;
    vec2 ull;
    vec2 lul;
    vec2 uul;
    vec2 llu;
    vec2 ulu;
    vec2 luu;
    vec2 uuu;
};

int permAtIndex(int index) {
    
    vec4 texVal = texture2D(u_PermutationInfo, vec2(float(index) / 255.0, 0.0));
    return int(floor(texVal.x * 255.0));
}

PermutationIndices indicesAtPosition(vec3 pos) {
    
    int xIndexL = int(floor(pos.x));
    int xIndexU = xIndexL + 1;
    int yIndexL = int(floor(pos.y));
    int yIndexU = yIndexL + 1;
    int zIndexL = int(floor(pos.z));
    int zIndexU = zIndexL + 1;
    
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
    
    PermutationIndices indices;
    indices.lll = vec2(zPermIndexLLL, 0.0) / 255.0;
    indices.ull = vec2(zPermIndexULL, 0.0) / 255.0;
    indices.lul = vec2(zPermIndexLUL, 0.0) / 255.0;
    indices.uul = vec2(zPermIndexUUL, 0.0) / 255.0;
    indices.llu = vec2(zPermIndexLLU, 0.0) / 255.0;
    indices.ulu = vec2(zPermIndexULU, 0.0) / 255.0;
    indices.luu = vec2(zPermIndexLUU, 0.0) / 255.0;
    indices.uuu = vec2(zPermIndexUUU, 0.0) / 255.0;
    
    return indices;
}

void main(void) {
    vec2 offset = u_InstanceOffsets[cc_InstanceID];
    vec4 pos = u_Projection * vec4(a_Position + offset * u_Size, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture + u_TextureSize * offset;
    v_NoiseTexture = a_NoiseTexture + vec3(offset, 0.0);
    
    vec3 noisePos = u_NoiseOffset + vec3(offset, 0.0);
    
    PermutationIndices i1 = indicesAtPosition(noisePos);
    
    /*indexLLL = vec2(zPermIndexLLL, 0.0) / 255.0;
    indexULL = vec2(zPermIndexULL, 0.0) / 255.0;
    indexLUL = vec2(zPermIndexLUL, 0.0) / 255.0;
    indexUUL = vec2(zPermIndexUUL, 0.0) / 255.0;
    indexLLU = vec2(zPermIndexLLU, 0.0) / 255.0;
    indexULU = vec2(zPermIndexULU, 0.0) / 255.0;
    indexLUU = vec2(zPermIndexLUU, 0.0) / 255.0;
    indexUUU = vec2(zPermIndexUUU, 0.0) / 255.0;*/
    indexLLL = i1.lll;
    indexULL = i1.ull;
    indexLUL = i1.lul;
    indexUUL = i1.uul;
    indexLLU = i1.llu;
    indexULU = i1.ulu;
    indexLUU = i1.luu;
    indexUUU = i1.uuu;
    
}//main