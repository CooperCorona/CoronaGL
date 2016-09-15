precision mediump float;

uniform highp sampler2D u_TextureInfo;
uniform highp sampler2D u_GradientInfo;

varying vec2 v_Texture;

void main(void) {
    
    vec4 gradientCoordVec = texture2D(u_TextureInfo, v_Texture);
    vec4 texColor = texture2D(u_GradientInfo, vec2(gradientCoordVec.x, 0.0));
    texColor.a *= gradientCoordVec.a;
    
    gl_FragColor = texColor;
}//main