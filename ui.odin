package guards

import "core:fmt"
import rl "vendor:raylib"



UI_Board_Element :: struct {
    hovered_space: Target,
    texture: rl.RenderTexture2D,
}

UI_Card_Element :: struct {
    card_id: Card_ID,
    hovered: bool,  // @cleanup bit_set these??
    hidden: bool,
    selected: bool,
}

UI_Button_Element :: struct {
    event: Event,
    text: cstring,
    hovered: bool,
    global: bool,
}

// UI_Text_Input_Element :: struct {
//     text: strings.builder //?
// }

UI_Variant :: union {
    UI_Board_Element,
    UI_Card_Element,
    UI_Button_Element,
}

UI_Input_Proc :: #type proc(^Game_State, Input_Event, ^UI_Element) -> bool
UI_Render_Proc :: #type proc(^Game_State, UI_Element)

UI_Element :: struct {
    bounding_rect: rl.Rectangle,
    variant: UI_Variant,
    consume_input: UI_Input_Proc,
    render: UI_Render_Proc,
}

Side_Button_Manager :: struct {
    buttons: []UI_Element,
    first_button_index: int,
    button_location: rl.Rectangle,
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
    cstring,
    Formatted_String,
}



BUTTON_PADDING :: 10
TOOLTIP_FONT_SIZE :: 50

SELECTION_BUTTON_SIZE :: Vec2{400, 100}
FIRST_SIDE_BUTTON_LOCATION :: rl.Rectangle {
    BOARD_TEXTURE_SIZE.x + BUTTON_PADDING, 
    HEIGHT - BUTTON_PADDING - SELECTION_BUTTON_SIZE.y,
    SELECTION_BUTTON_SIZE.x,
    SELECTION_BUTTON_SIZE.y,
}

null_input_proc: UI_Input_Proc : proc(_: ^Game_State, _: Input_Event, _: ^UI_Element) -> bool { return false }
null_render_proc: UI_Render_Proc : proc(_: ^Game_State, _: UI_Element) {}

check_outside_or_deselected :: proc(input: Input_Event, element: UI_Element) -> bool {
    #partial switch var in input {
    case Mouse_Up_Event, Mouse_Down_Event, Mouse_Pressed_Event, Mouse_Motion_Event:
        if !rl.CheckCollisionPointRec(ui_state.mouse_pos, element.bounding_rect) {
            return false
        }
    case Input_Already_Consumed:
        return false
    }
    return true
}

button_input_proc: UI_Input_Proc : proc(gs: ^Game_State, input: Input_Event, element: ^UI_Element)-> bool {
    button_element := assert_variant(&element.variant, UI_Button_Element)
    if !check_outside_or_deselected(input, element^) {
        button_element.hovered = false
        return false
    }

    #partial switch var in input {
    case Mouse_Pressed_Event:
        if button_element.global {
            broadcast_game_event(gs, button_element.event)
        } else {
            append(&gs.event_queue, button_element.event)
        }
    }

    button_element.hovered = true
    return true
}

draw_button: UI_Render_Proc : proc(_: ^Game_State, element: UI_Element) {
    button_element := assert_variant_rdonly(element.variant, UI_Button_Element)

    TEXT_PADDING :: 20

    rl.DrawRectangleRec(element.bounding_rect, rl.GRAY)
    rl.DrawTextEx(
        default_font,
        button_element.text,
        {element.bounding_rect.x + TEXT_PADDING, element.bounding_rect.y + TEXT_PADDING}, 
        element.bounding_rect.height - 2 * TEXT_PADDING,
        FONT_SPACING,
        rl.BLACK,
    )
    if button_element.hovered {
        rl.DrawRectangleLinesEx(element.bounding_rect, TEXT_PADDING / 2, rl.WHITE)
    }
}

format_tooltip :: proc(gs: ^Game_State, tooltip: Tooltip) -> cstring {
    context.allocator = context.temp_allocator
    switch variant in tooltip {
    case cstring: return variant
    case Formatted_String:
        args: [dynamic]any  // spicy
        for arg in variant.arguments {
            switch arg_variant in arg {
            case Implicit_Quantity:
                append(&args, calculate_implicit_quantity(gs, arg_variant, NULL_CARD_ID))
            case Conditional_String_Argument:
                append(&args, arg_variant.arg1 if calculate_implicit_condition(gs, arg_variant.condition) else arg_variant.arg2)
            case any: append(&args, arg_variant)
            }
        }
        return fmt.ctprintf(variant.format, ..args[:])

    }
    return nil
}

render_tooltip :: proc(gs: ^Game_State) {
    if gs.tooltip == nil do return
    tooltip_text := format_tooltip(gs, gs.tooltip)
    dimensions := rl.MeasureTextEx(default_font, tooltip_text, TOOLTIP_FONT_SIZE, FONT_SPACING)
    top_width := WIDTH - BOARD_TEXTURE_SIZE.x
    offset := BOARD_TEXTURE_SIZE.x + (top_width - dimensions.x) / 2
    rl.DrawTextEx(default_font, tooltip_text, {offset, 0}, TOOLTIP_FONT_SIZE, FONT_SPACING, rl.WHITE)
}


add_generic_button :: proc(gs: ^Game_State, location: rl.Rectangle, text: cstring, event: Event, global: bool = false) {
    append(&gs.ui_stack, UI_Element {
        location, UI_Button_Element {
            event, text, false, global,
        },
        button_input_proc,
        draw_button,
    })
}

add_side_button :: proc(gs: ^Game_State, text: cstring, event: Event, global: bool = false) {
    if len(gs.side_button_manager.buttons) == 0 {
        gs.side_button_manager.first_button_index = len(gs.ui_stack)
    }

    add_generic_button(gs, gs.side_button_manager.button_location, text, event, global)
    gs.side_button_manager.buttons = gs.ui_stack[gs.side_button_manager.first_button_index:][:len(gs.side_button_manager.buttons) + 1]
    gs.side_button_manager.button_location.y -= SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

pop_side_button :: proc(gs: ^Game_State) {
    if len(gs.side_button_manager.buttons) == 0 do return
    pop(&gs.ui_stack)
    gs.side_button_manager.buttons = gs.ui_stack[gs.side_button_manager.first_button_index:][:len(gs.side_button_manager.buttons) - 1]
    gs.side_button_manager.button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

clear_side_buttons :: proc(gs: ^Game_State) {
    resize(&gs.ui_stack, len(gs.ui_stack) - len(gs.side_button_manager.buttons))
    gs.side_button_manager.buttons = {}
    gs.side_button_manager.button_location = FIRST_SIDE_BUTTON_LOCATION
}

add_game_ui_elements :: proc(gs: ^Game_State) {
    clear(&gs.ui_stack)
    gs.side_button_manager = Side_Button_Manager {
        buttons = {},
        first_button_index = 0,
        button_location = FIRST_SIDE_BUTTON_LOCATION,
    }

    board_render_texture := rl.LoadRenderTexture(i32(BOARD_TEXTURE_SIZE.x), i32(BOARD_TEXTURE_SIZE.y))

    append(&gs.ui_stack, UI_Element {
        BOARD_POSITION_RECT,
        UI_Board_Element{
            texture = board_render_texture,
        },
        board_input_proc,
        draw_board,
    })

    for player_id in 0..<len(gs.players) {
        player := get_player_by_id(gs, player_id)

        if player_id == gs.my_player_id {
            for card in player.hero.cards {
                append(&gs.ui_stack, UI_Element{
                    card_hand_position_rects[card.color],
                    UI_Card_Element{card_id = card.id},
                    card_input_proc,
                    draw_card,
                })
            }
        } else {
            for card in player.hero.cards {
                append(&gs.ui_stack, UI_Element {
                    {},
                    UI_Card_Element{card_id = card.id},
                    card_input_proc,
                    draw_card,
                })
            }
        }
    }
}