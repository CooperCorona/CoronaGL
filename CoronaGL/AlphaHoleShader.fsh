precision mediump float;

uniform highp sampler2D u_TextureInfo;
uniform vec2 u_FadePosition;
uniform float u_InnerRadius;
uniform float u_OuterRadius;
uniform float u_InnerAlpha;
uniform float u_OuterAlpha;

varying vec2 v_Position;
varying vec2 v_Texture;

void main(void) {
    vec4 texColor = texture2D(u_TextureInfo, v_Texture);
    float dist = distance(v_Position, u_FadePosition);
    float alphaFactor = clamp((dist - u_InnerRadius) / u_OuterRadius, 0.0, 1.0);
    alphaFactor = smoothstep(0.0, 1.0, alphaFactor);
    texColor.a *= mix(u_InnerAlpha, u_OuterAlpha, alphaFactor);
    gl_FragColor = texColor;
}//main