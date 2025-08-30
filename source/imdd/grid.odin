package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Grid_Plane :: struct {
    position: glm.vec3,
    size: glm.vec2,
    normal: glm.vec3,
    cell_size: glm.vec2,
    line_width: f32,
    color: i32,
}

debug_grid_n :: proc(position: glm.vec3, size: glm.vec2, normal: glm.vec3, cell_size: glm.vec2, line_width: f32, color: i32) {
    grid := &system.grid_data[system.grid_len]
    grid.position = position
    grid.size = size / 2
    grid.normal = normal
    grid.cell_size = cell_size
    grid.line_width = line_width
    grid.color = color
    system.grid_len = (system.grid_len + 1) % DEBUG_GRID_CAP
}

debug_grid_xy :: proc(position: glm.vec3, size: glm.vec2, cell_size: glm.vec2, line_width: f32, color: i32) {
    grid := &system.grid_data[system.grid_len]
    grid.position = position
    grid.size = size / 2
    grid.normal = {0, 0, 1}
    grid.cell_size = cell_size
    grid.line_width = line_width
    grid.color = color
    system.grid_len = (system.grid_len + 1) % DEBUG_GRID_CAP
}

debug_grid_xz :: proc(position: glm.vec3, size: glm.vec2, cell_size: glm.vec2, line_width: f32, color: i32) {
    grid := &system.grid_data[system.grid_len]
    grid.position = position
    grid.size = size / 2
    grid.normal = {0, 1, 0}
    grid.cell_size = cell_size
    grid.line_width = line_width
    grid.color = color
    system.grid_len = (system.grid_len + 1) % DEBUG_GRID_CAP
}

debug_grid_zy :: proc(position: glm.vec3, size: glm.vec2, cell_size: glm.vec2, line_width: f32, color: i32) {
    grid := &system.grid_data[system.grid_len]
    grid.position = position
    grid.size = size / 2
    grid.normal = {1, 0, 0}
    grid.cell_size = cell_size
    grid.line_width = line_width
    grid.color = color
    system.grid_len = (system.grid_len + 1) % DEBUG_GRID_CAP
}

debug_grid :: proc {
    debug_grid_n,
    debug_grid_xz,
}

// rendering
GRID_VS :: `#version 460 core

    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec2 i_size;
    layout(location = 2) in vec3 i_normal;
    layout(location = 3) in vec2 i_cell_size;
    layout(location = 4) in float i_line_width;
    layout(location = 5) in int i_color;

    out vec2 v_line_width;
    out vec3 v_color;
    out vec2 v_tex_coord;
    out float v_depth;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    const vec2 positions[4] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );

    const vec2 tex_coords[4] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        vec3 tangent_x = normalize(
            abs(i_normal.x) < 0.99
                ? cross(i_normal, vec3(1.0, 0.0, 0.0))
                : cross(i_normal, vec3(0.0, 1.0, 0.0))
        );
        vec3 tangent_y = normalize(cross(i_normal, tangent_x));

        vec2 local = positions[gl_VertexID];
        vec4 position = vec4(tangent_x * local.x * i_size.x + tangent_y * local.y * i_size.y + i_position, 1.0);

        gl_Position = u_projection * u_view * position;
        v_line_width = vec2(i_line_width, i_line_width) / i_cell_size;
        v_color = int_to_rgb(i_color);
        v_tex_coord = tex_coords[gl_VertexID] * i_size / i_cell_size * 2.0;
        v_depth = -(u_view * position).z;
    }
`

GRID_FS :: `#version 460 core
precision highp float;

in vec2 v_line_width;
in vec3 v_color;
in vec2 v_tex_coord;
in float v_depth;

out vec4 o_frag_color;

uniform vec2 u_resolution;
uniform sampler2D sa_depth;

float draw_grid(vec2 uv, vec2 line_width) {
    vec2 ddx = dFdx(uv), ddy = dFdy(uv);
    vec2 uv_deriv = vec2(length(vec2(ddx.x, ddy.x)), length(vec2(ddx.y, ddy.y)));
    vec2 line_aa = uv_deriv * 1.5;

    bvec2 invert_line = bvec2(line_width.x > 0.5, line_width.y > 0.5);
    vec2 target_width = vec2(
        invert_line.x ? 1.0 - line_width.x : line_width.x,
        invert_line.y ? 1.0 - line_width.y : line_width.y
    );
    vec2 draw_width = clamp(target_width, uv_deriv, vec2(0.5));

    vec2 grid_uv = abs(fract(uv) * 2.0 - 1.0);
    grid_uv.x = invert_line.x ? grid_uv.x : 1.0 - grid_uv.x;
    grid_uv.y = invert_line.y ? grid_uv.y : 1.0 - grid_uv.y;

    vec2 grid = smoothstep(draw_width + line_aa, draw_width - line_aa, grid_uv);
    grid *= clamp(target_width / draw_width, 0.0, 1.0);
    grid = mix(grid, target_width, clamp(uv_deriv * 2.0 - 1.0, 0.0, 1.0));
    grid.x = invert_line.x ? 1.0 - grid.x : grid.x;
    grid.y = invert_line.y ? 1.0 - grid.y : grid.y;

    return mix(grid.x, 1.0, grid.y);
}

void main() {
    #ifdef USE_DEPTH
        vec2 rm_uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
        float rm_depth = texture(sa_depth, rm_uv).x;

        if (rm_depth < v_depth) {
            discard;
        }
    #endif

    vec2 uv = v_tex_coord;

    o_frag_color = vec4(v_color, draw_grid(uv, v_line_width));
}
`

init_grid_rdr :: proc() {
    // data
    system.grid_data = make([dynamic]Debug_Grid_Plane, DEBUG_GRID_CAP, DEBUG_GRID_CAP)

    // vao
    gl.GenVertexArrays(1, &system.grid_vao)
    gl.BindVertexArray(system.grid_vao)

    // vbo
    gl.GenBuffers(1, &system.grid_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.grid_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Grid_Plane) * DEBUG_GRID_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(0, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(1, 1)
    offset += size_of(glm.vec2)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(2, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(3, 1)
    offset += size_of(glm.vec2)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 1, gl.FLOAT, false, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(4, 1)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 1, gl.INT, size_of(Debug_Grid_Plane), offset)
    gl.VertexAttribDivisor(5, 1)

    // shaders
    make_shader(&system.grid_shader, gl.load_shaders_source(GRID_VS, GRID_FS))
}

free_grid_rdr :: proc() {
    delete(system.grid_data)
    gl.DeleteVertexArrays(1, &system.grid_vao)
    gl.DeleteBuffers(1, &system.grid_vbo)
    delete_shader(&system.grid_shader)
}

render_grid_rdr :: proc() {
    if system.grid_len == 0 {
        return
    }

    uniforms := &system.grid_shader.uniforms

    use_shader(&system.grid_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])

    gl.BindVertexArray(system.grid_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.grid_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Grid_Plane) * DEBUG_GRID_CAP, &system.grid_data[0])

    gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, system.grid_len)

    system.grid_len = 0
}
