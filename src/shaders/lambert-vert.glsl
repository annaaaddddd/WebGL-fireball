#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform float u_Speed;    // Global animation speed multiplier
uniform float u_Wobble;   // Amplitude of the low-frequency sinusoidal layer
uniform float u_FbmAmp;   // Amplitude of the high-frequency FBM detail layer
uniform float u_FbmFreq;  // Spatial frequency of the FBM detail layer

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out float fs_Displacement;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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

void main()
{
    vec3 pos = vs_Pos.xyz;

    float t = u_Time * u_Speed;
    float lowFreq = sin(1.1 * pos.x + t) * sin(0.5 * pos.y + 1.3 * t) + sin(2.3 * pos.z + 0.7 * t);
    fs_Displacement = u_Wobble * lowFreq + u_FbmAmp * fbm(pos * u_FbmFreq + vec3(0.0, -t, 0.0));
    vec4 displacedPos = vs_Pos + vs_Nor * fs_Displacement;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * displacedPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
