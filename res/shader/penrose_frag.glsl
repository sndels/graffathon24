#version 430

#include "hg_sdf.glsl"
#include "uniforms.glsl"

// uniform vec3 dCamera;      // x, y, rot
// uniform vec3 dZoom;        // x, y, amount
// uniform float dColorStyle; // thresholded at 0.5 to switch between the 2
// styles uniform vec3 dWarp;        // x, y, bläst
const vec3 dColor1 = vec3(0.297, 0.454, 0.752);
const vec3 dColor2 = vec3(0.798, 0.145, 0.370);

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

RECURSE_TRIANGLES(recf8, tail, 7)
RECURSE_TRIANGLES(recf7, recf8, 6)
RECURSE_TRIANGLES(recf6, recf7, 5)
RECURSE_TRIANGLES(recf5, recf6, 4)
RECURSE_TRIANGLES(recf4, recf5, 3)
RECURSE_TRIANGLES(recf3, recf4, 2)
RECURSE_TRIANGLES(recf2, recf3, 1)
RECURSE_TRIANGLES(recf1, recf2, 0)

vec3 color(vec2 uv, int type, float colorStyle)
{
    vec3 color1, color2;
    if (type == 0) {
        vec3 a = vec3(uv.x, uv.y, 1.0 - uv.x - uv.y);
        float mask = pow(a.y*a.x*8.0, 0.3);
        vec3 c = dColor1;
        color1 = c*mask;
    }
    else {
        vec3 a = vec3(uv.x, uv.y, 1.0 - uv.x - uv.y);
        float mask = pow(a.y*a.x*4.0, 0.3);
        vec3 c = dColor2;
        color1 = c*mask;
    }

    float a = square(uv.x * 2.0 - 1.0);
    a -= a * a;
    a *= 4.0;
    color2 = vec3(a, a, a);
    return (1.0-colorStyle)*color1 + colorStyle*color2;
}

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1 || uAspectRatio < -1 || nTriangles < -1)
        discard;

    vec2 p = (gl_FragCoord.xy * 2.0) / uRes.yy - vec2(uAspectRatio, 1.0);

    float t = uTime - 60;
    float rotT = t + .2 * (sin((uTime / 120) * 128 * 3.1415 * 2) * 0.5 + 1);
    float zoomT = t;
    if (uTime > 72)
        zoomT -= (uTime - 72) * 1.25;
    vec3 dCamera = vec3(0, 0, 0); // x, y, rot
    dCamera.z = mix(-.5, 2.0, rotT / 5.0);
    vec3 dZoom = vec3(0, 0, 0); // x, y, amount
    dZoom.z = mix(-.5, 2.0, zoomT / 5.0);
    float dColorStyle = 0.0;
    if (uTime > 70)
        dColorStyle = mix(0., 1.0, clamp((uTime - 70) / 4, 0, 1));
    vec3 dWarp = vec3(0, 0, 0); // x, y, bläst
    if (uTime > 72)
    {
        dWarp.x = mix(0.0, .5, (t - 12) / t);
        dWarp.z = mix(0.0, 2.0, (t - 12) / t);
    }

    p -= dZoom.xy;
    float zoom = dZoom.z;

    vec2 warpVec = p - dWarp.xy;
    float w = dot(warpVec, warpVec);

    p *= (1.0 - dWarp.z) + dWarp.z / (w + 0.5);

    p /= 0.25 * pow(GOLDEN_RATIO, zoom);

    mat2 cameraRot =
        mat2(cos(dCamera.z), sin(dCamera.z), -sin(dCamera.z), cos(dCamera.z));
    p = cameraRot * p;
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

            vec3 cc1, cc2;
//            if (dColorStyle < 0.5)
//            {
                vec3 ca = color(uv1, type1, dColorStyle);
                vec3 cb = color(uv2, type2, dColorStyle);
                cc1 = (1.0 - zoomFrac) * ca + zoomFrac * cb;
//            }
//            else
//            {
                vec3 c1 = color(uv1, 0, dColorStyle);
                vec3 c2 = color(uv2, 0, dColorStyle);
                vec3 c3 = color(uv3, 0, dColorStyle);
                vec3 c4 = color(uv4, 0, dColorStyle);

                float z1 = clamp((zoomFrac + 1.0) * 0.5, 0.0, 1.0);
                vec3 w1 =
                    vec3(square(1.0 - z1), 2.0 * z1 * (1.0 - z1), z1 * z1);
                float z2 = clamp(zoomFrac * 0.5, 0.0, 1.0);
                vec3 w2 =
                    vec3(square(1.0 - z2), 2.0 * z2 * (1.0 - z2), z2 * z2);
                float wm = clamp(zoomFrac, 0.0, 1.0);

                ca = w1.x * c1 + w1.y * c2 + w1.z * c3;
                cb = w2.x * c2 + w2.y * c3 + w2.z * c4;
                cc2 = (1.0 - wm) * ca + wm * cb;

                cc2 = 0.5 + 0.5 * tanh((cc2 - 0.5) * 5.0);
                cc2.r = pow(cc2.r, 10.0);
                cc2.g = pow(cc2.g, 7.0);
                cc2.b = pow(cc2.b, 3.0);
//            }

            fragColor = vec4((1.0-dColorStyle)*cc1 + dColorStyle*cc2, 1.0);
            return;
        }
    }

    fragColor = vec4(0.0, 0.0, 0, 1);
}
