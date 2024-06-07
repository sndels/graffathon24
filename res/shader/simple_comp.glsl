#version 430

#include "noise.glsl"
#include "uniforms.glsl"

layout(std430, binding = 0) buffer DataT { uvec4 positionsSpeeds[]; }
Data;

layout(local_size_x = 256) in;
void main()
{
    uint particleIndex = gl_GlobalInvocationID.x;
    // Should be initialized at the shader entrypoint e.g. as uvec3(px,
    // frameIndex)
    pcg_state = uvec3(particleIndex, uTime, 0);

    vec3 particlePos;
    particlePos.xy = unpackHalf2x16(Data.positionsSpeeds[particleIndex].x);
    particlePos.z = unpackHalf2x16(Data.positionsSpeeds[particleIndex].y).x;
    vec3 particleSpeed;
    bool resetPositions = length(particlePos) == 0;
    // resetPositions = true;
    if (resetPositions)
    {
        particlePos = rnd3d01() * 2 - 1;
        while (length(particlePos) > 1)
            particlePos = rnd3d01() * 2 - 1;
        particleSpeed = vec3(0);
    }
    else
    {
        particleSpeed.xy =
            unpackHalf2x16(Data.positionsSpeeds[particleIndex].z);
        particleSpeed.z =
            unpackHalf2x16(Data.positionsSpeeds[particleIndex].w).x;
    }

    particlePos += particleSpeed;

    float gravity = .005;
    // Clamp to avoid acceleration exploding near origo
    particleSpeed += -particlePos * gravity;
    float scale = .1;
    // particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
    particleSpeed += (sin(particlePos.x) * scale - scale / 2) * gravity;
    // particleSpeed += (sin(particlePos.z) * scale - scale / 2) * gravity;
    particleSpeed += (rnd3d01() * .1 - .1) * gravity;
    particleSpeed = min(particleSpeed, gravity * 10);
    // particleSpeed += rnd3d01() * .1 - .05;

    Data.positionsSpeeds[particleIndex] = uvec4(
        packHalf2x16(particlePos.xy), packHalf2x16(vec2(particlePos.z, 1.)),
        packHalf2x16(particleSpeed.xy),
        packHalf2x16(vec2(particleSpeed.z, 1.)));
}
