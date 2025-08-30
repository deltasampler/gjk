package imdd

import glm "core:math/linalg/glsl"

quat_rotation_xyz :: proc(rotation: glm.vec3) -> glm.quat {
    return glm.quatAxisAngle({1, 0, 0}, rotation.x) * glm.quatAxisAngle({0, 1, 0}, rotation.y) * glm.quatAxisAngle({0, 0, -1}, rotation.z)
}

quat_rotation_dir :: proc(dir: glm.vec3) -> glm.quat {
    return glm.quatFromMat4(glm.mat4Orientation(dir, {0, 1, 0}))
}

rgb_f32 :: proc(r: f32, g: f32, b: f32) -> i32 {
    return (i32(r) << 16) | (i32(g) << 8) | i32(b);
}

rgba_f32 :: proc(r: f32, g: f32, b: f32, a: f32) -> i32 {
    return (i32(r) << 24) | (i32(g) << 16) | (i32(b) << 8) | i32(a);
}

rgb_ivec3 :: proc(color: glm.ivec3) -> i32 {
    return (color.r << 16) | (color.g << 8) | color.b;
}

rgba_ivec4 :: proc(color: glm.ivec4) -> i32 {
    return (color.r << 24) | (color.g << 16) | (color.b << 8) | color.a;
}
