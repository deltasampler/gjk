package collision

import glm "core:math/linalg/glsl"

Face :: struct {
    indices: [dynamic]u32,
    normal: glm.vec3,
}

Hull :: struct {
    vertices: [dynamic]glm.vec3,
    faces: [dynamic]Face,
    center: glm.vec3,
}

hull_delete :: proc(hull: Hull) {
    delete(hull.vertices)

    for &face in hull.faces {
        delete(face.indices)
    }

    delete(hull.faces)
}

hull_add_vertex :: proc(hull: ^Hull, vertex: glm.vec3) -> u32 {
    append(&hull.vertices, vertex)

    return u32(len(hull.vertices)) - 1
}

hull_add_face :: proc(hull: ^Hull, indices: []u32) {
    append(&hull.faces, Face{})

    face := &hull.faces[len(hull.faces) - 1]
    append(&face.indices, ..indices)
}

hull_gen_cube :: proc(hull: ^Hull, position: glm.vec3, size: glm.vec3) {
    extent := size / 2
    min := position - extent
    max := position + extent

    // left
    v0 := hull_add_vertex(hull, {min.x, min.y, min.z})
    v1 := hull_add_vertex(hull, {min.x, min.y, max.z})
    v2 := hull_add_vertex(hull, {min.x, max.y, max.z})
    v3 := hull_add_vertex(hull, {min.x, max.y, min.z})

    // right
    v4 := hull_add_vertex(hull, {max.x, min.y, max.z})
    v5 := hull_add_vertex(hull, {max.x, min.y, min.z})
    v6 := hull_add_vertex(hull, {max.x, max.y, min.z})
    v7 := hull_add_vertex(hull, {max.x, max.y, max.z})

    // left
    hull_add_face(hull, {v0, v1, v2, v3})
    // right
    hull_add_face(hull, {v4, v5, v6, v7})

    // bottom
    hull_add_face(hull, {v0, v5, v4, v1})
    // top
    hull_add_face(hull, {v2, v7, v6, v3})

    // back
    hull_add_face(hull, {v1, v4, v7, v2})
    // face
    hull_add_face(hull, {v5, v0, v3, v6})

    hull_compute_info(hull)
}

hull_compute_info :: proc(hull: ^Hull) {
    hull.center = {}

    for vertex in hull.vertices {
        hull.center += vertex
    }

    hull.center /= f32(len(hull.vertices))

    for &face in hull.faces {
        a := hull.vertices[face.indices[0]]
        b := hull.vertices[face.indices[1]]
        c := hull.vertices[face.indices[2]]
        face.normal = glm.normalize(glm.cross(b - a, c - a))
    }
}

hull_translate :: proc(hull: ^Hull, translation: glm.vec3) {
    for &vertex in hull.vertices {
        vertex += translation
    }

    hull_compute_info(hull)
}

hull_rotate_z :: proc(hull: ^Hull, angle: f32) {
    quat := glm.quatAxisAngle({0, 0, -1}, angle)

    for &vertex in hull.vertices {
        vertex = hull.center + glm.quatMulVec3(quat, vertex - hull.center)
    }

    hull_compute_info(hull)
}

hull_scale :: proc(hull: ^Hull, scale: glm.vec3) {
    for &vertex in hull.vertices {
        vertex = hull.center + (vertex - hull.center) * scale
    }
}
