#version 430

#include "uniforms.glsl"

// uniform float dIntensity;

// in vec3 inPosition;
layout(location = 0) in vec2 inCoord;
layout(location = 1) in vec3 inColor;

out vec4 outColor;

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1 || uAspectRatio < -1)
        discard;

    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec3 color = +vec3(0, 0, 0.1 * sin(uTime) + .1);
    float intensity = 1.0;
    if (uTime > 97.5)
        intensity = 1.7;
    if (uTime > 101.2)
        intensity = 2.2;
    if (uTime > 123.8)
        intensity = mix(10, 2.2, (uTime - 123.8) / (150 - 123.8));
    // intensity += dIntensity;

    intensity +=
        pow((cos((uTime / 60) * 128 * 3.1415 * 2) * 0.5 + 1), 1.5) * 0.5 - 0.5;

    color = inColor * intensity;
    float r = sqrt(dot(inCoord, inCoord));
    r = clamp(r, 0, 1);
    float fade = 1. - r;

    outColor = vec4(color, fade);
}
