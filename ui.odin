package guards

import "core:fmt"
import "core:strings"
import sa "core:container/small_array"

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

Side_Button_Manager :: struct {
    buttons: []UI_Element,
    first_button_index: int,
    button_location: Rectangle,
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



BUTTON_PADDING :: 10
TOOLTIP_FONT_SIZE :: 50

TOAST_TEXT_PADDING :: 10
TOAST_FONT_SIZE :: 40

FIRST_SIDE_BUTTON_LOCATION :: Rectangle {
    BOARD_TEXTURE_SIZE.x + BUTTON_PADDING, 
    HEIGHT - BUTTON_PADDING - SELECTION_BUTTON_SIZE.y,
    SELECTION_BUTTON_SIZE.x,
    SELECTION_BUTTON_SIZE.y,
}

null_input_proc: UI_Input_Proc : proc(_: ^Game_State, _: Input_Event, _: ^UI_Element) -> bool { return false }
null_render_proc: UI_Render_Proc : proc(_: ^Game_State, _: UI_Element) {}

button_input_proc: UI_Input_Proc : proc(gs: ^Game_State, input: Input_Event, element: ^UI_Element)-> bool {
    button_element := assert_variant(&element.variant, UI_Button_Element)

    #partial switch var in input {
    case Mouse_Pressed_Event:
        if button_element.global {
            broadcast_game_event(gs, button_element.event)
        } else {
            append(&gs.event_queue, button_element.event)
        }
        return true
    case Mouse_Motion_Event:
        return true
    }
    return false
}

draw_button: UI_Render_Proc : proc(_: ^Game_State, element: UI_Element) {
    button_element := assert_variant_rdonly(element.variant, UI_Button_Element)

when !ODIN_TEST {
    draw_rectangle_rec(element.bounding_rect, GRAY)
    draw_text_ex(
        default_font,
        button_element.text,
        {element.bounding_rect.x + BUTTON_TEXT_PADDING, element.bounding_rect.y + BUTTON_TEXT_PADDING}, 
        element.bounding_rect.height - 2 * BUTTON_TEXT_PADDING,
        FONT_SPACING,
        BLACK,
    )
    if .Hovered in element.flags {
        draw_rectangle_lines_ex(element.bounding_rect, BUTTON_TEXT_PADDING / 2, WHITE)
    }
}
}


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

// render_tooltip :: proc(gs: ^Game_State) {
//     if gs.tooltip == nil do return
//     tooltip_text := format_tooltip(gs, gs.tooltip)
//     dimensions := measure_text_ex(default_font, tooltip_text, TOOLTIP_FONT_SIZE, FONT_SPACING)
//     top_width := WIDTH - BOARD_TEXTURE_SIZE.x
//     offset := BOARD_TEXTURE_SIZE.x + (top_width - dimensions.x) / 2
//     draw_text_ex(default_font, tooltip_text, {offset, 0}, TOOLTIP_FONT_SIZE, FONT_SPACING, WHITE)
// }


add_generic_button :: proc(gs: ^Game_State, location: Rectangle, text: cstring, event: Event, global: bool = false) {
    append(&gs.ui_stack[.Buttons], UI_Element {
        location, UI_Button_Element {
            event, text, global,
        },
        button_input_proc,
        draw_button,
        {},
    })
}

add_side_button :: proc(gs: ^Game_State, text: cstring, event: Event, global: bool = false) {
    if len(gs.side_button_manager.buttons) == 0 {
        gs.side_button_manager.first_button_index = len(gs.ui_stack[.Buttons])
    }

    add_generic_button(gs, gs.side_button_manager.button_location, text, event, global)
    gs.side_button_manager.buttons = gs.ui_stack[.Buttons][gs.side_button_manager.first_button_index:][:len(gs.side_button_manager.buttons) + 1]
    gs.side_button_manager.button_location.y -= SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

pop_side_button :: proc(gs: ^Game_State) {
    if len(gs.side_button_manager.buttons) == 0 do return
    pop(&gs.ui_stack[.Buttons])
    gs.side_button_manager.buttons = gs.ui_stack[.Buttons][gs.side_button_manager.first_button_index:][:len(gs.side_button_manager.buttons) - 1]
    gs.side_button_manager.button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

clear_side_buttons :: proc(gs: ^Game_State) {
    resize(&gs.ui_stack[.Buttons], len(gs.ui_stack[.Buttons]) - len(gs.side_button_manager.buttons))
    gs.side_button_manager.buttons = {}
    gs.side_button_manager.button_location = FIRST_SIDE_BUTTON_LOCATION
}

add_game_ui_elements :: proc(gs: ^Game_State) {
    clear(&gs.ui_stack[.Buttons])
    gs.side_button_manager = Side_Button_Manager {
        buttons = {},
        first_button_index = 0,
        button_location = FIRST_SIDE_BUTTON_LOCATION,
    }

    board_render_texture: Render_Texture_2D
    when !ODIN_TEST {
        board_render_texture = load_render_texture(i32(BOARD_TEXTURE_SIZE.x), i32(BOARD_TEXTURE_SIZE.y))
    }

    append(&gs.ui_stack[.Board], UI_Element {
        BOARD_POSITION_RECT,
        UI_Board_Element{
            texture = board_render_texture,
        },
        board_input_proc,
        draw_board,
        {},
    })

    for player_id in 0..<len(gs.players) {
        player := get_player_by_id(gs, player_id)

        if player_id == gs.my_player_id {
            for card in player.hero.cards {
                append(&gs.ui_stack[.Cards], UI_Element{
                    card_hand_position_rects[card.color],
                    UI_Card_Element{card_id = card.id},
                    card_input_proc,
                    draw_card,
                    {},
                })
            }
        } else {
            for card in player.hero.cards {
                append(&gs.ui_stack[.Cards], UI_Element {
                    {},
                    UI_Card_Element{card_id = card.id},
                    card_input_proc,
                    draw_card,
                    {},
                })
            }
        }
    }
}

increase_window_size :: proc() {
    if window_size == .Small {
        window_size = .Big
        set_window_size(WIDTH, HEIGHT)
        window_scale = 1
    }
}

decrease_window_size :: proc() {
    if window_size == .Big {
        window_size = .Small
        set_window_size(WIDTH / 2, HEIGHT / 2)
        window_scale = 2
    }
}

toggle_fullscreen :: proc() {
    toggle_borderless_windowed()
    if window_size != .Fullscreen {
        window_size = .Fullscreen
        window_scale = WIDTH / f32(get_render_width())
    } else {
        window_size = .Small
        set_window_size(WIDTH / 2, HEIGHT / 2)
        window_scale = 2
    }
}

add_toast :: proc(gs: ^Game_State, text: string, duration: f64) {
    toast := Toast{duration = duration}
    new_string := string(text)
    copy(toast._text_buf[:], new_string[:])
    toast.start_time = get_time()
    append(&gs.toasts, toast)
}

draw_toast :: proc(toast: ^Toast) {
    t := (get_time() - toast.start_time) / toast.duration
    if t > 1 do return
    text := cstring(raw_data(toast._text_buf[:]))

    alpha := u8((1 - t) * 255)

    background_color := WHITE
    background_color.a = alpha
    text_color := BLACK
    text_color.a = alpha

    text_size := measure_text_ex(default_font, text, TOAST_FONT_SIZE, 0)
    rect_size := text_size + 2 * TOAST_TEXT_PADDING

    text_position := (Vec2{WIDTH, HEIGHT} - text_size) / 2
    text_position.y += 100 * f32(t)
    rect_position := text_position - TOAST_TEXT_PADDING

    draw_rectangle_v(rect_position, rect_size, background_color)
    draw_text_ex(default_font, text, text_position, TOAST_FONT_SIZE, 0, text_color)
}