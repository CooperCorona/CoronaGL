
precision mediump float;

uniform highp sampler2D u_TextureInfo;

varying vec2 v_Texture;
varying vec3 v_ShadeColor;
varying vec3 v_TintColor;
varying vec3 v_TintIntensity;
varying float v_Alpha;

void main(void) {
    
    vec4 texColor = texture2D(u_TextureInfo, v_Texture);
    texColor.rgb *= v_ShadeColor;
    texColor.rgb = mix(texColor.rgb, v_TintColor, v_TintIntensity);
    
    gl_FragColor = vec4(texColor.rgb, texColor.a * v_Alpha);
//    gl_FragColor = vec4(v_Texture, 0.0, 1.0);
}//main