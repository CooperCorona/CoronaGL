#version 150

precision mediump float;

uniform vec4 u_OnColor;
uniform vec4 u_OffColor;

in vec2 v_Texture;

out vec4 c_gl_FragColor;

int modulus(int x, int y) {
    return x - (x / y) * y;
}

void main(void) {
    int discreteFactor = int(floor(v_Texture.x) + floor(v_Texture.y));
    float whichColor = float(modulus(discreteFactor, 2));
    c_gl_FragColor = mix(u_OffColor, u_OnColor, whichColor);
}//main