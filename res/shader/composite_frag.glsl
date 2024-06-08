#version 430

#include "noise.glsl"
#include "uniforms.glsl"

uniform sampler2D uScenePingColorDepth;
uniform sampler2D uScenePongColorDepth;

out vec4 fragColor;

#define ABERR_SAMPLES 16

vec4 sampleSource(sampler2D s, float aberr)
{
    vec2 texCoord = gl_FragCoord.xy / uRes;
    vec4 value = texture(s, texCoord);
    if (aberr > 0)
    {
        vec2 dir = 0.5 - texCoord;
        vec2 caOffset = dir * aberr * 0.1;
        vec2 blurStep = caOffset * 0.06;

        vec3 sum = vec3(0);
        // TODO: This is expensive
        for (int i = 0; i < ABERR_SAMPLES; i++)
        {
            sum += vec3(
                texture(s, texCoord + caOffset + i * blurStep).r,
                texture(s, texCoord + i * blurStep).g,
                texture(s, texCoord - caOffset + i * blurStep).b);
        }

        value.rgb = sum / ABERR_SAMPLES;
    }
    return value;
}

uniform float dCaberr;
uniform float dTextMode;

void main()
{
    // Avoid nags if these aren't used
    if (uTime < -1 || uRes.x < -1)
        discard;

    vec4 ping = sampleSource(uScenePingColorDepth, dCaberr);
    vec4 pong = sampleSource(uScenePongColorDepth, dCaberr);

    vec3 color = vec3(0);
    if (dTextMode > .5)
    {
        if (pong.a > 0.)
            color = pong.rgb;
        else
            color = ping.rgb;
    }
    else
    {
        if (fbm(vec3(gl_FragCoord.xy * 0.01, uTime), 0.4, 4) > 0.8)
            color = ping.rgb;
        else
            color = pong.rgb;
    }
    fragColor = vec4(color, 1);
}
