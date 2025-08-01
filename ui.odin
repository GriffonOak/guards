package guards

import rl "vendor:raylib"

UI_Board_Element :: struct {
    hovered_cell: IVec2
}

UI_Card_Element :: struct {
    state: Card_State,
    card: ^Card,
    hovered: bool,
}

Button_Kind :: enum {
    CONFIRM,
    PRIMARY,
}

UI_Button_Element :: struct {
    kind: Button_Kind,
    text: cstring,
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
    },
    button_input_proc,
    draw_button,
}

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
    if !check_outside_or_deselected(input, element^) do return false

    #partial switch var in input {
    case Mouse_Pressed_Event:
        switch button_element.kind {
        case .CONFIRM:
            append(&event_queue, Confirm_Event{})
        case .PRIMARY:
        }
    }
    return false
}

draw_button: UI_Render_Proc : proc(element: UI_Element) {
    button_element, ok := element.variant.(UI_Button_Element)
    assert(ok)

    TEXT_PADDING :: 20

    rl.DrawRectangleRec(element.bounding_rect, rl.GREEN)
    rl.DrawText(
        button_element.text,
        i32(element.bounding_rect.x) + TEXT_PADDING,
        i32(element.bounding_rect.y) + TEXT_PADDING, 
        i32(element.bounding_rect.height) - 2 * TEXT_PADDING,
        rl.BLACK
    )
}