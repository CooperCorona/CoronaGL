uniform mat4 u_Projection;
uniform vec2 u_Size;
uniform vec2 u_DirectionVector;
uniform float u_BlurFactor;

attribute vec2 a_Position;
attribute vec2 a_Texture;

varying vec2 v_Texture;
varying vec2 v_BlurTexture[14];

void main(void) {
    vec4 pos = u_Projection * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
    
    for (int iii = -7; iii < 0; iii++) {
        v_BlurTexture[iii + 7] = v_Texture + u_DirectionVector * u_BlurFactor / u_Size * float(iii);
//        vec2 tex = v_Texture + u_DirectionVector * u_BlurFactor / u_Size * float(iii);
//        v_BlurTexture[iii + 7] = clamp(tex, vec2(0.0), vec2(1.0));
    }
    
    for (int iii = 7; iii < 14; iii++) {
//        vec2 tex = v_Texture + u_DirectionVector * u_BlurFactor / u_Size * float(iii - 6);
//        v_BlurTexture[iii] = clamp(tex, vec2(0.0), vec2(1.0));
        v_BlurTexture[iii] = v_Texture + u_DirectionVector * u_BlurFactor / u_Size * float(iii - 6);
    }
}//main