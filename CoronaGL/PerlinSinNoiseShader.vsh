uniform mat4 u_Projection;
uniform float u_NoiseAngle;

attribute vec2 a_Position;
attribute vec2 a_Texture;
attribute vec3 a_NoiseTexture;

varying vec2 v_Texture;
varying vec3 v_NoiseTexture;

void main(void) {
    
    vec4 pos = u_Projection * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
    /*vec3 noiseTex = a_NoiseTexture;
    float c = cos(u_NoiseAngle);
    float s = sin(u_NoiseAngle);
    noiseTex.x = noiseTex.x * c + noiseTex.y * s;
    noiseTex.y = -noiseTex.x * s + noiseTex.y * c;*/
    v_NoiseTexture = a_NoiseTexture;
}//main