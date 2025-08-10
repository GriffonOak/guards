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
TOOLTIP_FONT_SIZE :: 50

SELECTION_BUTTON_SIZE :: Vec2{400, 100}
FIRST_SIDE_BUTTON_LOCATION :: rl.Rectangle{BOARD_TEXTURE_SIZE.x + BUTTON_PADDING, BUTTON_PADDING + TOOLTIP_FONT_SIZE, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}

tooltip: cstring

ui_stack: [dynamic]UI_Element

