package guards

// This is a good file. It knows exactly what it is trying to do and does it extremely well.

import "core:reflect"
import sa "core:container/small_array"
import "core:log"


Marker_Event :: struct {}

Join_Network_Game_Chosen_Event :: struct {}
Join_Local_Game_Chosen_Event :: struct {}
Host_Game_Chosen_Event :: struct {}

Update_Player_Data_Event :: struct {
    player_base: Player_Base,
}

Enter_Lobby_Event :: struct {}
Change_Hero_Event :: struct {
    hero_id: Hero_ID,
}
Begin_Game_Event :: struct {}

Space_Hovered_Event :: struct {
    space: Target,
}

Space_Clicked_Event :: struct {
    space: Target,
}

Card_Clicked_Event :: struct {
    card_element: ^UI_Card_Element,
}



// Confirm_Event :: struct {}
Cancel_Event :: struct {}

Unit_Translocation_Event :: struct {
    src, dest: Target,
}
Minion_Defeat_Event :: struct {
    target: Target,
    defeating_player: Player_ID,
}
Minion_Removal_Event :: struct {
    target: Target,
    removing_player: Player_ID,
}
Minion_Spawn_Event :: struct {
    target: Target,
    minion_type: Space_Flag,
    team: Team,
}

Minion_Blocked_Event :: struct {
    target: Target,
}

Begin_Interrupt_Event :: struct {
    interrupt: Interrupt,
}
Resolve_Interrupt_Event :: struct {}

Update_Tiebreaker_Event :: struct {
    tiebreaker: Team,
}

Begin_Card_Selection_Event :: struct {}
Card_Confirmed_Event :: struct {
    player_id: Player_ID,
    maybe_card_id: Maybe(Card_ID),
}

Card_Discarded_Event :: struct {
    card_id: Card_ID,
}

Card_Retrieved_Event :: struct {
    card_id: Card_ID,
}

Begin_Resolution_Stage_Event :: struct{}

Resolve_Same_Team_Tied_Event :: struct {
    team: Team,
    tied_player_ids: [5]Player_ID,
    num_ties: int,
}

Begin_Player_Resolution_Event :: struct {
    player_id: Player_ID,
}
Begin_Next_Action_Event :: struct {}
Resolve_Current_Action_Event :: struct {
    jump_index: Maybe(Action_Index),
}
End_Resolution_Event :: struct {
    player_id: Player_ID,
}

Check_Minions_Outside_Zone_Event :: struct {}

Resolutions_Completed_Event :: struct {}

End_Of_Turn_Event :: struct {}

Begin_Minion_Battle_Event :: struct {}

End_Minion_Battle_Event :: struct {}


Hero_Defeated_Event :: struct {
    defeated, defeater: Player_ID,
}

Hero_Respawn_Event :: struct {
    respawner: Player_ID,
    location: Target,
}

Add_Active_Effect_Event :: struct {
    effect_id: Active_Effect_ID,
}

Remove_Active_Effect_Event :: struct {
    effect_kind: Active_Effect_Kind,
}

Begin_Wave_Push_Event :: struct {
    pushing_team: Team,
}
Resolve_Blocked_Minions_Event :: struct {
    team: Team,
}
End_Wave_Push_Event :: struct{}

Begin_Upgrading_Event :: struct {}
Begin_Next_Upgrade_Event :: struct {}
End_Upgrading_Event :: struct {
    player_id: Player_ID,
}

Game_Over_Event :: struct {
    winning_team: Team,
}



Event :: union {

    Marker_Event,

    Join_Network_Game_Chosen_Event,
    // Join_Local_Game_Chosen_Event,
    Host_Game_Chosen_Event,

    Update_Player_Data_Event,

    Enter_Lobby_Event,
    Change_Hero_Event,
    Begin_Game_Event,
    
    Space_Hovered_Event,
    Space_Clicked_Event,
    Card_Clicked_Event,
    // Confirm_Event,
    Cancel_Event,

    Unit_Translocation_Event,

    Minion_Defeat_Event,
    Minion_Removal_Event,
    Minion_Spawn_Event,
    Minion_Blocked_Event,

    Card_Discarded_Event,
    Card_Retrieved_Event,

    Hero_Defeated_Event,
    Hero_Respawn_Event,

    Add_Active_Effect_Event,
    Remove_Active_Effect_Event,

    Begin_Interrupt_Event,
    Resolve_Interrupt_Event,

    Update_Tiebreaker_Event,

    Begin_Card_Selection_Event,
    Card_Confirmed_Event,

    Begin_Resolution_Stage_Event,
    Resolve_Same_Team_Tied_Event,
    Begin_Player_Resolution_Event,

    Begin_Next_Action_Event,
    Resolve_Current_Action_Event,
    End_Resolution_Event,
    Check_Minions_Outside_Zone_Event,

    Resolutions_Completed_Event,
    End_Of_Turn_Event,

    Begin_Minion_Battle_Event,
    
    Begin_Wave_Push_Event,
    Resolve_Blocked_Minions_Event,
    End_Wave_Push_Event,
    
    End_Minion_Battle_Event,

    Begin_Upgrading_Event,
    Begin_Next_Upgrade_Event,
    End_Upgrading_Event,

    Game_Over_Event,
}


resolve_event :: proc(gs: ^Game_State, event: Event) {

    log.infof("EVENT: %v", reflect.union_variant_typeid(event))
    switch var in event {

    case Marker_Event:
        return

    case Join_Network_Game_Chosen_Event:
        text_box := &gs.ui_stack[.BUTTONS][0].variant.(UI_Text_Box_Element)
        ip := string(sa.slice(&text_box.field))
        switch error in join_game(gs, ip) {
        case nil: append(&gs.event_queue, Enter_Lobby_Event{})
        case Parse_Error: add_toast(gs, "Unable to parse IP address.", 2)
        case Dial_Error: add_toast(gs, "Could not connect to IP address.", 2)
        }

    // case Join_Local_Game_Chosen_Event:
    //     if join_game(gs) {
    //         append(&gs.event_queue, Enter_Lobby_Event{})
    //     }

    case Host_Game_Chosen_Event:
        if begin_hosting_local_game(gs) {
            when !ODIN_TEST {
                begin_recording_events()
            }
            append(&gs.event_queue, Enter_Lobby_Event{})
        }

    case Update_Player_Data_Event:
        add_or_update_player(gs, var.player_base)

    case Enter_Lobby_Event:
        gs.stage = .IN_LOBBY
        clear(&gs.ui_stack[.BUTTONS])
        if gs.is_host {
            gs.tooltip = "Wait for players to join, then begin the game."
            button_loc := (Vec2{WIDTH, HEIGHT} - SELECTION_BUTTON_SIZE) / 2
            add_generic_button(gs, {button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, "Begin Game", Begin_Game_Event{}, global = true)
        } else {
            gs.tooltip = "Wait for the host to begin the game."
        }

        button_loc := Vec2{WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, TOOLTIP_FONT_SIZE + BUTTON_PADDING}
        for hero in Hero_ID {
            log.infof("adding button")
            add_generic_button(gs, {button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, hero_names[hero], Change_Hero_Event{hero})
            button_loc.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        }

    case Change_Hero_Event:
        log.assert(gs.stage == .IN_LOBBY, "Tried to change hero outside of lobby!")
        player_base := get_my_player(gs).base
        player_base.hero.id = var.hero_id

        broadcast_game_event(gs, Update_Player_Data_Event{player_base})

    case Begin_Game_Event:
        begin_game(gs)

    case Space_Hovered_Event:
        #partial switch get_my_player(gs).stage {
        case .RESOLVING, .INTERRUPTING:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                resize(&action_variant.path.spaces, action_variant.path.num_locked_spaces)

                if var.space == INVALID_TARGET do break
                if !action.targets[var.space.x][var.space.y].member do break

                starting_space := action_variant.path.spaces[action_variant.path.num_locked_spaces - 1]

                current_space := var.space
                for ; current_space != starting_space; current_space = {action.targets[current_space.x][current_space.y].prev_x, action.targets[current_space.x][current_space.y].prev_y} {
                    inject_at(&action_variant.path.spaces, action_variant.path.num_locked_spaces, current_space)
                }
            }
        }

    case Space_Clicked_Event:
        #partial switch get_my_player(gs).stage {
        case .RESOLVING, .INTERRUPTING:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)

            if !action.targets[var.space.x][var.space.y].member do break

            #partial switch &action_variant in action.variant {
            case Fast_Travel_Action:
                action_variant.result = var.space
                append(&gs.event_queue, Resolve_Current_Action_Event{})

            case Movement_Action:
                if len(action_variant.path.spaces) == action_variant.path.num_locked_spaces do break

                action_variant.path.num_locked_spaces = len(action_variant.path.spaces)
                calc_context := Calculation_Context{card_id = action_index.card_id}
                action.targets = make_movement_targets(gs, action_variant.criteria, calc_context)
                append(&gs.event_queue, Begin_Next_Action_Event{})

                // if _, ok := top_button.event.(Cancel_Event); ok && target_valid {
                //     add_side_button(gs, "Confirm move", Resolve_Current_Action_Event{})
                // } else if _, ok2 := top_button.event.(Resolve_Current_Action_Event); ok2 && !target_valid {
                //     pop_side_button(gs)
                // }

            case Choose_Target_Action:
                append(&action_variant.result, var.space)
                action.targets[var.space.x][var.space.y].member = false
                if len(action_variant.result) == calculate_implicit_quantity(gs, action_variant.num_targets, {card_id = action_index.card_id}) {
                    append(&gs.event_queue, Resolve_Current_Action_Event{})
                } else if len(gs.side_button_manager.buttons) == 0 {
                    add_side_button(gs, "Cancel", Cancel_Event{})
                }

            }
        }

    case Card_Clicked_Event:
        card_id := var.card_element.card_id
        card, card_ok := get_card_by_id(gs, card_id)

        #partial switch get_my_player(gs).stage {
        case .SELECTING:
            log.assert(card_ok, "Card element clicked with no card associated!")
            #partial switch card.state {
            case .IN_HAND:

                if selected_element, ok2 := find_selected_card_element(gs); ok2 {
                    selected_card_element := &selected_element.variant.(UI_Card_Element)
                    selected_card_element.selected = false
                    clear_side_buttons(gs)
                }

                var.card_element.selected = true
                add_side_button(gs, "Confirm card", Card_Confirmed_Event{gs.my_player_id, card_id}, global=true)
            }

        case .UPGRADING:
            if !card_ok {  // Clicked on an upgrade option

                // Find the predecessor card
                hero := &get_my_player(gs).hero
                hand_card := &hero.cards[card_id.color]
                
                // Swap over the card ID of the card element for the hand card
                ui_element, _  := find_element_for_card(gs, hand_card)
                log.assert(ui_element != nil, "Could not find hand card when upgrading!")
                hand_card_element := &ui_element.variant.(UI_Card_Element)
                hand_card_element.card_id = card_id

                // Swap over the card ID in hand
                hand_card.id = card_id
                
                // Add the alternate card to the hero's items
                hero.items[hero.item_count] = card_id
                hero.items[hero.item_count].alternate = !card_id.alternate
                hero.item_count += 1
                
                // Pop two card elements and a potential cancel button
                pop(&gs.ui_stack[.CARDS])
                pop(&gs.ui_stack[.CARDS])
                clear_side_buttons(gs)

                // Complete the upgrade
                append(&gs.event_queue, Begin_Next_Upgrade_Event{})
            } else {
                #partial switch card.state {
                case .IN_HAND:
                    if card.tier == 0 do break
                    // Ensure clicked card is able to be upgraded
                    lowest_tier: int = 1e6
                    for other_card in get_my_player(gs).hero.cards {
                        if other_card.tier == 0 do continue
                        lowest_tier = min(lowest_tier, other_card.tier)
                    }
                    if card.tier > lowest_tier || lowest_tier == 3 do break  // @cleanup This is not really correct, upgrade should not be possible if lowest tier is 3
    
                    // I shouldn't really be checking this through the ui stack like this tbh
                    // But I don't have a better way of seeing if an upgrade is happening. // @Cleanup?
                    top_element := gs.ui_stack[.CARDS][len(gs.ui_stack[.CARDS]) - 1]
                    card_element, ok2 := top_element.variant.(UI_Card_Element)
                    if ok2 {
                        if _, ok3 := get_card_by_id(gs, card_element.card_id); !ok3 do break
                    }
    
                    // Display possible upgrades for clicked card
                    card_element_width := (SELECTION_BUTTON_SIZE.x - BUTTON_PADDING) / 2
                    card_element_height := card_element_width * 3.5 / 2.5
    
                    card_position_rect := Rectangle {
                        FIRST_SIDE_BUTTON_LOCATION.x,
                        FIRST_SIDE_BUTTON_LOCATION.y - BUTTON_PADDING - card_element_height,
                        card_element_width,
                        card_element_height,
                    }
    
                    add_side_button(gs, "Cancel", Cancel_Event{})
    
                    upgrade_options, ok3 := find_upgrade_options(gs, card^)
                    log.assertf(ok3, "Card has no upgrade options!!!")
    
                    // fmt.printf("%#v\n", upgrade_options)
    
                    for option_card in upgrade_options {
                        option_id := option_card
                        option_id.owner_id = gs.my_player_id
                        append(&gs.ui_stack[.CARDS], UI_Element {
                            card_position_rect,
                            UI_Card_Element{
                                card_id = option_id,
                            },
                            card_input_proc,
                            draw_card,
                            {},
                        }) 
                        card_position_rect.x += BUTTON_PADDING + card_element_width
                    }  
                }
            }
        case .RESOLVING, .INTERRUPTING:
            action := get_current_action(gs)
            #partial switch &variant in action.variant {
            case Choose_Card_Action:
                for target_card_id in variant.card_targets {
                    if target_card_id == card_id {
                        variant.result = card_id
                        append(&gs.event_queue, Resolve_Current_Action_Event{})
                        break
                    }
                }
            }
        }

    case Cancel_Event:
        #partial switch get_my_player(gs).stage {
        case .RESOLVING, .INTERRUPTING:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                action_variant.path.num_locked_spaces = 1
                resize(&action_variant.path.spaces, 1)

                action.targets = make_movement_targets(gs, action_variant.criteria, {card_id = action_index.card_id})

                log.assert(len(gs.side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := gs.side_button_manager.buttons[len(gs.side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Resolve_Current_Action_Event); ok && len(action_variant.destination_criteria.conditions) != 0 {
                    pop_side_button(gs)
                }
            case Choose_Target_Action:
                log.assert(len(gs.side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := gs.side_button_manager.buttons[len(gs.side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Cancel_Event); ok {
                    pop_side_button(gs)
                }
                for space in action_variant.result {
                    action.targets[space.x][space.y].member = true
                }
                clear(&action_variant.result)
            }

        case .UPGRADING:
            pop(&gs.ui_stack[.CARDS])
            pop(&gs.ui_stack[.CARDS])
            clear_side_buttons(gs)
        }

    case Unit_Translocation_Event:
        translocate_unit(gs, var.src, var.dest)

    case Minion_Defeat_Event:
        space := &gs.board[var.target.x][var.target.y]
        minion := space.flags & MINION_FLAGS
        log.assert(space.flags & MINION_FLAGS != {}, "Tried to defeat a minion in a space with no minions!")
        minion_team := space.unit_team

        if .HEAVY_MINION in minion {
            log.assert(gs.minion_counts[minion_team] == 1, "Heavy minion defeated with an invalid number of minions left!")
            get_player_by_id(gs, var.defeating_player).hero.coins += 4
        } else {
            get_player_by_id(gs, var.defeating_player).hero.coins += 2
        }

    case Minion_Removal_Event:
        space := &gs.board[var.target.x][var.target.y]
        log.assert(space.flags & MINION_FLAGS != {}, "Tried to remove a minion from a space with no minions!")
        minion_team := space.unit_team
        log.assert(gs.minion_counts[minion_team] > 0, "Removing a minion but the game state claims there are 0 minions")
        space.flags -= MINION_FLAGS

        gs.minion_counts[minion_team] -= 1

        log.infof("Minion removed, new counts: %v", gs.minion_counts)

        if gs.minion_counts[minion_team] == 1 {
            remove_heavy_immunity(gs, minion_team)
        }

    case Minion_Spawn_Event:
        space := &gs.board[var.target.x][var.target.y]
        space.flags -= {.TOKEN}
        space.flags += {var.minion_type}
        if var.minion_type == .HEAVY_MINION {
            space.flags += {.IMMUNE}
        }
        space.unit_team = var.team
        gs.minion_counts[var.team] += 1

    case Minion_Blocked_Event:
        space := &gs.board[var.target.x][var.target.y]
        log.assert(space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT}) != {}, "Minion spawn blocked at non-spawnpoint!")
        append(&gs.blocked_spawns[space.spawnpoint_team], var.target)

    case Hero_Defeated_Event:
        defeated := get_player_by_id(gs, var.defeated)
        defeated_hero := &defeated.hero
        defeated_hero.dead = true
        defeater := get_player_by_id(gs, var.defeater)

        if defeated_card, ok := find_played_card(gs, var.defeated); ok {
            if var.defeated == gs.my_player_id && len(gs.interrupt_stack) > 0 {
                gs.interrupt_stack[0].previous_stage = .RESOLVED
            } else { 
                defeated.stage = .RESOLVED
            }
            resolve_card(gs, defeated_card)
        }        

        gs.board[defeated_hero.location.x][defeated_hero.location.y].flags -= {.HERO}

        for &player in gs.players {
            if player.team == defeater.team {
                if player.id == var.defeater {
                    player.hero.coins += defeated_hero.level
                } else {
                    player.hero.coins += num_life_counters[defeated_hero.level]
                }
            }
        }

        gs.life_counters[defeated.team] -= num_life_counters[defeated_hero.level]
        if gs.life_counters[defeated.team] <= 0 {
            append(&gs.event_queue, Game_Over_Event{defeater.team})
        }

    case Hero_Respawn_Event:
        player := get_player_by_id(gs, var.respawner)
        player.hero.location = var.location
        player.hero.dead = false
        gs.board[var.location.x][var.location.y].flags += {.HERO}
        gs.board[var.location.x][var.location.y].hero_id = player.hero.id
        gs.board[var.location.x][var.location.y].unit_team = player.team
        gs.board[var.location.x][var.location.y].owner = var.respawner

    case Add_Active_Effect_Event:

        // parent_card, ok := get_card_by_id(gs, var.effect_id.parent_card_id)
        // log.assertf(ok, "Invalid card ID in new active effect!")
        parent_card_data, ok := get_card_data_by_id(gs, var.effect_id.parent_card_id)
        log.assertf(ok, "Could not find primary data for card!")
        effect_action := parent_card_data.primary_effect[0].variant.(Add_Active_Effect_Action).effect

        log.infof("Adding active effect: %v", var.effect_id.kind)
        gs.ongoing_active_effects[var.effect_id.kind] = Active_Effect {
            var.effect_id,
            effect_action.timing,
            effect_action.target_set,
        }

    case Remove_Active_Effect_Event:
        delete_key(&gs.ongoing_active_effects, var.effect_kind)

    case Begin_Interrupt_Event:
        interrupt := var.interrupt
        if interrupt.interrupted_player != gs.my_player_id {  // The interruptee should already have added to their own interrupt stack in become_interrupted
            previous_stage := get_my_player(gs).stage        // Therefore we only add an interrupt to the stack if we are not the interuuptee
            expanded_interrupt := Expanded_Interrupt {
                interrupt = interrupt,
                previous_stage = previous_stage,
                previous_action_index = get_my_player(gs).hero.current_action_index,
            }
            append(&gs.interrupt_stack, expanded_interrupt)
        }

        if interrupt.interrupting_player == gs.my_player_id {
            get_my_player(gs).stage = .INTERRUPTING

            switch &interrupt_variant in gs.interrupt_stack[len(gs.interrupt_stack) - 1].interrupt.variant {
            case Action_Index:
                get_my_player(gs).hero.current_action_index = interrupt_variant
                append(&gs.event_queue, Begin_Next_Action_Event{})
            case Wave_Push_Interrupt:
                broadcast_game_event(gs, Begin_Wave_Push_Event{interrupt_variant.pushing_team})
            case Attack_Interrupt:
                // @Todo need to do attacks now
                get_my_player(gs).hero.current_action_index = {sequence = .BASIC_DEFENSE, index = 0}
                append(&gs.event_queue, Begin_Next_Action_Event{})
            }
        } else {
            get_my_player(gs).stage = .INTERRUPTED
        }

    case Resolve_Interrupt_Event:
        log.assert(len(gs.interrupt_stack) > 0, "Interrupt resolved with no interrupt on the stack!")
        most_recent_interrupt := pop(&gs.interrupt_stack)
        get_my_player(gs).stage = most_recent_interrupt.previous_stage
        get_my_player(gs).hero.current_action_index = most_recent_interrupt.previous_action_index
        if most_recent_interrupt.interrupt.interrupted_player == gs.my_player_id {
            append(&gs.event_queue, most_recent_interrupt.on_resolution)
        }

    case Update_Tiebreaker_Event:
        gs.tiebreaker_coin = var.tiebreaker
        
    case Begin_Card_Selection_Event:
        get_my_player(gs).stage = .SELECTING
        gs.stage = .SELECTION
        gs.confirmed_players = 0
        gs.tooltip = "Choose a card to play and then confirm it."

        // Streamline card selection if player has 0 or 1 cards
        hand_card_count := 0
        hand_card: Maybe(Card_ID) = nil

        for card in get_my_player(gs).hero.cards {
            if card.state == .IN_HAND {
                hand_card_count += 1
                hand_card = card.id
            }
        }

        // 0 or 1 cards remaining => forced choice
        if hand_card_count <= 1 {
            broadcast_game_event(gs, Card_Confirmed_Event{gs.my_player_id, hand_card})
        }

    case Card_Confirmed_Event:
        player := get_player_by_id(gs, var.player_id)
        player.stage = .CONFIRMED
        gs.confirmed_players += 1

        card_id, played_card_exists := var.maybe_card_id.?
        if played_card_exists {
            card, ok := get_card_by_id(gs, card_id)
            log.assert(ok, "Invalid card ID in card confirmation event!")
            play_card(gs, card)
        }

        if var.player_id == gs.my_player_id {
            clear_side_buttons(gs)
            gs.tooltip = "Waiting for other players to confirm their cards."
        }

        if gs.is_host && gs.confirmed_players == len(gs.players) {
            broadcast_game_event(gs, Begin_Resolution_Stage_Event{})
        }

    case Card_Discarded_Event:
        card, ok := get_card_by_id(gs, var.card_id)
        log.assert(ok, "Discarded card has invalid card ID!")
        discard_card(gs, card)

    case Card_Retrieved_Event:
        card, ok := get_card_by_id(gs, var.card_id)
        log.assert(ok, "Retrieved card has invalid card ID!")
        retrieve_card(gs, card)

    case Begin_Resolution_Stage_Event: 
        gs.stage = .RESOLUTION

        // Unhide hidden cards
        for _, player_id in gs.players {
            player_card, ok := find_played_card(gs, player_id)
            if !ok do continue  // Player had no played card
            element, _ := find_element_for_card(gs, player_card^)
            card_element := &element.variant.(UI_Card_Element)
            card_element.hidden = false
        }

        if gs.is_host {
            broadcast_game_event(gs, get_next_turn_event(gs))
        }

    case Resolve_Same_Team_Tied_Event:
        if var.team == get_my_player(gs).team && get_my_player(gs).is_team_captain {
            gs.tooltip = "Tied initiative: Choose which player on your team acts first."
            for tied_id, index in var.tied_player_ids {
                if index == var.num_ties do break
                add_side_button(gs, get_username(gs, tied_id), Begin_Player_Resolution_Event{tied_id}, global = true)
            }
        } else {
            gs.tooltip = "Waiting for the team captain to resolve tied initiative."
        }

    case Begin_Player_Resolution_Event:
        gs.players[var.player_id].stage = .RESOLVING
        gs.tooltip = "Waiting for other players to resolve their cards."
        clear_side_buttons(gs)
        if var.player_id != gs.my_player_id do break

        // Find the played card
        card, ok := find_played_card(gs)
        log.assert(ok, "No played card when player begins their resolution!")

        get_my_player(gs).hero.current_action_index = {card_id = card.id, sequence=.FIRST_CHOICE}

        if get_my_player(gs).hero.dead {
            become_interrupted (
                gs,
                gs.my_player_id,
                Action_Index{sequence = .RESPAWN, index = 0},
                Begin_Next_Action_Event{},
            )
            break
        }

        append(&gs.event_queue, Begin_Next_Action_Event{})

    case Begin_Next_Action_Event:

        action_index := get_my_player(gs).hero.current_action_index
        calc_context := Calculation_Context{card_id = action_index.card_id}
        action := get_action_at_index(gs, action_index)

        skip_index := action.skip_index
    
        gs.tooltip = action.tooltip
        log.infof("ACTION: %v", reflect.union_variant_typeid(action.variant))

        if !validate_action(gs, action_index) {
            if action.optional {
                append(&gs.event_queue, Resolve_Current_Action_Event{skip_index})
            } else {
                end_current_action_sequence(gs)
            }
        }

        clear_side_buttons(gs)
        if action.optional {
            add_side_button(gs, "Skip" if action.skip_name == nil else action.skip_name, Resolve_Current_Action_Event{skip_index})
        }

        switch &action_type in action.variant {
        case Movement_Action:
            add_side_button(gs, "Reset move", Cancel_Event{})

            top_space := action_type.path.spaces[len(action_type.path.spaces) - 1]
            target_valid := !action.targets[top_space.x][top_space.y].invalid
            if target_valid {
                add_side_button(gs, "Confirm move", Resolve_Current_Action_Event{})
            }

        case Choose_Target_Action:
            clear(&action_type.result)
            if count_members(&action.targets) == calculate_implicit_quantity(gs, action_type.num_targets, calc_context) && !action.optional {
                iter := make_target_set_iterator(&action.targets)
                for _, space in target_set_iter_members(&iter) {
                    append(&action_type.result, space)
                }
                append(&gs.event_queue, Resolve_Current_Action_Event{})
            }

        case Choice_Action:
            choices_added: int
            most_recent_choice: Action_Index

            for choice in action_type.choices {
                if choice.valid {
                    jump_index := choice.jump_index
                    if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
                    add_side_button(gs, choice.name, Resolve_Current_Action_Event{jump_index})
                    choices_added += 1
                    most_recent_choice = jump_index
                }
            }

            if choices_added == 1 {
                append(&gs.event_queue, Resolve_Current_Action_Event{most_recent_choice})
            }

        case Attack_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            space := &gs.board[target.x][target.y]
            attack_strength := calculate_implicit_quantity(gs, action_type.strength, calc_context)
            log.infof("Attack strength: %v", attack_strength)
            // Here we assume the target must be an enemy. Enemy should always be in the selection flags for attacks.
            if MINION_FLAGS & space.flags != {} {
                if defeat_minion(gs, target) {  // Add a wave push interrupt if the minion defeated was the last one
                    become_interrupted (
                        gs,
                        0,  // Host ID
                        Wave_Push_Interrupt{get_my_player(gs).team},
                        Resolve_Current_Action_Event{},
                    )
                } else {
                    append(&gs.event_queue, Resolve_Current_Action_Event{})
                }
            } else {
                owner := space.owner
                become_interrupted (
                    gs,
                    owner,
                    Attack_Interrupt {
                        strength = attack_strength,
                    },
                    Resolve_Current_Action_Event{},
                )
            }

        case Force_Discard_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            space := gs.board[target.x][target.y]
            log.assert(.HERO in space.flags, "Forced a space without a hero to discard!")
            owner := space.owner
            become_interrupted (
                gs,
                owner,
                Action_Index{sequence = .DISCARD_ABLE} if !action_type.or_is_defeated else Action_Index{sequence = .DISCARD_DEFEAT},
                Resolve_Current_Action_Event{},
            )
        
        case Add_Active_Effect_Action:
            effect_id := action_type.effect.id
            parent_card, ok := get_card_by_id(gs, action_index.card_id)
            log.assert(ok, "Could not resolve parent card when adding an active effect!")
            effect_id.parent_card_id = parent_card.id
            broadcast_game_event(gs, Add_Active_Effect_Event{effect_id})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Halt_Action:
            end_current_action_sequence(gs)

        case Minion_Defeat_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            space := gs.board[target.x][target.y]
            if MINION_FLAGS & space.flags != {} {
                if defeat_minion(gs, target) {  // Add a wave push interrupt if the minion defeated was the last one
                    become_interrupted (
                        gs,
                        0,  // Host ID
                        Wave_Push_Interrupt{get_my_player(gs).team},
                        Resolve_Current_Action_Event{},
                    )
                } else {
                    append(&gs.event_queue, Resolve_Current_Action_Event{})
                }
            }

        case Minion_Removal_Action:
            // This assert might not be necessary once we expand to more cases where minions can get removed.
            log.assert(get_my_player(gs).is_team_captain && get_my_player(gs).stage == .INTERRUPTING && gs.stage == .MINION_BATTLE)
            minions_to_remove := calculate_implicit_target_slice(gs, action_type.targets)
            for minion in minions_to_remove {
                log.assert(!remove_minion(gs, minion), "Minion removal during battle caused wave push!")
            }
            append(&gs.event_queue, Resolve_Current_Action_Event{})

            
        case Jump_Action:
            jump_index := calculate_implicit_action_index(gs, action_type.jump_index, calc_context)
            // jump_index.card_id = action_index.card_id
            append(&gs.event_queue, Resolve_Current_Action_Event{jump_index})
            
        case Minion_Spawn_Action:
            target := calculate_implicit_target(gs, action_type.location, calc_context)
            spawnpoint := calculate_implicit_target(gs, action_type.spawnpoint, calc_context)
            space := gs.board[spawnpoint.x][spawnpoint.y]
            spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT})
            log.assert(spawnpoint_flags != {}, "Minion spawn action with invalid spawnpoint!!!")
            spawnpoint_type := get_first_set_bit(spawnpoint_flags).?
            minion_type := spawnpoint_to_minion[spawnpoint_type]
            minion_team := space.spawnpoint_team

            if len(gs.blocked_spawns[get_my_player(gs).team]) > 0 {
                pop(&gs.blocked_spawns[get_my_player(gs).team])
            }

            broadcast_game_event(gs, Minion_Spawn_Event{target, minion_type, minion_team})
            append(&gs.event_queue, Resolve_Current_Action_Event{})
            
        case Discard_Card_Action:
            card_id := calculate_implicit_card_id(gs, action_type.card)
            broadcast_game_event(gs, Card_Discarded_Event{card_id})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Defend_Action:
            can_defend: bool
            if action_type.block_condition != nil do can_defend = calculate_implicit_condition(gs, action_type.block_condition, calc_context)
            else {
                attack_strength := -1e6
                search_interrupts: #reverse for expanded_interrupt in gs.interrupt_stack {
                    #partial switch interrupt_variant in expanded_interrupt.interrupt.variant {
                    case Attack_Interrupt:
                        attack_strength = interrupt_variant.strength
                        break search_interrupts
                    }
                }
                log.assert(attack_strength != -1e6, "No attack found in interrupt stack!!!!!")

                // We do it this way so that defense items get calculated
                defense_strength := calculate_implicit_quantity(gs, action_type.strength, calc_context)
                can_defend = defense_strength >= attack_strength
            }
            if can_defend do append(&gs.event_queue, Resolve_Current_Action_Event{})
            else do append(&gs.event_queue, Resolve_Current_Action_Event{Action_Index{sequence = .DIE}})
            // @Defense: Here you would add an interrupt to perform the "defense action"
            

        case Retrieve_Card_Action:
            card_id := calculate_implicit_card_id(gs, action_type.card)
            broadcast_game_event(gs, Card_Retrieved_Event{card_id})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Gain_Coins_Action:
            gain := calculate_implicit_quantity(gs, action_type.gain, calc_context)
            player_base := get_my_player(gs).base
            player_base.hero.coins += gain
            broadcast_game_event(gs, Update_Player_Data_Event{player_base})

        case Get_Defeated_Action:
            // Here we assume the player who added the last interrupt is the one who kills us. This may not be correct always...
            // Would be nice to somehow store the defeater in the action itself
            top_interrupt := gs.interrupt_stack[len(gs.interrupt_stack) - 1].interrupt

            broadcast_game_event(gs, Hero_Defeated_Event{gs.my_player_id, top_interrupt.interrupted_player})

            // @Todo: cancel active effects & recall markers
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Respawn_Action:
            // @Cleanup yet another point where Choose_Target_Action kind of gets in the way of clear code
            // We know that the player has chosen a single spawnpoint to respawn at by this point,
            // why do we need to go through all the trouble of recalculating it?
            // Shouldn't need the card ID here
            respawn_point := calculate_implicit_target(gs, action_type.location, calc_context)
            broadcast_game_event(gs, Hero_Respawn_Event{gs.my_player_id, respawn_point})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Fast_Travel_Action, Clear_Action, Choose_Card_Action:
            // nuffink
        }

    case Resolve_Current_Action_Event:
        clear_side_buttons(gs)

        action_index := get_my_player(gs).hero.current_action_index
        action := get_action_at_index(gs, action_index)

        #partial switch &variant in action.variant {
        case Fast_Travel_Action:
            broadcast_game_event(gs, Unit_Translocation_Event{get_my_player(gs).hero.location, variant.result})
        case Movement_Action:
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

            starting_space := variant.path.spaces[0]
            ending_space := variant.path.spaces[len(variant.path.spaces) - 1]
            broadcast_game_event(gs, Unit_Translocation_Event{starting_space, ending_space})
        case Choice_Action:
            variant.result = var.jump_index.?            
        }

        action.targets = {}
        
        gs.tooltip = nil

        // Here would be where we need to handle minions outside the zone

        // Determine next action
        next_index := get_my_player(gs).hero.current_action_index
        if index, ok := var.jump_index.?; ok {
            if index.card_id == {} do index.card_id = next_index.card_id
            next_index = index
        } else {
            next_index.index += 1
        }

        if next_index.sequence == .HALT || get_action_at_index(gs, next_index) == nil {
            end_current_action_sequence(gs)
            break
        }

        get_my_player(gs).hero.current_action_index = next_index
        append(&gs.event_queue, Begin_Next_Action_Event{})

    case End_Resolution_Event:
        clear_side_buttons(gs)

        // This is to ensure that if a player's state changes mid-interrupt, only the underlying "base state" changes, rather than all the froth on top.
        gs.players[var.player_id].stage = .RESOLVED


        card, ok := find_played_card(gs, var.player_id)
        
        log.assert(ok, "No played card to resolve!")
        resolve_card(gs, card)
        if var.player_id == gs.my_player_id {
            gs.tooltip = "Waiting for other players to finish resolution."
        }

        if gs.is_host {
            if gs.initiative_tied {
                broadcast_game_event(gs, Update_Tiebreaker_Event{get_enemy_team(gs.tiebreaker_coin)})
            }
            gs.initiative_tied = false

            append(&gs.event_queue, Check_Minions_Outside_Zone_Event{})
        }

    case Check_Minions_Outside_Zone_Event:

        log.assert(gs.is_host, "Clients should not be checking minions outside the battle zone")

        needs_interrupt: [Team]bool

        check_spaces: for region_id in Region_ID{
            if region_id == .NONE || region_id == gs.current_battle_zone do continue
            for index in zone_indices[region_id] {
                space := gs.board[index.x][index.y]
                if space.flags & MINION_FLAGS != {} {
                    needs_interrupt[space.unit_team] = true
                    if space.unit_team == gs.tiebreaker_coin do break check_spaces
                }
            }
        }

        if needs_interrupt[gs.tiebreaker_coin] {
            become_interrupted (
                gs,
                gs.team_captains[gs.tiebreaker_coin],
                Action_Index{sequence = .MINION_OUTSIDE_ZONE, index = 0},
                Check_Minions_Outside_Zone_Event{},
            )
        } else if non_tb_team := get_enemy_team(gs.tiebreaker_coin); needs_interrupt[non_tb_team] {
            become_interrupted (
                gs,
                gs.team_captains[non_tb_team],
                Action_Index{sequence = .MINION_OUTSIDE_ZONE, index = 0},
                Check_Minions_Outside_Zone_Event{},
            )
        } else {
            broadcast_game_event(gs, get_next_turn_event(gs))
        }

    case Resolutions_Completed_Event:
        gs.turn_counter += 1
        if gs.is_host {
            append(&gs.event_queue, End_Of_Turn_Event{})
        }

    case End_Of_Turn_Event:
        log.assert(gs.is_host, "Clients should not be resolving end of turn")

        
        // Start any extra actions from end of turn effects
        // @Todo in the future we need to care more about the order in which end of turn effects take place
        for effect_kind, effect in gs.ongoing_active_effects {
            #partial switch timing in effect.timing {
            case End_Of_Turn:
                broadcast_game_event(gs, Remove_Active_Effect_Event{effect_kind})
                action_index := timing.extra_action_index
                action_index.card_id = effect.parent_card_id  // Very important do to this otherwise we get lost
                become_interrupted (
                    gs,
                    effect.parent_card_id.owner_id,
                    action_index,
                    End_Of_Turn_Event{},
                )
                return
            }
        }

        // Remove effects that last for the turn
        for effect_kind, effect in gs.ongoing_active_effects {
            #partial switch timing in effect.timing {
            case Single_Turn:
                if calculate_implicit_quantity(gs, timing, calc_context = {card_id = effect.parent_card_id}) != gs.turn_counter {
                    broadcast_game_event(gs, Remove_Active_Effect_Event{effect_kind})
                }
            }
        }

        if gs.turn_counter < 4 {
            broadcast_game_event(gs, Begin_Card_Selection_Event{})
        } else {
            // Start any extra actions from end of round effects
            // @Todo in the future we need to care more about the order in which end of turn effects take place
            for effect_kind, effect in gs.ongoing_active_effects {
                #partial switch timing in effect.timing {
                case End_Of_Round:
                    broadcast_game_event(gs, Remove_Active_Effect_Event{effect_kind})
                    action_index := timing.extra_action_index
                    action_index.card_id = effect.parent_card_id  // Very important do to this otherwise we get lost
                    become_interrupted (
                        gs,
                        effect.parent_card_id.owner_id,
                        action_index,
                        End_Of_Turn_Event{},
                    )
                    return
                }
            }
            broadcast_game_event(gs, Begin_Minion_Battle_Event{})
        }


    case Begin_Minion_Battle_Event:
        gs.stage = .MINION_BATTLE
        // Let the team captain choose which minions to delete
        // append(&gs.event_queue, End_Minion_Battle_Event{})

        if !gs.is_host do break

        minion_difference := gs.minion_counts[.RED] - gs.minion_counts[.BLUE]
        // pushing_team := .RED if minion_difference > 0 else .BLUE
        // pushed_team := get_enemy_team(pushing_team)
        if abs(minion_difference) > 0 {
            pushing_team: Team = .RED if minion_difference > 0 else .BLUE
            pushed_team := get_enemy_team(pushing_team)
            if abs(minion_difference) >= gs.minion_counts[pushed_team] {
                become_interrupted (
                    gs,
                    gs.my_player_id,
                    Wave_Push_Interrupt{pushing_team},
                    End_Minion_Battle_Event{},
                )
            } else {
                become_interrupted (
                    gs,
                    gs.team_captains[pushed_team],
                    Action_Index{sequence = .MINION_REMOVAL, index = 0},
                    End_Minion_Battle_Event{},
                )
            }
        } else {
            append(&gs.event_queue, End_Minion_Battle_Event{})
        }

    case End_Minion_Battle_Event:

        log.assert(gs.is_host, "Client should never reach here!!!!!")

        // Host only
        broadcast_game_event(gs, Begin_Upgrading_Event{})

    case Begin_Wave_Push_Event:
        // Check if game over

        // log.assert(is_host, "Client should never reach here!!!")

        gs.wave_counters -= 1

        prev_battle_zone := gs.current_battle_zone

        gs.current_battle_zone += Region_ID(1) if var.pushing_team == .RED else Region_ID(-1)

        if gs.wave_counters == 0 || gs.current_battle_zone == .RED_BASE || gs.current_battle_zone == .BLUE_BASE {
            // Win on base push or last push
            append(&gs.event_queue, Game_Over_Event{var.pushing_team})
            break
        }

        // Remove all minions in current battle zone
        for target in zone_indices[prev_battle_zone] {
            space := &gs.board[target.x][target.y]
            space.flags -= MINION_FLAGS
        }

        gs.minion_counts[.RED] = 0
        gs.minion_counts[.BLUE] = 0

        for &array in gs.blocked_spawns {
            clear(&array)
        }

        if !gs.is_host do break

        spawn_minions(gs, gs.current_battle_zone)

        append(&gs.event_queue, Resolve_Blocked_Minions_Event{gs.tiebreaker_coin}) 
    
    case Resolve_Blocked_Minions_Event:
        next_event: Event = Resolve_Blocked_Minions_Event{get_enemy_team(var.team)} if var.team == gs.tiebreaker_coin else End_Wave_Push_Event{}
        if len(gs.blocked_spawns[var.team]) > 0 {
            become_interrupted (
                gs,
                gs.team_captains[var.team],
                Action_Index{sequence = .MINION_SPAWN, index = 0},
                next_event,
            )
        } else {
            append(&gs.event_queue, next_event)
        }

    case End_Wave_Push_Event:

        log.assert(gs.is_host, "sometyhing sommethign client")
        broadcast_game_event(gs, Resolve_Interrupt_Event{})

    case Begin_Upgrading_Event:
        clear(&gs.ongoing_active_effects)
        retrieve_all_cards(gs)
        gs.upgraded_players = 0

        if get_my_player(gs).hero.coins < get_my_player(gs).hero.level {
            // log.infof("Pity coin collected. Current coin count: %v", get_my_player(gs).hero.coins)
            get_my_player(gs).hero.coins += 1
            broadcast_game_event(gs, End_Upgrading_Event{gs.my_player_id})
        } else {
            append(&gs.event_queue, Begin_Next_Upgrade_Event{})
        }

    case Begin_Next_Upgrade_Event:
        get_my_player(gs).stage = .UPGRADING
        clear_side_buttons(gs)
        gs.tooltip = "Choose a card to upgrade."
        if get_my_player(gs).hero.coins >= get_my_player(gs).hero.level {
            get_my_player(gs).hero.coins -= get_my_player(gs).hero.level
            get_my_player(gs).hero.level += 1
            log.infof("Player levelled up! Current level: %v", get_my_player(gs).hero.level)
        } else {
            broadcast_game_event(gs, End_Upgrading_Event{gs.my_player_id})
        }

    case End_Upgrading_Event:
        if var.player_id == gs.my_player_id {
            gs.tooltip = "Waiting for other players to finish upgrading."
        }
        gs.upgraded_players += 1

        if gs.upgraded_players == len(gs.players) {
            broadcast_game_event(gs, Update_Player_Data_Event{get_my_player(gs).base})
            gs.turn_counter = 0
            if gs.is_host {
                broadcast_game_event(gs, Begin_Card_Selection_Event{})
            }
        }

    case Game_Over_Event:
        // not too much fanfare here
        log.infof("%v team has won!", var.winning_team)
    }
}
