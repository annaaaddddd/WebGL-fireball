// Shared color / toolbox helpers, pulled into shaders via `#include "color.glsl"`
// (spliced in as a string by assembleShader in main.ts). Any shader that needs to match
// the fireball's current theme (e.g. the background glow) should use
// themeColor() so every theme change stays consistent across the scene.

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

// Maps a brightness value t in [0, 1] to the given theme's color ramp.
// The palette themes get a brightness ramp layered on top so every theme
// keeps the same dark-body / hot-tips structure as the fire gradient.
vec3 themeColor(float t, int theme)
{
    vec3 col;
    if (theme == 1) {
        // Ghostfire: deep blue -> bright cyan
        col = cosinePalette(t, vec3(0.15, 0.40, 0.65), vec3(0.20, 0.45, 0.35),
                               vec3(0.5), vec3(0.50, 0.52, 0.45));
    } else if (theme == 2) {
        // Toxic: near-black -> acid green
        col = cosinePalette(t, vec3(0.10, 0.40, 0.15), vec3(0.30, 0.50, 0.20),
                               vec3(0.5), vec3(0.50, 0.50, 0.55));
    } else if (theme == 3) {
        // Cosmic: dark violet -> pink lavender
        col = cosinePalette(t, vec3(0.35, 0.15, 0.50), vec3(0.45, 0.25, 0.40),
                               vec3(0.5), vec3(0.48, 0.50, 0.42));
    } else {
        col = fireGradient(t);
    }

    if (theme != 0) {
        col *= 0.3 + 0.7 * t;
    }

    return col;
}
