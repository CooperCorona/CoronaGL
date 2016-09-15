
precision mediump float;

uniform highp sampler2D u_TextureInfo1;
uniform highp sampler2D u_TextureInfo2;

varying vec2 v_Texture1;
varying vec2 v_Texture2;

void main(void) {
    
    vec4 texColor = texture2D(u_TextureInfo1, v_Texture1) * texture2D(u_TextureInfo2, v_Texture2);
    
    gl_FragColor = texColor;
}//main