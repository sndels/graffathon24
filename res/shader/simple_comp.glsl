#version 430

#include "noise.glsl"
#include "uniforms.glsl"

layout(std430, binding = 0) buffer DataT { uvec4 positionsSpeeds[]; }
Data;

layout(local_size_x = 256) in;
void main()
{
    if (uTime < -1 || uRes.x < -1)
        return;

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

    // TODO:
    // Pass in dt in addition to uTime and scale this
    float gravity = .001;
    // Clamp to avoid acceleration exploding near origo
    float scale = .1;

    vec3 sink0 = vec3(-2, 0, 0);
    vec3 sink1 = vec3(2, 0, 0);

    // Flower cloud thing
    particleSpeed += -particlePos * gravity * fbm(particlePos * 3, .25, 5);
    // float speed = length(particleSpeed);
    // float speedScale = speed / (gravity * 10);
    // if (speedScale > 1)
    //     particleSpeed /= speedScale;

    // Kewl sheared cube thing
    // particleSpeed += -particlePos * gravity;
    // particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
    // particleSpeed = min(particleSpeed, gravity * 10);

    // clang-format off
    Data.positionsSpeeds[particleIndex] = uvec4(
        packHalf2x16(particlePos.xy),
        packHalf2x16(vec2(particlePos.z, 1.)),
        packHalf2x16(particleSpeed.xy),
        packHalf2x16(vec2(particleSpeed.z, 1.))
    );
    // clang-format on
}
