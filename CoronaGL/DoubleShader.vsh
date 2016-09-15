
uniform mat4 u_Projection;

attribute vec2 a_Position;
attribute vec2 a_Texture1;
attribute vec2 a_Texture2;

varying vec2 v_Texture1;
varying vec2 v_Texture2;

void main(void) {
    
    vec4 pos = u_Projection * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture1 = a_Texture1;
    v_Texture2 = a_Texture2;
}//main