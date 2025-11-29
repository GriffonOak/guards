package guards

import "core:fmt"
import "core:strings"
import sa "core:container/small_array"
import clay "clay-odin"

_ :: strings

UI_Domain :: enum {
    None,
    Board,
    Cards,
    Buttons,
}

UI_Index :: struct {
    domain: UI_Domain,
    index: int,
}

UI_Board_Element :: struct {
    hovered_space: Target,
    texture: Render_Texture_2D,
}

UI_Card_Element :: struct {
    card_id: Card_ID,
    hidden: bool,
    selected: bool,
}

UI_Button_Element :: struct {
    event: Event,
    text: cstring,
    global: bool,
}

UI_Text_Box_Element :: struct {
    field: sa.Small_Array(40, u8),
    cursor_index: int,
    last_click_time: f64,
    default_string: string,
}

UI_Variant :: union {
    UI_Board_Element,
    UI_Card_Element,
    UI_Button_Element,
    UI_Text_Box_Element,
}

UI_Input_Proc :: #type proc(^Game_State, Input_Event, ^UI_Element) -> bool
UI_Render_Proc :: #type proc(^Game_State, UI_Element)

UI_Element_Flag :: enum {
    Hovered,
    Active,
}

UI_Element :: struct {
    bounding_rect: Rectangle,
    variant: UI_Variant,
    consume_input: UI_Input_Proc,
    render: UI_Render_Proc,
    flags: bit_set[UI_Element_Flag],
}

Button_Data :: struct {
    event: Event,
    text: string,
    global: bool,
    id: clay.ElementId,
}

Side_Button_Manager :: struct {
    button_data: [dynamic]Button_Data,
    // first_button_index: int,
    // button_location: Rectangle,
}

Conditional_String_Argument :: struct {
    condition: Implicit_Condition,
    arg1, arg2: string,  // This should be able to work with the `any` type, but for some reason it doesn't :(
}

Formatted_String_Argument :: union {
    Implicit_Quantity,
    Conditional_String_Argument,
    any,
}

Formatted_String :: struct {
    format: string,
    arguments: []Formatted_String_Argument,
}

Tooltip :: union {
    string,
    Formatted_String,
}

Toast :: struct {
    _text_buf: [50]u8,
    start_time, duration: f64,
}



// TOOLTIP_FONT_SIZE :: 50

TOAST_TEXT_PADDING :: 10
TOAST_FONT_SIZE :: 40

null_input_proc: UI_Input_Proc : proc(_: ^Game_State, _: Input_Event, _: ^UI_Element) -> bool { return false }
null_render_proc: UI_Render_Proc : proc(_: ^Game_State, _: UI_Element) {}


format_tooltip :: proc(gs: ^Game_State, tooltip: Tooltip) -> string {
    context.allocator = context.temp_allocator
    switch variant in tooltip {
    case string: return variant
    case Formatted_String:
        args: [dynamic]any  // spicy
        for arg in variant.arguments {
            switch arg_variant in arg {
            case Implicit_Quantity:
                append(&args, calculate_implicit_quantity(gs, arg_variant))
            case Conditional_String_Argument:
                append(&args, arg_variant.arg1 if calculate_implicit_condition(gs, arg_variant.condition) else arg_variant.arg2)
            case any: append(&args, arg_variant)
            }
        }
        return fmt.tprintf(variant.format, ..args[:])

    }
    return ""
}

add_side_button :: proc(gs: ^Game_State, text: string, event: Event, global: bool = false) {

    append(&gs.side_button_manager.button_data, Button_Data {
        event = event,
        text = text,
        global = global,
        id = clay.ID(text),
    })
}

pop_side_button :: proc(gs: ^Game_State) {
    if len(gs.side_button_manager.button_data) == 0 do return
    pop(&gs.side_button_manager.button_data)
}

clear_side_buttons :: proc(gs: ^Game_State) {
    clear(&gs.side_button_manager.button_data)
}

toggle_fullscreen :: proc() {
    toggle_borderless_windowed()
}

add_toast :: proc(gs: ^Game_State, text: string, duration: f64) {
    toast := Toast{duration = duration}
    new_string := string(text)
    copy(toast._text_buf[:], new_string[:])
    toast.start_time = get_time()
    append(&gs.toasts, toast)
}

draw_toast :: proc(toast: ^Toast) {
    // t := (get_time() - toast.start_time) / toast.duration
    // if t > 1 do return
    // // text := cstring(raw_data(toast._text_buf[:]))

    // alpha := u8((1 - t) * 255)

    // background_color := WHITE
    // background_color.a = alpha
    // text_color := BLACK
    // text_color.a = alpha

    // // text_size := measure_text_ex(default_font, text, TOAST_FONT_SIZE, 0)
    // // rect_size := text_size + 2 * TOAST_TEXT_PADDING

    // text_position := (Vec2{STARTING_WIDTH, STARTING_HEIGHT} - text_size) / 2
    // text_position.y += 100 * f32(t)
    // rect_position := text_position - TOAST_TEXT_PADDING

    // draw_rectangle_v(rect_position, rect_size, background_color)
    // draw_text_ex(default_font, text, text_position, TOAST_FONT_SIZE, 0, text_color)
}