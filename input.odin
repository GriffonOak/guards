package guards

// import "core:math"
import ba "core:container/bit_array"
// import "core:fmt"


Input_Event :: union {
    Mouse_Pressed_Event,
    Mouse_Motion_Event,
    // Mouse_Down_Event,
    // Mouse_Up_Event,
    // Mouse_Scroll_Event,
    // Key_Down_Event,
    // Key_Up_Event
    Key_Pressed_Event,
    // Input_Already_Consumed,
}

Input_Already_Consumed :: struct{}

Mouse_Pressed_Event :: struct {
    pos: Vec2,
    button: Mouse_Button,
}

Mouse_Motion_Event :: struct {
    pos: Vec2,
    delta: Vec2,
}

Mouse_Down_Event :: struct {
    pos: Vec2,
    button: Mouse_Button,
}

Mouse_Up_Event :: struct {
    pos: Vec2,
    button: Mouse_Button,
}

Mouse_Scroll_Event :: struct {
    pos: Vec2,
    scroll: Vec2,
}

Key_Down_Event :: struct {
    key: Keyboard_Key,
}

Key_Up_Event :: struct {
    key: Keyboard_Key,
}

Key_Pressed_Event :: struct {
    key: Keyboard_Key,
}

UI_State :: struct {
    mouse_pos: Vec2,
    mouse_state: bit_set[Mouse_Button],
    pressed_this_frame: bit_set[Mouse_Button],
    released_this_frame: bit_set[Mouse_Button],

    keyboard_state: ba.Bit_Array,
    keys_pressed_this_frame: ba.Bit_Array,
    keys_released_this_frame: ba.Bit_Array,

    char_pressed_this_frame: rune,
}



ui_state: UI_State

input_queue: [dynamic]Input_Event

check_for_input_events :: proc(q: ^[dynamic]Input_Event) {
    p := get_mouse_position() * window_scale
    // x := p.x
    // y := p.y

    ba.clear(&ui_state.keys_pressed_this_frame)
    ba.clear(&ui_state.keys_released_this_frame)
    for key := get_key_pressed(); key != .KEY_NULL; key = get_key_pressed() {
        key_int := int(key)
        ba.set(&ui_state.keyboard_state, key_int)
        ba.set(&ui_state.keys_pressed_this_frame, key_int)
        append(q, Key_Pressed_Event { key })
    }

    ui_state.char_pressed_this_frame = get_char_pressed()

    iterator := ba.make_iterator(&ui_state.keyboard_state)
    key_idx, ok := ba.iterate_by_set(&iterator)
    for ; ok ; key_idx, ok = ba.iterate_by_set(&iterator) {
        key := cast(Keyboard_Key) key_idx
        if !is_key_down(key) {
            ba.unset(&ui_state.keyboard_state, key_idx)
            ba.set(&ui_state.keys_released_this_frame, key_idx)
            // append(q, Key_Up_Event { key })
        } else if is_key_pressed_repeat(key) {
            append(q, Key_Pressed_Event { key })
            ba.set(&ui_state.keys_pressed_this_frame, key_idx)
        }
    }

    do_button_events :: proc(b: Mouse_Button, p: Vec2, q: ^[dynamic]Input_Event) {
        if is_mouse_button_pressed(b) {
            append(q, Mouse_Pressed_Event { p, b })
        }
        if is_mouse_button_down(b) && b not_in ui_state.mouse_state {
            ui_state.mouse_state += {b}
            ui_state.pressed_this_frame += {b}
            // append(q, Mouse_Down_Event {p, b})
        } else {
            ui_state.pressed_this_frame -= {b}
        } 
        if is_mouse_button_up(b) && b in ui_state.mouse_state {
            ui_state.mouse_state -= {b}
            ui_state.released_this_frame += {b}
            // append(q, Mouse_Up_Event {p, b})
        } else {
            ui_state.released_this_frame -= {b}
        }
    }
    do_button_events(.LEFT, p, q)
    do_button_events(.RIGHT, p, q)
    do_button_events(.MIDDLE, p, q)

    // scroll := rl.GetMouseWheelMoveV()
    // if scroll != {0, 0} {
    //     append(q, Mouse_Scroll_Event { p, scroll })
    // }

    if ui_state.mouse_pos != p {
        append(q, Mouse_Motion_Event {
            p, p - ui_state.mouse_pos,
        })
        ui_state.mouse_pos = p
        // find_mouse_region()
    }
}