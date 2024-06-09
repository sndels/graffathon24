#include "penroseTriangles.hpp"

#include <vector>


constexpr double deg18 = (18.0/180.0)*M_PI;
constexpr double deg36 = (36.0/180.0)*M_PI;
constexpr double goldenRatio = 1.618033988749894;
constexpr double goldenRatioInv = 1.0 / goldenRatio;
constexpr double goldenRatioInv1 = 1.0-goldenRatioInv;


PenroseTriangles::PenroseTriangles() : _triangles(10)
{
    glGenBuffers(1, &_penroseSsbo);

    // Generate lvl0 triangles for penrose sun
    for (int i=0; i<10; ++i) {
        auto& triangle = _triangles[i];
        Vec2d a(cos(deg36*(i+1)), sin(deg36*(i+1)));
        Vec2d b(cos(deg36*i), sin(deg36*i));
        Vec2d c(0.0, 0.0);

        triangle.m << 0, 0, 0, 0;
        triangle.o = i%2 == 0 ? a : b;
        triangle.u = i%2 == 0 ? (b-a) : (a-b);
        triangle.v = i%2 == 0 ? (c-a) : (c-b);
    }

    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();
    subdivideTriangles();

    update(0.0f);
}

void PenroseTriangles::subdivideTriangles()
{
    auto nTriangles = _triangles.size();
    for (int i=0; i<nTriangles; ++i) {
        auto& triangle = _triangles[i];
        if (triangle.m(1) > 0) // triangle already has children
            continue;
        if (triangle.m(0) == 0) { // half-kite
            PenroseTriangle t1, t2, t3;
            t1.m << 0, 0, 0, 0;
            t1.o = triangle.o + triangle.u;
            t1.u = (triangle.v - triangle.u) * goldenRatioInv1;
            t1.v = triangle.o - t1.o;
            t2.m << 0, 0, 0, 0;
            t2.o = triangle.o + triangle.v * goldenRatioInv;
            t2.u = t1.o + t1.u - t2.o;
            t2.v = triangle.o - t2.o;
            t3.m << 1, 0, 0, 0;
            t3.o = triangle.o + triangle.u + t1.u;
            t3.u = t2.o - t3.o;
            t3.v = triangle.o + triangle.v - t3.o;

            triangle.m(1) = _triangles.size();
            triangle.m(2) = _triangles.size()+1;
            triangle.m(3) = _triangles.size()+2;
            _triangles.push_back(std::move(t1));
            _triangles.push_back(std::move(t2));
            _triangles.push_back(std::move(t3));
        }
        else { // half-dart
            PenroseTriangle t1, t2;
            t1.m << 0, 0, 0, 0;
            t1.o = triangle.o + triangle.v*goldenRatioInv1;
            t1.v = triangle.o + triangle.v - t1.o;
            t1.u = triangle.o + triangle.u - t1.o;
            t2.m << 1, 0, 0, 0;
            t2.o = triangle.o + triangle.u;
            t2.u = -t1.u;
            t2.v = -triangle.u;

            triangle.m(1) = _triangles.size();
            triangle.m(2) = _triangles.size()+1;
            _triangles.push_back(std::move(t1));
            _triangles.push_back(std::move(t2));
        }
    }
}

void PenroseTriangles::update(float time)
{
    if (_triangleData.empty())
    {
        _triangleData.clear();
        for (const auto &triangle : _triangles)
        {
            Mat2d uvm;
            uvm << triangle.u, triangle.v;
            _triangleData.push_back(TriangleData{
                triangle.m, uvm.inverse().cast<float>(),
                triangle.o.cast<float>()});
        }
    }

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, _penroseSsbo);
    {
        glBufferData(
            GL_SHADER_STORAGE_BUFFER,
            _triangleData.size() * sizeof(PenroseTriangle), _triangleData.data(), GL_DYNAMIC_DRAW);
    }
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
}

void PenroseTriangles::bind(Shader* shader)
{
    shader->setInt("nTriangles", _triangles.size());
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, _penroseSsbo);
}
