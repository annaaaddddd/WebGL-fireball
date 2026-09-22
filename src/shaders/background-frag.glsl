#version 300 es

// Fragment shader for space themed background.
precision highp float;

uniform float u_Time;
uniform float u_Aspect;

in vec2 fs_UV;

out vec4 out_Col;

#include "noise.glsl"

// One layer of stars via cell-based scattering: each grid cell hashes out
// whether it holds a star, where the star sits, and its twinkle phase.
float starLayer(vec2 p, float density, float seed) {
    vec2 cell = floor(p * density);  // which cell this pixel is in
    vec2 f = fract(p * density);     // local position within the cell, [0, 1)

    float rnd = random3D(vec3(cell, seed));

    vec2 starPos = vec2(random3D(vec3(cell, seed + 1.0)),
                        random3D(vec3(cell, seed + 2.0)));  // star's spot in the cell

    float d = length(f - starPos);
    float star = smoothstep(0.06, 0.0, d);  // soft round dot
    float twinkle = 0.55 + 0.45 * sin(u_Time * 2.0 + rnd * 40.0);  // per-star phase
    
    return star * twinkle * step(0.9, rnd);  // only ~10% of cells hold a star
}

void main()
{
    vec2 p = fs_UV; p.x *= u_Aspect;

    vec3 col = mix(vec3(0.01, 0.01, 0.03), vec3(0.03, 0.05, 0.12), smoothstep(-1.0, 1.0, fs_UV.y));

    // Faint nebula haze; time on the third axis so it morphs instead of sliding
    col += vec3(0.08, 0.05, 0.16) * fbm(vec3(p * 2.0, u_Time * 0.02)) * 0.4;

    // Two star layers: large sparse + small dense (dimmer, reads as farther)
    col += vec3(0.9, 0.95, 1.0) * starLayer(p, 12.0, 7.0);
    col += vec3(0.7, 0.8, 1.0) * starLayer(p, 30.0, 57.0) * 0.6;

    out_Col = vec4(col, 1.0);
}
