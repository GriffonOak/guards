package guards

import "base:intrinsics"
import rl "vendor:raylib"

assert_variant :: proc(u: ^$U, $V: typeid) -> ^V where intrinsics.type_is_union(U) && intrinsics.type_is_variant_of(U, V) {
    out, ok := &u.(V)
    assert(ok)
    return out
}

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

find_played_card :: proc() -> (element: ^UI_Element, card_element: ^UI_Card_Element) {
    for &ui_element in ui_stack[1:][:5] {
        card_element = assert_variant(&ui_element.variant, UI_Card_Element)
        if card_element.card.state == .PLAYED {
            return &ui_element, card_element
        }
    }
    return nil, nil
}

retrieve_cards :: proc() {
    for &ui_element in ui_stack[1:][:5] {
        card_element := assert_variant(&ui_element.variant, UI_Card_Element)
        ui_element.bounding_rect = card_hand_position_rects[card_element.card.color]
        card_element.card.state = .IN_HAND
    }
}