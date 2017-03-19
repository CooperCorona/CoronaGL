
precision mediump float;

uniform vec4 u_OnColor;
uniform vec4 u_OffColor;
varying vec2 v_Texture;


int modulus(int x, int y) {
    return x - (x / y) * y;
}

void main(void) {
    int discreteFactor = int(floor(v_Texture.x) + floor(v_Texture.y));
    float whichColor = float(modulus(discreteFactor, 2));
    gl_FragColor = mix(u_OffColor, u_OnColor, whichColor);
}//main