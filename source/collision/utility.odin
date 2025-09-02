package collision

import glm "core:math/linalg/glsl"

calc_normal :: proc(a: glm.vec3, b: glm.vec3, c: glm.vec3) -> glm.vec3 {
    return glm.normalize(glm.cross(b - a, c - a))
}

calc_hull_extent :: proc(vertices: []glm.vec3) -> glm.vec3 {
    min := vertices[0]
    max := vertices[0]

    for i in 1 ..< len(vertices) {
        vertex := vertices[i]

        min = glm.min(min, vertex)
        max = glm.max(max, vertex)
    }

    return glm.abs(max - min) / 2
}
