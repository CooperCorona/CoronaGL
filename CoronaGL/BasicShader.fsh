

precision mediump float;

uniform highp sampler2D u_TextureInfo;
uniform float u_Alpha;
uniform vec3 u_TintColor;
uniform vec3 u_TintIntensity;
uniform vec3 u_ShadeColor;

varying vec2 v_Texture;

void main(void) {
    
    vec4 texColor = texture2D(u_TextureInfo, v_Texture);
    
    texColor.rgb *= u_ShadeColor;
    texColor = vec4(mix(texColor.rgb, u_TintColor, u_TintIntensity), texColor.a * u_Alpha);
    
    gl_FragColor = texColor;
//    gl_FragColor = vec4(v_Texture, 0.0, 1.0);
}//main