package guards

// This is a good file. It knows exactly what it is trying to do and does it extremely well.

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

Begin_Resolution_Event :: struct {action_list: []Action}

Begin_Next_Action_Event :: struct {}

Resolve_Current_Action_Event :: struct {
    jump_index: Maybe(int)
}

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

    fmt.printfln("EVENT: %v", reflect.union_variant_typeid(event))
    switch var in event {

    case Space_Clicked_Event:
        #partial switch player.stage {
        case .RESOLVING:
            action := get_current_action(&player.hero)

            if ui_stack[0].variant.(UI_Board_Element).hovered_space not_in action.targets do break

            #partial switch &action_variant in action.variant {
            case Fast_Travel_Action:
                action_variant.result = var.space
                append(&event_queue, Resolve_Current_Action_Event{})

            case Movement_Action:
                if len(action_variant.path.spaces) == action_variant.path.num_locked_spaces do break

                action_variant.path.num_locked_spaces = len(action_variant.path.spaces)
                last_target := action_variant.path.spaces[len(action_variant.path.spaces)-1]
                
                target_valid: bool = true
                if action_variant.valid_destinations != nil {
                    context.allocator = context.temp_allocator
                    destination_set := calculate_implicit_target_set(action_variant.valid_destinations)
                    target_valid = var.space in destination_set
                }

                delete(action.targets)
                action.targets = make_movement_targets(
                    distance = Implicit_Quantity(calculate_implicit_quantity(action_variant.distance) - action_variant.path.num_locked_spaces),
                    origin = last_target,
                    valid_destinations = action_variant.valid_destinations,
                )

                assert(len(side_button_manager.buttons) > 0)
                top_button := side_button_manager.buttons[len(side_button_manager.buttons) - 1].variant.(UI_Button_Element)

                if _, ok := top_button.event.(Cancel_Event); ok && target_valid {
                    add_side_button("Confirm move", Resolve_Current_Action_Event{})
                } else if _, ok := top_button.event.(Resolve_Current_Action_Event); ok && !target_valid {
                    pop_side_button()
                }

            case Choose_Target_Action:
                action_variant.result = var.space
                append(&event_queue, Resolve_Current_Action_Event{})

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
                add_side_button("Confirm card", Confirm_Event{})
            }

            element.bounding_rect = CARD_PLAYED_POSITION_RECT
            card_element.card.state = .PLAYED
        case .PLAYED:
            element.bounding_rect = card_hand_position_rects[card_element.card.color]
            card_element.card.state = .IN_HAND
            clear_side_buttons()
        }

    case Confirm_Event:
        #partial switch player.stage {
        case .SELECTING:
            player.stage = .CONFIRMED
            clear_side_buttons()
            game_state.confirmed_players += 1
            if game_state.confirmed_players == game_state.num_players {
                game_state.stage = .RESOLUTION
                game_state.resolved_players = 0
    
                // @Todo figure out resolution order
                append(&event_queue, Begin_Choosing_Action_Event{})
            }
        case .RESOLVING:
            assert(false)
        }

    case Cancel_Event:
        #partial switch player.stage {
        case .RESOLVING:
            action := get_current_action(&player.hero)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                action_variant.path.num_locked_spaces = 0
                clear(&action_variant.path.spaces)

                movement_val := action_variant.distance
                delete(action.targets)
                action.targets = make_movement_targets(movement_val, action_variant.target, action_variant.valid_destinations)

                assert(len(side_button_manager.buttons) > 0)
                top_button := side_button_manager.buttons[len(side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Resolve_Current_Action_Event); ok && action_variant.valid_destinations != nil {
                    pop_side_button()
                }
            }
        }
        
    case Begin_Card_Selection_Event:
        player.stage = .SELECTING
        game_state.stage = .SELECTION
        game_state.confirmed_players = 0
        tooltip = "Choose a card to play and then confirm it."

    case Begin_Choosing_Action_Event:
        player.stage = .CHOOSING_ACTION
        // Find the played card
        element, card_element := find_played_card()
        assert(element != nil && card_element != nil)
        tooltip = "Choose an action to take with your played card."

        card := card_element.card

        primary: if card.primary != .DEFENSE {
            if len(card.primary_effect) == 0 do break primary
            populate_targets(card.primary_effect)
            if action_can_be_taken(card.primary_effect[0]) {
                add_side_button("Primary", Begin_Resolution_Event{card.primary_effect})
            }
        }

        movement_value := card.secondaries[.MOVEMENT]
        if movement_value > 0 {
            populate_targets(basic_movement_action)
            if action_can_be_taken(basic_movement_action[0]) {
                add_side_button("Movement", Begin_Resolution_Event{basic_movement_action})
            }            
        }

        if card.primary == .MOVEMENT || card.secondaries[.MOVEMENT] > 0 {
            populate_targets(basic_fast_travel_action)
            if action_can_be_taken(basic_fast_travel_action[0]) {
                add_side_button("Fast travel", Begin_Resolution_Event{basic_fast_travel_action})
            }
        }

        if card.primary == .ATTACK || card.secondaries[.ATTACK] > 0 {
            populate_targets(basic_clear_action)
            if action_can_be_taken(basic_clear_action[0]) {
                add_side_button("Clear", Begin_Resolution_Event{basic_clear_action})
            }
        }

        add_side_button("Hold", Begin_Resolution_Event{})
    
    case Begin_Resolution_Event:
        player.stage = .RESOLVING
        player.hero.current_action_index = 0

        clear_side_buttons()

        player.hero.action_list = var.action_list
        append(&event_queue, Begin_Next_Action_Event{})

    case Begin_Next_Action_Event:
        if player.hero.current_action_index >= len(player.hero.action_list) {
            append(&event_queue, End_Resolution_Event{})
            return
        }

        action := get_current_action(&player.hero)
        tooltip = action.tooltip
        fmt.printfln("ACTION: %v", reflect.union_variant_typeid(action.variant))
        if len(action.targets) == 0 {
            populate_targets(player.hero.action_list, index = player.hero.current_action_index)
        }

        if action.optional {
            add_side_button("Skip", Resolve_Current_Action_Event{action.skip_index})
        }

        #partial switch &action_type in action.variant {
        case Movement_Action:
            add_side_button("Reset move", Cancel_Event{})
            // This is technically wrong because a move of 0 could still be a valid destination
            if action_type.valid_destinations == nil {
                add_side_button("Confirm move", Resolve_Current_Action_Event{})
            }

        case Choose_Target_Action:
            if len(action.targets) == 0 {
                append(&event_queue, End_Resolution_Event{})
            } else if len(action.targets) == 1 && !action.optional {
                // Don't know a better way of extracting just the first element
                for space in action.targets {
                    action_type.result = space
                }
                append(&event_queue, Resolve_Current_Action_Event{})
            }

        case Choice_Action:
            choices_added: int
            most_recent_choice: int
            for choice in action_type.choices {
                child_action := &player.hero.action_list[choice.jump_index]
                populate_targets(player.hero.action_list, choice.jump_index)
                if action_can_be_taken(child_action^) {
                    add_side_button(choice.name, Resolve_Current_Action_Event{choice.jump_index})
                    choices_added += 1
                    most_recent_choice = choice.jump_index
                }
            }
            if choices_added == 0 {
                append(&event_queue, End_Resolution_Event{})
            } if choices_added == 1 {
                append(&event_queue, Resolve_Current_Action_Event{most_recent_choice})
            }

        case Halt_Action: 
            append(&event_queue, End_Resolution_Event{})
            return

        }

    case End_Resolution_Event:
        assert(player.stage == .RESOLVING)
        clear_side_buttons()
        player.stage = .RESOLVED
        game_state.resolved_players += 1

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
        clear_side_buttons()

        action := get_current_action(&player.hero)

        #partial switch &variant in action.variant {
        case Fast_Travel_Action:
            translocate_unit(player.hero.location, variant.result)
        case Movement_Action:
            if len(variant.path.spaces) == 0 do break
            defer {
                delete(variant.path.spaces)
                variant.path.spaces = nil
                variant.path.num_locked_spaces = 0
            }
            if _, ok := var.jump_index.?; ok do break  // Movement Skipped
            for space in variant.path.spaces {
                // Stuff that happens on move through goes here
                // fmt.println(space)
            }
            translocate_unit(calculate_implicit_target(variant.target), variant.path.spaces[len(variant.path.spaces) - 1])
        case Choice_Action:
            variant.result = var.jump_index.?
        }

        delete(action.targets)
        action.targets = nil
        
        tooltip = nil

        // Here would be where we need to handle minions outside the zone or wave pushes mid-turn

        if index, ok := var.jump_index.?; ok {
            player.hero.current_action_index = index
        } else {
            player.hero.current_action_index += 1
        }
        append(&event_queue, Begin_Next_Action_Event{})


    }
}