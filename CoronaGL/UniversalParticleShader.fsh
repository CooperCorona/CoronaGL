
precision mediump float;

uniform highp sampler2D u_TextureInfo;

varying vec3 v_Color;
varying vec4 v_TextureAnchor;

void main(void) {
    
    vec4 tex = texture2D(u_TextureInfo, gl_PointCoord * v_TextureAnchor.zw + v_TextureAnchor.xy);
    tex.rgb *= v_Color;
    
    gl_FragColor = tex;
}