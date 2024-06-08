#version 430

#include "uniforms.glsl"

uniform float dIntensity;

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
    color = inColor * dIntensity + 0.01;
    float r = sqrt(dot(inCoord, inCoord));
    r = clamp(r, 0, 1);
    float fade = 1. - r;

    outColor = vec4(color, fade);
}
