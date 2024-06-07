mat4 worldToCamera(vec3 eye, vec3 target, vec3 up)
{
    vec3 fwd = normalize(target - eye);
    vec3 z = -fwd;
    vec3 right = normalize(cross(up, z));
    vec3 newUp = normalize(cross(z, right));

    // Right handed camera
    // clang-format off
    return mat4(
        right.x,          newUp.x,          z.x,          0.,
        right.y,          newUp.y,          z.y,          0.,
        right.z,          newUp.z,          z.z,          0.,
        -dot(right, eye), -dot(newUp, eye), -dot(z, eye), 1.
    );
    // clang-format on
}

mat4 cameraToClip(float fov, vec2 res, float zN, float zF)
{
    float ar = res.x / res.y;
    const float tf = 1. / tan(fov * 0.5f);
    // clang-format off
    return mat4(
        tf / ar, 0.,                      0.,  0.,
             0., tf,                      0.,  0.,
             0., 0.,   (zF + zN) / (zN - zF), -1.,
             0., 0., 2 * zF * zN / (zN - zF),  0.
    );
    // clang-format off
}
