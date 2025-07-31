package guards

import "core:fmt"

Player_State :: enum {
    SELECTING,
    CONFIRMED,
    RESOLVING,
    RESOLVED,

}

current_player_state: Player_State

Space_Clicked :: struct {
    space: IVec2
}

Card_Clicked :: struct {
    element: ^UI_Element
}

Event :: union {
    Space_Clicked,
    Card_Clicked,
}

event_queue: [dynamic]Event

resolve_event :: proc(event: Event) {
    switch var in event {
    case Space_Clicked:
        fmt.println(var.space)
    case Card_Clicked:
        element := var.element
        card_element := assert_variant(&element.variant, UI_Card_Element)
        #partial switch card_element.state {
        case .IN_HAND:
            // See if there is an already played card first
            // This is a bit hacky, consider having a separate struct to keep track of what cards are where
            need_to_add_button := true
            for &other_element in ui_stack {
                if other_card, ok := &other_element.variant.(UI_Card_Element); ok && other_card.state == .PLAYED {
                    other_element.bounding_rect = card_hand_position_rects[other_card.card.color]
                    other_card.state = .IN_HAND
                    need_to_add_button = false
                    break
                }
            }

            if need_to_add_button {
                append(&ui_stack, confirm_button)
            }

            element.bounding_rect = CARD_PLAYED_POSITION_RECT
            card_element.state = .PLAYED
        case .PLAYED:
            element.bounding_rect = card_hand_position_rects[card_element.card.color]
            card_element.state = .IN_HAND
            pop(&ui_stack)
        }
    }
}