package guards

import "core:fmt"

Space_Clicked_Event :: struct {
    space: IVec2
}

Card_Clicked_Event :: struct {
    element: ^UI_Element
}

Confirm_Event :: struct {
    played_card: ^UI_Element
}

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

        if player.stage != .SELECTING do return
        #partial switch card_element.state {
        case .IN_HAND:
            // See if there is an already played card first
            // This is a bit hacky, consider having a separate struct to keep track of what cards are where

            other_element, other_card := find_played_card()
            if other_element != nil {
                other_element.bounding_rect = card_hand_position_rects[other_card.card.color]
                other_card.state = .IN_HAND
            } else {
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
        if player.stage == .SELECTING {
            player.stage = .CONFIRMED
            pop(&ui_stack)
        }

        game_state.confirmed_players += 1
        if game_state.confirmed_players == game_state.num_players {
            game_state.stage = .RESOLUTION

            // @Todo figure out resolution order
            append(&event_queue, Begin_Resolution_Event{})
        }

    case Begin_Resolution_Event:
        player.stage = .RESOLVING
        // Find the played card
        element, card_element := find_played_card()
        assert(element != nil && card_element != nil)

        // Make some buttons, yeah?
        SELECTION_BUTTON_SIZE :: Vec2{400, 100}

        card := card_element.card

        buttons_made: f32 = 0.0

        if card.primary != .DEFENSE {
            primary_button := UI_Element {
                {WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, BUTTON_PADDING, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y},
                UI_Button_Element{
                    .PRIMARY,
                    "Primary",
                },
                button_input_proc,
                draw_button,
            }
    
            append(&ui_stack, primary_button)
            buttons_made += 1
        }

        // for value, kind in card.secondaries {
        //     if value == 0 do continue
        //     append(&ui_stack, UI_Element{
        //         {WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, BUTTON_PADDING + buttons_made * (BUTTON_PADDING + SELECTION_BUTTON_SIZE.y), SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y},
        //         UI_Button_Element{
        //             .PRIMARY,

        //         }
        //     })
        // }

    }
}