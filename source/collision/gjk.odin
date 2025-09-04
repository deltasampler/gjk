package collision

import "core:fmt"
import glm "core:math/linalg/glsl"

GJK_ITER_LIMIT :: 64

GJK_State :: struct {
    contains_origin: bool,
    dir: glm.vec3,
    simplex: Simplex,
}

case_simplex2 :: proc(state: ^GJK_State, point: glm.vec3) {
    vec_a := simplex_get(state.simplex, 1)
    vec_b := simplex_get(state.simplex, 0)

    vec_ab := vec_b - vec_a
    vec_ao := point - vec_a

    if is_same_dir(vec_ab, vec_ao) {
        state.dir = glm.cross(glm.cross(vec_ab, vec_ao), vec_ab)
    } else {
        state.simplex.points[0] = vec_a
        state.simplex.len = 1

        state.dir = vec_ao
    }
}

case_simplex3 :: proc(state: ^GJK_State, point: glm.vec3) {
    vec_a := simplex_get(state.simplex, 2)
    vec_b := simplex_get(state.simplex, 1)
    vec_c := simplex_get(state.simplex, 0)

    vec_ab := vec_b - vec_a
    vec_ac := vec_c - vec_a
    vec_ao := point - vec_a

    vec_abc := glm.cross(vec_ab, vec_ac)
    vec_abc_ac := glm.cross(vec_abc, vec_ac)

    if is_same_dir(vec_abc_ac, vec_ao) {
        if is_same_dir(vec_ac, vec_ao) {
            state.simplex.points[0] = vec_c
            state.simplex.points[1] = vec_a
            state.simplex.len = 2

            state.dir = glm.cross(glm.cross(vec_ac, vec_ao), vec_ac)
        } else {
            if is_same_dir(vec_ab, vec_ao) {
                state.simplex.points[0] = vec_b
                state.simplex.points[1] = vec_a
                state.simplex.len = 2

                state.dir = glm.cross(glm.cross(vec_ab, vec_ao), vec_ab)
            } else {
                state.simplex.points[0] = vec_a
                state.simplex.len = 1

                state.dir = vec_ao
            }
        }
    } else {
        vec_ab_abc := glm.cross(vec_ab, vec_abc)

        if is_same_dir(vec_ab_abc, vec_ao) {
            if glm.dot(vec_ab, vec_ao) > 0 {
                state.simplex.points[0] = vec_b
                state.simplex.points[1] = vec_a
                state.simplex.len = 2

                state.dir = glm.cross(glm.cross(vec_ab, vec_ao), vec_ab)
            } else {
                state.simplex.points[0] = vec_a
                state.simplex.len = 1

                state.dir = vec_ao
            }
        } else {
            if is_same_dir(vec_abc, vec_ao) {
                state.dir = vec_abc
            } else {
                state.simplex.points[0] = vec_b
                state.simplex.points[1] = vec_c

                state.dir = -vec_abc
            }
        }
    }
}

case_simplex4 :: proc(state: ^GJK_State, point: glm.vec3) {
    vec_a := simplex_get(state.simplex, 3)
    vec_b := simplex_get(state.simplex, 2)
    vec_c := simplex_get(state.simplex, 1)
    vec_d := simplex_get(state.simplex, 0)

    vec_ab := vec_b - vec_a
    vec_ac := vec_c - vec_a
    vec_ao := point - vec_a

    vec_abc := glm.cross(vec_ab, vec_ac)

    if is_same_dir(vec_abc, vec_ao) {
        state.simplex.points[0] = vec_c
        state.simplex.points[1] = vec_b
        state.simplex.points[2] = vec_a
        state.simplex.len = 3

        state.dir = vec_abc

        return
    }

    vec_ad := vec_d - vec_a
    vec_acd := glm.cross(vec_ac, vec_ad)

    if is_same_dir(vec_acd, vec_ao) {
        state.simplex.points[2] = vec_a
        state.simplex.len = 3

        state.dir = vec_acd

        return
    }

    vec_adb := glm.cross(vec_ad, vec_ab)

    if is_same_dir(vec_adb, vec_ao) {
        state.simplex.points[0] = vec_b
        state.simplex.points[1] = vec_d
        state.simplex.points[2] = vec_a
        state.simplex.len = 3

        state.dir = vec_adb

        return
    }

    state.contains_origin = true
}

gjk :: proc(collider0: Collider, collider1: Collider) -> bool {
    dir := collider1.position - collider0.position
    point := support(collider1, dir) - support(collider0, -dir)

    state: GJK_State
    state.dir = -point
    simplex_push(&state.simplex, point)

    for i in 0 ..< GJK_ITER_LIMIT {
        point = support(collider1, state.dir) - support(collider0, -state.dir)

        if !is_same_dir(point, state.dir) {
            return false
        }

        simplex_push(&state.simplex, point)

        switch state.simplex.len {
        case 2:
            case_simplex2(&state, {})
        case 3:
            case_simplex3(&state, {})
        case 4:
            case_simplex4(&state, {})
        }

        if state.contains_origin {
            return true
        }
    }

    return false
}
