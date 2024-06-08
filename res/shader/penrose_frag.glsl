#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"

uniform vec3 dColor;

uniform vec2 points[3] = {{1.0, 0.0}, {0.0, 0.5}, {0.5, 1.0}};

out vec4 fragColor;

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1)
        discard;

    vec2 p = (gl_FragCoord.xy*2.0) / uRes.yy - vec2(uAspectRatio, 1.0);

    int pId = 0;
    vec2 diff;
    float disSqr = 0.0;
    float minDisSqr = 100.0;
    for (int i=0; i<3; ++i) {
        diff = points[i]-p;
        disSqr = dot(diff, diff);
        if (disSqr < minDisSqr) {
            minDisSqr = disSqr;
            pId = i;
        }
    }

    fragColor = vec4(0.5+0.5*sin(pId), 0.5+0.5*cos(pId), 0.5-0.5*sin(pId), 1);
}
