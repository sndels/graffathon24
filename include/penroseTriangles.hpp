#pragma once

#include "shader.hpp"
#include "mathTypes.hpp"


struct PenroseTriangle {
    Vec2f   p;
};

class PenroseTriangles {
public:
    PenroseTriangles();

    void update(float time);

    void bind(Shader* shader);

private:
    GLuint                          _penroseSsbo;
    std::vector<PenroseTriangle>    _triangleData;
};
