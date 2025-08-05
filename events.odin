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

Confirm_Event :: struct {}

Cancel_Event :: struct {}


Begin_Card_Selection_Event :: struct {}

Begin_Choosing_Action_Event :: struct {}

Begin_Resolution_Event :: struct {action_list: []Action_Temp}

Begin_Next_Action_Event :: struct {}

Resolve_Current_Action_Event :: struct {}

End_Resolution_Event :: struct {}

Resolutions_Completed_Event :: struct {}

Begin_Minion_Battle_Event :: struct {}

End_Minion_Battle_Event :: struct {}

Begin_Wave_Push_Event :: struct {}

End_Wave_Push_Event :: struct {}

Retrieve_Cards_Event :: struct {}

Begin_Upgrading_Event :: struct {}

End_Upgrading_Event :: struct {}


Event :: union {
    Space_Clicked_Event,
    Card_Clicked_Event,
    Confirm_Event,
    Cancel_Event,

    Begin_Card_Selection_Event,

    Begin_Choosing_Action_Event,

    Begin_Resolution_Event,
    Begin_Next_Action_Event,
    Resolve_Current_Action_Event,
    End_Resolution_Event,

    Resolutions_Completed_Event,
    Begin_Minion_Battle_Event,
    End_Minion_Battle_Event,

    Begin_Wave_Push_Event,
    End_Wave_Push_Event,

    Retrieve_Cards_Event,

    Begin_Upgrading_Event,
    End_Upgrading_Event,

}

event_queue: [dynamic]Event

resolve_event :: proc(event: Event) {

    fmt.println(event)
    switch var in event {

    case Space_Clicked_Event:
        fmt.println(var.space)
        #partial switch player.stage {
        case .RESOLVING:
            if !ui_stack[0].variant.(UI_Board_Element).space_in_target_list do break

            #partial switch action in get_current_action(&player.hero) {
            case Fast_Travel_Action:
                if len(player.hero.chosen_targets) == 0 {
                    append(&player.hero.chosen_targets, Target{loc = var.space})
                } else {
                    player.hero.chosen_targets[0] = Target{loc = var.space}
                }

                append(&event_queue, Resolve_Current_Action_Event{})
            case Movement_Action:

                if len(player.hero.chosen_targets) == player.hero.num_locked_targets do break
                last_target := player.hero.chosen_targets[len(player.hero.chosen_targets)-1].loc

                player.hero.num_locked_targets = len(player.hero.chosen_targets)
                make_movement_targets(action.distance - player.hero.num_locked_targets, last_target)
                player.hero.target_list = movement_targets
            }
        }

    case Card_Clicked_Event:
        element := var.element
        card_element := assert_variant(&element.variant, UI_Card_Element)

        if player.stage != .SELECTING do return
        #partial switch card_element.card.state {
        case .IN_HAND:
            other_element, other_card := find_played_card()
            if other_element != nil {
                other_element.bounding_rect = card_hand_position_rects[other_card.card.color]
                other_card.card.state = .IN_HAND
            } else {
                append(&ui_stack, confirm_button)
            }

            element.bounding_rect = CARD_PLAYED_POSITION_RECT
            card_element.card.state = .PLAYED
        case .PLAYED:
            element.bounding_rect = card_hand_position_rects[card_element.card.color]
            card_element.card.state = .IN_HAND
            pop(&ui_stack)
        }

    case Confirm_Event:
        #partial switch player.stage {
        case .SELECTING:
            player.stage = .CONFIRMED
            pop(&ui_stack) // Confirm button
            game_state.confirmed_players += 1
            if game_state.confirmed_players == game_state.num_players {
                game_state.stage = .RESOLUTION
                game_state.resolved_players = 0
    
                // @Todo figure out resolution order
                append(&event_queue, Begin_Choosing_Action_Event{})
            }
        case .RESOLVING:
            append(&event_queue, Resolve_Current_Action_Event{})
        }

    case Cancel_Event:
        #partial switch player.stage {
        case .RESOLVING:
            #partial switch action in get_current_action((&player.hero)) {
            case Movement_Action:
                player.hero.num_locked_targets = 0
                clear(&player.hero.chosen_targets)

                movement_val := action.distance
                make_movement_targets(movement_val, player.hero.location)
                player.hero.target_list = movement_targets
            }
        }
        
    case Begin_Card_Selection_Event:
        player.stage = .SELECTING
        game_state.stage = .SELECTION
        game_state.confirmed_players = 0

    case Begin_Choosing_Action_Event:
        player.stage = .CHOOSING_ACTION
        // Find the played card
        element, card_element := find_played_card()
        assert(element != nil && card_element != nil)

        // Make some buttons, yeah?
        SELECTION_BUTTON_SIZE :: Vec2{400, 100}

        card := card_element.card

        player.action_button_count = 0
        button_location := rl.Rectangle{WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, BUTTON_PADDING, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}

        if card.primary != .DEFENSE {
            if len(card.primary_effect) > 0 && len(make_targets(card.primary_effect[0])) > 0 {
                add_button(button_location, "Primary", Begin_Resolution_Event{card.primary_effect})
                player.action_button_count += 1
                button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
            }
        }

        movement_value := card.secondaries[.MOVEMENT]
        if movement_value > 0 {
            movement_action := &basic_movement_action[0].(Movement_Action)
            movement_action.distance = movement_value
            if len(make_targets(movement_action^)) > 0 {
                add_button(button_location, "Movement", Begin_Resolution_Event{basic_movement_action})
                player.action_button_count += 1
                button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
            }            
        }

        if card.primary == .MOVEMENT || card.secondaries[.MOVEMENT] > 0 {
            if len(make_targets(basic_fast_travel_action[0])) > 0 {
                add_button(button_location, "Fast travel", Begin_Resolution_Event{basic_fast_travel_action})
                player.action_button_count += 1
                button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
            }
        }

        if card.primary == .ATTACK || card.secondaries[.ATTACK] > 0 {
            if len(make_targets(basic_clear_action[0])) > 0 {
                add_button(button_location, "Clear", Begin_Resolution_Event{basic_clear_action})
                player.action_button_count += 1
                button_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
            }
        }

        add_button(button_location, "Hold", Begin_Resolution_Event{basic_hold_action})
        player.action_button_count += 1
    
    case Begin_Resolution_Event:
        player.stage = .RESOLVING
        player.hero.current_action_index = 0

        // Might not be the right time to do this
        clear(&player.hero.chosen_targets)


        for i in 0..<player.action_button_count {
            pop(&ui_stack)  // Purge action buttons
        }
        player.hero.action_list = var.action_list
        append(&event_queue, Begin_Next_Action_Event{})

    case Begin_Next_Action_Event:
        if player.hero.current_action_index >= len(player.hero.action_list) {
            append(&event_queue, End_Resolution_Event{})
            break
        }

        action := get_current_action(&player.hero)
        player.hero.target_list = make_targets(action^)
        #partial switch action in get_current_action(&player.hero) {
        case Movement_Action:
            append(&ui_stack, confirm_button)
            append(&ui_stack, cancel_button)
        }

    case End_Resolution_Event:
        assert(player.stage == .RESOLVING)
        player.stage = .RESOLVED
        game_state.resolved_players += 1
        player.hero.target_list = {}

        element, card_element := find_played_card()
        assert(element != nil && card_element != nil)
        card_element.card.state = .RESOLVED
        element.bounding_rect = FIRST_CARD_RESOLVED_POSITION_RECT
        element.bounding_rect.x += f32(game_state.turn_counter) * (FIRST_CARD_RESOLVED_POSITION_RECT.x + FIRST_CARD_RESOLVED_POSITION_RECT.width)

        if game_state.resolved_players == game_state.num_players {
            append(&event_queue, Resolutions_Completed_Event{})
        }
        
    case Resolutions_Completed_Event:
        // Check for end of turn effects and stuff here


        game_state.turn_counter += 1
        if game_state.turn_counter >= 4 {
            append(&event_queue, Begin_Minion_Battle_Event{})
        } else {
            append(&event_queue, Begin_Card_Selection_Event{})
        }

        // anyway

    case Begin_Minion_Battle_Event:
        // Let the team captain choose which minions to delete
        append(&event_queue, End_Minion_Battle_Event{})


    case End_Minion_Battle_Event:


        if false { // count up the minions here, see if one side has 0
            append(&event_queue, Begin_Wave_Push_Event{})
        } else {
            append(&event_queue, Retrieve_Cards_Event{})
        }

    case Begin_Wave_Push_Event:
        // pass
    case End_Wave_Push_Event:
        // pass

    case Retrieve_Cards_Event:
        // need to retrieve cards here :D
        retrieve_cards()
        append(&event_queue, Begin_Upgrading_Event{})

    case Begin_Upgrading_Event:
        append(&event_queue, End_Upgrading_Event{})

    case End_Upgrading_Event:
        game_state.turn_counter = 0
        append(&event_queue, Begin_Card_Selection_Event{})

    case Resolve_Current_Action_Event:
        #partial switch action in get_current_action(&player.hero) {
        case Fast_Travel_Action:
            translocate_unit(player.hero.location, player.hero.chosen_targets[0].loc)
        case Movement_Action:
            pop(&ui_stack)
            pop(&ui_stack)
            if len(player.hero.chosen_targets) == 0 do break
            for space in player.hero.chosen_targets[:len(player.hero.chosen_targets) - 1] {
                // Stuff that happens on move through goes here
                fmt.println(space)
            }
            translocate_unit(player.hero.location, player.hero.chosen_targets[len(player.hero.chosen_targets) - 1].loc)
            player.hero.num_locked_targets = 0
        }
        
        clear(&player.hero.chosen_targets)
        player.hero.current_action_index += 1
        append(&event_queue, Begin_Next_Action_Event{})

    }
}