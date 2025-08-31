package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "imdd"

Simplex :: struct {
    points: [4]glm.vec3,
    len: int,
    dir: glm.vec3,
    contains: bool,
}

simplex_push :: proc(simplex: ^Simplex, point: glm.vec3) {
    if simplex.len >= 4 {
        return
    }

    simplex.points[simplex.len] = point
    simplex.len += 1
}

simplex_pop :: proc(simplex: ^Simplex) {
    if simplex.len <= 0 {
        return
    }

    simplex.len -= 1
}

simplex_get :: proc(simplex: ^Simplex, i: int) -> glm.vec3 {
    if i < 0 || i >= simplex.len {
        return {}
    }

    return simplex.points[i]
}

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

gjk_support_hull :: proc(hull: Hull, dir: glm.vec3) -> glm.vec3 {
    point_max := hull.vertices[0]
    dot_max := glm.dot(point_max, dir)

    for i in 1 ..< len(hull.vertices) {
        point := hull.vertices[i]
        dot := glm.dot(point, dir)

        if dot > dot_max {
            point_max = point
            dot_max = dot
        }
    }

    return point_max
}

gjk_support_sphere :: proc(position: glm.vec3, radius: f32, dir: glm.vec3) -> glm.vec3 {
    return position + dir * radius
}

gjk_simplex :: proc(simplex: ^Simplex) {
    if simplex.len == 2 {
        vec_a := simplex_get(simplex, 1)
        vec_b := simplex_get(simplex, 0)

        vec_ao := -vec_a
        vec_ab := vec_b - vec_a

        if glm.dot(vec_ab, vec_ao) > 0 {
            simplex.dir = glm.normalize(glm.cross(glm.cross(vec_ab, vec_ao), vec_ab))

            return
        } else {
            simplex.points[0] = simplex.points[1]
            simplex.len = 1

            dir := glm.normalize(vec_ao)

            return
        }
    }

    if simplex.len == 3 {
        vec_a := simplex_get(simplex, 2)
        vec_b := simplex_get(simplex, 1)
        vec_c := simplex_get(simplex, 0)

        vec_ao := -vec_a
        vec_ab := vec_b - vec_a
        vec_ac := vec_c - vec_a

        vec_abc := glm.cross(vec_ab, vec_ac)
        vec_abc_ac := glm.cross(vec_abc, vec_ac)
        vec_ab_abc := glm.cross(vec_ab, vec_abc)

        if glm.dot(vec_abc_ac, vec_ao) > 0 {
            if glm.dot(vec_ac, vec_ao) > 0 {
                simplex.points[0] = vec_c
                simplex.points[1] = vec_a
                simplex.len = 2

                simplex.dir = glm.normalize(glm.cross(glm.cross(vec_ac, vec_ao), vec_ac))
            } else {
                if glm.dot(vec_ab, vec_ao) > 0 {
                    simplex.points[0] = vec_b
                    simplex.points[1] = vec_a
                    simplex.len = 2

                    simplex.dir = glm.normalize(glm.cross(glm.cross(vec_ab, vec_ao), vec_ab))
                } else {
                    simplex.points[0] = vec_a
                    simplex.len = 1

                    simplex.dir = glm.normalize(vec_ao)
                }
            }
        } else {
            if glm.dot(vec_ab_abc, vec_ao) > 0 {
                if glm.dot(vec_ab, vec_ao) > 0 {
                    simplex.points[0] = vec_b
                    simplex.points[1] = vec_a
                    simplex.len = 2

                    simplex.dir = glm.normalize(glm.cross(glm.cross(vec_ab, vec_ao), vec_ab))
                } else {
                    simplex.points[0] = vec_a
                    simplex.len = 1

                    simplex.dir = glm.normalize(vec_ao)
                }
            } else {
                if glm.dot(vec_abc, vec_ao) > 0 {
                    simplex.dir = glm.normalize(vec_abc)
                } else {
                    simplex.points[0] = vec_b
                    simplex.points[1] = vec_c

                    simplex.dir = glm.normalize(-vec_abc)
                }
            }
        }

        return
    }

    if simplex.len == 4 {
        vec_a := simplex_get(simplex, 3)
        vec_b := simplex_get(simplex, 2)
        vec_c := simplex_get(simplex, 1)
        vec_d := simplex_get(simplex, 0)

        vec_ao := -vec_a

        vec_ab := vec_b - vec_a
        vec_ac := vec_c - vec_a
        vec_ad := vec_d - vec_a

        vec_abc := glm.cross(vec_ab, vec_ac)
        vec_acd := glm.cross(vec_ac, vec_ad)
        vec_adb := glm.cross(vec_ad, vec_ab)

        if glm.dot(vec_abc, vec_ao) > 0 {
            simplex.points[0] = vec_c
            simplex.points[1] = vec_b
            simplex.points[2] = vec_a
            simplex.len = 3

            simplex.dir = glm.normalize(vec_abc)

            return
        }

        if glm.dot(vec_acd, vec_ao) > 0 {
            simplex.points[0] = vec_d
            simplex.points[1] = vec_c
            simplex.points[2] = vec_a
            simplex.len = 3

            simplex.dir = glm.normalize(vec_acd)

            return
        }

        if glm.dot(vec_adb, vec_ao) > 0 {
            simplex.points[0] = vec_b
            simplex.points[1] = vec_d
            simplex.points[2] = vec_a
            simplex.len = 3

            simplex.dir = glm.normalize(vec_adb)

            return
        }

        simplex.contains = true

        return
    }
}

gjk :: proc(hull: Hull, position: glm.vec3, radius: f32, initial_dir: glm.vec3) -> bool {
    simplex: Simplex

    point := gjk_support_hull(hull, initial_dir) - gjk_support_sphere(position, radius, -initial_dir)
    simplex_push(&simplex, point)

    simplex.dir = glm.normalize(-point)

    for i in 0 ..< 10 {
        point = gjk_support_hull(hull, simplex.dir) - gjk_support_sphere(position, radius, -simplex.dir)
        simplex_push(&simplex, point)

        if glm.dot(point, simplex.dir) < 0 {
            return false
        }

        gjk_simplex(&simplex)

        if simplex.contains {
            return true
        }
    }

    return false
}
