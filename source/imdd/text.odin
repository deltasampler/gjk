package imdd

import "core:image/png"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Debug_Char :: struct {
    char: i32,
    position: glm.vec3,
    offset: glm.vec2,
    size: f32,
    color: i32,
}

debug_text :: proc(text: string, position: glm.vec3, size: f32, color: i32) {
    len := len(text)

    for i in 0 ..< len {
        char := &system.text_data[system.text_len]
        char.char = i32(text[i]) - 32
        char.position = position
        char.offset = {-f32(len) / 2 + 0.5 + f32(i), 0}
        char.size = size
        char.color = color
        system.text_len = (system.text_len + 1) % DEBUG_TEXT_CAP
    }
}

// rendering
TEXT_VS :: `#version 460 core

    layout(location = 0) in int i_char;
    layout(location = 1) in vec3 i_position;
    layout(location = 2) in vec2 i_offset;
    layout(location = 3) in float i_size;
    layout(location = 4) in int i_color;

    #define BITMAP_SIZE ivec2(10, 10)
    #define CHAR_RATIO vec2(0.5, 1.0)

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
        vec2(0.0, 1.0),
        vec2(1.0, 1.0),
        vec2(0.0, 0.0),
        vec2(1.0, 0.0)
    );

    vec3 int_to_rgb(int i) {
        return vec3(
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    vec2 calc_tex_coord(int index) {
        vec2 tile_size = vec2(1.0) / vec2(BITMAP_SIZE);
        float col = float(index % BITMAP_SIZE.x);
        float row = float(index / BITMAP_SIZE.y);

        return tex_coords[gl_VertexID] * tile_size + vec2(col, row) * tile_size;
    }

    void main() {
        vec2 local = positions[gl_VertexID] * 0.5 * CHAR_RATIO * i_size;
        local += i_offset * i_size * CHAR_RATIO;

        vec4 position = vec4(transpose(mat3(u_view)) * vec3(local, 0.0) + i_position, 1.0);

        gl_Position = u_projection * u_view * position;
        v_color = int_to_rgb(i_color);
        v_tex_coord = calc_tex_coord(i_char);
        v_depth = -(u_view * position).z;
    }
`

TEXT_FS :: `#version 460 core
precision highp float;

in vec3 v_color;
in vec2 v_tex_coord;
in float v_depth;

out vec4 o_frag_color;

uniform vec2 u_resolution;
uniform sampler2D sa_depth;
uniform sampler2D sa_bitmap;

void main() {
    #ifdef USE_DEPTH
        vec2 rm_uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution;
        float rm_depth = texture(sa_depth, rm_uv).x;

        if (rm_depth < v_depth) {
            discard;
        }
    #endif

    o_frag_color = texture(sa_bitmap, v_tex_coord) * vec4(v_color, 1.0);
}
`

init_text_rdr :: proc() {
    // data
    system.text_data = make([dynamic]Debug_Char, DEBUG_TEXT_CAP, DEBUG_TEXT_CAP)

    // vao
    gl.GenVertexArrays(1, &system.text_vao)
    gl.BindVertexArray(system.text_vao)

    // vbo
    gl.GenBuffers(1, &system.text_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.text_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(Debug_Char) * DEBUG_TEXT_CAP, nil, gl.DYNAMIC_DRAW)

    // attributes
    offset: uintptr = 0

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribIPointer(0, 1, gl.INT, size_of(Debug_Char), offset)
    gl.VertexAttribDivisor(0, 1)
    offset += size_of(i32)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Debug_Char), offset)
    gl.VertexAttribDivisor(1, 1)
    offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(Debug_Char), offset)
    gl.VertexAttribDivisor(2, 1)
    offset += size_of(glm.vec2)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 1, gl.FLOAT, false, size_of(Debug_Char), offset)
    gl.VertexAttribDivisor(3, 1)
    offset += size_of(f32)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Debug_Char), offset)
    gl.VertexAttribDivisor(4, 1)

    // font bitmap
    data := #load("assets/font.png");
    image, _ := png.load_from_bytes(data); defer png.destroy(image)

    gl.BindTexture(gl.TEXTURE_2D, system.text_tbo)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(image.width), i32(image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, &image.pixels.buf[0])
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    // shaders
    make_shader(&system.text_shader, gl.load_shaders_source(TEXT_VS, TEXT_FS))
}

free_text_rdr :: proc() {
    delete(system.text_data)
    gl.DeleteVertexArrays(1, &system.text_vao)
    gl.DeleteBuffers(1, &system.text_vbo)
    gl.DeleteTextures(1, &system.text_tbo)
    delete_shader(&system.text_shader)
}

render_text_rdr :: proc() {
    if system.text_len == 0 {
        return
    }

    uniforms := &system.text_shader.uniforms

    use_shader(&system.text_shader)
    gl.Uniform2f(uniforms["u_resolution"] - 1, f32(system.width), f32(system.height))
    gl.UniformMatrix4fv(uniforms["u_projection"] - 1, 1, false, &system.projection[0][0])
    gl.UniformMatrix4fv(uniforms["u_view"] - 1, 1, false, &system.view[0][0])

    gl.BindVertexArray(system.text_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, system.text_vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Debug_Char) * DEBUG_TEXT_CAP, &system.text_data[0])

    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, system.text_tbo)

    gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, system.text_len)

    system.text_len = 0
}
