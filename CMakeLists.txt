cmake_minimum_required(VERSION 3.4)

project(skunkwork)

# Get built dynamic libs next to the exe
option(DISTRIBUTE_DEMO "Compile distributable" OFF)

if(DISTRIBUTE_DEMO)
    # Set relative paths for shared libraries
    set(CMAKE_INSTALL_RPATH $ORIGIN)

    # Set relative path to distributable res directory
    add_definitions(-DDEMO_MODE -DRES_DIRECTORY="./res/")

    # Compile demo as a win32 app to avoid issues with it losing focus because of the opened console window
    set(WIN32_DEF WIN32)
else()
    # Set absolute path to res directory
    add_definitions(-DRES_DIRECTORY="${CMAKE_CURRENT_SOURCE_DIR}/res/")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Set up external dependencies
find_package(OpenGL REQUIRED)

# Set up sub-builds and sources
add_subdirectory(ext)
add_subdirectory(include)
add_subdirectory(src)

# Set up project targets
add_executable(skunkwork ${WIN32_DEF} ${SKUNKWORK_SOURCES})
target_compile_features(skunkwork
    PRIVATE
    cxx_std_17
)

if(MSVC)
    target_compile_options(skunkwork
        PRIVATE

        # /Wall is very very pedantic
        /W4
    )
    add_definitions(-DNOMINMAX -DWIN32_LEAN_AND_MEAN)
else()
    target_compile_options(skunkwork
        PRIVATE
        -Wall
        -pedantic
    )
endif()

target_compile_definitions(skunkwork PRIVATE ROCKET SDL_MAIN_HANDLED)
target_include_directories(skunkwork
    PRIVATE
    ${SKUNKWORK_INCLUDE_DIR}
)
target_link_libraries(skunkwork
    PRIVATE
    ${OPENGL_LIBRARIES}
    eigen
    glm
    libgl3w
    librocket
    imgui
    SDL2
    SDL2_mixer
)

if(DISTRIBUTE_DEMO)
    # Prevent SDL build symlinks, we want the raw file for this to be portable
    set_property(TARGET SDL2 PROPERTY VERSION)
    set_property(TARGET SDL2 PROPERTY SOVERSION)
    set_property(TARGET SDL2_mixer PROPERTY VERSION)
    set_property(TARGET SDL2_mixer PROPERTY SOVERSION)

    install(TARGETS skunkwork SDL2 SDL2_mixer
        RUNTIME DESTINATION ${CMAKE_BINARY_DIR}/skunkwork_dist
        LIBRARY DESTINATION ${CMAKE_BINARY_DIR}/skunkwork_dist
        ARCHIVE DESTINATION ${CMAKE_BINARY_DIR}/skunkwork_dist
    )
endif()

# "shadertoy" only, doesn't include audio or rocket support
add_executable(skunktoy ${SKUNKTOY_SOURCES})
target_compile_features(skunktoy
    PRIVATE
    cxx_std_17
)

if(MSVC)
    target_compile_options(skunktoy
        PRIVATE
        /Wall
    )
else()
    target_compile_options(skunktoy
        PRIVATE
        -Wall
        -pedantic
    )
endif()

target_compile_definitions(skunktoy
    PRIVATE
    SDL_MAIN_HANDLED
)
target_include_directories(skunktoy
    PRIVATE
    ${SKUNKWORK_INCLUDE_DIR}
)
target_link_libraries(skunktoy
    PRIVATE
    ${OPENGL_LIBRARIES}
    glm
    libgl3w
    imgui
    SDL2
)
