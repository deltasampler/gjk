package imdd

import glm "core:math/linalg/glsl"

Index_Offset :: struct {
    pos: uintptr,
    len: i32,
}

geometry_lines_box :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec3) -> (offset: Index_Offset) {
    offset.pos = cast(uintptr) len(indices)

    index := u32(len(vertices))

    append(vertices,
        glm.vec3{-size.x, -size.y,  size.z},
        glm.vec3{ size.x, -size.y,  size.z},
        glm.vec3{ size.x,  size.y,  size.z},
        glm.vec3{-size.x,  size.y,  size.z},
        glm.vec3{ size.x, -size.y, -size.z},
        glm.vec3{-size.x, -size.y, -size.z},
        glm.vec3{-size.x,  size.y, -size.z},
        glm.vec3{ size.x,  size.y, -size.z},
    )

    append(indices,
        index,     index + 1,
        index + 1, index + 2,
        index + 2, index + 3,
        index + 3, index + 0,

        index + 4, index + 5,
        index + 5, index + 6,
        index + 6, index + 7,
        index + 7, index + 4,

        index + 5, index + 0,
        index + 6, index + 3,

        index + 1, index + 4,
        index + 2, index + 7
    )

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_cylinder :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(uintptr) len(indices)

    angle := glm.PI * 2 / f32(segments)
    index := u32(len(vertices))

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, -size.y, z * size.x})
    }

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, size.y, z * size.x})
    }

    for i: u32 = 0; i < u32(segments); i += 1 {
        append(indices, index + i, index + (i + 1) % u32(segments))
        append(indices, index + u32(segments) + i, index + u32(segments) + (i + 1) % u32(segments))
        append(indices, index + i, index + u32(segments) + i)
    }

    half := u32(segments / 2)
    quarter := u32(segments / 4)
    top_start := index + u32(segments)

    append(indices, index + 0, index + half)
    append(indices, index + quarter, index + quarter + half)

    append(indices, top_start + 0, top_start + half)
    append(indices, top_start + quarter, top_start + quarter + half)

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_cone :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(uintptr) len(indices)

    angle := glm.PI * 2 / f32(segments)
    index := u32(len(vertices))

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, -size.y, z * size.x})
    }

    append(vertices, glm.vec3{0, size.y, 0})

    for i: u32 = 0; i < u32(segments); i += 1 {
        append(indices, index + i, index + (i + 1) % u32(segments))
        append(indices, index + i, index + u32(segments) )
    }

    half := u32(segments / 2)
    quarter := u32(segments / 4)

    append(indices, index + 0, index + half)
    append(indices, index + quarter, index + quarter + half)

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_sphere :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, radius: f32, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(uintptr) len(indices)

    rings := segments / 2
    start_index := u32(len(vertices))
    first_ring_start := start_index + 1

    append(vertices, glm.vec3{0, radius, 0})

    for lat in 1 ..< rings {
        theta := glm.PI * f32(lat) / f32(rings)
        y := radius * glm.cos(theta)
        r := radius * glm.sin(theta)

        for lon in 0 ..< segments {
            phi := 2.0 * glm.PI * f32(lon) / f32(segments)
            x := r * glm.cos(phi)
            z := r * glm.sin(phi)

            append(vertices, glm.vec3{x, y, z})
        }
    }

    num_mid_rings := u32(glm.max(0, rings - 1))
    bottom_index := first_ring_start + num_mid_rings * u32(segments)

    append(vertices, glm.vec3{0, -radius, 0})

    for lat: u32 = 0; lat < num_mid_rings; lat += 1 {
        row_start := first_ring_start + lat * u32(segments)

        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            next_lon := (lon + 1) % u32(segments)
            append(indices, row_start + lon, row_start + next_lon)
        }
    }

    if num_mid_rings > 0 {
        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            append(indices, start_index, first_ring_start + lon)
        }
    }

    if num_mid_rings >= 2 {
        for lat: u32 = 0; lat + 1 < num_mid_rings; lat += 1 {
            row0 := first_ring_start + lat * u32(segments)
            row1 := row0 + u32(segments)

            for lon: u32 = 0; lon < u32(segments); lon += 1 {
                append(indices, row0 + lon, row1 + lon)
            }
        }
    }

    if num_mid_rings > 0 {
        last_ring_start := bottom_index - u32(segments)

        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            append(indices, last_ring_start + lon, bottom_index)
        }
    } else {
        append(indices, start_index, bottom_index)
    }

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}
