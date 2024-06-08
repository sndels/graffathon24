#version 430

#include "noise.glsl"
#include "uniforms.glsl"

#define INF (1.0 / 0.0)
#include "hg_sdf.glsl"

struct Particle
{
    vec4 position;
    vec4 speed;
};

layout(std430, binding = 0) buffer DataT { Particle particles[]; }
Data;

uniform bool dReset;
uniform float dMorph;

vec2 scene(vec3 p)
{
    vec2 h = vec2(INF);

    // p.z -= 1;

    {
        vec3 pp = p;
        /*
         */
        pR(p.xz, uTime * 0.1);
        pR(pp.xz, uTime * 0.5);
        pR(pp.yz, uTime * 0.5);
        float b = fBox(pp, vec3(0.3));
        float s0 = fSphere(
            p + vec3(
                    0.2 + sin(uTime * 0.8) * .5, 0.5 * sin(uTime * 0.7) * 1.2,
                    0),
            0.3);
        float s1 = fSphere(p, 0.5);
        float s2 = fSphere(p - vec3(0.3, 0, 0.5), 0.2);
        float s = fOpUnionRound(fOpUnionRound(s0, s1, 0.1), s2, 0.1);
        float d = mix(s, b, (sin(uTime * 0.2) + 1) * 0.5);
        // float d = mix(s, b, dMorph);
        h = d < h.x ? vec2(d, 0) : h;
    }

    return h;
}

vec3 normal(vec3 p)
{
    vec3 e = vec3(0.00001, 0, 0);
    vec3 n = vec3(
        scene(vec3(p + e.xyy)).x - scene(vec3(p - e.xyy)).x,
        scene(vec3(p + e.yxy)).x - scene(vec3(p - e.yxy)).x,
        scene(vec3(p + e.yyx)).x - scene(vec3(p - e.yyx)).x);
    return normalize(n);
}

layout(local_size_x = 256) in;
void main()
{
    if (uTime < -1 || uRes.x < -1 || uAspectRatio < -1)
        return;

    uint particleIndex = gl_GlobalInvocationID.x;
    // Should be initialized at the shader entrypoint e.g. as uvec3(px,
    // frameIndex)
    pcg_state = uvec3(particleIndex, uTime, 0);

    bool sdfScene = (uTime > 30 && uTime < 45) || uTime > 52.6;

    vec3 particlePos = Data.particles[particleIndex].position.xyz;
    vec3 particleSpeed;
    bool resetPositions = length(particlePos) == 0 || uTime < 7.2;
    // resetPositions = true;
    if (resetPositions || dReset)
    {
        if (sdfScene)
        {
            particlePos = rnd3d01() * 0.5;
            // particlePos = vec3(0);
            int maxIter = 10;
            while (length(particlePos) > 1 && maxIter > 0)
            {
                particlePos = rnd3d01() * 2 - 1;
                maxIter--;
            }
            particleSpeed = (rnd3d01() - 0.5) * 10;
        }
        else
        {
            // No time here to keep the reset state constant
            pcg_state = uvec3(particleIndex, 0, 0);
            particlePos = rnd3d01() * 2 - 1;
            int maxIter = 10;
            while (length(particlePos) > 1.2 && maxIter > 0)
            {
                particlePos = rnd3d01() * 2 - 1;
                maxIter--;
            }
            // particleSpeed += -particlePos * .8 * fbm(particlePos * 3, .25,
            // 5);
            particlePos += -particlePos * .7 * fbm(particlePos * 3, .25, 5);
            particleSpeed =
                0.1 * vec3(
                          sin(particlePos.y * 2) * sin(particlePos.z) * .01,
                          sin(particlePos.x) * .005, 0);
        }
    }
    else
        particleSpeed = Data.particles[particleIndex].speed.xyz;

    if (sdfScene)
        particlePos += particleSpeed * 1.9;
    else
        particlePos += particleSpeed;

    // TODO:
    // Pass in dt in addition to uTime and scale this
    float gravity = .001;
    if (uTime > 45)
        gravity *= 4;
    // Clamp to avoid acceleration exploding near origo
    float scale = .1;

    if (sdfScene)
    {
        if (scene(particlePos).x > 0 &&
            (dot(particleSpeed / length(particleSpeed), normal(particlePos)) >=
             0))
        {
#if 1
            particleSpeed =
                0.9999 * reflect(particleSpeed, normal(particlePos)) +
                0.0001 * -normal(particlePos);
#else
            particleSpeed =
                mix(reflect(particleSpeed, normal(particlePos)),
                    -normal(particlePos), 0.0);
#endif
        }
    }
    else if (uTime > 15)
    {
        // Flower cloud thing
        if (uTime < 45)
        {
            particleSpeed +=
                -particlePos * gravity * fbm(particlePos * 3, .25, 5);
            particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
        }
        else if (uTime < 45.4)
            particleSpeed +=
                particlePos * gravity * .5 * fbm(particlePos * 20, .85, 5);
        else
        {
            particleSpeed +=
                -particlePos * gravity * fbm(particlePos * 3, .25, 5);
            particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
            particleSpeed.x += sin(uTime) * gravity * .1;
        }
        if (uTime > 21.1)
            particleSpeed += (sin(particlePos.x) * scale - scale / 2) * gravity;
    }

    Data.particles[particleIndex].position = vec4(particlePos, 1.);
    Data.particles[particleIndex].speed = vec4(particleSpeed, 1.);
}
