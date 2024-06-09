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

// uniform bool dReset;
// uniform float dMorph;

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

    float zoomerStart = 61.5;
    float zoomerEnd = 90;
    float firstSdfStart = 15;
    float firstSdfEnd = 40;
    // This matches intesity change in solid_frag
    float secondSdfStart = 101.2;
    float secondSdfEnd = 120.0;

    bool sdfScene = (uTime > firstSdfStart && uTime < firstSdfEnd) ||
                    (uTime > secondSdfStart && uTime < secondSdfEnd);

    vec3 particlePos = Data.particles[particleIndex].position.xyz;
    vec3 particleSpeed;
    bool resetPositions =
        length(particlePos) == 0 || uTime < 7.2 || (uTime > 90 && uTime < 100);
    // resetPositions |= dReset ;
    if (resetPositions)
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
            float initialSize = 1.2;
            // This matches intesity change in solid_frag
            if (uTime > 97.5)
                initialSize = 2.5;
            while (length(particlePos) > initialSize && maxIter > 0)
            {
                particlePos = rnd3d01() * 2 - 1;
                maxIter--;
            }
            // particleSpeed += -particlePos * .8 * fbm(particlePos * 3, .25,
            // 5);
            vec3 noisePos = particlePos;
            // This can be used to reset the system in sync with music
            if (uTime > 90)
                pR(noisePos.xy, 7);
            // These also match color changes in solid_vert
            if (uTime > 93.8 && uTime < 97.5)
                pR(noisePos.xz, 3);
            else if (uTime > 97.5)
                pR(noisePos.xz, -3);
            if (uTime < 97.5)
                particlePos += -particlePos * .7 * fbm(noisePos * 3, .25, 5);
            else
            {
                particlePos += -particlePos * .6 * fbm(noisePos * 2.5, .6, 4);
                particlePos *= 2;
            }
            particleSpeed =
                0.1 * vec3(
                          sin(particlePos.y * 2) * sin(particlePos.z) * .01,
                          sin(particlePos.x) * .005, 0);
            if (uTime > 97.5)
            {
                particleSpeed.x += sin(particlePos.z) * .03;
                particleSpeed.x += sin(particlePos.y) * .02;
                particleSpeed.z += -sin(particlePos.y) * .02;
                // particleSpeed.z += 0.02;
            }
        }
    }
    else
        particleSpeed = Data.particles[particleIndex].speed.xyz;

    // TODO:
    // Pass in dt in addition to uTime and scale this
    float gravity = .001;
    if (uTime > 45)
        gravity *= 4;

    if (sdfScene)
        particlePos += particleSpeed * 1.9;
    else if (uTime < zoomerStart || uTime > secondSdfEnd)
        particlePos += particleSpeed;

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
    else if (
        (uTime > firstSdfEnd && uTime < zoomerStart) || uTime > secondSdfEnd)
    {
        // Flower cloud thing
        if (uTime < 45)
        {
            particleSpeed +=
                -particlePos * gravity * fbm(particlePos * 3, .25, 5);
            particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
        }
        else
        {
            particleSpeed +=
                -particlePos * gravity * fbm(particlePos * 3, .25, 5);
            particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
            particleSpeed.x += sin(uTime) * gravity * .1;
        }
        // This could be used in a later effect
        // if (uTime > 21.1)
        //     particleSpeed += (sin(particlePos.x) * scale - scale / 2) *
        //     gravity;
    }

    // Clear before zoomer
    if (uTime > 60 && uTime < zoomerStart)
        particleSpeed = particleSpeed + vec3(gravity * 5, 0, 0);

    Data.particles[particleIndex].position = vec4(particlePos, 1.);
    Data.particles[particleIndex].speed = vec4(particleSpeed, 1.);
}
