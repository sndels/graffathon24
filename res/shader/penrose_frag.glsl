#version 430

#include "hg_sdf.glsl"
#include "uniforms.glsl"

uniform vec3 dColor;


struct PenroseTriangle {
    vec2    p;
};

layout(std430, binding = 0) buffer Triangles { PenroseTriangle data[]; } triangles;
uniform int nTriangles;

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
    for (int i=0; i<nTriangles; ++i) {
        diff = triangles.data[i].p-p;
        disSqr = dot(diff, diff);
        if (disSqr < 0.0001) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }

        if (disSqr < minDisSqr) {
            minDisSqr = disSqr;
            pId = i;
        }
    }

    fragColor = vec4(0.5+0.5*sin(pId), 0.5+0.5*cos(pId), 0.5-0.5*sin(pId), 1);
}
