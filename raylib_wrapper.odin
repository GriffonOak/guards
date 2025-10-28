package guards

import rl "vendor:raylib"
import "core:time"

Rectangle :: rl.Rectangle
Colour :: rl.Color
Trace_Log_Level :: rl.TraceLogLevel
Config_Flags :: rl.ConfigFlags
Render_Texture_2D :: rl.RenderTexture2D
Image :: rl.Image
Texture :: rl.Texture
Texture_Filter :: rl.TextureFilter
Font :: rl.Font
Mouse_Button :: rl.MouseButton
Keyboard_Key :: rl.KeyboardKey

MAGENTA :: rl.MAGENTA
PURPLE :: rl.PURPLE
LIGHTGRAY :: rl.LIGHTGRAY
GRAY :: rl.GRAY
DARKGRAY :: rl.DARKGRAY
WHITE :: rl.WHITE
RAYWHITE :: rl.RAYWHITE
BLACK :: rl.BLACK
VIOLET :: rl.VIOLET
GOLD :: rl.GOLD
RED :: rl.RED
LIME :: rl.LIME
BLUE :: rl.BLUE
DARKBLUE :: rl.DARKBLUE

get_time :: proc() -> f64 {
    program_duration := time.since(start_time)
    return time.duration_seconds(program_duration)
}

get_frame_time :: proc() -> f32 {
    when !ODIN_TEST {
        return rl.GetFrameTime()
    } else {
        return 0
    }
}

get_screen_width :: proc() -> i32 {
    when !ODIN_TEST {
        return rl.GetScreenWidth()
    } else {
        return 0
    }
}

get_screen_height :: proc() -> i32 {
    when !ODIN_TEST {
        return rl.GetScreenHeight()
    } else {
        return 0
    }
}
 
get_render_width :: proc() -> i32 {
    when !ODIN_TEST {
        return rl.GetRenderWidth()
    } else {
        return 0
    }
}

get_render_height :: proc() -> i32 {
    when !ODIN_TEST {
        return rl.GetRenderHeight()
    } else {
        return 0
    }
}

get_window_scale_dpi :: proc() -> Vec2 {
    when !ODIN_TEST {
        return rl.GetWindowScaleDPI()
    } else {
        return {}
    }
}
 
draw_ring :: proc(centre: Vec2, inner_radius, outer_radius, start_angle, end_angle: f32, segments: i32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRing(centre, inner_radius, outer_radius, start_angle, end_angle, segments, colour)
    }
}

draw_circle_v :: proc(centre: Vec2, radius: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawCircleV(centre, radius, colour)
    }
}

draw_poly_lines_ex :: proc(centre: Vec2, sides: i32, radius, rotation, line_thick: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawPolyLinesEx(centre, sides, radius, rotation, line_thick, colour)
    }
}

begin_texture_mode :: proc(render_texture: Render_Texture_2D) {
    when !ODIN_TEST {
        rl.BeginTextureMode(render_texture)
    }
}

end_texture_mode :: proc() {
    when !ODIN_TEST {
        rl.EndTextureMode()
    }
}

begin_scissor_mode :: proc(x, y, width, height: i32) {
    when !ODIN_TEST {
        rl.BeginScissorMode(x, y, width, height)
    }
}

end_scissor_mode :: proc() {
    when !ODIN_TEST {
        rl.EndScissorMode()
    }
}

clear_background :: proc(colour: Colour) {
    when !ODIN_TEST {
        rl.ClearBackground(colour)
    }
}

draw_poly :: proc(centre: Vec2, sides: i32, radius, rotation: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawPoly(centre, sides, radius, rotation, colour)
    }
}

draw_line_ex :: proc(start_pos, end_pos: Vec2, thick: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawLineEx(start_pos, end_pos, thick, colour)
    }
}

measure_text_ex :: proc(font: Font, text: cstring, font_size, spacing: f32) -> Vec2 {
    when !ODIN_TEST {
        return rl.MeasureTextEx(font, text, font_size, spacing)
    } else {
        return {}
    }
}

draw_text_ex :: proc(font: Font, text: cstring, position: Vec2, font_size, spacing: f32, tint: Colour) {
    when !ODIN_TEST {
        rl.DrawTextEx(font, text, position, font_size, spacing, tint)
    }
}

draw_texture_pro :: proc(texture: Texture, source, dest: Rectangle, origin: Vec2, rotation: f32, tint: Colour) {
    when !ODIN_TEST {
        rl.DrawTexturePro(texture, source, dest, origin, rotation, tint)
    }
}

load_render_texture :: proc(width, height: i32) -> Render_Texture_2D {
    when !ODIN_TEST {
        return rl.LoadRenderTexture(width, height)
    } else {
        return {}
    }
}

set_texture_filter :: proc(texture: Texture, filter: Texture_Filter) {
    when !ODIN_TEST {
        rl.SetTextureFilter(texture, filter)
    }
}

draw_rectangle :: proc(pos_x, pos_y, width, height: i32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangle(pos_x, pos_y, width, height, colour)
    }
}

draw_rectangle_v :: proc(position, size: Vec2, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangleV(position, size, colour)
    }
}

draw_rectangle_rec :: proc(rec: Rectangle, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangleRec(rec, colour)
    }
}

draw_rectangle_lines_ex :: proc(rec: Rectangle, line_thick: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangleLinesEx(rec, line_thick, colour)
    }
}

draw_rectangle_rounded :: proc(rec: Rectangle, roundness: f32, segments: i32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangleRounded(rec, roundness, segments, colour)
    }
}

draw_rectangle_rounded_lines_ex :: proc(rec: Rectangle, roundness: f32, segments: i32, line_thick: f32, colour: Colour) {
    when !ODIN_TEST {
        rl.DrawRectangleRoundedLinesEx(rec, roundness, segments, line_thick, colour)
    }
}

load_image_from_memory :: proc(file_type: cstring, file_data: rawptr, data_size: i32) -> Image {
    when !ODIN_TEST {
        return rl.LoadImageFromMemory(file_type, file_data, data_size)
    } else {
        return {}
    }
}

load_image_from_texture :: proc(texture: Texture) -> Image {
    when !ODIN_TEST {
        return rl.LoadImageFromTexture(texture)
    } else {
        return {}
    }
}

gen_image_colour :: proc(width, height: i32, colour: Colour) -> Image {
    when !ODIN_TEST {
        return rl.GenImageColor(width, height, colour)
    } else {
        return {}
    }
}

image_alpha_mask :: proc(image: ^Image, alpha_mask: Image) {
    when !ODIN_TEST {
        rl.ImageAlphaMask(image, alpha_mask)
    }
}

image_flip_vertical :: proc(image: ^Image) {
    when !ODIN_TEST {
        rl.ImageFlipVertical(image)
    }
}

load_texture_from_image :: proc(image: Image) -> Texture {
    when !ODIN_TEST {
        return rl.LoadTextureFromImage(image)
    } else {
        return {}
    }
}

set_trace_log_level :: proc(log_level: Trace_Log_Level) {
    when !ODIN_TEST {
        rl.SetTraceLogLevel(log_level)
    }
}

set_config_flags :: proc(flags: Config_Flags) {
    when !ODIN_TEST {
        rl.SetConfigFlags(flags)
    }
}

init_window :: proc(width, height: i32, title: cstring) {
    when !ODIN_TEST {
        rl.InitWindow(width, height, title)
    }
}

close_window :: proc() {
    when !ODIN_TEST {
        rl.CloseWindow()
    }
}

set_window_size :: proc(width, height: i32) {
    when !ODIN_TEST {
        rl.SetWindowSize(width, height)
    }
}

toggle_borderless_windowed :: proc() {
    when !ODIN_TEST {
        rl.ToggleBorderlessWindowed()
    }
}

begin_drawing :: proc() {
    when !ODIN_TEST {
        rl.BeginDrawing()
    }
}

end_drawing :: proc() {
    when !ODIN_TEST {
        rl.EndDrawing()
    }
}

load_font_from_memory :: proc(
    file_type: cstring,
    file_data: rawptr,
    data_size, font_size: i32,
    codepoints: [^]rune,
    codepoint_count: i32,
) -> Font {
    when !ODIN_TEST {
        return rl.LoadFontFromMemory(file_type, file_data, data_size, font_size, codepoints, codepoint_count)
    } else {
        return {}
    }
}

window_should_close :: proc() -> bool {
    when !ODIN_TEST {
        return rl.WindowShouldClose()
    } else {
        return false
    }
}

check_collision_point_rec :: proc(point: Vec2, rec: Rectangle) -> bool {
    when !ODIN_TEST {
        return rl.CheckCollisionPointRec(point, rec)
    } else {
        return false
    }
}

get_mouse_position :: proc() -> Vec2 {
    when !ODIN_TEST {
        return rl.GetMousePosition()
    } else {
        return {}
    }
}

get_mouse_wheel_move_v :: proc() -> Vec2 {
    when !ODIN_TEST {
        return rl.GetMouseWheelMoveV()
    } else {
        return {}
    }
}

get_key_pressed :: proc() -> Keyboard_Key {
    when !ODIN_TEST {
        return rl.GetKeyPressed()
    } else {
        return .KEY_NULL
    }
}

get_char_pressed :: proc() -> rune {
    when !ODIN_TEST {
        return rl.GetCharPressed()
    } else {
        return 0
    }
}

is_key_down :: proc(key: Keyboard_Key) -> bool {
    when !ODIN_TEST {
        return rl.IsKeyDown(key)
    } else {
        return false
    }
}

is_key_pressed :: proc(key: Keyboard_Key) -> bool {
    when !ODIN_TEST {
        return rl.IsKeyPressed(key)
    } else {
        return false
    }
}

is_key_pressed_repeat :: proc(key: Keyboard_Key) -> bool {
    when !ODIN_TEST {
        return rl.IsKeyPressedRepeat(key)
    } else {
        return false
    }
}

is_mouse_button_pressed :: proc(button: Mouse_Button) -> bool {
    when !ODIN_TEST {
        return rl.IsMouseButtonPressed(button)
    } else {
        return false
    }
}

is_mouse_button_down :: proc(button: Mouse_Button) -> bool {
    when !ODIN_TEST {
        return rl.IsMouseButtonDown(button)
    } else {
        return false
    }
}

is_mouse_button_up :: proc(button: Mouse_Button) -> bool {
    when !ODIN_TEST {
        return rl.IsMouseButtonUp(button)
    } else {
        return false
    }
}

get_clipboard_text :: proc() -> cstring {
    when !ODIN_TEST {
        return rl.GetClipboardText()
    } else {
        return ""
    }
}
