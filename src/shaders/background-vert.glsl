#version 300 es

//This is a vertex shader for space themed background.

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

out vec2 fs_UV;

void main()
{
    gl_Position = vec4(vs_Pos.xy, 0.0, 1.0);
    fs_UV = vs_Pos.xy;  // NDC xy doubles as the UV, range [-1, 1]
}