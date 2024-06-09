#pragma once

#include "mathTypes.hpp"
#include "shader.hpp"

struct PenroseTriangle
{
    Vec4i m; // metadata: type, children ids
    Vec2d o;
    Vec2d u;
    Vec2d v;
};

struct TriangleData
{
    Vec4i m; // metadata: type, children ids
    Mat2f uvmInv;
    Vec2f o;
};
static_assert(sizeof(TriangleData) % 16 == 0, "Required for SSBO");
static_assert(alignof(TriangleData) >= 16, "Required for SSBO");

class PenroseTriangles
{
  public:
    PenroseTriangles();

    void subdivideTriangles();

    void update(float time);

    void bind(Shader *shader);

  private:
    GLuint _penroseSsbo;
    std::vector<PenroseTriangle> _triangles;
    std::vector<TriangleData> _triangleData;
};
