package main

import "core:math/rand"
import "core:fmt"
import glm "core:math/linalg/glsl"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"
import "imdd"

WINDOW_TITLE :: "GJK"
WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6

OUTPUT_VS :: `#version 460 core
    out vec2 v_tex_coord;

    const vec2 positions[] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );

    const vec2 tex_coords[] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );

    void main() {
        gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
        v_tex_coord = tex_coords[gl_VertexID];
    }
`

OUTPUT_FS :: `#version 460 core
    precision highp float;

    in vec2 v_tex_coord;

    out vec4 o_frag_color;

    uniform sampler2D sa_texture;

    void main() {
        o_frag_color = texture(sa_texture, v_tex_coord);
    }
`

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.printf("SDL ERROR: %s\n", sdl.GetError())

        return
    }

    defer sdl.Quit()

    window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL, .RESIZABLE})
    defer sdl.DestroyWindow(window)

    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfile.CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    gl_context := sdl.GL_CreateContext(window)
    defer sdl.GL_DestroyContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

    sdl.SetWindowPosition(window, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED)
    _ = sdl.SetWindowRelativeMouseMode(window, true)

    viewport_x, viewport_y: i32; sdl.GetWindowSize(window, &viewport_x, &viewport_y)
    key_state := sdl.GetKeyboardState(nil)
    time: u64 = sdl.GetTicks()
    time_delta : f32 = 0
    time_last := time

    orthographic_camera: Camera; init_orthographic_camera(&orthographic_camera)
    perspective_camera: Camera; init_perspective_camera(&perspective_camera)
    camera := &perspective_camera
    movement_speed: f32 = 256
    yaw_speed: f32 = 0.002
    pitch_speed: f32 = 0.002
    zoom_speed: f32 = 0.2

    output_shader: imdd.Shader
    imdd.make_shader(&output_shader, gl.load_shaders_source(OUTPUT_VS, OUTPUT_FS))

    imdd.debug_init(WINDOW_WIDTH, WINDOW_HEIGHT); defer imdd.debug_free()

    hull: Hull; defer hull_delete(hull)
    hull_gen_cube(&hull, {}, {64, 64, 64})
    hull_rotate_z(&hull, glm.radians_f32(30))

    debug_mesh: imdd.Debug_Mesh;

    for &face in hull.faces {
        index := len(debug_mesh.vertices)
        r := rand.float32() * 255; g := rand.float32() * 255; b := rand.float32() * 255

        for index in face.indices {
            vertex := hull.vertices[index]

            append(&debug_mesh.vertices, imdd.Debug_Mesh_Vertex{vertex, face.normal, imdd.rgb_f32(r, g, b)})
        }

        for i := 0; i < len(face.indices) - 2; i += 1 {
            append(&debug_mesh.triangles, imdd.Debug_Mesh_Triangle{u32(index), u32(index + i + 1), u32(index + i + 2)})
        }
    }

    imdd.build_debug_mesh(&debug_mesh); defer imdd.destroy_debug_mesh(&debug_mesh)

    loop: for {
        time = sdl.GetTicks()
        time_delta = f32(time - time_last) / 1000
        time_last = time

        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    break loop
                case .WINDOW_RESIZED:
                    sdl.GetWindowSize(window, &viewport_x, &viewport_y)

                    imdd.debug_resize(viewport_x, viewport_y)
                case .KEY_DOWN:
                    if event.key.scancode == sdl.Scancode.ESCAPE {
                        _ = sdl.SetWindowRelativeMouseMode(window, !sdl.GetWindowRelativeMouseMode(window))
                    }
                case .MOUSE_MOTION:
                    if sdl.GetWindowRelativeMouseMode(window) {
                        if camera.mode == .PERSPECTIVE {
                            rotate_camera(camera, event.motion.xrel * yaw_speed, event.motion.yrel * pitch_speed, 0)
                        }
                    }
            }
        }

        if (sdl.GetWindowRelativeMouseMode(window)) {
            speed := time_delta * movement_speed

            if key_state[sdl.Scancode.A] {
                move_camera(camera, {-speed, 0, 0})
            }

            if key_state[sdl.Scancode.D] {
                move_camera(camera, {speed, 0, 0})
            }

            if key_state[sdl.Scancode.S] {
                if camera.mode == .PERSPECTIVE {
                    move_camera(camera, {0, 0, -speed})
                } else {
                    move_camera(camera, {0, -speed, 0})
                }
            }

            if key_state[sdl.Scancode.W] {
                if camera.mode == .PERSPECTIVE {
                    move_camera(camera, {0, 0, speed})
                } else {
                    move_camera(camera, {0, speed, 0})
                }
            }

            if key_state[sdl.Scancode.Q] {
                zoom_camera(camera, time_delta * zoom_speed)
            }

            if key_state[sdl.Scancode.E] {
                zoom_camera(camera, -time_delta * zoom_speed)
            }
        }

        compute_camera_projection(camera, f32(viewport_x), f32(viewport_y))
        compute_camera_view(camera)

        imdd.debug_grid_xz({0, 0, 0}, {16384, 16384}, {32, 32}, 1, 0xffffff)

        imdd.debug_arrow({0, 0, 0}, {64, 0, 0}, 4, 0xff0000)
        imdd.debug_arrow({0, 0, 0}, {0, 64, 0}, 4, 0x00ff00)

        position := camera.position + camera.forward * 64
        radius: f32 = 8
        test := gjk(hull, position, radius, {1, 0, 0})

        if test {
            imdd.debug_sphere(position, radius, 0xff0000)
        } else {
            imdd.debug_sphere(position, radius, 0xaaaaaa)
        }

        imdd.debug_mesh(&debug_mesh)

        imdd.debug_prepare(
            i32(camera.mode),
            camera.position,
            camera.forward,
            camera.projection,
            camera.view
        )
        imdd.debug_render()

        gl.Viewport(0, 0, viewport_x, viewport_y)
        gl.ClearColor(0, 0, 0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, imdd.debug_get_framebuffer().color_tbo)

        imdd.use_shader(&output_shader)
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)

        sdl.GL_SwapWindow(window)
    }
}
