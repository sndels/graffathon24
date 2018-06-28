#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
#endif // _WIN32

#include <GL/gl3w.h>
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw_gl3.h>
#include <iostream>
#include <sstream>
#include <sync.h>
#include <track.h>

#include "audioStream.hpp"
#include "logger.hpp"
#include "gpuProfiler.hpp"
#include "quad.hpp"
#include "scene.hpp"
#include "shaderProgram.hpp"
#include "timer.hpp"

// Comment out to disable autoplay without tcp-Rocket
//#define MUSIC_AUTOPLAY
// Comment out to load sync from files
//#define TCPROCKET
// Comment out to remove gui
#define GUI

using std::cout;
using std::cerr;
using std::endl;

namespace {
    const static char* WINDOW_TITLE = "skunkwork";
    GLsizei XRES = 1280;
    GLsizei YRES = 720;
    float LOGW = 690.f;
    float LOGH = 210.f;
    float LOGM = 10.f;
    GLfloat CURSOR_POS[] = {0.f, 0.f};
}

//Set up audio callbacks for rocket
static struct sync_cb audioSync = {
    AudioStream::pauseStream,
    AudioStream::setStreamRow,
    AudioStream::isStreamPlaying
};

void keyCallback(GLFWwindow* window, int32_t key, int32_t scancode, int32_t action,
                 int32_t mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
#ifdef GUI
    else
        ImGui_ImplGlfwGL3_KeyCallback(window, key, scancode, action, mods);
#endif // GUI
}

void cursorCallback(GLFWwindow* window, double xpos, double ypos)
{
    if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS) {
        CURSOR_POS[0] = 2 * xpos / XRES - 1.f;
        CURSOR_POS[1] = 2 * (YRES - ypos) / YRES - 1.f;
    }
}

void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
#ifdef GUI
    if (ImGui::IsMouseHoveringAnyWindow()) {
        ImGui_ImplGlfwGL3_MouseButtonCallback(window, button, action, mods);
        return;
    }
#endif //GUI

    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        double xpos, ypos;
        glfwGetCursorPos(window, &xpos, &ypos);
        CURSOR_POS[0] = 2 * xpos / XRES - 1.f;
        CURSOR_POS[1] = 2 * (YRES - ypos) / YRES - 1.f;
    }
}

void windowSizeCallback(GLFWwindow* window, int width, int height)
{
    (void) window;
    XRES = width;
    YRES = height;
    glViewport(0, 0, XRES, YRES);
}

static void errorCallback(int error, const char* description)
{
    cerr << "GLFW error " << error << ": " << description << endl;
}

#ifdef _WIN32
int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR lpCmdLine, INT nCmdShow)
{
    (void) hInstance;
    (void) hPrevInstance;
    (void) lpCmdLine;
    (void) nCmdShow;
#else
int main()
{
#endif // _WIN32
    // Init GLFW-context
    glfwSetErrorCallback(errorCallback);
    if (!glfwInit()) exit(EXIT_FAILURE);

    // Set desired context hints
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // Create the window
    GLFWwindow* windowPtr;
    windowPtr = glfwCreateWindow(XRES, YRES, WINDOW_TITLE, NULL, NULL);
    if (!windowPtr) {
        glfwTerminate();
        cerr << "Error creating GLFW-window!" << endl;
        exit(EXIT_FAILURE);
    }
    glfwMakeContextCurrent(windowPtr);

    // Init GL
    if (gl3wInit()) {
        glfwDestroyWindow(windowPtr);
        glfwTerminate();
        cerr << "Error initializing GL3W!" << endl;
        exit(EXIT_FAILURE);
    }

    // Set vsync on
    glfwSwapInterval(1);

    // Init GL settings
    glViewport(0, 0, XRES, YRES);
    glClearColor(0.f, 0.f, 0.f, 1.f);

    GLenum error = glGetError();
    if(error != GL_NO_ERROR) {
        glfwDestroyWindow(windowPtr);
        glfwTerminate();
        cerr << "Error initializing GL!" << endl;
        exit(EXIT_FAILURE);
    }

#ifdef GUI
    // Setup imgui
    ImGui_ImplGlfwGL3_Init(windowPtr, true);
    ImGuiWindowFlags logWindowFlags= 0;
    logWindowFlags |= ImGuiWindowFlags_NoTitleBar;
    logWindowFlags |= ImGuiWindowFlags_AlwaysAutoResize;
    bool showLog = true;
    bool showTweak = true;
    bool useSlider = false;
    float sliderTime = 0.f;

    Logger logger;
    logger.AddLog("[gl] Context: %s\n     GLSL: %s\n",
                   glGetString(GL_VERSION),
                   glGetString(GL_SHADING_LANGUAGE_VERSION));


    // Capture cout for logging
    std::stringstream logCout;
    std::streambuf* oldCout = std::cout.rdbuf(logCout.rdbuf());
#endif // GUI

    // Set glfw-callbacks, these will pass to imgui's callbacks if overridden
    glfwSetWindowSizeCallback(windowPtr, windowSizeCallback);
    glfwSetKeyCallback(windowPtr, keyCallback);
    glfwSetCursorPosCallback(windowPtr, cursorCallback);
    glfwSetMouseButtonCallback(windowPtr, mouseButtonCallback);

    Quad q;

    // Set up audio
    std::string musicPath(RES_DIRECTORY);
    musicPath += "music/illegal_af.mp3";
    AudioStream::getInstance().init(musicPath, 175.0, 8);
    int32_t streamHandle = AudioStream::getInstance().getStreamHandle();

    // Set up rocket
    sync_device *rocket = sync_create_device("sync");
    if (!rocket) cout << "[rocket] failed to init" << endl;

    // Set up scene
    std::string vertPath(RES_DIRECTORY);
    vertPath += "shader/basic_vert.glsl";
    std::string fragPath(RES_DIRECTORY);
    fragPath += "shader/basic_frag.glsl";
    Scene scene(std::vector<std::string>({vertPath, fragPath}),
                std::vector<std::string>(), rocket);

#ifdef TCPROCKET
    // Try connecting to rocket-server
    int rocketConnected = sync_tcp_connect(rocket, "localhost", SYNC_DEFAULT_PORT) == 0;
    if (!rocketConnected)
        cout << "[rocket] failed to connect" << endl;
#endif // TCPROCKET

    // Init rocket tracks here

    Timer reloadTime;
    Timer globalTime;
    GpuProfiler sceneProf(5);

#ifdef MUSIC_AUTOPLAY
    AudioStream::getInstance().play();
#endif // MUSIC_AUTOPLAY

    // Run the main loop
    while (!glfwWindowShouldClose(windowPtr)) {
        glfwPollEvents();

        // Sync
        double syncRow = AudioStream::getInstance().getRow();

#ifdef TCPROCKET
        // Try re-connecting to rocket-server if update fails
        // Drops all the frames, if trying to connect on windows
        if (sync_update(rocket, (int)floor(syncRow), &audioSync, (void *)&streamHandle))
            sync_tcp_connect(rocket, "localhost", SYNC_DEFAULT_PORT);
#endif // TCPROCKET

#ifdef GUI
        ImGui_ImplGlfwGL3_NewFrame();
#endif // GUI

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

#ifdef GUI
        // Update imgui
        {
            // Tweak
            ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiSetCond_Always);
            ImGui::Begin("Tweak", &showTweak, 0);
            ImGui::Checkbox("Slider time", &useSlider);
            ImGui::SliderFloat("Time", &sliderTime, 0.f, 150.f);
            ImGui::End();
            // Log
            ImGui::SetNextWindowSize(ImVec2(LOGW, LOGH), ImGuiSetCond_Once);
            ImGui::SetNextWindowPos(ImVec2(LOGM, YRES - LOGH - LOGM), ImGuiSetCond_Always);
            ImGui::Begin("Log", &showLog, logWindowFlags);
            ImGui::Text("Frame: %.1f Scene: %.1f", 1000.f / ImGui::GetIO().Framerate, sceneProf.getAvg());
            if (logCout.str().length() != 0) {
                logger.AddLog("%s", logCout.str().c_str());
                logCout.str("");
            }
            logger.Draw();
            ImGui::End();
        }
#endif // GUI

        // Try reloading the shader every 0.5s
        if (reloadTime.getSeconds() > 0.5f) {
            scene.reload();
            reloadTime.reset();
        }

        sceneProf.startSample();
        scene.bind(syncRow);
#ifdef GUI
        glUniform1f(scene.getULoc("uTime"), useSlider ? sliderTime : globalTime.getSeconds());
#else
        glUniform1f(scene.getULoc("uTime"), globalTime.getSeconds());
#endif // GUI
        GLfloat res[] = {static_cast<GLfloat>(XRES), static_cast<GLfloat>(YRES)};
        glUniform2fv(scene.getULoc("uRes"), 1, res);
        glUniform2fv(scene.getULoc("uMPos"), 1, CURSOR_POS);
        q.render();
        sceneProf.endSample();

#ifdef GUI
        ImGui::Render();
#endif // GUI

        glfwSwapBuffers(windowPtr);

#ifdef MUSIC_AUTOPLAY
        if (!AudioStream::getInstance().isPlaying()) glfwSetWindowShouldClose(windowPtr, GLFW_TRUE);
#endif // MUSIC_AUTOPLAY
    }

    // Save rocket tracks
    sync_save_tracks(rocket);

    // Release resources
    sync_destroy_device(rocket);

#ifdef GUI
    std::cout.rdbuf(oldCout);
    ImGui_ImplGlfwGL3_Shutdown();
#endif // GUI

    glfwDestroyWindow(windowPtr);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}
