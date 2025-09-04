package collision

import glm "core:math/linalg/glsl"

// Original author: Gary Snethen
// Original source: https://github.com/erwincoumans/xenocollide/blob/master/XenoTestbed/Tests/TestXenoCollide/Collide.cpp

MPR_ITER_LIMIT :: 64
MPR_BOUNDARY_TOLERANCE :: 0.000001

MPR_Collision_Info :: struct {
    intersects: bool,
    point0: glm.vec3,
    point1: glm.vec3,
    normal: glm.vec3,
}

mpr_intersect :: proc(collider0: Collider, collider1: Collider) -> bool {
    v0 := collider1.position - collider0.position

    if glm.dot(v0, v0) < glm.F32_EPSILON * glm.F32_EPSILON {
        return true
    }

    n := -v0
    v1 := support(collider1, n) - support(collider0, -n)

    if glm.dot(v1, n) <= 0 {
        return false
    }

    n = glm.cross(v1, v0)

    if glm.dot(n, n) < glm.F32_EPSILON * glm.F32_EPSILON {
        return true
    }

    v2 := support(collider1, n) - support(collider0, -n)

    if glm.dot(v2, n) <= 0 {
        return false
    }

    n = glm.cross(v1 - v0, v2 - v0)

    if glm.dot(n, v0) > 0 {
        temp := v1
        v1 = v2
        v2 = v1

        n = -n
    }

    for i in 0 ..< MPR_ITER_LIMIT {
        v3 := support(collider1, n) - support(collider0, -n)

        if glm.dot(v3, n) <= 0 {
            return false
        }

        if glm.dot(glm.cross(v1, v3), v0) < 0 {
            v2 = v3
            n = glm.cross(v1 - v0, v3 - v0)

            continue
        }

        if glm.dot(glm.cross(v3, v2), v0) < 0 {
            v1 = v3
            n = glm.cross(v3 - v0, v2 - v0)

            continue
        }

        for j in 0 ..< MPR_ITER_LIMIT {
            n = glm.cross(v2 - v1, v3 - v1)

            if glm.dot(n, v1) >= 0 {
                return true
            }

            v4 := support(collider1, n) - support(collider0, -n)

            n = glm.normalize(n)

            if -glm.dot(v4, n) >= 0 || glm.dot(v4 - v3, n) < MPR_BOUNDARY_TOLERANCE {
                return false
            }

            cross := glm.cross(v4, v0)

            if glm.dot(v1, cross) > 0 {
                if glm.dot(v2, cross) > 0 {
                    v1 = v4
                } else {
                    v3 = v4
                }
            } else {
                if glm.dot(v3, cross) > 0 {
                    v2 = v4
                } else {
                    v1 = v4
                }
            }
        }
    }

    return false
}

mpr_contact :: proc(collider0: Collider, collider1: Collider) -> (info: MPR_Collision_Info) {
    collide_epsilon: f32 = 1e-3

    v01 := collider0.position
    v02 := collider1.position
    v0 := v02 - v01

    if glm.dot(v0, v0) < glm.F32_EPSILON * glm.F32_EPSILON {
        v0 = {0.00001, 0, 0}
    }

    n := -v0
    v11 := support(collider0, -n)
    v12 := support(collider1, n)
    v1 := v12 - v11

    if glm.dot(v1, n) <= 0 {
        info.normal = n

        return
    }

    n = glm.cross(v1, v0)

    if glm.dot(n, n) < glm.F32_EPSILON * glm.F32_EPSILON {
        n = glm.normalize(v1 - v0)

        info.intersects = true
        info.normal = n
        info.point0 = v11
        info.point1 = v12

        return
    }

    v21 := support(collider0, -n)
    v22 := support(collider1, n)
    v2 := v22 - v21

    if glm.dot(v2, n) <= 0 {
        info.normal = n

        return
    }

    n = glm.cross(v1 - v0, v2 - v0)
    dist := glm.dot(n, v0)

    if dist > 0 {
        temp := v1
        v1 = v2
        v2 = temp

        temp = v11
        v11 = v21
        v21 = temp

        temp = v12
        v12 = v22
        v22 = temp

        n = -n
    }

    for i in 0 ..< MPR_ITER_LIMIT {
        v31 := support(collider0, -n)
        v32 := support(collider1, n)
        v3 := v32 - v31

        if glm.dot(v3, n) <= 0 {
            info.normal = n

            return
        }

        if glm.dot(glm.cross(v1, v3), v0) < 0 {
            v2 = v3
            v21 = v31
            v22 = v32
            n = glm.cross(v1 - v0, v3 - v0)

            continue
        }

        if glm.dot(glm.cross(v3, v2), v0) < 0 {
            v1 = v3
            v11 = v31
            v12 = v32
            n = glm.cross(v3 - v0, v2 - v0)

            continue
        }

        hit := false

        for j in 0 ..< MPR_ITER_LIMIT {
            n = glm.cross(v2 - v1, v3 - v1)

            if glm.dot(n, n) < glm.F32_EPSILON * glm.F32_EPSILON {
                info.intersects = true

                return
            }

            n = glm.normalize(n)

            d := glm.dot(n, v1)

            if d >= 0 && !hit {
                info.normal = n

                b0 := glm.dot(glm.cross(v1, v2), v3)
                b1 := glm.dot(glm.cross(v3, v2), v0)
                b2 := glm.dot(glm.cross(v0, v1), v3)
                b3 := glm.dot(glm.cross(v2, v1), v0)

                sum := b0 + b1 + b2 + b3

                if sum <= 0 {
                    b0 = 0
                    b1 = glm.dot(glm.cross(v2, v3), n)
                    b2 = glm.dot(glm.cross(v3, v1), n)
                    b3 = glm.dot(glm.cross(v1, v2), n)

                    sum = b1 + b2 + b3
                }

                inv := 1 / sum

                info.point0 = (b0 * v01 + b1 * v11 + b2 * v21 + b3 * v31) * inv
                info.point1 = (b0 * v02 + b1 * v12 + b2 * v22 + b3 * v32) * inv
                info.intersects = true

                hit = true
            }

            v41 := support(collider0, -n)
            v42 := support(collider1, n)
            v4 := v42 - v41

            delta := glm.dot(v4 - v3, n)
            separation := -glm.dot(v4, n)

            if delta <= collide_epsilon || separation >= 0 {
                info.intersects = hit
                info.normal = n

                return
            }

            d1 := glm.dot(glm.cross(v4, v1), v0)
            d2 := glm.dot(glm.cross(v4, v2), v0)
            d3 := glm.dot(glm.cross(v4, v3), v0)

            if d1 < 0 {
                if d2 < 0 {
                    v1 = v4
                    v11 = v41
                    v12 = v42
                } else {
                    v3 = v4
                    v31 = v41
                    v32 = v42
                }
            } else {
                if d3 < 0 {
                    v2 = v4
                    v21 = v41
                    v22 = v42
                } else {
                    v1 = v4
                    v11 = v41
                    v12 = v42
                }
            }
        }
    }

    return
}
