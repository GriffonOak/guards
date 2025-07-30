package guards

import rl "vendor:raylib"

UI_Board_Element :: struct {
    hovered_cell: IVec2
}

Card_State :: enum {
    IN_HAND,
    PLAYED,
    RESOLVED,
    DISCARDED,
}

UI_Card_Element :: struct {
    state: Card_State,
    card: ^Card,
    hovered: bool,
}

UI_Variant :: union {
    UI_Board_Element,
    UI_Card_Element,
}

UI_Input_Proc :: #type proc(Input_Event, ^UI_Element) -> bool

null_input_proc: UI_Input_Proc : proc(_: Input_Event, _: ^UI_Element) -> bool { return false }

UI_Render_Proc :: #type proc(UI_Element)

UI_Element :: struct {
    bounding_rect: rl.Rectangle,
    variant: UI_Variant,
    consume_input: UI_Input_Proc,
    render: UI_Render_Proc,
}