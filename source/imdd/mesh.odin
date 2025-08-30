package imdd

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Mesh_Vertex :: struct {
    position: glm.vec3,
    normal: glm.vec3,
    color: i32,
}

Debug_Mesh_Triangle :: struct {
    a: u32,
    b: u32,
    c: u32,
}

Debug_Mesh :: struct {
    // cpu
    vertices: [dynamic]Debug_Mesh_Vertex,
    triangles: [dynamic]Debug_Mesh_Triangle,

    // gpu
    vao: u32,
    vbo: u32,
    ibo: u32,
}

debug_mesh :: proc(mesh: ^Debug_Mesh) {
    system.mesh_data[system.mesh_len] = mesh
    system.mesh_len = (system.mesh_len + 1) % DEBUG_MESH_CAP
}

debug_mesh_box2 :: proc(mesh: ^Debug_Mesh, position: glm.vec3, size: glm.vec3, color: i32) {
    index := u32(len(mesh.vertices))

    min := position - size / 2
    max := position + size / 2

    append(&mesh.vertices,
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {0, 0, 1}, color}
    )

    append(&mesh.triangles,
        Debug_Mesh_Triangle{index + 0, index + 1, index + 2},
        Debug_Mesh_Triangle{index + 0, index + 2, index + 3}
    )
}

debug_mesh_box3 :: proc(mesh: ^Debug_Mesh, position: glm.vec3, size: glm.vec3, color: i32) {
    index := u32(len(mesh.vertices))

    min := position - size / 2
    max := position + size / 2

    append(&mesh.vertices,
        // left
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {-1, 0, 0}, color},
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {-1, 0, 0}, color},
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {-1, 0, 0}, color},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {-1, 0, 0}, color},

        // right
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {1, 0, 0}, color},
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {1, 0, 0}, color},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {1, 0, 0}, color},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {1, 0, 0}, color},

        // bottom
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {0, -1, 0}, color},
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {0, -1, 0}, color},
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {0, -1, 0}, color},
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {0, -1, 0}, color},

        // top
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {0, 1, 0}, color},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {0, 1, 0}, color},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {0, 1, 0}, color},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {0, 1, 0}, color},

        // back
        Debug_Mesh_Vertex{{min.x, min.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{max.x, min.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{max.x, max.y, max.z}, {0, 0, 1}, color},
        Debug_Mesh_Vertex{{min.x, max.y, max.z}, {0, 0, 1}, color},

        // front
        Debug_Mesh_Vertex{{max.x, min.y, min.z}, {0, 0, -1}, color},
        Debug_Mesh_Vertex{{min.x, min.y, min.z}, {0, 0, -1}, color},
        Debug_Mesh_Vertex{{min.x, max.y, min.z}, {0, 0, -1}, color},
        Debug_Mesh_Vertex{{max.x, max.y, min.z}, {0, 0, -1}, color}

    )

    append(&mesh.triangles,
        Debug_Mesh_Triangle{index + 0, index + 1, index + 2},
        Debug_Mesh_Triangle{index + 0, index + 2, index + 3},
        Debug_Mesh_Triangle{index + 4, index + 5, index + 6},
        Debug_Mesh_Triangle{index + 4, index + 6, index + 7},
        Debug_Mesh_Triangle{index + 8, index + 9, index + 10},
        Debug_Mesh_Triangle{index + 8, index + 10, index + 11},
        Debug_Mesh_Triangle{index + 12, index + 13, index + 14},
        Debug_Mesh_Triangle{index + 12, index + 14, index + 15},
        Debug_Mesh_Triangle{index + 16, index + 17, index + 18},
        Debug_Mesh_Triangle{index + 16, index + 18, index + 19},
        Debug_Mesh_Triangle{index + 20, index + 21, index + 22},
        Debug_Mesh_Triangle{index + 20, index + 22, index + 23}
    )
}

// rendering
MESH_VS :: `#version 460 core

    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec3 i_normal;
    layout(location = 2) in int i_color;

    out vec3 v_normal;
    out vec3 v_color;
    out vec3 v_frag_pos;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        gl_Position = u_projection * u_view * vec4(i_position, 1.0);
        v_normal = i_normal;
        v_color = int_to_rgb(i_color);
        v_frag_pos = i_position;
    }
`

MESH_FS :: `#version 460 core
precision highp float;

in vec3 v_normal;
in vec3 v_color;
in vec3 v_frag_pos;

out vec4 o_frag_color;
out vec4 o_frag_normal;

uniform vec2 u_resolution;
uniform mat4 u_projection;
uniform mat4 u_view;
uniform vec3 u_camera_position;
uniform vec3 u_light_dir;
uniform vec3 u_light_color;
uniform float u_ambient_strength;
uniform float u_specular_strength;
uniform sampler2D sa_depth;

void main() {
    #ifdef USE_DEPTH
        vec2 rm_uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
        float rm_depth = texture(sa_depth, rm_uv).x;

        if (rm_depth < v_depth) {
            discard;
        }
    #endif

    vec3 view_dir = normalize(u_camera_position - v_frag_pos);
    vec3 reflect_dir = reflect(-u_light_dir, v_normal);

    // ambient
    vec3 ambient = u_light_color * u_ambient_strength;

    // diffuse
    float diffuse_factor = max(dot(v_normal, u_light_dir), 0.0);
    vec3 diffuse = u_light_color * diffuse_factor;

    // specular
    float specular_factor = pow(max(dot(view_dir, reflect_dir), 0.0), 32.0) * u_specular_strength;
    vec3 specular = u_light_color * specular_factor;

    // final
    vec3 final = (ambient + diffuse + specular) * v_color;
    vec3 result = pow(final, vec3(1.0 / 2.2));

    o_frag_color = vec4(result, 1.0);
    o_frag_normal = vec4(v_normal, 1.0);
}
`

MESH_CS :: `#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

layout(rgba32f, binding = 0) uniform image2D im_color;
layout(rgba32f, binding = 1) uniform image2D im_normal;
layout(r32f, binding = 2) uniform image2D im_depth;

uniform vec2 u_resolution;

const ivec2 offsets[] = ivec2[](
    ivec2(-1,  1), ivec2(0,  1), ivec2(1,  1),
    ivec2(-1,  0), ivec2(0,  0), ivec2(1,  0),
    ivec2(-1, -1), ivec2(0, -1), ivec2(1, -1)
);

const float weights[] = float[](
    1, 1, 1,
    1, 8, 1,
    1, 1, 1
);

void main() {
    ivec2 global_pos = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(im_color);

    vec4 color = imageLoad(im_color, global_pos);
    vec3 normal = imageLoad(im_normal, global_pos).rgb;

    float edge_sum = 0.0;
    float weight_sum = 0.0;

    for (int k = 0; k < 9; k++) {
        ivec2 sample_pos = clamp(global_pos + offsets[k] * 1, ivec2(0), size - ivec2(1));
        vec3 normal_sample = imageLoad(im_normal, sample_pos).rgb;

        float local_edge = length(normal_sample - normal);
        edge_sum += local_edge * weights[k];
        weight_sum += weights[k];
    }

    for (int k = 0; k < 9; k++) {
        ivec2 sample_pos = clamp(global_pos + offsets[k] * 2, ivec2(0), size - ivec2(1));
        vec3 normal_sample = imageLoad(im_normal, sample_pos).rgb;

        float local_edge = length(normal_sample - normal);
        edge_sum += local_edge * weights[k];
        weight_sum += weights[k];
    }

    float edge = clamp(edge_sum / weight_sum, 0.0, 1.0);
    vec3 edge_color = max(color.r, max(color.g, color.b)) < 0.5 ? vec3(1.0) : vec3(0.0);
    vec3 result = mix(color.rgb, edge_color, edge);

    imageStore(im_color, global_pos, vec4(result, color.a));
}
`

build_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    // vao
    gl.GenVertexArrays(1, &mesh.vao)
    gl.BindVertexArray(mesh.vao)

    // vbo
    gl.GenBuffers(1, &mesh.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Mesh_Vertex) * len(mesh.vertices), &mesh.vertices[0], gl.STATIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Debug_Mesh_Vertex), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Mesh_Vertex), offset)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribIPointer(2, 1, gl.INT, size_of(Debug_Mesh_Vertex), offset)

    // ibo
    gl.GenBuffers(1, &mesh.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(Debug_Mesh_Triangle) * len(mesh.triangles), &mesh.triangles[0], gl.DYNAMIC_DRAW)
}

reload_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    gl.BindVertexArray(mesh.vao)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Mesh_Vertex) * len(mesh.vertices), &mesh.vertices[0], gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(Debug_Mesh_Triangle) * len(mesh.triangles), &mesh.triangles[0], gl.DYNAMIC_DRAW)
}

destroy_debug_mesh :: proc(mesh: ^Debug_Mesh) {
    delete(mesh.vertices)
    delete(mesh.triangles)
    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ibo)
}

init_mesh_rdr :: proc() {
    // data
    system.mesh_data = make([dynamic]^Debug_Mesh, DEBUG_MESH_CAP, DEBUG_MESH_CAP)

    // shaders
    make_shader(&system.mesh_shader, gl.load_shaders_source(MESH_VS, MESH_FS))
    make_shader(&system.mesh_pp_shader, gl.load_compute_source(MESH_CS))
}

free_mesh_rdr :: proc() {
    delete_shader(&system.mesh_shader)
    delete_shader(&system.mesh_pp_shader)
}

render_mesh_rdr :: proc() {
    uniforms := &system.mesh_shader.uniforms

    gl.Enable(gl.CULL_FACE); defer gl.Disable(gl.CULL_FACE)

    use_shader(&system.mesh_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])
    gl.Uniform3fv(uniforms["u_camera_position"] - 1, 1, &system.camera_position[0])
    gl.Uniform3fv(uniforms["u_light_dir"] - 1, 1, &system.light_dir[0])
    gl.Uniform3fv(uniforms["u_light_color"] - 1, 1, &system.light_color[0])
    gl.Uniform1f(uniforms["u_ambient_strength"] - 1, system.ambient_strength)
    gl.Uniform1f(uniforms["u_specular_strength"] - 1, system.specular_strength)

    for i in 0 ..< system.mesh_len {
        mesh := system.mesh_data[i]

        gl.BindVertexArray(mesh.vao)
        gl.DrawElements(gl.TRIANGLES, cast(i32) len(mesh.triangles) * 3, gl.UNSIGNED_INT, nil)
    }

    system.mesh_len = 0

    // post process
    uniforms = &system.mesh_pp_shader.uniforms

    gl.BindImageTexture(0, system.framebuffer.color_tbo, 0, gl.FALSE, 0, gl.READ_WRITE, gl.RGBA32F);
    gl.BindImageTexture(1, system.framebuffer.normal_tbo, 0, gl.FALSE, 0, gl.READ_WRITE, gl.RGBA32F);
    gl.BindImageTexture(2, system.framebuffer.depth_tbo, 0, gl.FALSE, 0, gl.READ_WRITE, gl.RGBA32F);

    use_shader(&system.mesh_pp_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.DispatchCompute(cast(u32) glm.ceil(f32(system.framebuffer.width) / 8), cast(u32) glm.ceil(f32(system.framebuffer.height) / 8), 1)
}
