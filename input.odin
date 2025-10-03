package guards

// import "core:math"
import ba "core:container/bit_array"
// import "core:log"



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
    pressed_keys: ba.Bit_Array,
}



ui_state: UI_State

input_queue: [dynamic]Input_Event

check_for_input_events :: proc(q: ^[dynamic]Input_Event) {
    p := get_mouse_position() * window_scale
    // x := p.x
    // y := p.y

    for key := get_key_pressed(); key != .KEY_NULL; key = get_key_pressed() {
        ba.set(&ui_state.pressed_keys, cast(int) key)
        append(q, Key_Pressed_Event { key })
    }

    iterator := ba.make_iterator(&ui_state.pressed_keys)
    key_idx, ok := ba.iterate_by_set(&iterator)
    for ; ok ; key_idx, ok = ba.iterate_by_set(&iterator) {
        key := cast(Keyboard_Key) key_idx
        if !is_key_down(key) {
            ba.unset(&ui_state.pressed_keys, key_idx)
            // append(q, Key_Up_Event { key })
        } else if is_key_pressed_repeat(key) {
            append(q, Key_Pressed_Event { key })
        }
    }

    do_button_events :: proc(b: Mouse_Button, p: Vec2, q: ^[dynamic]Input_Event) {
        if is_mouse_button_pressed(b) {
            append(q, Mouse_Pressed_Event { p, b })
        }
        // if rl.IsMouseButtonDown(b) && b not_in ui_state.mouse_state {
        //     ui_state.mouse_state += {b}
        //     append(q, Mouse_Down_Event {p, b})
        // } else if rl.IsMouseButtonUp(b) && b in ui_state.mouse_state {
        //     ui_state.mouse_state -= {b}
        //     append(q, Mouse_Up_Event {p, b})
        // }
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