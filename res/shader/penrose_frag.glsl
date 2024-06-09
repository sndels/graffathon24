#version 430

#include "hg_sdf.glsl"
#include "uniforms.glsl"

uniform vec3 dCamera; // x, y, rot
uniform vec3 dZoom; // x, y, amount
uniform float dColorStyle; // thresholded at 0.5 to switch between the 2 styles
uniform vec3 dWarp; // x, y, bläst

struct PenroseTriangle
{
    ivec4 m;
    mat2 uvmInv;
    vec2 o;
    uint _pad0;
    uint _pad1;
};

layout(std430, binding = 0) buffer Triangles { PenroseTriangle data[]; }
triangles;
uniform int nTriangles;

out vec4 fragColor;

#define REC_DEPTH 9
#define GOLDEN_RATIO 1.618033988749894

bool tail(
    in vec2 p, int tId, out int tIds[REC_DEPTH], out vec2 uvs[REC_DEPTH],
    out int types[REC_DEPTH])
{
    vec2 uv = triangles.data[tId].uvmInv * (p - triangles.data[tId].o);
    if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x + uv.y < 1.0)
    {
        uvs[REC_DEPTH - 1] = uv;
        tIds[REC_DEPTH - 1] = tId;
        types[REC_DEPTH - 1] = triangles.data[tId].m[0];
        return true;
    }
    return false;
}

#define RECURSE_TRIANGLES(fname, fchildname, reclevel)                         \
    bool fname(                                                                \
        in vec2 p, int tId, out int tIds[REC_DEPTH], out vec2 uvs[REC_DEPTH],  \
        out int types[REC_DEPTH])                                              \
    {                                                                          \
        vec2 uv = triangles.data[tId].uvmInv * (p - triangles.data[tId].o);    \
        if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x + uv.y < 1.0)                   \
        {                                                                      \
            for (int i = 0; i < 3; ++i)                                        \
            {                                                                  \
                int tId2 = triangles.data[tId].m[i + 1];                       \
                if (tId2 == 0)                                                 \
                    break;                                                     \
                if (fchildname(p, tId2, tIds, uvs, types))                     \
                    break;                                                     \
            }                                                                  \
            uvs[reclevel] = uv;                                                \
            tIds[reclevel] = tId;                                              \
            types[reclevel] = triangles.data[tId].m[0];                        \
            return true;                                                       \
        }                                                                      \
        return false;                                                          \
    }

//RECURSE_TRIANGLES(recf8, tail, 7)
//RECURSE_TRIANGLES(recf7, recf8, 6)
//RECURSE_TRIANGLES(recf6, recf7, 5)
RECURSE_TRIANGLES(recf5, tail, 4)
RECURSE_TRIANGLES(recf4, recf5, 3)
RECURSE_TRIANGLES(recf3, recf4, 2)
RECURSE_TRIANGLES(recf2, recf3, 1)
RECURSE_TRIANGLES(recf1, recf2, 0)

vec3 color(vec2 uv, int type)
{
    if (dColorStyle < 0.5)
    {
        if (type == 0) {
            float d = sqrt(dot(uv, uv));
            float a1 = d < 1.0 - 1.0 / GOLDEN_RATIO ? 0.0 : 1.0;
            return vec3(a1, 0.0, 0.0);
        }
        else
            return vec3(0.3, 0.8, 0.5);
    }
    else
    {
        float a = square(uv.x * 2.0 - 1.0);
        a -= a * a;
        a *= 4.0;
        return vec3(a, a, a);
    }
}

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1 || uAspectRatio < -1 || nTriangles < -1)
        discard;

    vec2 p = (gl_FragCoord.xy * 2.0) / uRes.yy - vec2(uAspectRatio, 1.0);

    p -= dZoom.xy;
    float zoom = dZoom.z;

    vec2 warpVec = p - dWarp.xy;
    float w = dot(warpVec, warpVec);

    p *= (1.0 - dWarp.z) + dWarp.z / (w + 0.5);

    p /= 0.25 * pow(GOLDEN_RATIO, zoom);

    mat2 cameraRot = mat2(cos(dCamera.z), sin(dCamera.z), -sin(dCamera.z), cos(dCamera.z));
    p = cameraRot*p;
    p += dCamera.xy;

    int tIds[REC_DEPTH];
    vec2 uvs[REC_DEPTH];
    int types[REC_DEPTH];
    for (int tId = 0; tId < 10; ++tId)
    {
        if (recf1(p, tId, tIds, uvs, types))
        {
            int zoomLevel = int(zoom);
            float zoomFrac = zoom - zoomLevel;
            vec2 uv1 = uvs[zoomLevel];
            vec2 uv2 = uvs[zoomLevel + 1];
            vec2 uv3 = uvs[zoomLevel + 2];
            vec2 uv4 = uvs[zoomLevel + 3];
            int type1 = types[zoomLevel];
            int type2 = types[zoomLevel + 1];
            int type3 = types[zoomLevel + 2];
            int type4 = types[zoomLevel + 3];

            vec3 c;
            if (dColorStyle < 0.5)
            {
                vec3 c2 = color(uv2, type2);
                c = c2;
            }
            else
            {
                vec3 c1 = color(uv1, 0);
                vec3 c2 = color(uv2, 0);
                vec3 c3 = color(uv3, 0);
                vec3 c4 = color(uv4, 0);

                float z1 = clamp((zoomFrac + 1.0) * 0.5, 0.0, 1.0);
                vec3 w1 =
                    vec3(square(1.0 - z1), 2.0 * z1 * (1.0 - z1), z1 * z1);
                float z2 = clamp(zoomFrac * 0.5, 0.0, 1.0);
                vec3 w2 =
                    vec3(square(1.0 - z2), 2.0 * z2 * (1.0 - z2), z2 * z2);
                float wm = clamp(zoomFrac, 0.0, 1.0);

                vec3 ca = w1.x * c1 + w1.y * c2 + w1.z * c3;
                vec3 cb = w2.x * c2 + w2.y * c3 + w2.z * c4;
                c = (1.0 - wm) * ca + wm * cb;

                c = 0.5 + 0.5 * tanh((c - 0.5) * 5.0);
                c.r = pow(c.r, 10.0);
                c.g = pow(c.g, 7.0);
                c.b = pow(c.b, 3.0);
            }

            fragColor = vec4(c, 1.0);
            return;
        }
    }

    fragColor = vec4(0.0, 0.0, 0, 1);
}
