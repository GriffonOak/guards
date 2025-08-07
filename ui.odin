package guards

import rl "vendor:raylib"



UI_Board_Element :: struct {
    hovered_space: IVec2,
}

UI_Card_Element :: struct {
    card: ^Card,
    hovered: bool,
}

UI_Button_Element :: struct {
    event: Event,
    text: cstring,
    hovered: bool,
}

UI_Variant :: union {
    UI_Board_Element,
    UI_Card_Element,
    UI_Button_Element,
}

UI_Input_Proc :: #type proc(Input_Event, ^UI_Element) -> bool
UI_Render_Proc :: #type proc(UI_Element)

UI_Element :: struct {
    bounding_rect: rl.Rectangle,
    variant: UI_Variant,
    consume_input: UI_Input_Proc,
    render: UI_Render_Proc,
}

Side_Button_Manager :: struct {
    buttons: []UI_Element,
    first_button_index: int,
    button_location: rl.Rectangle
}



BUTTON_PADDING :: 10

SELECTION_BUTTON_SIZE :: Vec2{400, 100}
FIRST_SIDE_BUTTON_LOCATION :: rl.Rectangle{WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, BUTTON_PADDING, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}



ui_stack: [dynamic]UI_Element

side_button_manager := Side_Button_Manager {
    buttons = {},
    first_button_index = 0,
    button_location = FIRST_SIDE_BUTTON_LOCATION
}



null_input_proc: UI_Input_Proc : proc(_: Input_Event, _: ^UI_Element) -> bool { return false }
null_render_proc: UI_Render_Proc : proc(_: UI_Element) {}

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

button_input_proc: UI_Input_Proc : proc(input: Input_Event, element: ^UI_Element)-> bool {
    button_element := assert_variant(&element.variant, UI_Button_Element)
    if !check_outside_or_deselected(input, element^) {
        button_element.hovered = false
        return false
    }

    #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, button_element.event)
    }

    button_element.hovered = true
    return true
}

draw_button: UI_Render_Proc : proc(element: UI_Element) {
    button_element, ok := element.variant.(UI_Button_Element)
    assert(ok)

    TEXT_PADDING :: 20

    rl.DrawRectangleRec(element.bounding_rect, rl.GRAY)
    rl.DrawTextEx(
        default_font,
        button_element.text,
        {element.bounding_rect.x + TEXT_PADDING, element.bounding_rect.y + TEXT_PADDING}, 
        element.bounding_rect.height - 2 * TEXT_PADDING,
        FONT_SPACING,
        rl.BLACK
    )
    if button_element.hovered {
        rl.DrawRectangleLinesEx(element.bounding_rect, TEXT_PADDING / 2, rl.WHITE)
    }
}

add_side_button :: proc(text: cstring, event: Event) {
    if len(side_button_manager.buttons) == 0 {
        side_button_manager.first_button_index = len(ui_stack)
    }
    append(&ui_stack, UI_Element {
        side_button_manager.button_location, UI_Button_Element {
            event, text, false,
        },
        button_input_proc,
        draw_button,
    })
    side_button_manager.buttons = ui_stack[side_button_manager.first_button_index:][:len(side_button_manager.buttons) + 1]
    side_button_manager.button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

pop_side_button :: proc() {
    if len(side_button_manager.buttons) == 0 do return
    pop(&ui_stack)
    side_button_manager.buttons = ui_stack[side_button_manager.first_button_index:][:len(side_button_manager.buttons) - 1]
    side_button_manager.button_location.y -= SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
}

clear_side_buttons :: proc() {
    resize(&ui_stack, len(ui_stack) - len(side_button_manager.buttons))
    side_button_manager.buttons = {}
    side_button_manager.button_location = FIRST_SIDE_BUTTON_LOCATION
}