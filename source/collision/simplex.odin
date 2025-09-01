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
