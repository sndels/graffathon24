#version 430

#include "hg_sdf.glsl"
#include "uniforms.glsl"

uniform vec3 dColor;

out vec4 fragColor;

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1)
        discard;

    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec3 color = dColor + vec3(uv, 0.5 * sin(uTime) + 0.5);

    // fragColor = vec4(color, 1);
    fragColor = vec4(1);
}
