precision mediump float;

uniform highp sampler2D u_TextureInfo;

varying vec2 v_Texture;
varying vec2 v_BlurTexture[14];

void main(void) {
    
    vec4 blurColor = texture2D(u_TextureInfo, v_BlurTexture[0]) * 0.0044299121055113265;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[1 ]) * 0.00895781211794;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[2 ]) * 0.0215963866053;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[3 ]) * 0.0443683338718;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[4 ]) * 0.0776744219933;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[5 ]) * 0.115876621105;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[6 ]) * 0.147308056121;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[7 ]) * 0.147308056121;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[8 ]) * 0.115876621105;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[9 ]) * 0.0776744219933;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[10]) * 0.0443683338718;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[11]) * 0.0215963866053;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[12]) * 0.00895781211794;
    blurColor += texture2D(u_TextureInfo, v_BlurTexture[13]) * 0.0044299121055113265;
    
    //.840423087839
    vec4 color = texture2D(u_TextureInfo, v_Texture) * 0.159576912161;
    color += blurColor;
    
//    gl_FragColor = color;
    gl_FragColor = color;
}//main
