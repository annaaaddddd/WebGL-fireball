#version 300 es

// Fireball fragment shader. The surface is treated as self-emissive: color is
// driven entirely by the vertex displacement (fs_Displacement) rather than by
// Lambert lighting, since a fireball is its own light source.
precision highp float;

uniform vec4 u_Color;  // Unused by the fireball themes; kept so the renderer's
                       // setGeometryColor call still has a matching uniform.
uniform float u_Time;
uniform float u_Speed; // Global animation speed multiplier (shared with the vertex shader)
uniform float u_Heat;  // Bias amount: low = small hot core, high = white-hot ball
uniform int u_Theme;   // 0 = hand-tuned fire gradient, 1+ = cosine palettes

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Displacement;
in vec4 fs_Pos;

out vec4 out_Col;

#include "noise.glsl"
#include "color.glsl"

void main()
{
    // Geometry contribution: normalized displacement (bumps read as hotter).
    float shape = smoothstep(-0.6, 0.85, fs_Displacement);

    // Surface fire: domain-warped FBM evaluated per pixel on the un-displaced
    // model-space position, drifting upward over time. This carries the
    // "burning" look now, so the silhouette can stay stable.
    float tt = u_Time * u_Speed;
    vec3 p = fs_Pos.xyz;
    float warp = fbm(p * 2.0 + vec3(0.0, -0.5 * tt, 0.0));
    float fire = fbm(p * 5.0 + vec3(1.5 * warp) + vec3(0.0, -2.0 * tt, 0.0));

    float t = 0.35 * shape + 0.75 * fire;

    // Time flicker: a small displacement-phased shimmer so the color animates
    // independently of the geometry. Keeps the frag shader time-driven.
    // (6.7 * default speed 0.3 ~= the original hardcoded flicker rate of 2.0)
    t += 0.04 * sin(u_Time * u_Speed * 6.7 + fs_Displacement * 8.0);
    t = clamp(t, 0.0, 1.0);

    // Reshape the ramp: darken midtones so the bright core stays concentrated
    // at the tips instead of washing over the whole surface.
    t = bias(u_Heat, t);

    out_Col = vec4(themeColor(t, u_Theme), 1.0);
}
