#version 430

#include "camera.glsl"
#include "uniforms.glsl"

uniform vec3 dCamTarget;

layout(std430, binding = 0) buffer DataT { uvec4 positionsSpeeds[]; }
Data;

layout(location = 0) out vec2 outCoord;

void main()
{
    int particleIndex = gl_VertexID / 6;
    int vertexIndex = gl_VertexID % 6;

    vec3 particlePos;
    particlePos.xy = unpackHalf2x16(Data.positionsSpeeds[particleIndex].x);
    particlePos.z = unpackHalf2x16(Data.positionsSpeeds[particleIndex].y).x;

    vec3 camPos = vec3(0, 0, -2);
    vec3 camTarget = vec3(0, 0, 0);
    // vec3 camTarget = dCamTarget;
    mat4 viewMat = worldToCamera(camPos, camTarget, vec3(0, 1, 0));

    particlePos = (viewMat * vec4(particlePos, 1.)).xyz;

    float radius = .005;

    if (vertexIndex == 0 || vertexIndex == 3)
    {
        particlePos += vec3(-radius, -radius, 0.);
        outCoord = vec2(-1, -1);
    }
    else if (vertexIndex == 1)
    {
        particlePos += vec3(radius, -radius, 0.);
        outCoord = vec2(1, -1);
    }
    else if (vertexIndex == 2 || vertexIndex == 4)
    {
        particlePos += vec3(radius, radius, 0.);
        outCoord = vec2(1, 1);
    }
    else
    {
        particlePos += vec3(-radius, radius, 0.);
        outCoord = vec2(-1, 1);
    }

    mat4 clipMat = cameraToClip(radians(60), uRes, .1, 100.);

    gl_Position = clipMat * vec4(particlePos, 1.);
}
