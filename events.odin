package guards

import "core:fmt"

Game_Stage :: enum {
    SELECTION,
    RESOLUTION,
    UPGRADES,
}

Game_State :: struct {
    num_players: int,
    confirmed_players: int,
    stage: Game_Stage,
}

Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

current_player_stage: Player_Stage = .SELECTING

game_state: Game_State = {
    1, 0,
    .SELECTION,
}

Space_Clicked_Event :: struct {
    space: IVec2
}

Card_Clicked_Event :: struct {
    element: ^UI_Element
}

Confirm_Event :: struct {}

Begin_Resolution_Event :: struct {}

Event :: union {
    Space_Clicked_Event,
    Card_Clicked_Event,
    Confirm_Event,
    Begin_Resolution_Event,
}

event_queue: [dynamic]Event

resolve_event :: proc(event: Event) {
    switch var in event {

    case Space_Clicked_Event:
        fmt.println(var.space)

    case Card_Clicked_Event:
        element := var.element
        card_element := assert_variant(&element.variant, UI_Card_Element)

        if current_player_stage != .SELECTING do return
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

    case Confirm_Event:
        if current_player_stage == .SELECTING {
            current_player_stage = .CONFIRMED
            pop(&ui_stack)
        }

        game_state.confirmed_players += 1
        if game_state.confirmed_players == game_state.num_players {
            game_state.stage = .RESOLUTION

            // @Todo figure out resolution order
            append(&event_queue, Begin_Resolution_Event{})
        }

    case Begin_Resolution_Event:
        
    }
}