#include <GL/gl3w.h>

#include "gpuProfiler.hpp"
#include "gui.hpp"
#include "quad.hpp"
#include "shader.hpp"
#include "timer.hpp"
#include "window.hpp"

int main()
{
    Window window;
    if (!window.init(1280, 720, "skunktoy"))
        return -1;

    // Setup imgui
    GUI gui;
    gui.init(window.ptr(), window.ctx());

    Quad q;

    // Set up scene
    std::string vertPath(RES_DIRECTORY);
    vertPath += "shader/basic_vert.glsl";
    std::string fragPath(RES_DIRECTORY);
    fragPath += "shader/basic_frag.glsl";
    Shader shader("Shader", vertPath, fragPath, "");

    Timer reloadTime;
    Timer globalTime;
    GpuProfiler sceneProf(5);
    std::vector<std::pair<std::string, const GpuProfiler *>> profilers = {
        {"Scene", &sceneProf}};

    // Run the main loop
    while (window.open())
    {
        window.startFrame();

        int32_t sceneI = 0;
        float t = 0;
        if (window.drawGUI())
            gui.startFrame(sceneI, t, {&shader}, profilers);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Try reloading the shader every 0.5s
        if (reloadTime.getSeconds() > 0.5f)
        {
            shader.reload();
            reloadTime.reset();
        }

        // TODO: No need to reset before switch back
        if (gui.useSliderTime())
            globalTime.reset();

        sceneProf.startSample();
        shader.bind();
        shader.setFloat(
            "uTime",
            gui.useSliderTime() ? gui.sliderTime() : globalTime.getSeconds());
        shader.setVec2(
            "uRes", (GLfloat)window.width(), (GLfloat)window.height());
        q.render();
        shader.setFloat(
            "uAspectRatio", (GLfloat)window.width() / (GLfloat)window.height());
        sceneProf.endSample();

        if (window.drawGUI())
            gui.endFrame();

        window.endFrame();
    }

    gui.destroy();
    window.destroy();
    exit(EXIT_SUCCESS);
}
