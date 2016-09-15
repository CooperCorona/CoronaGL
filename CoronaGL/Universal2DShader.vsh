#define UNIFORM_COUNT 112

uniform mat4 u_Projection;
uniform mat4 u_ModelMatrix[UNIFORM_COUNT];

uniform vec3 u_TintColor[UNIFORM_COUNT];
uniform vec3 u_TintIntensity[UNIFORM_COUNT];
uniform vec3 u_ShadeColor[UNIFORM_COUNT];

uniform float u_Alpha[UNIFORM_COUNT];

attribute float a_Index;

attribute vec2 a_Position;
attribute vec2 a_Texture;

varying vec2 v_Texture;
varying vec3 v_ShadeColor;
varying vec3 v_TintColor;
varying vec3 v_TintIntensity;
varying float v_Alpha;

void main(void) {
    
    int index = int(a_Index);
    vec4 pos = u_Projection * u_ModelMatrix[index] * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_ShadeColor = u_ShadeColor[index];
    v_TintColor = u_TintColor[index];
    v_TintIntensity = u_TintIntensity[index];
    v_Alpha = u_Alpha[index];
    v_Texture = a_Texture;
}