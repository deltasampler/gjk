package imdd

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"

Uniforms :: map[string]i32

get_uniforms_from_program :: proc(program: u32) -> (uniforms: Uniforms) {
    uniform_count: i32
    gl.GetProgramiv(program, gl.ACTIVE_UNIFORMS, &uniform_count)

    if uniform_count > 0 {
        reserve(&uniforms, int(uniform_count))
    }

    for i in 0 ..< uniform_count {
        length: i32
        cname: [256]u8
        gl.GetActiveUniformName(program, u32(i), 256, &length, &cname[0])

        name := strings.clone(string(cname[:length]))
        location := gl.GetUniformLocation(program, cstring(&cname[0])) + 1

        uniforms[name] = location
    }

    return uniforms
}

delete_uniforms :: proc(u: Uniforms) {
    for k in u {
        delete(k)
    }

    delete(u)
}

load_shaders_source :: proc(vs_source, gs_source, fs_source: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
    vertex_shader_id := gl.compile_shader_from_source(vs_source, gl.Shader_Type.VERTEX_SHADER) or_return
    defer gl.DeleteShader(vertex_shader_id)

    geometry_shader_id := gl.compile_shader_from_source(gs_source, gl.Shader_Type.GEOMETRY_SHADER) or_return
    defer gl.DeleteShader(geometry_shader_id)

    fragment_shader_id := gl.compile_shader_from_source(fs_source, gl.Shader_Type.FRAGMENT_SHADER) or_return
    defer gl.DeleteShader(geometry_shader_id)

    return gl.create_and_link_program([]u32{vertex_shader_id, geometry_shader_id, fragment_shader_id}, binary_retrievable)
}

Shader :: struct {
    program: u32,
    ok: bool,
    uniforms: Uniforms,
}

make_shader :: proc(shader: ^Shader, program: u32, ok: bool) {
    if !ok {
        fmt.println(gl.get_last_error_message())

        return
    }

    shader.program = program
    shader.ok = ok
    shader.uniforms = get_uniforms_from_program(program)
}

delete_shader :: proc(shader: ^Shader) {
    gl.DeleteProgram(shader.program)
    delete_uniforms(shader.uniforms)
}

use_shader :: proc(shader: ^Shader) {
    gl.UseProgram(shader.program)
}
