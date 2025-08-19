package guards

// This is a good file. It knows exactly what it is trying to do and does it extremely well.

import rl "vendor:raylib"

import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:log"


Increase_Window_Size_Event :: struct {}  
Decrease_Window_Size_Event :: struct {}  
Toggle_Fullscreen_Event :: struct {}

Join_Game_Chosen_Event :: struct {}
Host_Game_Chosen_Event :: struct {}

Enter_Lobby_Event :: struct {}
Begin_Game_Event :: struct {}

Space_Clicked_Event :: struct {
    space: IVec2
}

Card_Clicked_Event :: struct {
    card_id: Card_ID
}

Confirm_Event :: struct {}
Cancel_Event :: struct {}

Begin_Card_Selection_Event :: struct {}
Begin_Resolution_Event :: struct {}
Begin_Next_Action_Event :: struct {}
Resolve_Current_Action_Event :: struct {
    jump_index: Maybe(Action_Index)
}
End_Resolution_Event :: struct {}
Resolutions_Completed_Event :: struct {}

Begin_Minion_Battle_Event :: struct {}
Begin_Minion_Removal_Event :: struct {
    team: Team
}
End_Minion_Battle_Event :: struct {}
Begin_Wave_Push_Event :: struct {
    pushing_team: Team
}

End_Wave_Push_Event :: struct {}
Retrieve_Cards_Event :: struct {}


Begin_Upgrading_Event :: struct {}
Begin_Next_Upgrade_Event :: struct {}
End_Upgrading_Event :: struct {}

Game_Over_Event :: struct {
    winning_team: Team
}



Event :: union {

    Increase_Window_Size_Event,
    Decrease_Window_Size_Event,
    Toggle_Fullscreen_Event,

    Join_Game_Chosen_Event,
    Host_Game_Chosen_Event,

    Enter_Lobby_Event,
    Begin_Game_Event,

    Space_Clicked_Event,
    Card_Clicked_Event,
    Confirm_Event,
    Cancel_Event,

    Begin_Card_Selection_Event,

    Begin_Resolution_Event,
    Begin_Next_Action_Event,
    Resolve_Current_Action_Event,
    End_Resolution_Event,

    Resolutions_Completed_Event,

    Begin_Minion_Battle_Event,
    Begin_Minion_Removal_Event,
    
    Begin_Wave_Push_Event,
    End_Wave_Push_Event,
    
    End_Minion_Battle_Event,
    
    Retrieve_Cards_Event,

    Begin_Upgrading_Event,
    Begin_Next_Upgrade_Event,
    End_Upgrading_Event,

    Game_Over_Event,
}



event_queue: [dynamic]Event



resolve_event :: proc(event: Event) {

    log.infof("EVENT: %v", reflect.union_variant_typeid(event))
    switch var in event {

    case Increase_Window_Size_Event:
        if window_size == .SMALL {
            window_size = .BIG
            rl.SetWindowSize(WIDTH, HEIGHT)
            window_scale = 1
        }

    case Decrease_Window_Size_Event:
        if window_size == .BIG {
            window_size = .SMALL
            rl.SetWindowSize(WIDTH / 2, HEIGHT / 2)
            window_scale = 2
        }
    
    case Toggle_Fullscreen_Event:
        rl.ToggleBorderlessWindowed()
        if window_size != .FULL_SCREEN {
            window_size = .FULL_SCREEN
            window_scale = WIDTH / f32(rl.GetRenderWidth())
        } else {
            window_size = .SMALL
            rl.SetWindowSize(WIDTH / 2, HEIGHT / 2)
            window_scale = 2
        }


    case Join_Game_Chosen_Event:
        if join_local_game() {
            append(&event_queue, Enter_Lobby_Event{})
        }

    case Host_Game_Chosen_Event:
        if begin_hosting_local_game() {
            append(&event_queue, Enter_Lobby_Event{})
        }


    case Enter_Lobby_Event:
        game_state.stage = .IN_LOBBY
        clear(&ui_stack)
        if is_host {
            tooltip = "Wait for players to join, then begin the game."
            button_loc := (Vec2{WIDTH, HEIGHT} - SELECTION_BUTTON_SIZE) / 2
            add_generic_button({button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, "Begin Game", Begin_Game_Event{})
        } else {
            tooltip = "Wait for the host to begin the game."
        }

    case Begin_Game_Event:
        if is_host {
            broadcast_network_event(Event(Begin_Game_Event{}))
        }
        begin_game()
        add_game_ui_elements()

    case Space_Clicked_Event:
        #partial switch get_my_player().stage {
        case .RESOLVING, .INTERRUPTING:
            action := get_current_action()

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

                log.assert(len(side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := side_button_manager.buttons[len(side_button_manager.buttons) - 1].variant.(UI_Button_Element)

                if _, ok := top_button.event.(Cancel_Event); ok && target_valid {
                    add_side_button("Confirm move", Resolve_Current_Action_Event{})
                } else if _, ok := top_button.event.(Resolve_Current_Action_Event); ok && !target_valid {
                    pop_side_button()
                }

            case Choose_Target_Action:
                append(&action_variant.result, var.space)
                delete_key(&action.targets, var.space)
                if len(action_variant.result) == calculate_implicit_quantity(action_variant.num_targets) {
                    append(&event_queue, Resolve_Current_Action_Event{})
                } else if len(side_button_manager.buttons) == 0 {
                    add_side_button("Cancel", Cancel_Event{})
                }

            }
        }

    case Card_Clicked_Event:
        card_id := var.card_id
        card, ok := get_card_by_id(card_id)
        log.assert(ok, "Card element clicked with no card associated!")

        #partial switch get_my_player().stage {
        case .SELECTING:
            #partial switch card.state {
            case .IN_HAND:
                played_card, ok := find_played_card()
                if ok {
                    retrieve_card(played_card)
                } else {
                    add_side_button("Confirm card", Confirm_Event{})
                }

                play_card(card)

            case .PLAYED:
                clear_side_buttons()

                retrieve_card(card)
            }

        case .UPGRADING:
            #partial switch card.state {
            case .IN_HAND:
                if card.tier == 0 do break
                // Ensure clicked card is able to be upgraded
                lowest_tier: int = 1e6
                for other_card in get_my_player().hero.cards {
                    if other_card.tier == 0 do continue
                    lowest_tier = min(lowest_tier, other_card.tier)
                }
                if card.tier > lowest_tier || lowest_tier == 3 do break  // @cleanup This is not really correct, upgrade should not be possible if lowest tier is 3

                // I shouldn't really be checking this through the ui stack like this tbh
                // But I don't have a better way of seeing if an upgrade is happening. // @Cleanup?
                top_element := ui_stack[len(ui_stack) - 1]
                card_element, ok := top_element.variant.(UI_Card_Element)
                if ok {
                    card, ok2 := get_card_by_id(card_element.card_id)
                    if card.state == .NONEXISTENT do break
                }

                // Display possible upgrades for clicked card
                card_element_width := (SELECTION_BUTTON_SIZE.x - BUTTON_PADDING) / 2
                card_element_height := card_element_width * 3.5 / 2.5

                card_position_rect := rl.Rectangle {
                    FIRST_SIDE_BUTTON_LOCATION.x,
                    FIRST_SIDE_BUTTON_LOCATION.y - BUTTON_PADDING - card_element_height,
                    card_element_width,
                    card_element_height,
                }

                add_side_button("Cancel", Cancel_Event{})

                upgrade_options := find_upgrade_options(card^)

                // fmt.printf("%#v\n", upgrade_options)

                for option in upgrade_options {
                    option_card_id := make_card_id(option, my_player_id)
                    fmt.println(option_card_id)
                    append(&ui_stack, UI_Element {
                        card_position_rect,
                        UI_Card_Element{option_card_id, false},
                        card_input_proc,
                        draw_card,
                    }) 
    
                    card_position_rect.x += BUTTON_PADDING + card_element_width
                }

            case .NONEXISTENT:
                // Clicked on a new card to upgrade an existing card
                
                // Find predecessor card
                // There is probably a better way of doing this. maybe we can store the predecessor somewhere when it's clicked.
                for &hand_card in get_my_player().hero.cards {

                    if card.color == hand_card.color {
                        // swap over the card ID to the new card
                        hand_card_element := &find_element_for_card(hand_card).variant.(UI_Card_Element)

                        hand_card_element.card_id = make_card_id(card^, my_player_id)
                        hand_card = card^
                        hand_card.owner = my_player_id
                        hand_card.state = .IN_HAND
                        
                        // Pop two card elements and a potential cancel button
                        pop(&ui_stack)
                        pop(&ui_stack)
                        clear_side_buttons()

                        append(&event_queue, Begin_Next_Upgrade_Event{})
                        break
                    }
                }
            }
        }

    case Confirm_Event:
        #partial switch get_my_player().stage {
        case .SELECTING:
            get_my_player().stage = .CONFIRMED
            clear_side_buttons()
            game_state.confirmed_players += 1
            if game_state.confirmed_players == game_state.num_players {
                game_state.stage = .RESOLUTION
                game_state.resolved_players = 0
    
                // @Todo figure out resolution order
                append(&event_queue, Begin_Resolution_Event{})
            }
        case .RESOLVING:
            log.errorf("Unreachable")
        }

    case Cancel_Event:
        #partial switch get_my_player().stage {
        case .RESOLVING, .INTERRUPTING:
            action := get_current_action()
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                action_variant.path.num_locked_spaces = 0
                clear(&action_variant.path.spaces)

                movement_val := action_variant.distance
                delete(action.targets)
                action.targets = make_movement_targets(movement_val, action_variant.target, action_variant.valid_destinations)

                log.assert(len(side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := side_button_manager.buttons[len(side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Resolve_Current_Action_Event); ok && action_variant.valid_destinations != nil {
                    pop_side_button()
                }
            case Choose_Target_Action:
                log.assert(len(side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := side_button_manager.buttons[len(side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Cancel_Event); ok {
                    pop_side_button()
                }
                for space in action_variant.result {
                    action.targets[space] = {}
                }
                clear(&action_variant.result)
            }

        case .UPGRADING:
            pop(&ui_stack)
            pop(&ui_stack)
            clear_side_buttons()
        }
        
    case Begin_Card_Selection_Event:
        get_my_player().stage = .SELECTING
        game_state.stage = .SELECTION
        game_state.confirmed_players = 0
        tooltip = "Choose a card to play and then confirm it."

    case Begin_Resolution_Event:
        get_my_player().stage = .RESOLVING

        // Find the played card
        card, ok := find_played_card()
        log.assert(ok, "No played card when player begins their resolution!")
        card.turn_played = game_state.turn_counter

        get_my_player().hero.action_list = card.primary_effect

        get_my_player().hero.current_action_index = {sequence=.FIRST_CHOICE}

        append(&event_queue, Begin_Next_Action_Event{})

    case Begin_Next_Action_Event:

        action := get_current_action()
        tooltip = action.tooltip
        log.infof("ACTION: %v", reflect.union_variant_typeid(action.variant))
        if len(action.targets) == 0 {
            populate_targets(get_my_player().hero.current_action_index)
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
            } else if len(action.targets) == calculate_implicit_quantity(action_type.num_targets) && !action.optional {
                for space in action.targets {
                    append(&action_type.result, space)
                }
                append(&event_queue, Resolve_Current_Action_Event{})
            }

        case Choice_Action:
            choices_added: int
            most_recent_choice: Action_Index
            for choice in action_type.choices {
                populate_targets(choice.jump_index)
                if action_can_be_taken(choice.jump_index) {
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

        case Attack_Action:
            target := calculate_implicit_target(action_type.target)
            space := &board[target.x][target.y]
            log.debugf("Attack strength: %v", calculate_implicit_quantity(action_type.strength))
            // Here we assume the target must be an enemy. Enemy should always be in the selection flags for attacks.
            if MINION_FLAGS & space.flags != {} {
                if !defeat_minion(target) {
                    append(&event_queue, Resolve_Current_Action_Event{})
                } else {
                    // get interrupted lol
                }
            }
        
        case Add_Active_Effect_Action:
            effect := action_type.effect
            log.infof("Adding active effect: %v", effect.id)
            parent_card_id, ok := find_played_card_id()
            log.assert(ok, "Could not resolve parent card when adding an active effect!")
            effect.parent_card_id = parent_card_id
            game_state.ongoing_active_effects[effect.id] = effect
            append(&event_queue, Resolve_Current_Action_Event{})

        case Halt_Action: 
            append(&event_queue, End_Resolution_Event{})

        case Minion_Removal_Action:
            log.assert(get_my_player().is_team_captain && get_my_player().stage == .INTERRUPTING && game_state.stage == .MINION_BATTLE)
            minions_to_remove := minion_removal_action[0].variant.(Choose_Target_Action).result
            for minion in minions_to_remove {
                log.assert(!remove_minion(minion), "Minion removal during battle caused wave push!")
            }
            append(&event_queue, End_Minion_Battle_Event{})
            get_my_player().stage = .RESOLVED
        }

    case End_Resolution_Event:
        log.assert(get_my_player().stage == .RESOLVING, "Player is not resolving!")
        clear_side_buttons()
        get_my_player().stage = .RESOLVED
        game_state.resolved_players += 1

        card, ok := find_played_card()
        log.assert(ok, "No played card to resolve!")
        resolve_card(card)

        if game_state.resolved_players == game_state.num_players {
            append(&event_queue, Resolutions_Completed_Event{})
        }
        
    case Resolutions_Completed_Event:
        // Check for end of turn effects and stuff here
        for effect_id, effect in game_state.ongoing_active_effects {
            if turn, ok := effect.duration.(Single_Turn); ok && calculate_implicit_quantity(turn) == game_state.turn_counter {
                log.infof("Removing active effect: %v", effect_id)
                delete_key(&game_state.ongoing_active_effects, effect_id)
            }
        }

        game_state.turn_counter += 1
        if game_state.turn_counter >= 4 {
            // End of round stuffs
            append(&event_queue, Begin_Minion_Battle_Event{})
        } else {
            append(&event_queue, Begin_Card_Selection_Event{})
        }


    case Begin_Minion_Battle_Event:
        game_state.stage = .MINION_BATTLE
        // Let the team captain choose which minions to delete
        // append(&event_queue, End_Minion_Battle_Event{})

        minion_difference := game_state.minion_counts[.RED] - game_state.minion_counts[.BLUE]
        // pushing_team := .RED if minion_difference > 0 else .BLUE
        // pushed_team := get_enemy_team(pushing_team)
        if minion_difference > 0 {
            if minion_difference >= game_state.minion_counts[.BLUE] {
                append(&event_queue, Begin_Wave_Push_Event{.RED})
            } else {
                append(&event_queue, Begin_Minion_Removal_Event{.BLUE})
            }
        } else if minion_difference < 0 {
            if -minion_difference >= game_state.minion_counts[.RED] {
                append(&event_queue, Begin_Wave_Push_Event{.BLUE})
            } else {
                append(&event_queue, Begin_Minion_Removal_Event{.RED})
            }
        } else {
            append(&event_queue, End_Minion_Battle_Event{})
        }

    case Begin_Minion_Removal_Event:
        if get_my_player().team == var.team && get_my_player().is_team_captain {
            get_my_player().hero.current_action_index = {sequence=.MINION_REMOVAL}
            get_my_player().stage = .INTERRUPTING
            append(&event_queue, Begin_Next_Action_Event{}) 
            break
        }

        minion_difference := abs(game_state.minion_counts[.RED] - game_state.minion_counts[.BLUE])

        for target in zone_indices[game_state.current_battle_zone] {
            space := &board[target.x][target.y]
            if space.flags & {.RANGED_MINION, .MELEE_MINION} != {} && space.unit_team == var.team {
                log.assert(!remove_minion(target), "Minion removal during battle caused wave push!")
                minion_difference -= 1
                if minion_difference == 0 do break
            }
        }

        append(&event_queue, End_Minion_Battle_Event{})


    case End_Minion_Battle_Event:

        append(&event_queue, Retrieve_Cards_Event{})

    case Begin_Wave_Push_Event:
        // Check if game over

        game_state.wave_counters -= 1

        prev_battle_zone := game_state.current_battle_zone

        game_state.current_battle_zone += Region_ID(1) if var.pushing_team == .RED else Region_ID(-1)

        if game_state.wave_counters == 0 || game_state.current_battle_zone == .RED_BASE || game_state.current_battle_zone == .BLUE_BASE {
            // Win on base push or last push
            append(&event_queue, Game_Over_Event{var.pushing_team})
            return
        }

        // Remove all minions in current battle zone
        for target in zone_indices[prev_battle_zone] {
            space := &board[target.x][target.y]
            space.flags -= MINION_FLAGS
        }

        game_state.minion_counts[.RED] = 0
        game_state.minion_counts[.BLUE] = 0

        spawn_minions(game_state.current_battle_zone)

        // deal with unspawned minions

        append(&event_queue, End_Wave_Push_Event{})


    case End_Wave_Push_Event:
        switch game_state.stage {
        case .MINION_BATTLE:
            append(&event_queue, Retrieve_Cards_Event{})
        case .RESOLUTION:
            append(&event_queue, Resolve_Current_Action_Event{})
        case .PRE_LOBBY, .IN_LOBBY, .SELECTION, .UPGRADES:
            log.assertf(false, "Invalid state at end of wave push: %v", game_state.stage)
        }

    case Retrieve_Cards_Event:
        // need to retrieve cards here :D
        retrieve_cards()
        append(&event_queue, Begin_Upgrading_Event{})

    case Begin_Upgrading_Event:
        // append(&event_queue, End_Upgrading_Event{})

        if get_my_player().hero.coins < get_my_player().hero.level {
            get_my_player().hero.coins += 1
            log.infof("Pity coin collected. Current coin count: %v", get_my_player().hero.coins)
            append(&event_queue, End_Upgrading_Event{})
        } else {
            append(&event_queue, Begin_Next_Upgrade_Event{})
        }

    case Begin_Next_Upgrade_Event:
        get_my_player().stage = .UPGRADING
        clear_side_buttons()
        tooltip = "Choose a card to upgrade."
        if get_my_player().hero.coins >= get_my_player().hero.level {
            get_my_player().hero.coins -= get_my_player().hero.level
            get_my_player().hero.level += 1
            log.infof("Player levelled up! Current level: %v", get_my_player().hero.level)
        } else {
            append(&event_queue, End_Upgrading_Event{})
        }
        

    case End_Upgrading_Event:
        game_state.turn_counter = 0
        append(&event_queue, Begin_Card_Selection_Event{})

    case Resolve_Current_Action_Event:
        clear_side_buttons()

        action := get_current_action()

        #partial switch &variant in action.variant {
        case Fast_Travel_Action:
            translocate_unit(get_my_player().hero.location, variant.result)
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
                log.debugf("Traversed_space: %v", space)
            }
            translocate_unit(calculate_implicit_target(variant.target), variant.path.spaces[len(variant.path.spaces) - 1])
        case Choice_Action:
            variant.result = var.jump_index.?
        }

        delete(action.targets)
        action.targets = nil
        
        tooltip = nil

        // Here would be where we need to handle minions outside the zone or wave pushes mid-turn

        // Determine next action
        next_index := get_my_player().hero.current_action_index
        if index, ok := var.jump_index.?; ok {
            next_index = index
        } else {
            next_index.index += 1
        }
        if next_index.sequence == .HALT || get_action_at_index(next_index) == nil {
            append(&event_queue, End_Resolution_Event{})
            return
        }

        get_my_player().hero.current_action_index = next_index
        append(&event_queue, Begin_Next_Action_Event{})

    case Game_Over_Event:
        // not too much fanfare here
        log.infof("%v team has won!", var.winning_team)
    }
}