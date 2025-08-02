package guards

import rl "vendor:raylib"

import "core:fmt"
import "core:reflect"
import "core:strings"

Space_Clicked_Event :: struct {
    space: IVec2
}

Card_Clicked_Event :: struct {
    element: ^UI_Element
}

Confirm_Event :: struct {
    played_card: ^UI_Element
}

Begin_Choosing_Action_Event :: struct {}

Begin_Resolution_Event :: struct {}

Event :: union {
    Space_Clicked_Event,
    Card_Clicked_Event,
    Confirm_Event,
    Begin_Choosing_Action_Event,
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
            append(&event_queue, Begin_Choosing_Action_Event{})
        }

    case Begin_Choosing_Action_Event:
        player.stage = .CHOOSING_ACTION
        // Find the played card
        element, card_element := find_played_card()
        assert(element != nil && card_element != nil)

        // Make some buttons, yeah?
        SELECTION_BUTTON_SIZE :: Vec2{400, 100}

        card := card_element.card

        buttons_made := 0
        button_location := rl.Rectangle{WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, BUTTON_PADDING, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}

        if card.primary != .DEFENSE {
            add_button(button_location, "Primary", .PRIMARY)
            buttons_made += 1
            button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        }

        for value, kind in card.secondaries {
            if value == 0 || kind == .DEFENSE do continue
            name, ok := reflect.enum_name_from_value(kind); assert(ok)
            text := strings.clone_to_cstring(strings.to_pascal_case(name))
            add_button(button_location, text, buttons_for_secondaries[kind])
            buttons_made += 1
            button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        }

        if card.primary == .MOVEMENT || card.secondaries[.MOVEMENT] > 0 {
            add_button(button_location, "Fast travel", .SECONDARY_FAST_TRAVEL)
            buttons_made += 1
            button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        }

        if card.primary == .ATTACK || card.secondaries[.ATTACK] > 0 {
            add_button(button_location, "Clear", .SECONDARY_CLEAR)
            buttons_made += 1
            button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        }

        add_button(button_location, "Hold", .SECONDARY_HOLD)
        buttons_made += 1\
    
    case Begin_Resolution_Event:
        
    }
}