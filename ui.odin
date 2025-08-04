package guards

import rl "vendor:raylib"

UI_Board_Element :: struct {
    hovered_space: IVec2,
    space_in_target_list: bool,
}

UI_Card_Element :: struct {
    card: ^Card,
    hovered: bool,
}

Button_Kind :: enum {
    CONFIRM,
    PRIMARY,
    SECONDARY_MOVEMENT,
    SECONDARY_FAST_TRAVEL,
    SECONDARY_ATTACK,
    SECONDARY_CLEAR,
    SECONDARY_HOLD,
}

buttons_for_secondaries: [Action_Kind]Button_Kind = #partial {
    .MOVEMENT = .SECONDARY_MOVEMENT,
    .ATTACK   = .SECONDARY_ATTACK,
}

UI_Button_Element :: struct {
    kind: Button_Kind,
    text: cstring,
    hovered: bool,
}

UI_Variant :: union {
    UI_Board_Element,
    UI_Card_Element,
    UI_Button_Element,
}

CONFIRM_BUTTON_SIZE :: Vec2{300, 100}

BUTTON_PADDING :: 10

confirm_button := UI_Element {
    {WIDTH - CONFIRM_BUTTON_SIZE.x - BUTTON_PADDING, HEIGHT - CARD_HOVER_POSITION_RECT.height - CONFIRM_BUTTON_SIZE.y - BUTTON_PADDING, CONFIRM_BUTTON_SIZE.x, CONFIRM_BUTTON_SIZE.y},
    UI_Button_Element{
        .CONFIRM,
        "Confirm",
        false,
    },
    button_input_proc,
    draw_button,
}

// undo_button := UI

UI_Input_Proc :: #type proc(Input_Event, ^UI_Element) -> bool
UI_Render_Proc :: #type proc(UI_Element)

null_input_proc: UI_Input_Proc : proc(_: Input_Event, _: ^UI_Element) -> bool { return false }
null_render_proc: UI_Render_Proc : proc(_: UI_Element) {}


UI_Element :: struct {
    bounding_rect: rl.Rectangle,
    variant: UI_Variant,
    consume_input: UI_Input_Proc,
    render: UI_Render_Proc,
}

ui_stack: [dynamic]UI_Element

button_input_proc: UI_Input_Proc : proc(input: Input_Event, element: ^UI_Element)-> bool {
    button_element := assert_variant(&element.variant, UI_Button_Element)
    if !check_outside_or_deselected(input, element^) {
        #partial switch button_element.kind {
        case .SECONDARY_MOVEMENT, .SECONDARY_FAST_TRAVEL:
            player.target_list = nil
        }
        button_element.hovered = false
        return false
    }

    #partial switch var in input {
    case Mouse_Pressed_Event:
        switch button_element.kind {
        case .CONFIRM:
            append(&event_queue, Confirm_Event{})
        case .PRIMARY, .SECONDARY_ATTACK, .SECONDARY_CLEAR, .SECONDARY_HOLD:
            // player.resolution_list = hold_list
            // player.resolution_list.current_action = 0
            append(&event_queue, Begin_Resolution_Event{.HOLD})
        case .SECONDARY_MOVEMENT:
            append(&event_queue, Begin_Resolution_Event{.MOVEMENT})
        case .SECONDARY_FAST_TRAVEL:
            append(&event_queue, Begin_Resolution_Event{.FAST_TRAVEL})
        }
    }

    #partial switch button_element.kind {
    case .SECONDARY_MOVEMENT:
        player.target_list = movement_targets[:]
    case .SECONDARY_FAST_TRAVEL:
        player.target_list = fast_travel_targets[:]
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
        font_spacing,
        rl.BLACK
    )
    if button_element.hovered {
        rl.DrawRectangleLinesEx(element.bounding_rect, TEXT_PADDING / 2, rl.WHITE)
    }
}

add_button :: proc(loc: rl.Rectangle, text: cstring, kind: Button_Kind) {
    append(&ui_stack, UI_Element {
        loc,
        UI_Button_Element {
            kind,
            text,
            false,
        },
        button_input_proc,
        draw_button,
    })
}