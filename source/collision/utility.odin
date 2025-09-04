package collision

import glm "core:math/linalg/glsl"

is_same_dir :: proc(a: glm.vec3, b: glm.vec3) -> bool {
    return glm.dot(a, b) > 0
}

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

project_point_on_line :: proc(vec_a: glm.vec3, vec_b: glm.vec3, point: glm.vec3, clamp: bool = false) -> glm.vec3 {
    vec_ab := vec_b - vec_a
    vec_ao := point - vec_a

    t := glm.dot(vec_ao, vec_ab) / glm.dot(vec_ab, vec_ab)
    t = clamp ? glm.clamp(t, 0, 1) : t

    return vec_a + t * vec_ab
}

project_point_on_triangle :: proc(vec_a: glm.vec3, vec_b: glm.vec3, vec_c: glm.vec3, point: glm.vec3, clamp: bool = false) -> glm.vec3 {
    vec_ab := vec_b - vec_a
    vec_ac := vec_c - vec_a
    vec_ao := point - vec_a

    d00 := glm.dot(vec_ab, vec_ab)
    d01 := glm.dot(vec_ab, vec_ac)
    d11 := glm.dot(vec_ac, vec_ac)
    d20 := glm.dot(vec_ao, vec_ab)
    d21 := glm.dot(vec_ao, vec_ac)

    denom := d00 * d11 - d01 * d01
    v := (d11 * d20 - d01 * d21) / denom
    w := (d00 * d21 - d01 * d20) / denom
    u := 1.0 - v - w

    if clamp {
        v = glm.clamp(v, 0.0, 1.0)
        w = glm.clamp(w, 0.0, 1.0)
        u = glm.clamp(u, 0.0, 1.0)

        sum := u + v + w

        u /= sum
        v /= sum
        w /= sum
    }

    return vec_a * u + vec_b * v + vec_c * w
}

project_point_on_tetrahedron :: proc(vec_a: glm.vec3, vec_b: glm.vec3, vec_c: glm.vec3, vec_d: glm.vec3, point: glm.vec3) -> glm.vec3 {
    faces: [4][3]glm.vec3
    faces[0] = {vec_a, vec_b, vec_c}
    faces[1] = {vec_a, vec_b, vec_d}
    faces[2] = {vec_a, vec_c, vec_d}
    faces[3] = {vec_b, vec_c, vec_d}

    closest := vec_a
    dist_min := glm.dot(point - vec_a, point - vec_a)

    for face in faces {
        proj := project_point_on_triangle(face[0], face[1], face[2], point, true)
        delta := point - proj
        dist := glm.dot(delta, delta)

        if dist < dist_min {
            dist_min = dist
            closest = proj
        }
    }

    return closest
}
