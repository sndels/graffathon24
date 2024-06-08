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

    p.z -= 1;

    {
        vec3 pp = p;
        /*
         */
        pR(p.xz, uTime * 0.1);
        pR(pp.xz, uTime);
        pR(pp.yz, uTime);
        float b = fBox(pp, vec3(0.3));
        float s0 = fSphere(p + vec3(0.5, 0.5 * sin(uTime), 0), 0.4);
        float s1 = fSphere(p, 0.5);
        float s2 = fSphere(p - vec3(0.6, 0, 0.5), 0.3);
        float s = fOpUnionRound(fOpUnionRound(s0, s1, 0.2), s2, 0.2);
        float d = mix(s, b, (sin(uTime * 0.5) + 1) * 0.5);
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

    // TODO:
    // Pass in dt in addition to uTime and scale this
    float gravity = .001;

    bool sdfScene = uTime > 30;

    vec3 particlePos = Data.particles[particleIndex].position.xyz;
    vec3 particleSpeed;
    bool resetPositions = length(particlePos) == 0;
    // resetPositions = true;
    if (resetPositions || dReset)
    {
        if (sdfScene)
        {
            particlePos = rnd3d01() * 0.5;
            // particlePos = vec3(0);
            while (length(particlePos) > 1)
                particlePos = rnd3d01() * 2 - 1;
            particleSpeed = (rnd3d01() - 0.5) * 10;
        }
        else
        {
            // Don't include time when reseting to have the same starting state
            pcg_state = uvec3(particleIndex, 0, 0);
            float startRadius = .5;
            particlePos = rnd3d01() * startRadius * 2 - startRadius;
            // particlePos.y *= .4;
            int maxIter = 10;
            while (length(particlePos) > startRadius && maxIter > 0)
            {
                particlePos = rnd3d01() * startRadius * 2 - startRadius;
                maxIter--;
            }
            particlePos += -particlePos * .3 * fbm(particlePos * 3, .55, 5);
            // vec3 fromOrigin = normalize(particlePos);
            particleSpeed = particlePos * .1 * rnd01();
        }
    }
    else
        particleSpeed = Data.particles[particleIndex].speed.xyz;

    if (sdfScene)
        particlePos += particleSpeed * 0.002;
    else
        particlePos += particleSpeed;

    // Clamp to avoid acceleration exploding near origo
    float scale = .1;

    if (sdfScene)
    {
        if (scene(particlePos).x > 0 &&
            (dot(particleSpeed / length(particleSpeed), normal(particlePos)) >=
             0))
        {
            particleSpeed = reflect(particleSpeed, normal(particlePos));
        }
    }
    else
    {
        // Flower cloud thing
        particleSpeed -= particlePos * gravity * fbm(particlePos * 5, .5, 5);
        particleSpeed.x += sin(particlePos.x) * cos(uTime) * gravity * .01;
        particleSpeed.y += sin(particlePos.y) * cos(uTime) * gravity * .01;
    }
    // particleSpeed.z += cos(uTime) * gravity * .1;
    // float speed = length(particleSpeed);
    // float speedScale = speed / (gravity * 10);
    // if (speedScale > 1)
    //     particleSpeed /= speedScale;

    Data.particles[particleIndex].position = vec4(particlePos, 1.);
    Data.particles[particleIndex].speed = vec4(particleSpeed, 1.);
}
