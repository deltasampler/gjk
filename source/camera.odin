package main

import glm "core:math/linalg/glsl"

Camera_Mode :: enum {
    PERSPECTIVE,
    ORTHOGRAPHIC,
}

Camera :: struct {
    mode: Camera_Mode,

    position: glm.vec3,
    forward: glm.vec3,
    right: glm.vec3,
    up: glm.vec3,
    world_up: glm.vec3,
    is_locked: bool,

    near: f32,
    far: f32,
    fov: f32,
    projection: glm.mat4,
    view: glm.mat4,
}

init_perspective_camera :: proc(camera: ^Camera) {
    camera.mode = .PERSPECTIVE
    camera.forward = {0, 0, -1}
    camera.world_up = {0, 1, 0}
    camera.is_locked = true
    camera.near = 0.1
    camera.far = 8192
    camera.fov = 90
    rotate_camera(camera, 0, 0, 0)
}

init_orthographic_camera :: proc(camera: ^Camera) {
    camera.mode = .ORTHOGRAPHIC
    camera.forward = {0, 0, -1}
    camera.world_up = {0, 1, 0}
    camera.is_locked = true
    camera.near = -1024
    camera.far = 1024
    camera.fov = 1
    rotate_camera(camera, 0, 0, 0)
}

move_camera :: proc(camera: ^Camera, direction: glm.vec3) {
    camera.position += camera.forward * direction.z
    camera.position += camera.right * direction.x
    camera.position += camera.up * direction.y
}

rotate_camera :: proc(camera: ^Camera, yaw: f32, pitch: f32, roll: f32) {
    if (camera.is_locked) {
        camera.up = camera.world_up
    }

    // yaw
    quat := glm.quatAxisAngle(camera.up, -yaw)
    camera.forward = glm.normalize(glm.quatMulVec3(quat, camera.forward))
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))

    // pitch
    quat = glm.quatAxisAngle(camera.right, -pitch)
    forward := glm.normalize(glm.quatMulVec3(quat, camera.forward))

    if !camera.is_locked || abs(glm.dot(forward, camera.up)) < 0.99 {
        camera.forward = forward
    }

    // roll
    if (!camera.is_locked && roll != 0) {
        quat = glm.quatAxisAngle(camera.forward, -roll)
        camera.right = glm.normalize(glm.quatMulVec3(quat, camera.right))
    }

    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

zoom_camera :: proc(camera: ^Camera, direction: f32) {
    camera.fov = glm.clamp(camera.fov + direction, 0.01, 179.99)
}

point_camera_at :: proc(camera: ^Camera, point: glm.vec3) {
    if glm.distance(camera.position, point) < glm.F32_EPSILON {
        return
    }

    if (camera.is_locked) {
        camera.up = camera.world_up
    }

    camera.forward = glm.normalize(point - camera.position)
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))
    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

lock_camera :: proc(camera: ^Camera) {
    camera.is_locked = true
    camera.world_up = camera.up
}

unlock_camera :: proc(camera: ^Camera) {
    camera.is_locked = false
}

compute_camera_projection :: proc(camera: ^Camera, width: f32, height: f32) {
    if camera.mode == .PERSPECTIVE {
        camera.projection = glm.mat4Perspective(glm.radians(camera.fov), width / height, camera.near, camera.far)
    } else {
        camera.projection = glm.mat4Ortho3d(
            -width * 0.5 * camera.fov,
            width * 0.5 * camera.fov,
            -height * 0.5 * camera.fov,
            height * 0.5 * camera.fov,
            camera.near,
            camera.far
        )
    }
}

compute_camera_view :: proc(camera: ^Camera) {
    camera.view = glm.mat4LookAt(camera.position, camera.position + camera.forward, camera.up)
}
