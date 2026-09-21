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

out vec4 out_Col;

// Toolbox function: bias. b < 0.5 pulls midtones down (concentrates the
// bright range near t = 1), b > 0.5 pushes them up.
float bias(float b, float t)
{
    return t / ((1.0 / b - 2.0) * (1.0 - t) + 1.0);
}

// Inigo Quilez cosine palette: a + b * cos(2pi * (c * t + d)).
// With c = 0.5 the palette sweeps exactly half a period over t in [0, 1],
// so it runs dark -> bright monotonically instead of wrapping around.
vec3 cosinePalette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos(6.2831853 * (c * t + d));
}

// Theme 0: hand-tuned fire gradient. Four color stops blended with
// smoothstep so each transition's position and width is art-directable.
vec3 fireGradient(float t)
{
    const vec3 smoke  = vec3(0.08, 0.02, 0.02);
    const vec3 red    = vec3(0.55, 0.05, 0.00);
    const vec3 orange = vec3(1.00, 0.45, 0.05);
    const vec3 yellow = vec3(1.00, 0.90, 0.30);
    const vec3 white  = vec3(1.00, 1.00, 0.95);

    vec3 col = mix(smoke, red, smoothstep(0.00, 0.35, t));
    col = mix(col, orange, smoothstep(0.35, 0.65, t));
    col = mix(col, yellow, smoothstep(0.65, 0.85, t));
    col = mix(col, white,  smoothstep(0.85, 1.00, t));
    return col;
}

void main()
{
    // Normalize displacement (roughly [-0.6, 0.85] out of the vertex shader)
    // to [0, 1]; smoothstep also clamps anything outside the range.
    float t = smoothstep(-0.6, 0.85, fs_Displacement);

    // Time flicker: a small displacement-phased shimmer so the color animates
    // independently of the geometry. Keeps the frag shader time-driven.
    // (6.7 * default speed 0.3 ~= the original hardcoded flicker rate of 2.0)
    t += 0.04 * sin(u_Time * u_Speed * 6.7 + fs_Displacement * 8.0);
    t = clamp(t, 0.0, 1.0);

    // Reshape the ramp: darken midtones so the bright core stays concentrated
    // at the tips instead of washing over the whole surface.
    t = bias(u_Heat, t);

    vec3 col;
    if (u_Theme == 1) {
        // Ghostfire: deep blue -> bright cyan
        col = cosinePalette(t, vec3(0.15, 0.40, 0.65), vec3(0.20, 0.45, 0.35),
                               vec3(0.5), vec3(0.50, 0.52, 0.45));
    } else if (u_Theme == 2) {
        // Toxic: near-black -> acid green
        col = cosinePalette(t, vec3(0.10, 0.40, 0.15), vec3(0.30, 0.50, 0.20),
                               vec3(0.5), vec3(0.50, 0.50, 0.55));
    } else if (u_Theme == 3) {
        // Cosmic: dark violet -> pink lavender
        col = cosinePalette(t, vec3(0.35, 0.15, 0.50), vec3(0.45, 0.25, 0.40),
                               vec3(0.5), vec3(0.48, 0.50, 0.42));
    } else {
        col = fireGradient(t);
    }

    // For the palette themes, layer a brightness ramp on top so every theme
    // keeps the same dark-body / hot-tips structure as the fire gradient.
    if (u_Theme != 0) {
        col *= 0.3 + 0.7 * t;
    }

    out_Col = vec4(col, 1.0);
}
