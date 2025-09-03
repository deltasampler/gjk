package collision

import glm "core:math/linalg/glsl"

SIMPLEX_CAP :: 4

Simplex :: struct {
    points: [SIMPLEX_CAP]glm.vec3,
    len: int,
}

simplex_push :: proc(simplex: ^Simplex, point: glm.vec3) {
    if simplex.len >= SIMPLEX_CAP {
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

simplex_get :: proc(simplex: Simplex, i: int) -> glm.vec3 {
    if i < 0 || i >= simplex.len {
        return {}
    }

    return simplex.points[i]
}

simplex_project_point :: proc(simplex: Simplex, point: glm.vec3) -> glm.vec3 {
    switch simplex.len {
    case 1:
        return simplex.points[0]
    case 2:
        return project_point_on_line(simplex.points[1], simplex.points[0], point)
    case 3:
        return project_point_on_triangle(simplex.points[2], simplex.points[1], simplex.points[0], point)
    case 4:
        return project_point_on_tetrahedron(simplex.points[3], simplex.points[2], simplex.points[1], simplex.points[0], point)
    }

    return {}
}
