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

CONFIRM_BUTTON_SIZE :: Vec2{300, 100}

BUTTON_PADDING :: 10

cancel_button := UI_Element {
    {WIDTH - CONFIRM_BUTTON_SIZE.x - BUTTON_PADDING, HEIGHT - CARD_HOVER_POSITION_RECT.height - 2 * (CONFIRM_BUTTON_SIZE.y + BUTTON_PADDING), CONFIRM_BUTTON_SIZE.x, CONFIRM_BUTTON_SIZE.y},
    UI_Button_Element {
        Cancel_Event{},
        "Cancel",
        false
    },
    button_input_proc,
    draw_button,
}

confirm_button := UI_Element {
    {WIDTH - CONFIRM_BUTTON_SIZE.x - BUTTON_PADDING, HEIGHT - CARD_HOVER_POSITION_RECT.height - CONFIRM_BUTTON_SIZE.y - BUTTON_PADDING, CONFIRM_BUTTON_SIZE.x, CONFIRM_BUTTON_SIZE.y},
    UI_Button_Element{
        Confirm_Event{},
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
        #partial switch event in button_element.event {
        case Begin_Resolution_Event:
            if len(event.action_list) == 0 do break
            #partial switch action in event.action_list[0] {
            case Movement_Action, Fast_Travel_Action:
                player.hero.target_list = nil
            }
        }
        button_element.hovered = false
        return false
    }

    #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, button_element.event)
    }

    // It would be nice to have this be more general
    #partial switch event in button_element.event {
    case Begin_Resolution_Event:
        if len(event.action_list) == 0 do break
        #partial switch action in event.action_list[0] {
        case Choose_Target_Action:
            player.hero.target_list = arbitrary_targets
        case Movement_Action:
            player.hero.target_list = movement_targets
        case Fast_Travel_Action:
            player.hero.target_list = fast_travel_targets
        }
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

add_button :: proc(loc: rl.Rectangle, text: cstring, event: Event) {
    append(&ui_stack, UI_Element {
        loc, UI_Button_Element {
            event, text, false,
        },
        button_input_proc,
        draw_button,
    })
}