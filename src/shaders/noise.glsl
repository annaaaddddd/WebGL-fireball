// Shared noise helpers, pulled into shaders via `#include "noise.glsl"`
// (spliced in as a string by assembleShader in main.ts).
// No #version or precision here — the including shader provides those.

// Hash a 3D position to a deterministic value in [0, 1].
float random3D(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

// 3D value noise: random values at the eight lattice corners around p,
// blended with Perlin's fade curve so the result is smooth.
float valueNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    float c000 = random3D(i + vec3(0.0, 0.0, 0.0));
    float c100 = random3D(i + vec3(1.0, 0.0, 0.0));
    float c010 = random3D(i + vec3(0.0, 1.0, 0.0));
    float c110 = random3D(i + vec3(1.0, 1.0, 0.0));
    float c001 = random3D(i + vec3(0.0, 0.0, 1.0));
    float c101 = random3D(i + vec3(1.0, 0.0, 1.0));
    float c011 = random3D(i + vec3(0.0, 1.0, 1.0));
    float c111 = random3D(i + vec3(1.0, 1.0, 1.0));

    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float x00 = mix(c000, c100, u.x);
    float x10 = mix(c010, c110, u.x);
    float x01 = mix(c001, c101, u.x);
    float x11 = mix(c011, c111, u.x);

    float y0 = mix(x00, x10, u.y);
    float y1 = mix(x01, x11, u.y);

    return mix(y0, y1, u.z);
}

// Fractional Brownian motion: five octaves of value noise, each at double
// the frequency and half the amplitude, so detail appears at several scales.
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * valueNoise3D(p * frequency);

        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}
