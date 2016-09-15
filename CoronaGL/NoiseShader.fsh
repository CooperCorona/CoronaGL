
precision mediump float;

uniform sampler2D u_TextureInfo;
uniform int u_Tiles;
uniform vec2 u_Offset;

varying highp vec2 v_Texture;
varying highp vec2 v_NoiseTexture;
varying vec3 v_Color;//                                         10
varying vec4 v_NoiseColor;

float randomNoise(vec2 p)
{//get random noise
    return fract(8263.0 * sin(149.0 * p.x + 1289.0 * p.y));
}//get random noise

float smoothNoise(vec2 c)
{//smooth noise
    float north = randomNoise(vec2(c.x, c.y + 1.0));//          20
    float east = randomNoise(vec2(c.x + 1.0, c.y));
    float south = randomNoise(vec2(c.x, c.y - 1.0));
    float west = randomNoise(vec2(c.x - 1.0, c.y));
    
    return randomNoise(c) * .5 + .125 * (north + east + south + west);
}//smooth noise

float interpolateNoise(highp vec2 p)
{//interpolate noise
    float q11 = smoothNoise(floor(p));//                        30
    float q12 = smoothNoise(vec2(floor(p.x), ceil(p.y)));
    float q21 = smoothNoise(vec2(ceil(p.x), floor(p.y)));
    float q22 = smoothNoise(ceil(p));
    
    vec2 m = fract(p);
    vec2 s = smoothstep(0.0, 1.0, fract(p));
    //vec2 s = 3.0 * m * m - 2.0 * m * m * m;
    //vec2 s = m;
    //s = p;
    //                                                          40
    float r1 = mix(q11, q21, fract(s.x));
    float r2 = mix(q12, q22, fract(s.x));
    
    return mix(r1, r2, fract(s.y));
}//interpolate noise

void main(void)
{//main
    //Usually, I would calculate the real texture position using
    //v_Texture * u_TextureAnchor.zw + u_TextureAnchor.xy       50
    //but then I can't take advantage of the gpu's texture grabbing
    //optimizations (which only occur if the coordinates are unchanged)
    //so instead I apply the inverse to the actual noise texture
    vec4 tex = texture2D(u_TextureInfo, v_Texture);
    
    highp vec2 texTile = v_NoiseTexture * float(u_Tiles) + u_Offset;
    float factor = interpolateNoise(texTile) * v_NoiseColor.a;
    
//    vec3 col = tex.rgb * v_Color.rgb * (1.0 - factor) + (v_NoiseColor.rgb * factor);//60
    vec3 col = tex.rgb * mix(v_Color.rgb, v_NoiseColor.rgb, factor);
    
    gl_FragColor = vec4(col, tex.a);
}//main