package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

LINE_MODE_DEFAULT :: 0
LINE_MODE_ARROW :: 1

Debug_Line :: struct {
    start: glm.vec3,
    end: glm.vec3,
    width: f32,
    color: i32,
    bit: i32,
}

debug_line :: proc(start: glm.vec3, end: glm.vec3, width: f32, color: i32) {
    line := &system.line_data[system.line_len]
    line.start = start
    line.end = end
    line.width = width
    line.color = color
    line.bit = LINE_MODE_DEFAULT << 0
    system.line_len = (system.line_len + 1) % DEBUG_LINE_CAP
}

debug_arrow :: proc(start: glm.vec3, end: glm.vec3, width: f32, color: i32) {
    line := &system.line_data[system.line_len]
    line.start = start
    line.end = end
    line.width = width
    line.color = color
    line.bit = LINE_MODE_ARROW << 0
    system.line_len = (system.line_len + 1) % DEBUG_LINE_CAP
}

// rendering
LINE_VS :: `#version 460 core

layout(location = 0) in vec3 i_start;
layout(location = 1) in vec3 i_end;
layout(location = 2) in float i_width;
layout(location = 3) in int i_color;
layout(location = 4) in int i_bit;

out Geometry_Data {
    vec3 start;
    vec3 end;
    float width;
    int color;
    int bit;
} v_gd;

void main() {
    v_gd.start = i_start;
    v_gd.end = i_end;
    v_gd.width = i_width;
    v_gd.color = i_color;
    v_gd.bit = i_bit;
}
`

LINE_GS :: `#version 460 core

#define LINE_MODE_DEFAULT 0
#define LINE_MODE_ARROW 1

layout (points) in;
layout (triangle_strip, max_vertices = 7) out;

out vec3 v_color;
out float v_depth;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform int u_camera_mode;
uniform vec3 u_camera_position;
uniform vec3 u_camera_forward;

in Geometry_Data {
    vec3 start;
    vec3 end;
    float width;
    int color;
    int bit;
} v_gd[];

vec3 int_to_rgb(int i) {
    return vec3(
        (i >> 16) & 0xFF,
        (i >> 8) & 0xFF,
        i & 0xFF
    ) / 255.0;
}

void main() {
    vec3 start = v_gd[0].start;
    vec3 end   = v_gd[0].end;
    float width = v_gd[0].width;
    int color   = v_gd[0].color;
    int bit     = v_gd[0].bit;

    vec3 start_view = (u_view * vec4(start, 1.0)).xyz;
    vec3 end_view   = (u_view * vec4(end, 1.0)).xyz;

    vec3 line_dir = normalize(end_view - start_view);
    vec3 line_mid = (start_view + end_view) * 0.5;
    vec3 cam_dir = u_camera_mode == 0 ? normalize(line_mid - (u_view * vec4(u_camera_position, 1.0)).xyz) : vec3(0, 0, -1);
    vec3 perp = normalize(cross(line_dir, cam_dir));

    float base_width = width * 0.5;
    float cap_width  = base_width * 4.0;
    float cap_length = base_width * 8.0;
    vec3 cap_pos = bool(bit & LINE_MODE_ARROW) ? end_view - line_dir * cap_length : end_view;

    v_color = int_to_rgb(color);

    vec3 verts[4] = vec3[4](
        start_view - perp * base_width,
        start_view + perp * base_width,
        cap_pos    - perp * base_width,
        cap_pos    + perp * base_width
    );

    for (int i = 0; i < 4; i++) {
        gl_Position = u_projection * vec4(verts[i], 1.0);
        v_depth = -verts[i].z;
        EmitVertex();
    }

    if (bool(bit & LINE_MODE_ARROW)) {
        vec3 cap_verts[3] = vec3[3](
            cap_pos - perp * cap_width,
            cap_pos + perp * cap_width,
            end_view
        );

        for (int i = 0; i < 3; i++) {
            gl_Position = u_projection * vec4(cap_verts[i], 1.0);
            v_depth = -cap_verts[i].z;
            EmitVertex();
        }
    }
}
`

LINE_FS :: `#version 460 core
precision highp float;

in vec3 v_color;
in float v_depth;

out vec4 o_frag_color;

uniform vec2 u_resolution;
uniform sampler2D sa_depth;

void main() {
    #ifdef USE_DEPTH
        vec2 rm_uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
        float rm_depth = texture(sa_depth, rm_uv).x;

        if (rm_depth < v_depth) {
            discard;
        }
    #endif

    o_frag_color = vec4(v_color, 1.0);
}
`

init_line_rdr :: proc() {
    // data
    system.line_data = make([dynamic]Debug_Line, DEBUG_LINE_CAP, DEBUG_LINE_CAP)

    // vao
    gl.GenVertexArrays(1, &system.line_vao)
    gl.BindVertexArray(system.line_vao)

    // vbo
    gl.GenBuffers(1, &system.line_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.line_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Line) * DEBUG_LINE_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 1, gl.FLOAT, false, size_of(Debug_Line), offset)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.INT, size_of(Debug_Line), offset)
    offset += size_of(i32)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Debug_Line), offset)

    // shaders
    make_shader(&system.line_shader, load_shaders_source(LINE_VS, LINE_GS, LINE_FS))
}

free_line_rdr :: proc() {
    delete(system.line_data)
    gl.DeleteVertexArrays(1, &system.line_vao)
    gl.DeleteBuffers(1, &system.line_vbo)
    delete_shader(&system.line_shader)
}

render_line_rdr :: proc() {
    if system.line_len == 0 {
        return
    }

    uniforms := &system.line_shader.uniforms

    use_shader(&system.line_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])
    gl.Uniform1i(uniforms["u_camera_mode"] - 1, system.camera_mode)
    gl.Uniform3fv(uniforms["u_camera_position"] - 1, 1, &system.camera_position[0])
    gl.Uniform3fv(uniforms["u_camera_forward"] - 1, 1, &system.camera_forward[0])

    gl.BindVertexArray(system.line_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.line_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Line) * DEBUG_LINE_CAP, &system.line_data[0])

    gl.DrawArrays(gl.POINTS, 0, system.line_len)

    system.line_len = 0
}
