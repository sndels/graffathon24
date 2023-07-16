#include "audioStream.hpp"

#include <cstdio>

namespace {
    static int32_t ROW_RATE = 0;
}

void AudioStream::pauseStream(void* data, int32_t flag)
{
    if (flag)
        Mix_PauseMusic();
    else if (Mix_PlayingMusic())
        Mix_ResumeMusic();
    else {
        Mix_Music* music = (Mix_Music*)data;
        Mix_PlayMusic(music, 0);
    }
}

void AudioStream::setStreamRow(void* /*data*/, int32_t row)
{
    double const timeS = row / (double)ROW_RATE;
    Mix_SetMusicPosition(timeS);
}

int32_t AudioStream::isStreamPlaying(void* /*data*/)
{
    return Mix_PlayingMusic();
}

bool AudioStream::init(const std::string& filePath, double bpm, int32_t rpb)
{
    int audio_rate = 44100;
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
    uint16_t audio_format = AUDIO_S16LSB;
#else
    uint16_t audio_format = AUDIO_S16MSB;
#endif
    int audio_channels = 2;

    if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, 4096) < 0)
    {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
        return false;
    }

    Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
    printf("Opened audio at %d Hz %d bit%s %s\n", audio_rate,
        (audio_format&0xFF),
        (SDL_AUDIO_ISFLOAT(audio_format) ? " (float)" : ""),
        (audio_channels > 2) ? "surround" :
        (audio_channels > 1) ? "stereo" : "mono");

    _music = Mix_LoadMUS(filePath.c_str());
    if (_music == nullptr) {
        fprintf(stderr, "Failed to open music from %s\n", filePath.c_str());
        fprintf(stderr, "%s\n", SDL_GetError());
        Mix_CloseAudio();
        return false;
    }

    ROW_RATE = bpm / 60 * rpb;
    _shouldRestart = false;
    return true;
}

void AudioStream::destroy()
{
    Mix_CloseAudio();
}

Mix_Music* AudioStream::getMusic() const
{
    return _music;
}

void AudioStream::play()
{
    if (_shouldRestart || !Mix_PausedMusic())
        Mix_PlayMusic(_music, 0);
    else
        Mix_ResumeMusic();
    _shouldRestart = false;
}

bool AudioStream::isPlaying() {
    return Mix_PlayingMusic() == 1;
}

void AudioStream::pause()
{
    Mix_PauseMusic();
}

void AudioStream::stop()
{
    Mix_PauseMusic();
    _shouldRestart = true;
}

double AudioStream::getRow() const
{
    double const timeS = Mix_GetMusicPosition(_music);
    return timeS * ROW_RATE;
}

void AudioStream::setRow(int32_t row)
{
    double const timeS = row / (double)ROW_RATE;
    Mix_SetMusicPosition(timeS);
}

AudioStream::~AudioStream()
{
    destroy();
}
