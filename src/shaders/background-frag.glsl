#version 300 es

// Fragment shader for space themed background.
precision highp float;

uniform float u_Time;
uniform float u_Aspect;
uniform int u_Theme;   // 0 = hand-tuned fire gradient, 1+ = cosine palettes
uniform float u_Glow;
uniform float u_Speed;

in vec2 fs_UV;

out vec4 out_Col;

#include "noise.glsl"
#include "color.glsl"

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

// ---- Meteor trail ----------------------------------------------------------

// Screen-space direction the tail streams toward (the head faces the opposite way)
const vec2 TRAIL_DIR = normalize(vec2(-0.75, 0.66));

// One companion debris streak: an elongated gaussian blob in trail space.
float streak(vec2 sr, vec2 center, float len, float width) {
    vec2 q = (sr - center) / vec2(len, width);
    return gaussian(length(q), 1.0);
}

// The main trail: a flaring band of light behind the head.
// s = distance along the tail axis (positive = tail side),
// r = perpendicular offset from the axis.
float trailBand(float s, float r) {
    float sw = max(s, 0.0);  // widths/fades only ever see the tail side
    float flare = gaussian(r, 15.0 / (1.0 + sw * 3.0)) * exp(-sw * 0.9);
    float core  = gaussian(r, 40.0 / (1.0 + sw * 1.5)) * exp(-sw * 0.6);
    // Smooth onset across the head instead of a hard cut at s = 0， because the old
    // `if (s < 0.0) return 0.0` drew a visible straight seam across the sky.
    return (flare * 1.2 + core * 0.8) * smoothstep(-0.3, 0.2, s);
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

    // Trail-space coordinates shared by the trail
    float sCoord = dot(p, TRAIL_DIR);
    float rCoord = dot(p, vec2(-TRAIL_DIR.y, TRAIL_DIR.x));

    // Fireball glow: Gaussian falloff, slow pulse,
    // tinted by the current theme's bright end.
    p -= TRAIL_DIR * 0.05;
    float d = length(p);
    float glow = gaussian(d, 3.0);
    glow *= 0.6 + 0.2 * sin(u_Time * u_Speed * 3.0);
    col += themeColor(0.75, u_Theme) * glow * u_Glow;

    // Meteor trail: color runs hot near the head, cooling toward the tail.
    float trail = trailBand(sCoord, rCoord);
    vec3 trailCol = themeColor(mix(0.9, 0.35, clamp(sCoord, 0.0, 1.0)), u_Theme);
    col += trailCol * trail * u_Glow;

    // Rim fire: a ring hugging the ball's silhouette, strongest toward the
    // tail side, so the flames appear to peel off the ball rather than start
    // behind it. 0.45 = the ball's approximate screen radius.
    float rim = gaussian(d - 0.45, 300.0) * smoothstep(0.0, 0.6, sCoord);
    col += themeColor(0.85, u_Theme) * rim * 0.35 * u_Glow;

    // Companion debris: hard-coded streaks beside the trail.
    vec3 debrisCol = themeColor(0.7, u_Theme);
    vec2 sr = vec2(sCoord, rCoord);
    col += debrisCol * streak(sr, vec2(0.70,  0.30), 0.30, 0.018)
        * (0.7 + 0.3 * sin(u_Time * u_Speed * 4.0 + 1.0));
    col += debrisCol * streak(sr, vec2(0.60, -0.26), 0.20, 0.014)
        * (0.7 + 0.3 * sin(u_Time * u_Speed * 3.5 + 5.0)) * 0.9;
    col += debrisCol * streak(sr, vec2(1.10, -0.40), 0.26, 0.016)
        * (0.6 + 0.3 * sin(u_Time * u_Speed * 5.0 + 3.0)) * 0.8;
    col += debrisCol * streak(sr, vec2(1.40,  0.22), 0.18, 0.012)
        * (0.5 + 0.3 * sin(u_Time * u_Speed * 4.5 + 2.0)) * 0.6;
    col += debrisCol * streak(sr, vec2(0.95,  0.08), 0.22, 0.014)
        * (0.65 + 0.3 * sin(u_Time * u_Speed * 4.2 + 4.0)) * 0.85;

    out_Col = vec4(col, 1.0);
}
