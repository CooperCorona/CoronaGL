#version 150

uniform mat4 u_Projection;
uniform mat4 u_ModelMatrix;

in vec2 a_Position;
in vec2 a_Texture;

out vec2 v_Texture;

void main(void) {
    
    vec4 pos = u_Projection * u_ModelMatrix * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
}//main
