#version 430

#include "camera.glsl"
#include "uniforms.glsl"

uniform vec3 dCamTarget;
uniform float dRadius;
uniform float dHue0;
uniform float dHue1;

struct Particle
{
    vec4 position;
    vec4 speed;
};

layout(std430, binding = 0) buffer DataT { Particle particles[]; }
Data;

layout(location = 0) out vec2 outCoord;
layout(location = 1) out vec3 outColor;

vec3 rgbToHsv(vec3 rgb)
{
    // https://en.wikipedia.org/wiki/HSL_and_HSV

    float value = max(max(rgb.r, rgb.g), rgb.b);
    float valueMinusChroma = min(min(rgb.r, rgb.g), rgb.b);
    float chroma = value - valueMinusChroma;

    // TODO:
    // Feels like these branches and the value/valueMinusChroma could be folded
    // together
    float hue;
    if (chroma == 0.)
        hue = 0.;
    else if (value == rgb.r)
        hue = mod((rgb.g - rgb.b) / chroma, 6.);
    else if (value == rgb.g)
        hue = (rgb.b - rgb.r) / chroma + 2.;
    else
        hue = (rgb.r - rgb.g) / chroma + 4.;

    float saturation = value == 0. ? 0. : chroma / value;

    return vec3(hue, saturation, value);
}

// Expects HSV with hue not scaled to degrees
vec3 hsvToRgb(vec3 hsv)
{
    // https://en.wikipedia.org/wiki/HSL_and_HSV

    float hue = hsv.r;
    float saturation = hsv.g;
    float value = hsv.b;

    float chroma = value * saturation;

    float x = chroma * (1. - abs(mod(hue, 2.) - 1.));

    // TODO:
    // That's a lot of branching. Is there a clever branchless algo here that's
    // nicer for GPUs?
    vec3 rgb;
    if (hue < 1.)
        rgb = vec3(chroma, x, 0.);
    else if (hue < 2.)
        rgb = vec3(x, chroma, 0.);
    else if (hue < 3.)
        rgb = vec3(0., chroma, x);
    else if (hue < 4.)
        rgb = vec3(0., x, chroma);
    else if (hue < 5.)
        rgb = vec3(x, 0., chroma);
    else
        rgb = vec3(chroma, 0., x);

    float m = value - chroma;

    return rgb + m;
}

void main()
{
    int particleIndex = gl_VertexID / 6;
    int vertexIndex = gl_VertexID % 6;

    vec3 particlePos = Data.particles[particleIndex].position.xyz;
    vec3 particleSpeed = Data.particles[particleIndex].speed.xyz;

    vec3 camPos = vec3(0, 0, -2);
    float camSpeed = .1;
    camPos = vec3(sin(uTime * camSpeed), 0, cos(uTime * camSpeed));
    vec3 camTarget = vec3(0, 0, 0);
    // vec3 camTarget = dCamTarget;
    mat4 viewMat = worldToCamera(camPos, camTarget, vec3(0, 1, 0));

    particlePos = (viewMat * vec4(particlePos, 1.)).xyz;

    float radius = 0.0035 + .001 * dRadius;

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

    float fov = radians(100);
    mat4 clipMat = cameraToClip(fov, uRes, .1, 100.);

    gl_Position = clipMat * vec4(particlePos, 1.);

    vec3 hsv0;
    vec3 hsv1;
    if (uTime < 21)
    {
        hsv0 = vec3(4.11, .85, .6);
        hsv1 = vec3(4.11, .85, .6);
    }
    else if (uTime < 22)
    {
        hsv0 = vec3(4.11, .9, .8);
        hsv1 = vec3(5.11, .9, .7);
    }
    else
    {
        hsv0 = vec3(4.11, .9, .8);
        hsv1 = vec3(9.92, .9, .7);
    }

    vec3 hsv =
        mix(hsv0, hsv1, 1 - clamp(length(particleSpeed) * 200. - 2., 0, 1));
    outColor = hsvToRgb(hsv);
}
