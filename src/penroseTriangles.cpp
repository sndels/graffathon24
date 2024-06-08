#include "penroseTriangles.hpp"

#include <vector>


PenroseTriangles::PenroseTriangles() :
    _triangleData   (60)
{
    glGenBuffers(1, &_penroseSsbo);
    update(0.0f);
}

void PenroseTriangles::update(float time)
{
    for (int i=0; i<_triangleData.size(); ++i) {
        auto& triangle = _triangleData[i];
        triangle.p << sinf(1.0*time+i*0.1), cosf(0.25*time+i*0.1);
    }

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, _penroseSsbo);
    {
        glBufferData(
            GL_SHADER_STORAGE_BUFFER, _triangleData.size() * sizeof(PenroseTriangle),
            _triangleData.data(), GL_DYNAMIC_DRAW);
    }
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
}

void PenroseTriangles::bind(Shader* shader)
{
    shader->setInt("nTriangles", _triangleData.size());
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, _penroseSsbo);
}
