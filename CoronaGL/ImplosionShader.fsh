precision mediump float;

uniform highp sampler2D u_TextureInfo;
uniform vec2 u_ImplosionPoint;
uniform float u_ImplosionStrength;
uniform float u_IsImplosion;

varying vec2 v_Texture;
varying vec2 v_ImplosionTexture;

void main(void) {
    vec2 offset = u_ImplosionPoint - v_ImplosionTexture;
    vec2 implosionCoordOffset = u_IsImplosion * u_ImplosionStrength * log(length(offset)) * normalize(offset);
    vec4 texColor = texture2D(u_TextureInfo, v_Texture + implosionCoordOffset);
    gl_FragColor = texColor;
}//main
