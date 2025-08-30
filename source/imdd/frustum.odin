package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Frustum :: struct {
    proj_view: glm.mat4,
    color: i32,
}

debug_frustum :: proc(proj_view: glm.mat4, color: i32) {
    frustum := &system.frustum_data[system.frustum_len]
    frustum.proj_view = proj_view
    frustum.color = color
    system.frustum_len = (system.frustum_len + 1) % DEBUG_FRUSTUM_CAP
}

// rendering
FRUSTUM_VS :: `#version 460 core

layout(location = 0) in vec4 i_proj_view0;
layout(location = 1) in vec4 i_proj_view1;
layout(location = 2) in vec4 i_proj_view2;
layout(location = 3) in vec4 i_proj_view3;
layout(location = 4) in int i_color;

out Geometry_Data {
    mat4 proj_view;
    vec3 color;
} v_gd;

vec3 int_to_rgb(int i) {
    return vec3(
        (i >> 16) & 0xFF,
        (i >> 8) & 0xFF,
        i & 0xFF
    ) / 255.0;
}

void main() {
    v_gd.proj_view = mat4(
        i_proj_view0,
        i_proj_view1,
        i_proj_view2,
        i_proj_view3
    );
    v_gd.color = int_to_rgb(i_color);
}
`

FRUSTUM_GS :: `#version 460 core

layout (points) in;
layout (line_strip, max_vertices = 24) out;

out vec3 v_color;
out float v_depth;

uniform mat4 u_projection;
uniform mat4 u_view;

in Geometry_Data {
    mat4 proj_view;
    vec3 color;
} v_gd[];

void emit_line(vec4 a_view, vec4 b_view, vec3 color) {
    v_color = color;

    v_depth = -a_view.z;
    gl_Position = u_projection * a_view;
    EmitVertex();

    v_depth = -b_view.z;
    gl_Position = u_projection * b_view;
    EmitVertex();

    EndPrimitive();
}

void main() {
    mat4 proj_view = v_gd[0].proj_view;
    vec3 color = v_gd[0].color;

    mat4 inv_proj_view = inverse(proj_view);

    vec4 c0 = inv_proj_view * vec4(-1, -1, -1, 1);
    vec4 c1 = inv_proj_view * vec4( 1, -1, -1, 1);
    vec4 c2 = inv_proj_view * vec4( 1,  1, -1, 1);
    vec4 c3 = inv_proj_view * vec4(-1,  1, -1, 1);
    vec4 c4 = inv_proj_view * vec4(-1, -1,  1, 1);
    vec4 c5 = inv_proj_view * vec4( 1, -1,  1, 1);
    vec4 c6 = inv_proj_view * vec4( 1,  1,  1, 1);
    vec4 c7 = inv_proj_view * vec4(-1,  1,  1, 1);

    c0 /= c0.w; c1 /= c1.w; c2 /= c2.w; c3 /= c3.w;
    c4 /= c4.w; c5 /= c5.w; c6 /= c6.w; c7 /= c7.w;

    c0 = u_view * c0;
    c1 = u_view * c1;
    c2 = u_view * c2;
    c3 = u_view * c3;
    c4 = u_view * c4;
    c5 = u_view * c5;
    c6 = u_view * c6;
    c7 = u_view * c7;

    emit_line(c0, c1, color);
    emit_line(c1, c2, color);
    emit_line(c2, c3, color);
    emit_line(c3, c0, color);

    emit_line(c4, c5, color);
    emit_line(c5, c6, color);
    emit_line(c6, c7, color);
    emit_line(c7, c4, color);

    emit_line(c0, c4, color);
    emit_line(c1, c5, color);
    emit_line(c2, c6, color);
    emit_line(c3, c7, color);
}
`

FRUSTUM_FS :: `#version 460 core
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

init_frustum_rdr :: proc() {
    // data
    system.frustum_data = make([dynamic]Debug_Frustum, DEBUG_FRUSTUM_CAP, DEBUG_FRUSTUM_CAP)

    // vao
    gl.GenVertexArrays(1, &system.frustum_vao)
    gl.BindVertexArray(system.frustum_vao)

    // vbo
    gl.GenBuffers(1, &system.frustum_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.frustum_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Frustum) * DEBUG_FRUSTUM_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, false, size_of(Debug_Frustum), offset)
    offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Debug_Frustum), offset)
    offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Debug_Frustum), offset)
    offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 4, gl.FLOAT, false, size_of(Debug_Frustum), offset)
    offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Debug_Frustum), offset)

    // shaders
    make_shader(&system.frustum_shader, load_shaders_source(FRUSTUM_VS, FRUSTUM_GS, FRUSTUM_FS))
}

free_frustum_rdr :: proc() {
    delete(system.frustum_data)
    gl.DeleteVertexArrays(1, &system.frustum_vao)
    gl.DeleteBuffers(1, &system.frustum_vbo)
    delete_shader(&system.frustum_shader)
}

render_frustum_rdr :: proc() {
    if system.frustum_len == 0 {
        return
    }

    uniforms := &system.frustum_shader.uniforms

    use_shader(&system.frustum_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])

    gl.BindVertexArray(system.frustum_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.frustum_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Frustum) * DEBUG_FRUSTUM_CAP, &system.frustum_data[0])

    gl.DrawArrays(gl.POINTS, 0, system.frustum_len)

    system.frustum_len = 0
}
