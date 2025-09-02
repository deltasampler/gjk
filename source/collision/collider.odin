package collision

import glm "core:math/linalg/glsl"

Collider_Type :: enum {
    BOX,
    SPHERE,
    CAPSULE,
    CYLINDER,
    HULL,
}

Collider :: struct {
    type: Collider_Type,

    // transform
    position: glm.vec3,
    rotation: glm.quat,

    // shape
    extent: glm.vec3,
    vertices: [dynamic]glm.vec3,
}

make_collider_box :: proc(collider: ^Collider, position: glm.vec3, extent: glm.vec3) {
    collider.type = .BOX
    collider.position = position
    collider.extent = extent
}

make_collider_sphere :: proc(collider: ^Collider, position: glm.vec3, radius: f32) {
    collider.type = .SPHERE
    collider.position = position
    collider.extent = radius
}

make_collider_capsule :: proc(collider: ^Collider, position: glm.vec3, radius: f32, extent: f32) {
    collider.type = .CAPSULE
    collider.position = position
    collider.extent = {radius, extent, radius}
}

make_collider_cylinder :: proc(collider: ^Collider, position: glm.vec3, radius: f32, extent: f32) {
    collider.type = .CYLINDER
    collider.position = position
    collider.extent = {radius, extent, radius}
}

make_collider_hull :: proc(collider: ^Collider, position: glm.vec3, vertices: []glm.vec3) {
    collider.type = .HULL
    collider.position = position
    collider.extent = calc_hull_extent(vertices)
    append(&collider.vertices, ..vertices)
}

delete_collider :: proc(collider: Collider) {
    delete(collider.vertices)
}

support :: proc(collider: Collider, dir: glm.vec3) -> glm.vec3 {
    dir := glm.normalize(dir)
    result: glm.vec3

    switch collider.type {
    case .BOX:
        result = {
            dir.x < 0 ? -collider.extent.x : collider.extent.x,
            dir.y < 0 ? -collider.extent.y : collider.extent.y,
            dir.z < 0 ? -collider.extent.z : collider.extent.z
        }
    case .SPHERE:
        result = dir * collider.extent.x
    case .CAPSULE:
        result = dir * collider.extent.x
        result.y += dir.y > 0 ? collider.extent.y : -collider.extent.y
    case .CYLINDER:
        result = glm.normalize(glm.vec3{dir.x, 0, dir.z}) * collider.extent.x
        result.y = dir.y > 0 ? collider.extent.y : -collider.extent.y
    case .HULL:
        vertex_max := collider.vertices[0]
        dot_max := glm.dot(vertex_max, dir)

        for i in 1 ..< len(collider.vertices) {
            vertex := collider.vertices[i]
            dot := glm.dot(vertex, dir)

            if dot > dot_max {
                vertex_max = vertex
                dot_max = dot
            }
        }

        result = vertex_max
    }

    return glm.quatMulVec3(collider.rotation, result) + collider.position
}
