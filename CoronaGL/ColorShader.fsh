precision mediump float;

uniform float u_Alpha;

varying vec4 v_Color;

void main(void) {
    
    gl_FragColor = vec4(v_Color.rgb, v_Color.a * u_Alpha);
}//main