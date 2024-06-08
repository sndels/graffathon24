#include "window.hpp"

#include <SDL_opengl.h>
#include <SDL_video.h>
#include <cstdio>
#include <imgui.h>
#include <imgui_impl_sdl.h>
#include <stdio.h>

bool Window::init(int w, int h, const std::string &title, int displayIndex)
{
    _w = w;
    _h = h;
    _drawGUI = true;
    GLenum err;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
    {
        fprintf(stderr, "SDL init failed: %s\n", SDL_GetError());
        return false;
    }

    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    SDL_GL_SetAttribute(
        SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    _window = SDL_CreateWindow(
        title.c_str(), SDL_WINDOWPOS_CENTERED_DISPLAY(displayIndex),
        SDL_WINDOWPOS_CENTERED_DISPLAY(displayIndex), _w, _h,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
    if (_window == nullptr)
    {
        fprintf(stderr, "Window create failed: %s\n", SDL_GetError());
        goto fail;
    }

    _context = SDL_GL_CreateContext(_window);
    if (_context == nullptr)
    {
        fprintf(stderr, "GL context create failed: %s\n", SDL_GetError());
        goto fail;
    }

    if (SDL_GL_SetSwapInterval(1))
    {
        fprintf(stderr, "Vsync setup failed: %s\n", SDL_GetError());
        goto fail;
    }

    // Init GL
    gl3wInit();
    glClearColor(0.f, 0.f, 0.f, 1.f);

    // Check that GL is happy
    err = glGetError();
    if (err != GL_NO_ERROR)
    {
        fprintf(stderr, "Error initializing GL!\n");
        fprintf(stderr, "Code: %d\n", err);
        goto fail;
    }

    return true;

fail:
    SDL_GL_DeleteContext(_context);
    SDL_DestroyWindow(_window);
    SDL_Quit();
    return false;
}

void Window::destroy() { }

Window::Window(Window &&other)
: _window(other._window)
, _w(other._w)
, _h(other._h)
, _drawGUI(other._drawGUI)
{
    other._window = nullptr;
}

bool Window::open() const { return !_shouldClose; }

void Window::setClose() { _shouldClose = true; }

SDL_Window *Window::ptr() const { return _window; }

SDL_GLContext Window::ctx() const { return _context; }

int Window::width() const { return _w; }

int Window::height() const { return _h; }

bool Window::drawGUI() const { return _drawGUI; }

bool Window::playPausePressed() const { return _playPausePressed; }

bool Window::startFrame()
{
    bool resized = false;
    _playPausePressed = false;

    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        case SDL_QUIT:
            _shouldClose = true;
            break;
        case SDL_KEYDOWN:
            handleKey(event);
            break;
        case SDL_WINDOWEVENT:
            resized |= handleWindow(event);
            break;
        default:
            break;
        }
        ImGui_ImplSDL2_ProcessEvent(&event);
    }

    return resized;
}

void Window::endFrame() const { SDL_GL_SwapWindow(_window); }

bool Window::handleWindow(SDL_Event const &event)
{
    bool resized = false;

    switch (event.window.event)
    {
    case SDL_WINDOWEVENT_RESIZED:
    case SDL_WINDOWEVENT_SIZE_CHANGED:
        _w = event.window.data1;
        _h = event.window.data2;
        glViewport(0, 0, _w, _h);
        resized = true;
        break;
    default:
        break;
    }

    return resized;
}

void Window::handleKey(SDL_Event const &event)
{
    // Skip key events when e.g. editing an input field
    if (!ImGui::IsAnyItemActive())
    {
        if (event.key.state == SDL_PRESSED)
        {
            switch (event.key.keysym.sym)
            {
            case SDLK_ESCAPE:
                _shouldClose = true;
                break;
            case SDLK_g:
                _drawGUI = !_drawGUI;
                break;
            case SDLK_SPACE:
                _playPausePressed = true;
                break;
            default:
                break;
            }
        }
    }
}
