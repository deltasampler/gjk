package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Shape :: struct {
    translation: glm.vec3,
    rotation: glm.quat,
    scale: glm.vec3,
    color: i32,
}

debug_aabb :: proc(position: glm.vec3, size: glm.vec3, color: i32) {
    shape := &system.box_data[system.box_len]
    shape.translation = position
    shape.rotation = {}
    shape.scale = size / 2
    shape.color = color
    system.box_len = (system.box_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_aabb_bounds :: proc(min: glm.vec3, max: glm.vec3, color: i32) {
    shape := &system.box_data[system.box_len]
    shape.translation = (min + max) / 2
    shape.rotation = {}
    shape.scale = glm.abs(max - min) / 2
    shape.color = color
    system.box_len = (system.box_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_obb :: proc(position: glm.vec3, size: glm.vec3, rotation: glm.vec3, color: i32) {
    shape := &system.box_data[system.box_len]
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = size / 2
    shape.color = color
    system.box_len = (system.box_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cylinder_aa :: proc(position: glm.vec3, size: glm.vec2, color: i32) {
    shape := &system.cylinder_data[system.cylinder_len]
    shape.translation = position
    shape.rotation = {}
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
    system.cylinder_len = (system.cylinder_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cylinder_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: i32) {
    shape := &system.cylinder_data[system.cylinder_len]
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
    system.cylinder_len = (system.cylinder_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cylinder_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: i32) {
    height := glm.distance(start, end) / 2

    shape := &system.cylinder_data[system.cylinder_len]
    shape.translation = (start + end) / 2
    shape.rotation = quat_rotation_dir(glm.normalize(end - start))
    shape.scale = {radius, height, radius}
    shape.color = color
    system.cylinder_len = (system.cylinder_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cone_aa :: proc(position: glm.vec3, size: glm.vec2, color: i32) {
    shape := &system.cone_data[system.cone_len]
    shape.translation = position
    shape.rotation = {}
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
    system.cone_len = (system.cone_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cone_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: i32) {
    shape := &system.cone_data[system.cone_len]
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
    system.cone_len = (system.cone_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_cone_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: i32) {
    height := glm.distance(start, end) / 2

    shape := &system.cone_data[system.cone_len]
    shape.translation = (start + end) / 2
    shape.rotation = quat_rotation_dir(glm.normalize(start - end))
    shape.scale = {radius, height, radius}
    shape.color = color
    system.cone_len = (system.cone_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

debug_sphere :: proc(position: glm.vec3, radius: f32, color: i32) {
    shape := &system.sphere_data[system.sphere_len]
    shape.translation = position
    shape.rotation = {}
    shape.scale = {radius, radius, radius}
    shape.color = color
    system.sphere_len = (system.sphere_len + 1) % DEBUG_SHAPE_CAP
    system.shape_len += 1
}

// rendering
SHAPE_VS :: `#version 460 core

    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec3 i_translation;
    layout(location = 2) in vec4 i_rotation;
    layout(location = 3) in vec3 i_scale;
    layout(location = 4) in int i_color;

    out Geometry_Data {
        vec3 color;
    } v_gd;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 rotate(vec3 v, vec4 q) {
        return 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v) + v;
    }

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        gl_Position = vec4(rotate(i_position * i_scale, i_rotation) + i_translation, 1.0);
        v_gd.color = int_to_rgb(i_color);
    }
`

SHAPE_GS :: `#version 460 core

#define LINE_WIDTH 2.0

layout (lines) in;
layout (triangle_strip, max_vertices = 4) out;

out vec3 v_color;
out float v_width;
out float v_dist;
out float v_depth;

in Geometry_Data {
    vec3 color;
} v_gd[];

uniform mat4 u_projection;
uniform mat4 u_view;
uniform vec2 u_resolution;

void main() {
    vec4 p0_world = gl_in[0].gl_Position;
    vec4 p1_world = gl_in[1].gl_Position;

    vec4 p0_view = u_view * p0_world;
    vec4 p1_view = u_view * p1_world;

    vec4 p0_clip = u_projection * p0_view;
    vec4 p1_clip = u_projection * p1_view;

    vec2 p0_ndc = p0_clip.xy / p0_clip.w;
    vec2 p1_ndc = p1_clip.xy / p1_clip.w;

    vec2 p0_screen = p0_ndc * u_resolution * 0.5;
    vec2 p1_screen = p1_ndc * u_resolution * 0.5;

    vec2 dir = normalize(p1_screen - p0_screen);
    vec2 normal = vec2(-dir.y, dir.x);
    vec2 offset = normal * (LINE_WIDTH * 0.5);

    vec2 p0a_screen = p0_screen + offset;
    vec2 p0b_screen = p0_screen - offset;
    vec2 p1a_screen = p1_screen + offset;
    vec2 p1b_screen = p1_screen - offset;

    vec2 p0a_ndc = p0a_screen / (u_resolution * 0.5);
    vec2 p0b_ndc = p0b_screen / (u_resolution * 0.5);
    vec2 p1a_ndc = p1a_screen / (u_resolution * 0.5);
    vec2 p1b_ndc = p1b_screen / (u_resolution * 0.5);

    v_color = v_gd[0].color;
    v_width = LINE_WIDTH;

    v_dist = 0.5;
    v_depth = -p0_view.z;
    gl_Position = vec4(p0a_ndc * p0_clip.w, p0_clip.z, p0_clip.w);
    EmitVertex();

    v_dist = -0.5;
    v_depth = -p0_view.z;
    gl_Position = vec4(p0b_ndc * p0_clip.w, p0_clip.z, p0_clip.w);
    EmitVertex();

    v_dist = 0.5;
    v_depth = -p1_view.z;
    gl_Position = vec4(p1a_ndc * p1_clip.w, p1_clip.z, p1_clip.w);
    EmitVertex();

    v_dist = -0.5;
    v_depth = -p1_view.z;
    gl_Position = vec4(p1b_ndc * p1_clip.w, p1_clip.z, p1_clip.w);
    EmitVertex();
}
`

SHAPE_FS :: `#version 460 core
precision highp float;

#define AA_WIDTH 1.0

in vec3 v_color;
in float v_width;
in float v_dist;
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

    float dist = abs(v_dist) * v_width;
    float alpha = 1.0 - smoothstep(v_width * 0.5 - AA_WIDTH, v_width * 0.5, dist);

    if (alpha <= 0.0) {
        discard;
    }

    o_frag_color = vec4(v_color, alpha);
}
`

init_shape_rdr :: proc() {
    vertices: [dynamic]glm.vec3; defer delete(vertices)
    indices: [dynamic]u32; defer delete(indices)

    system.box_offset = geometry_lines_box(&vertices, &indices, {1, 1, 1})
    system.cylinder_offset = geometry_lines_cylinder(&vertices, &indices, {1, 1}, 16)
    system.cone_offset = geometry_lines_cone(&vertices, &indices, {1, 1}, 16)
    system.sphere_offset = geometry_lines_sphere(&vertices, &indices, 1, 16)

    // vao
    gl.GenVertexArrays(1, &system.shape_vao)
    gl.BindVertexArray(system.shape_vao)

    // vbo
    gl.GenBuffers(1, &system.shape_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.shape_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(glm.vec3) * len(vertices), &vertices[0], gl.DYNAMIC_DRAW)

    // attributes
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

    // ibo
    gl.GenBuffers(1, &system.shape_ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, system.shape_ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), &indices[0], gl.DYNAMIC_DRAW)

    // data
    system.box_data = make([dynamic]Debug_Shape, DEBUG_SHAPE_CAP, DEBUG_SHAPE_CAP)
    system.cylinder_data = make([dynamic]Debug_Shape, DEBUG_SHAPE_CAP, DEBUG_SHAPE_CAP)
    system.cone_data = make([dynamic]Debug_Shape, DEBUG_SHAPE_CAP, DEBUG_SHAPE_CAP)
    system.sphere_data = make([dynamic]Debug_Shape, DEBUG_SHAPE_CAP, DEBUG_SHAPE_CAP)

    // ubo
    gl.GenBuffers(1, &system.shape_ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.shape_ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Shape) * DEBUG_SHAPE_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Shape), offset)
    gl.VertexAttribDivisor(1, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Debug_Shape), offset)
    gl.VertexAttribDivisor(2, 1)
    offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 3, gl.FLOAT, false, size_of(Debug_Shape), offset)
    gl.VertexAttribDivisor(3, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Debug_Shape), offset)
    gl.VertexAttribDivisor(4, 1)

    // shaders
    make_shader(&system.shape_shader, load_shaders_source(SHAPE_VS, SHAPE_GS, SHAPE_FS))
}

free_shape_rdr :: proc() {
    delete(system.box_data)
    delete(system.cylinder_data)
    delete(system.cone_data)
    delete(system.sphere_data)
    gl.DeleteVertexArrays(1, &system.shape_vao)
    gl.DeleteBuffers(1, &system.shape_vbo)
    gl.DeleteBuffers(1, &system.shape_ibo)
    gl.DeleteBuffers(1, &system.shape_ubo)
    delete_shader(&system.shape_shader)
}

render_shape_rdr :: proc() {
    if system.shape_len == 0 {
        return
    }

    uniforms := &system.shape_shader.uniforms

    use_shader(&system.shape_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])

    gl.BindVertexArray(system.shape_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.shape_ubo)

    if system.box_len > 0 {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Shape) * DEBUG_SHAPE_CAP, &system.box_data[0])
        gl.DrawElementsInstanced(gl.LINES, system.box_offset.len, gl.UNSIGNED_INT, cast(rawptr) (system.box_offset.pos * size_of(u32)), system.box_len)
        system.box_len = 0
    }

    if system.cylinder_len > 0 {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Shape) * DEBUG_SHAPE_CAP, &system.cylinder_data[0])
        gl.DrawElementsInstanced(gl.LINES, system.cylinder_offset.len, gl.UNSIGNED_INT, cast(rawptr) (system.cylinder_offset.pos * size_of(u32)), system.cylinder_len)
        system.cylinder_len = 0
    }

    if system.cone_len > 0 {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Shape) * DEBUG_SHAPE_CAP, &system.cone_data[0])
        gl.DrawElementsInstanced(gl.LINES, system.cone_offset.len, gl.UNSIGNED_INT, cast(rawptr) (system.cone_offset.pos * size_of(u32)), system.cone_len)
        system.cone_len = 0
    }

    if system.sphere_len > 0 {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Shape) * DEBUG_SHAPE_CAP, &system.sphere_data[0])
        gl.DrawElementsInstanced(gl.LINES, system.sphere_offset.len, gl.UNSIGNED_INT, cast(rawptr) (system.sphere_offset.pos * size_of(u32)), system.sphere_len)
        system.sphere_len = 0
    }

    system.shape_len = 0
}
