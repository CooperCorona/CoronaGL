uniform mat4 u_Projection;
uniform mat4 u_ModelMatrix;

attribute vec2 a_Position;
attribute vec4 a_Color;

varying vec4 v_Color;

void main(void) {
    
    vec4 pos = u_Projection * u_ModelMatrix * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Color = a_Color;
}//main