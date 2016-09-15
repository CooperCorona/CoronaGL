
uniform mat4 u_Projection;
uniform mat4 u_ModelMatrix;

attribute vec2 a_Position;
attribute vec2 a_Texture;
attribute vec2 a_NoiseTexture;
attribute vec3 a_Color;
attribute vec4 a_NoiseColor;

varying vec2 v_Texture;
varying vec2 v_NoiseTexture;
varying vec3 v_Color;
varying vec4 v_NoiseColor;

void main(void)
{//main
    vec4 pos = u_Projection * u_ModelMatrix * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
    v_NoiseTexture = a_NoiseTexture;
    v_Color = a_Color;
    v_NoiseColor = a_NoiseColor;
}//main