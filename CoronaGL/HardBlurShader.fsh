precision mediump float;
#define KernelSize 16
#define KernelFactor 1.0 / float((KernelSize + 1) * (KernelSize + 1))

uniform highp sampler2D u_TextureInfo;
uniform vec2 u_Size;
uniform float u_BlurFactor;
uniform vec2 u_DirectionVector;

varying vec2 v_Texture;

void main(void) {
    
    //    float u_BlurFactor = 1.0;
    
    float b = u_BlurFactor;
    float u = float(KernelSize) * (1.0 - b) + 1.0;
    
    float factor = KernelFactor;
    vec4 col = vec4(0.0);
    
    for (int iii = 0; iii < KernelSize; ++iii) {
        vec2 tex = v_Texture + float(iii - KernelSize) * u_DirectionVector / u_Size;
        tex = clamp(tex, vec2(0.0), vec2(1.0));
        float curFactor = float(KernelSize + 1) - abs(float(iii - KernelSize));
        col += texture2D(u_TextureInfo, tex) * (curFactor * factor * b);
    }
    
    col += texture2D(u_TextureInfo, v_Texture) * (float(KernelSize + 1) * factor * u);
    
    for (int iii = KernelSize + 1; iii < KernelSize * 2 + 1; ++iii) {
        vec2 tex = v_Texture + float(iii - KernelSize) * u_DirectionVector / u_Size;
        tex = clamp(tex, vec2(0.0), vec2(1.0));
        float curFactor = float(KernelSize + 1) - abs(float(iii - KernelSize));
        col += texture2D(u_TextureInfo, tex) * (curFactor * factor * b);
    }
    
    
    gl_FragColor = col;
}//main
