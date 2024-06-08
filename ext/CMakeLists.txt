# Pull submodules
execute_process(COMMAND git submodule update --recursive --init --depth 1)

# GLM is header only
add_library(glm INTERFACE)
target_include_directories(glm INTERFACE glm)

# Libraries
add_subdirectory(libgl3w)

set(SDL_STATIC OFF CACHE BOOL "Build a static version of the library")
set(SDL_TEST OFF CACHE BOOL "Build the SDL3_test library")
add_subdirectory(SDL)

set(SDL2MIXER_FLAC OFF CACHE BOOL "Enable FLAC music")
set(SDL2MIXER_MOD OFF CACHE BOOL "Enable MOD music")
set(SDL2MIXER_MP3 ON CACHE BOOL "Enable MP3 music")
set(SDL2MIXER_MIDI OFF CACHE BOOL "Enable MIDI music")
set(SDL2MIXER_OPUS OFF CACHE BOOL "Enable OPUS music")
set(SDL2MIXER_WAVE ON CACHE BOOL "Enable WAVE music")
set(SDL2MIXER_INSTALL OFF CACHE BOOL "Enable SDL2mixer install target")
set(SDL2MIXER_SAMPLES OFF CACHE BOOL "Build the SDL2_mixer sample program(s)")
add_subdirectory(SDL_mixer)

add_library(imgui STATIC "")
target_sources(imgui
    PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/imgui/imgui.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/imgui_draw.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/imgui_widgets.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/examples/imgui_impl_sdl.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/examples/imgui_impl_opengl3.cpp
)
target_include_directories(imgui
    PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/imgui
    ${CMAKE_CURRENT_LIST_DIR}/imgui/examples
)
target_link_libraries(imgui
    PUBLIC
    ${OPENGL_LIBRARIES}
    libgl3w
    SDL2
)

add_library(librocket STATIC "")
target_sources(librocket
    PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/rocket/lib/device.c
    ${CMAKE_CURRENT_LIST_DIR}/rocket/lib/track.c
)
target_include_directories(librocket
    PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/rocket/lib
)

if(MSVC)
    target_link_libraries(librocket
        PRIVATE
        ws2_32.lib
    )
endif()

add_subdirectory(eigen)
