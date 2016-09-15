uniform mat4 u_Projection;

attribute vec2 a_Position;
attribute vec2 a_Texture;
attribute vec3 a_NoiseTexture;

varying vec2 v_Texture;
varying vec3 v_NoiseTexture;

void main(void) {
    
    vec4 pos = u_Projection * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
    v_NoiseTexture = a_NoiseTexture;
}//main