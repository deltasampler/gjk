package collision

import glm "core:math/linalg/glsl"

EPA_ITER_LIMIT :: 64
EPA_FACES_CAP :: 64
EPA_EDGES_CAP :: 32
EPA_TOLERANCE :: 0.0001
EPA_BIAS :: 0.000001

Collision_Info :: struct {
    intersects: bool,
    normal: glm.vec3,
    depth: glm.vec3,
}

calc_normal :: proc(a: glm.vec3, b: glm.vec3, c: glm.vec3) -> glm.vec3 {
    return glm.normalize(glm.cross(b - a, c - a))
}

epa :: proc(collider0: Collider, collider1: Collider, simplex: Simplex) -> (info: Collision_Info) {
    a := simplex.points[3]
    b := simplex.points[2]
    c := simplex.points[1]
    d := simplex.points[0]

    faces: [EPA_FACES_CAP][4]glm.vec3
    faces_len := 4

    faces[0][0] = a;
    faces[0][1] = b;
    faces[0][2] = c;
    faces[0][3] = calc_normal(a, b, c)

    faces[1][0] = a;
    faces[1][1] = c;
    faces[1][2] = d;
    faces[1][3] = calc_normal(a, c, d)

    faces[2][0] = a;
    faces[2][1] = d;
    faces[2][2] = b;
    faces[2][3] = calc_normal(a, d, b)

    faces[3][0] = b;
    faces[3][1] = d;
    faces[3][2] = c;
    faces[3][3] = calc_normal(b, d, c)

    closest_face: int

    for i in 0 ..< EPA_ITER_LIMIT {
        dist_min := glm.dot(faces[0][0], faces[0][3])
        closest_face = 0

        for i in 1 ..< faces_len {
            dist := glm.dot(faces[i][0], faces[i][3])

            if dist < dist_min {
                dist_min = dist
                closest_face = i
            }
        }

        dir := faces[closest_face][3]
        point := support(collider1, dir) - support(collider0, -dir)

        if glm.dot(point, dir) - dist_min < EPA_TOLERANCE {
            info.intersects = true
            info.normal = faces[closest_face][3]
            info.depth = glm.dot(point, dir)

            return
        }

        edges: [EPA_EDGES_CAP][2]glm.vec3
        edges_len := 0

        for i := 0; i < faces_len; i += 1 {
            if glm.dot(faces[i][3], point - faces[i][0]) > 0 {
                for j in 0 ..< 3 {
                    current_edge := [2]glm.vec3{faces[i][j], faces[i][(j + 1) % 3]}
                    found_edge := false

                    for k := 0; k < edges_len; k += 1 {
                        if edges[k][1] == current_edge[0] && edges[k][0] == current_edge[1] {
                            edges[k][0] = edges[edges_len - 1][0]
                            edges[k][1] = edges[edges_len - 1][1]
                            edges_len -= 1
                            k = edges_len
                            found_edge = true
                        }
                    }

                    if !found_edge {
                        if edges_len >= EPA_EDGES_CAP {
                            break
                        }

                        edges[edges_len][0] = current_edge[0]
                        edges[edges_len][1] = current_edge[1]
                        edges_len += 1
                    }
                }

                faces[i][0] = faces[faces_len - 1][0]
                faces[i][1] = faces[faces_len - 1][1]
                faces[i][2] = faces[faces_len - 1][2]
                faces[i][3] = faces[faces_len - 1][3]
                faces_len -= 1
                i -= 1
            }
        }

        for i := 0; i < edges_len; i += 1 {
            if faces_len >= EPA_FACES_CAP {
                break
            }

            faces[faces_len][0] = edges[i][0]
            faces[faces_len][1] = edges[i][1]
            faces[faces_len][2] = point
            faces[faces_len][3] = calc_normal(edges[i][0], edges[i][1], point)

            if glm.dot(faces[faces_len][0], faces[faces_len][3]) + EPA_BIAS < 0 {
                temp := faces[faces_len][0]
                faces[faces_len][0] = faces[faces_len][1]
                faces[faces_len][1] = temp
                faces[faces_len][3] = -faces[faces_len][3]
            }

            faces_len += 1
        }
    }

    info.intersects = true
    info.normal = faces[closest_face][3]
    info.depth = glm.dot(faces[closest_face][0], faces[closest_face][3])

    return
}
