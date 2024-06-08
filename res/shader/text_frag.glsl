#version 430

#include "2d_sdf.glsl"
#include "uniforms.glsl"

uniform vec3 dColor;
uniform float dChar;

out vec4 fragColor;

void renderChar(uint c, vec2 pp, inout float d, inout float drawingCursor)
{
    if (c == 0)
        d = fOpUnion(d, dCharA(pp - vec2(drawingCursor, 0)));
    else if (c == 1)
        d = fOpUnion(d, dCharB(pp - vec2(drawingCursor, 0)));
    else if (c == 2)
        d = fOpUnion(d, dCharC(pp - vec2(drawingCursor, 0)));
    else if (c == 3)
        d = fOpUnion(d, dCharD(pp - vec2(drawingCursor, 0)));
    else if (c == 4)
        d = fOpUnion(d, dCharE(pp - vec2(drawingCursor, 0)));
    else if (c == 5)
        d = fOpUnion(d, dCharF(pp - vec2(drawingCursor, 0)));
    else if (c == 6)
        d = fOpUnion(d, dCharG(pp - vec2(drawingCursor, 0)));
    else if (c == 7)
        d = fOpUnion(d, dCharH(pp - vec2(drawingCursor, 0)));
    else if (c == 8)
        d = fOpUnion(d, dCharI(pp - vec2(drawingCursor, 0)));
    else if (c == 9)
        d = fOpUnion(d, dCharJ(pp - vec2(drawingCursor, 0)));
    else if (c == 10)
        d = fOpUnion(d, dCharK(pp - vec2(drawingCursor, 0)));
    else if (c == 11)
        d = fOpUnion(d, dCharL(pp - vec2(drawingCursor, 0)));
    else if (c == 12)
        d = fOpUnion(d, dCharM(pp - vec2(drawingCursor, 0)));
    else if (c == 13)
        d = fOpUnion(d, dCharN(pp - vec2(drawingCursor, 0)));
    else if (c == 14)
        d = fOpUnion(d, dCharO(pp - vec2(drawingCursor, 0)));
    else if (c == 15)
        d = fOpUnion(d, dCharP(pp - vec2(drawingCursor, 0)));
    else if (c == 16)
        d = fOpUnion(d, dCharQ(pp - vec2(drawingCursor, 0)));
    else if (c == 17)
        d = fOpUnion(d, dCharR(pp - vec2(drawingCursor, 0)));
    else if (c == 18)
        d = fOpUnion(d, dCharS(pp - vec2(drawingCursor, 0)));
    else if (c == 19)
        d = fOpUnion(d, dCharT(pp - vec2(drawingCursor, 0)));
    else if (c == 20)
        d = fOpUnion(d, dCharU(pp - vec2(drawingCursor, 0)));
    else if (c == 21)
        d = fOpUnion(d, dCharV(pp - vec2(drawingCursor, 0)));
    else if (c == 22)
        d = fOpUnion(d, dCharW(pp - vec2(drawingCursor, 0)));
    else if (c == 23)
        d = fOpUnion(d, dCharX(pp - vec2(drawingCursor, 0)));
    else if (c == 24)
        d = fOpUnion(d, dCharY(pp - vec2(drawingCursor, 0)));
    else if (c == 25)
        d = fOpUnion(d, dCharZ(pp - vec2(drawingCursor, 0)));
    else if (c == 26)
        d = fOpUnion(d, dCharExclamation(pp - vec2(drawingCursor, 0)));
    else if (c == 27)
        d = fOpUnion(d, dCharColon(pp - vec2(drawingCursor, 0)));
    else if (c == 28)
        d = fOpUnion(d, dCharDash(pp - vec2(drawingCursor, 0)));
    else if (c == 29)
        d = fOpUnion(d, dCharUnderscore(pp - vec2(drawingCursor, 0)));
    else if (c == 30)
        d = fOpUnion(d, dCharSpace(pp - vec2(drawingCursor, 0)));
    else
        d = fOpUnion(d, dCharBox(pp - vec2(drawingCursor, 0)));
    drawingCursor += FONT_WIDTH;
}

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1. || uRes.x < -1.)
        discard;

    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec3 color = vec3(0);
    float ar = float(uRes.x) / uRes.y;

    vec2 p = (uv * 2. - 1.);
    p.x *= ar;
    p *= 15;
    float r = .5;

    float d = INF;

    // Gridlines
    // if (fract(p.x) < .02 || fract(1. - p.x) < .02)
    //     color = vec3(.1);
    // if (abs(p.x - FONT_WIDTH / 2) < .02 || abs(p.x + FONT_WIDTH/ 2) < .02)
    //     color = vec3(.8, .0, .0);
    // if (abs(p.y - FONT_DESCENDERS) < .02)
    //     color = vec3(.8, .0, .0);
    // if (fract(p.y) < .02 || fract(1. - p.y) < .02)
    //     color = vec3(.1);

    const int CHAR_COUNT_LOREM = 402;
    const int CHARS_LOREM[CHAR_COUNT_LOREM] = int[](
        99, 14, 17, 4, 12, 30, 8, 15, 18, 20, 12, 30, 3, 14, 11, 14, 17, 30, 18,
        8, 19, 30, 0, 12, 4, 19, 99, 30, 2, 14, 13, 18, 4, 2, 19, 4, 19, 20, 17,
        30, 0, 3, 8, 15, 8, 18, 2, 8, 13, 6, 30, 4, 11, 8, 19, 99, 30, 18, 4, 3,
        30, 3, 14, 30, 4, 8, 20, 18, 12, 14, 3, 30, 19, 4, 12, 15, 14, 17, 30,
        8, 13, 2, 8, 3, 8, 3, 20, 13, 19, 30, 20, 19, 30, 11, 0, 1, 14, 17, 4,
        30, 4, 19, 30, 3, 14, 11, 14, 17, 4, 30, 12, 0, 6, 13, 0, 30, 0, 11, 8,
        16, 20, 0, 99, 30, 99, 8, 2, 19, 20, 12, 18, 19, 30, 16, 20, 8, 18, 16,
        20, 4, 30, 18, 0, 6, 8, 19, 19, 8, 18, 30, 15, 20, 17, 20, 18, 30, 18,
        8, 19, 99, 30, 99, 4, 11, 8, 19, 30, 20, 19, 30, 19, 14, 17, 19, 14, 17,
        30, 15, 17, 4, 19, 8, 20, 12, 30, 21, 8, 21, 4, 17, 17, 0, 30, 18, 20,
        18, 15, 4, 13, 3, 8, 18, 18, 4, 30, 15, 14, 19, 4, 13, 19, 8, 30, 13,
        20, 11, 11, 0, 12, 99, 30, 99, 11, 0, 13, 3, 8, 19, 30, 21, 14, 11, 20,
        19, 15, 0, 19, 30, 12, 0, 4, 2, 4, 13, 0, 18, 30, 21, 14, 11, 20, 19,
        15, 0, 19, 30, 1, 11, 0, 13, 3, 8, 19, 30, 0, 11, 8, 16, 20, 0, 12, 30,
        4, 19, 8, 0, 12, 99, 30, 99, 20, 8, 18, 30, 11, 4, 2, 19, 20, 18, 30,
        13, 20, 11, 11, 0, 30, 0, 19, 30, 21, 14, 11, 20, 19, 15, 0, 19, 99, 30,
        99, 6, 4, 19, 30, 4, 6, 4, 18, 19, 0, 18, 30, 15, 20, 17, 20, 18, 30,
        21, 8, 21, 4, 17, 17, 0, 30, 0, 2, 2, 20, 12, 18, 0, 13, 30, 8, 13, 30,
        13, 8, 18, 11, 30, 13, 8, 18, 8, 99, 30, 99, 20, 17, 15, 8, 18, 30, 12,
        0, 18, 18, 0, 30, 18, 4, 3, 30, 4, 11, 4, 12, 4, 13, 19, 20, 12, 30, 19,
        4, 12, 15, 20, 18, 30, 4, 6, 4, 18, 19, 0, 18, 99);

    vec2 pp = p;
    // Only consider a moving window from the text. No reason to have non
    // visible characters in the combined SDF, bleeding perf all over the floor
    int windowWidthChars = 20;
    float windowOffset = -30;
    float speed = 10.;
    float cursor = -uTime * speed;
    // What character is currently leftmost in the visible window
    float charCursor = cursor / FONT_WIDTH;
    int cursorOffset = int(abs(floor(charCursor)));
    // The floating cursor needs to snap the next character when one goes out of
    // the window
    float drawingCursor = fract(charCursor) * FONT_WIDTH;
    drawingCursor += windowOffset;

    for (int i = cursorOffset;
         i < min(cursorOffset + windowWidthChars, CHAR_COUNT_LOREM); ++i)
        renderChar(CHARS_LOREM[i], pp, d, drawingCursor);

    // 0 to alpha for composite
    fragColor = vec4(saturate(1. - (d * 20.)));
}
