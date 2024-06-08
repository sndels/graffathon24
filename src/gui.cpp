#include "gui.hpp"

#include <imgui.h>
#include <imgui_impl_opengl3.h>
#include <imgui_impl_sdl.h>

#include <algorithm>
#include <cstdio>

namespace
{
inline void uniformOffset()
{
    ImGui::SetCursorPosX(ImGui::GetCursorPosX() + 27.f);
}
} // namespace

GUI::GUI()
: _useSliderTime(false)
, _sliderTime(0.f)
{
}

void GUI::init(SDL_Window *window, SDL_GLContext context)
{
    _window = window;
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplSDL2_InitForOpenGL(_window, context);
    ImGui_ImplOpenGL3_Init("#version 430");

    ImGui::StyleColorsDark();
    ImGui::GetStyle().WindowRounding = 0.0f;
    ImGui::GetStyle().ChildRounding = 0.0f;
    ImGui::GetStyle().FrameRounding = 0.0f;
    ImGui::GetStyle().GrabRounding = 0.0f;
    ImGui::GetStyle().PopupRounding = 0.0f;
    ImGui::GetStyle().ScrollbarRounding = 0.0f;
}

void GUI::destroy()
{
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
}

bool GUI::useSliderTime() const { return _useSliderTime; }

float GUI::sliderTime() const { return _sliderTime; }

void GUI::startFrame(
    int32_t &sceneOverride, float &timeS, std::vector<Shader *> const &shaders,
    const std::vector<std::pair<std::string, const GpuProfiler *>> &timers)
{
    assert(_window != nullptr);

    // Start ImGui frame
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame(_window);
    ImGui::NewFrame();

    // Uniform editor
    ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiSetCond_Once);
    ImGui::SetNextWindowCollapsed(false, ImGuiSetCond_Once);
    ImGui::Begin("Skunkwork GUI", nullptr, ImGuiWindowFlags_AlwaysAutoResize);

    ImGui::InputInt("Scene override", &sceneOverride, 1, 1);
    ImGui::Checkbox("##Use slider time", &_useSliderTime);
    ImGui::SameLine();
    if (ImGui::Button("<<"))
        timeS -= 1.0;
    ImGui::SameLine();
    if (ImGui::Button(">>"))
        timeS += 1.0;
    ImGui::SameLine();
    ImGui::DragFloat("uTime", &timeS, 0.01f);
    if (timeS < 0.f)
        timeS = 0.f;
    _sliderTime = timeS;

    static size_t comboIndex = 0;
    comboIndex = std::min(comboIndex, shaders.size() - 1);
    if (ImGui::BeginCombo(
            "##ShaderDropdown", shaders[comboIndex]->name().c_str(), 0))
    {
        for (auto i = 0u; i < shaders.size(); ++i)
        {
            auto *s = shaders[i];
            assert(s != nullptr);
            bool selected = comboIndex == i;
            if (ImGui::Selectable(s->name().c_str(), selected))
                comboIndex = i;

            if (selected)
                ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
    }

    {
        auto *s = shaders[comboIndex];
        assert(s != nullptr);
        for (auto &e : s->dynamicUniforms())
        {
            std::string name = e.first + "##" + s->name();
            Uniform &uniform = e.second;
            switch (uniform.type)
            {
            case UniformType::Bool:
                uniformOffset();
                ImGui::Checkbox(name.c_str(), &uniform.value.b);
                break;
            case UniformType::Float:
                uniformOffset();
                ImGui::DragFloat(name.c_str(), uniform.value.f, 0.01f);
                break;
            case UniformType::Vec2:
                uniformOffset();
                ImGui::DragFloat2(name.c_str(), uniform.value.f, 0.01f);
                break;
            case UniformType::Vec3:
                ImGui::ColorEdit3(
                    std::string("##" + name).c_str(), uniform.value.f,
                    ImGuiColorEditFlags_NoInputs |
                        ImGuiColorEditFlags_PickerHueWheel);
                ImGui::SameLine();
                ImGui::DragFloat3(name.c_str(), uniform.value.f, 0.01f);
                break;
            default:
                printf("[gui] Unknown dynamic uniform type\n");
                break;
            }
        }
    }

    ImGui::Text("Frame: %.1f", 1000.f / ImGui::GetIO().Framerate);
    for (auto &t : timers)
    {
        ImGui::SameLine();
        ImGui::Text("%s: %.1f", t.first.c_str(), t.second->getAvg());
    }

    ImGui::End();
}

void GUI::endFrame()
{
    ImGui::Render();
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}
