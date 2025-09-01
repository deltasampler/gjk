package collision

import glm "core:math/linalg/glsl"

Collider_Type :: enum {
    SPHERE,
    BOX,
    HULL,
}

Collider :: struct {
    type: Collider_Type,
    position: glm.vec3,
    radius: f32,
    min: glm.vec3,
    max: glm.vec3,
    vertices: [dynamic]glm.vec3,
}

collider_sphere :: proc(collider: ^Collider, position: glm.vec3, radius: f32) {
    collider.type = .SPHERE
    collider.position = position
    collider.radius = radius
    collider.min = position - radius
    collider.max = position + radius
}

collider_box :: proc(collider: ^Collider, min: glm.vec3, max: glm.vec3) {
    collider.type = .BOX
    collider.position = (min + max) / 2
    collider.min = min
    collider.max = max
}

collider_hull :: proc(collider: ^Collider, position: glm.vec3, min: glm.vec3, max: glm.vec3, vertices: []glm.vec3) {
    collider.type = .HULL
    collider.position = position
    collider.min = min
    collider.max = max
    append(&collider.vertices, ..vertices)
}

delete_collider :: proc(collider: Collider) {
    delete(collider.vertices)
}

support :: proc(collider: Collider, dir: glm.vec3) -> glm.vec3 {
    dir := glm.normalize(dir)

    switch collider.type {
    case .SPHERE:
        return collider.position + dir * collider.radius
    case .BOX:
        return {
            dir.x < 0 ? collider.min.x : collider.max.x,
            dir.y < 0 ? collider.min.y : collider.max.y,
            dir.z < 0 ? collider.min.z : collider.max.z
        }
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

        return vertex_max
    }

    return {}
}
