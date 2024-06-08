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

vec2 scene(vec3 p)
{
    vec2 h = vec2(INF);
    
    p.z -= 1;

    {
        vec3 pp = p;
        pR(pp.xz, uTime);
        pR(pp.yz, uTime);
        float d = fBox(pp, vec3(0.3));
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

    vec3 particlePos = Data.particles[particleIndex].position.xyz;
    vec3 particleSpeed;
    bool resetPositions = length(particlePos) == 0;
    // resetPositions = true;
    if (resetPositions || dReset)
    {
        particlePos = rnd3d01() * 0.5;
        //particlePos = vec3(0);
        while (length(particlePos) > 1)
            particlePos = rnd3d01() * 2 - 1;
        particleSpeed = (rnd3d01() - 0.5) * 10;
    }
    else
        particleSpeed = Data.particles[particleIndex].speed.xyz;

    particlePos += particleSpeed * 0.001;

    // TODO:
    // Pass in dt in addition to uTime and scale this
    float gravity = .0001;
    // Clamp to avoid acceleration exploding near origo
    float scale = .1;

    vec3 sink0 = vec3(-2, 0, 0);
    vec3 sink1 = vec3(2, 0, 0);

    // Flower cloud thing
    //particleSpeed += -particlePos * gravity * fbm(particlePos * 3, .25, 5);
    // particleSpeed.x += sin(uTime) * gravity * .1;
    // particleSpeed.y += cos(uTime) * gravity * .1;
    // particleSpeed.z += cos(uTime) * gravity * .1;
    // float speed = length(particleSpeed);
    // float speedScale = speed / (gravity * 10);
    // if (speedScale > 1)
    //     particleSpeed /= speedScale;

    // Kewl sheared cube thing
    // particleSpeed += -particlePos * gravity;
    // particleSpeed += (sin(particlePos.y) * scale - scale / 2) * gravity;
    // particleSpeed = min(particleSpeed, gravity * 10);
    //particleSpeed += -normal(particlePos) * 0.1;

    if (scene(particlePos).x > 0 &&
        (dot(particleSpeed / length(particleSpeed), normal(particlePos)) >= 0)) {
        particleSpeed = reflect(particleSpeed, normal(particlePos));
    }

    Data.particles[particleIndex].position = vec4(particlePos, 1.);
    Data.particles[particleIndex].speed = vec4(particleSpeed, 1.);
}
