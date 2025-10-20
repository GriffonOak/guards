package guards

// This is a good file. It knows exactly what it is trying to do and does it extremely well.

import "core:reflect"
import sa "core:container/small_array"
import "core:log"
import "core:fmt"


Marker_Event :: struct {}

Join_Network_Game_Chosen_Event :: struct {}
Join_Local_Game_Chosen_Event :: struct {}
Host_Game_Chosen_Event :: struct {}

Update_Player_Data_Event :: struct {
    player_base: Player_Base,
}

Enter_Lobby_Event :: struct {}
Change_Hero_Event :: struct {
    player_id: Player_ID,
    hero_id: Hero_ID,
}
Change_Team_Event :: struct {
    player_id: Player_ID,
}
Begin_Game_Event :: struct {}

Space_Hovered_Event :: struct {
    space: Target,
}

Space_Clicked_Event :: struct {
    space: Target,
}

Card_Clicked_Event :: struct {
    card_id: Card_ID,
}



// Confirm_Event :: struct {}
Cancel_Event :: struct {}

Entity_Translocation_Event :: struct {
    src, dest: Target,
}

Entity_Swap_Event :: struct {
    target1, target2: Target,
}

Give_Marker_Event :: struct {
    player_id: Player_ID,
    marker: Marker,
}

Minion_Defeat_Event :: struct {
    target: Target,
    defeating_player: Player_ID,
}

Minion_Removal_Event :: struct {
    targets: [6]Target,
    num_targets: int,
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

Quantity_Chosen_Event :: struct {
    quantity: int,
}

Choice_Taken_Event :: struct {
    choice_index: int,
    jump_index: Action_Index,
}

Add_Global_Variable_Event :: struct {
    value: Action_Value,
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


Hero_Defeated_Event :: struct {
    defeated, defeater: Player_ID,
}

Hero_Respawn_Event :: struct {
    respawner: Player_ID,
    location: Target,
}

Add_Active_Effect_Event :: struct {
    from_action_index: Action_Index,
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
    Change_Team_Event,
    Begin_Game_Event,
    
    Space_Hovered_Event,
    Space_Clicked_Event,
    Card_Clicked_Event,
    // Confirm_Event,
    Cancel_Event,

    Entity_Translocation_Event,
    Entity_Swap_Event,

    Give_Marker_Event,

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

    Quantity_Chosen_Event,

    Choice_Taken_Event,

    Add_Global_Variable_Event,

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
        ip := string(sa.slice(&ip_text_box.field))
        switch error in join_game(gs, ip) {
        case Parse_Error: add_toast(gs, "Unable to parse IP address.", 2)
        case Dial_Error: add_toast(gs, "Could not connect to IP address.", 2)
        }

    case Host_Game_Chosen_Event:
        if begin_hosting_local_game(gs) {
            append(&gs.event_queue, Enter_Lobby_Event{})
        }

    case Update_Player_Data_Event:
        add_or_update_player(gs, var.player_base)

    case Enter_Lobby_Event:
        gs.stage = .In_Lobby
        clear(&gs.ui_stack[.Buttons])
        // button_loc := (Vec2{WIDTH, HEIGHT} - SELECTION_BUTTON_SIZE) / 2
        // if gs.is_host {
        //     gs.tooltip = "Wait for players to join, then begin the game."
        //     add_generic_button(gs, {button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, "Begin Game", Begin_Game_Event{}, global = true)
        // } else {
        //     gs.tooltip = "Wait for the host to begin the game."
        // }
        // button_loc.y += BUTTON_PADDING + SELECTION_BUTTON_SIZE.y
        // add_generic_button(gs, {button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, "Switch Team", Change_Team_Event{gs.my_player_id}, global = true)

        // button_loc := Vec2{WIDTH - SELECTION_BUTTON_SIZE.x - BUTTON_PADDING, TOOLTIP_FONT_SIZE + BUTTON_PADDING}
        // for hero in Hero_ID {
        //     log.infof("adding button")
        //     hero_name, _ := reflect.enum_name_from_value(hero)
        //     hero_name_cstring := strings.unsafe_string_to_cstring(hero_name)
        //     add_generic_button(gs, {button_loc.x, button_loc.y, SELECTION_BUTTON_SIZE.x, SELECTION_BUTTON_SIZE.y}, hero_name_cstring, Change_Hero_Event{gs.my_player_id, hero}, global=true)
        //     button_loc.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING
        // }

    case Change_Team_Event:
        player := get_player_by_id(gs, var.player_id)
        player.team = .Red if player.team == .Blue else .Blue

    case Change_Hero_Event:
        log.assert(gs.stage == .In_Lobby, "Tried to change hero outside of lobby!")
        player := get_player_by_id(gs, var.player_id)
        player.hero.id = var.hero_id

    case Begin_Game_Event:
        gs.current_battle_zone = .Centre
        gs.wave_counters = 5
        gs.life_counters[.Red] = 6
        gs.life_counters[.Blue] = 6

        spawn_heroes_at_start(gs)

        setup_hero_cards(gs)

        setup_icons()

        if gs.is_host {
            // tiebreaker: Team = .Red if rand.int31_max(2) == 0 else .Blue
            tiebreaker: Team = .Red
            broadcast_game_event(gs, Update_Tiebreaker_Event{tiebreaker})
            spawn_minions(gs, gs.current_battle_zone)
        }

        captains_assigned: [Team]bool
        for player in gs.players {
            if !captains_assigned[player.team] {
                gs.team_captains[player.team] = player.id
            }
        }

        add_game_ui_elements(gs)

        append(&gs.event_queue, Begin_Card_Selection_Event{})

    case Space_Hovered_Event:
        #partial switch get_my_player(gs).stage {
        case .Resolving, .Interrupting:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                path := get_top_action_value_of_type(gs, Path)
                resize(&path.spaces, path.num_locked_spaces)

                if var.space == INVALID_TARGET do break
                if !action.targets[var.space.x][var.space.y].member do break

                starting_space := path.spaces[path.num_locked_spaces - 1]

                current_space := var.space
                for ; current_space != starting_space; current_space = {action.targets[current_space.x][current_space.y].prev_x, action.targets[current_space.x][current_space.y].prev_y} {
                    inject_at(&path.spaces, path.num_locked_spaces, current_space)
                }
            }
        }

    case Space_Clicked_Event:
        #partial switch get_my_player(gs).stage {
        case .Resolving, .Interrupting:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)

            if !action.targets[var.space.x][var.space.y].member do break

            #partial switch &action_variant in action.variant {
            case Fast_Travel_Action:
                add_action_value(gs, var.space)
                append(&gs.event_queue, Resolve_Current_Action_Event{})

            case Movement_Action:
                path := get_top_action_value_of_type(gs, Path)
                if len(path.spaces) == path.num_locked_spaces do break
                path.num_locked_spaces = len(path.spaces)
                append(&gs.event_queue, Begin_Next_Action_Event{})

            case Choose_Target_Action:
                num_targets := calculate_implicit_quantity(gs, action_variant.num_targets, {card_id = action_index.card_id})
                current_slice := get_memory_slice_for_index(gs, action_index, gs.action_count)
                if len(current_slice) < num_targets {
                    add_action_value(gs, var.space, label = action_variant.label)
                    action.targets[var.space.x][var.space.y].member = false
                    if len(current_slice) + 1 == num_targets && !(.Up_To in action_variant.flags) {
                        append(&gs.event_queue, Resolve_Current_Action_Event{})
                    } else if len(current_slice) == 0 {
                        add_side_button(gs, "Cancel", Cancel_Event{})
                    }
                }

            case Choose_Dead_Minion_Type_Action:
                my_team := get_my_player(gs).team
                for minion_type, index in gs.dead_minions[my_team] {
                    dead_minion_target := dead_minion_target_indices[index]
                    if my_team == .Blue do dead_minion_target = {GRID_WIDTH-1, GRID_HEIGHT-1} - dead_minion_target
                    if var.space == dead_minion_target {
                        add_action_value(gs, Chosen_Minion_Type{minion_type})
                        append(&gs.event_queue, Resolve_Current_Action_Event{})
                        break
                    }
                }
            }
        }

    case Card_Clicked_Event:
        card_id := var.card_id
        card, card_ok := get_card_by_id(gs, card_id)

        #partial switch get_my_player(gs).stage {
        case .Selecting:
            log.assert(card_ok, "Card element clicked with no card associated!")
            #partial switch card.state {
            case .In_Hand:
                element, _ := find_element_for_card(gs, card_id)
                log.assert(element != nil, "Could not find element for card!")
                card_element := assert_variant(&element.variant, UI_Card_Element)

                if selected_element, ok2 := find_selected_card_element(gs); ok2 {
                    selected_card_element := &selected_element.variant.(UI_Card_Element)
                    selected_card_element.selected = false
                    clear_side_buttons(gs)
                }

                card_element.selected = true
                add_side_button(gs, "Confirm card", Card_Confirmed_Event{gs.my_player_id, card_id}, global=true)
            }

        case .Upgrading:
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
                pop(&gs.ui_stack[.Cards])
                pop(&gs.ui_stack[.Cards])
                clear_side_buttons(gs)

                // Complete the upgrade
                append(&gs.event_queue, Begin_Next_Upgrade_Event{})
            } else {
                #partial switch card.state {
                case .In_Hand:
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
                    top_element := gs.ui_stack[.Cards][len(gs.ui_stack[.Cards]) - 1]
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
                        append(&gs.ui_stack[.Cards], UI_Element {
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
        case .Resolving, .Interrupting:
            action := get_current_action(gs)
            #partial switch &variant in action.variant {
            case Choose_Card_Action:
                if card_id in variant.card_targets {
                    add_action_value(gs, card_id)
                    append(&gs.event_queue, Resolve_Current_Action_Event{})
                    break
                }
            }
        }

    case Cancel_Event:
        #partial switch get_my_player(gs).stage {
        case .Resolving, .Interrupting:
            action_index := get_my_player(gs).hero.current_action_index
            action := get_action_at_index(gs, action_index)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                path := get_top_action_value_of_type(gs, Path)
                path.num_locked_spaces = 1
                resize(&path.spaces, 1)
                append(&gs.event_queue, Begin_Next_Action_Event{})

            case Choose_Target_Action:
                log.assert(len(gs.side_button_manager.buttons) > 0, "No side buttons!?")
                top_button := gs.side_button_manager.buttons[len(gs.side_button_manager.buttons) - 1].variant.(UI_Button_Element)
                if _, ok := top_button.event.(Cancel_Event); ok {
                    pop_side_button(gs)
                }
                results := get_memory_slice_for_index(gs, action_index, gs.action_count)
                for value in results {
                    target := value.variant.(Target)
                    action.targets[target.x][target.y].member = true
                }
                clear_top_memory_slice(gs)
            }

        case .Upgrading:
            pop(&gs.ui_stack[.Cards])
            pop(&gs.ui_stack[.Cards])
            clear_side_buttons(gs)
        }

    case Entity_Translocation_Event:
        src_space := &gs.board[var.src.x][var.src.y]
        dest_space := &gs.board[var.dest.x][var.dest.y]

        src_transient_flags := src_space.flags - PERMANENT_FLAGS
        
        if .Hero in src_transient_flags {
            get_player_by_id(gs, src_space.owner).hero.location = var.dest
        }

        src_space.flags -= src_transient_flags
        dest_space.flags += src_transient_flags

        dest_space.transient = src_space.transient

        for &value in gs.action_memory {
            if target, ok := &value.variant.(Target); ok && target^ == var.src {
                target^ = var.dest
            }
        }

    case Entity_Swap_Event:
        target1_space := &gs.board[var.target1.x][var.target1.y]
        target2_space := &gs.board[var.target2.x][var.target2.y]

        target1_transient_flags := target1_space.flags - PERMANENT_FLAGS
        target2_transient_flags := target2_space.flags - PERMANENT_FLAGS

        // Relocate heroes
        if .Hero in target1_transient_flags {
            get_player_by_id(gs, target1_space.owner).hero.location = var.target2
        }
        if .Hero in target2_transient_flags {
            get_player_by_id(gs, target2_space.owner).hero.location = var.target1
        }

        // Swap flags
        target1_space.flags -= target1_transient_flags
        target2_space.flags -= target2_transient_flags
        target1_space.flags += target2_transient_flags
        target2_space.flags += target1_transient_flags

        // Swap transients
        target1_space.transient, target2_space.transient = target2_space.transient, target1_space.transient

        for &value in gs.action_memory {
            if target, ok := &value.variant.(Target); ok {
                if target^ == var.target1 {
                    target^ = var.target2
                } else if target^ == var.target2 {
                    target^ = var.target1
                }
            }
        }

    case Give_Marker_Event:

        // We loop over all players like this so that if someone else has the marker,
        // It gets transferred to the new player (there can only be 1 marker in play)
        for &player, player_id in gs.players {
            if player_id == var.player_id {
                player.hero.markers += {var.marker}
            } else {
                player.hero.markers -= {var.marker}
            }
        }

    case Minion_Defeat_Event:
        space := &gs.board[var.target.x][var.target.y]
        minion := space.flags & MINION_FLAGS
        log.assert(space.flags & MINION_FLAGS != {}, "Tried to defeat a minion in a space with no minions!")
        minion_team := space.unit_team

        if .Heavy_Minion in minion {
            log.assert(gs.minion_counts[minion_team] == 1, "Heavy minion defeated with an invalid number of minions left!")
            get_player_by_id(gs, var.defeating_player).hero.coins += 4
        } else {
            get_player_by_id(gs, var.defeating_player).hero.coins += 2
        }

        // Swift farm
        for _, effect in gs.ongoing_active_effects {
            effect_calc_context := Calculation_Context{target = var.target, card_id = effect.parent_card_id}
            if !effect_timing_valid(gs, effect.timing, effect_calc_context) do continue
            for outcome in effect.outcomes {
                if _, ok := outcome.(Gain_Extra_Coins_On_Defeat); !ok do continue
                if !calculate_implicit_condition(gs, And(effect.affected_targets), effect_calc_context) do continue
                swift_coin_count := &get_top_global_variable_by_label(gs, .Swift_Farm_Defeat_Count).variant.(Saved_Integer)
                swift_coin_count.integer += 1
                owner := get_player_by_id(gs, effect.parent_card_id.owner_id)
                owner.hero.coins += 1
            }
        }

        if gs.my_player_id == var.defeating_player {
            removal_event: Minion_Removal_Event
            removal_event.targets[0] = var.target
            removal_event.num_targets = 1
            removal_event.removing_player = var.defeating_player

            interrupted: bool
            check_for_interrupt: for _, effect in gs.ongoing_active_effects {
                effect_calc_context := Calculation_Context{target = var.target, card_id = effect.parent_card_id}
                if !effect_timing_valid(gs, effect.timing, effect_calc_context) do continue
                for outcome in effect.outcomes {
                    interrupt_defeat, ok := outcome.(Interrupt_On_Defeat)
                    if !ok do continue
                    if !calculate_implicit_condition(gs, And(effect.affected_targets), effect_calc_context) do continue
                    interrupted = true
                    jump_index := interrupt_defeat.interrupt_index
                    if jump_index.card_id == {} do jump_index.card_id = effect.parent_card_id
                    owner_id := effect.parent_card_id.owner_id
                    become_interrupted(gs, owner_id, jump_index, removal_event, global_resolution = true)
                    break check_for_interrupt
                }
            }
            if !interrupted {
                broadcast_game_event(gs, removal_event)
            }
        }

    case Minion_Removal_Event:
        minions: for target_index in 0..<var.num_targets {
            for var, index in gs.global_memory {
                if var.label == .Brogan_Prevent_Next_Minion_Removal {
                    unordered_remove(&gs.global_memory, index)
                    continue minions
                }
            }
            target := var.targets[target_index]
            space := &gs.board[target.x][target.y]
            log.assert(space.flags & MINION_FLAGS != {}, "Tried to remove a minion from a space with no minions!")
            minion_team := space.unit_team
            log.assert(gs.minion_counts[minion_team] > 0, "Removing a minion but the game state claims there are 0 minions")
            minion_flags := space.flags & MINION_FLAGS 
            minion_type := get_first_set_bit(minion_flags).?
            space.flags -= MINION_FLAGS
    
            gs.minion_counts[minion_team] -= 1
            append(&gs.dead_minions[minion_team], minion_type)
    
            log.infof("Minion removed, new counts: %v", gs.minion_counts)

            if gs.minion_counts[minion_team] == 1 {
                // Remove heavy minion immunity
                zone := zone_indices[gs.current_battle_zone]
                for zone_target in zone {
                    zone_space := &gs.board[zone_target.x][zone_target.y]
                    if zone_space.flags & {.Heavy_Minion} != {} && zone_space.unit_team == minion_team {
                        zone_space.flags -= {.Immune}
                    }
                }
            }
        }

        if var.removing_player == gs.my_player_id {
            my_player := get_my_player(gs)
            // @Note: Here we assume we only remove enemy minions.
            // If we somehow remove the heavy minion on our own team, an interrupt will not trigger.
            if gs.minion_counts[get_enemy_team(my_player.team)] == 0 {
                become_interrupted (
                    gs,
                    0,  // Host ID
                    Wave_Push_Interrupt{my_player.team},
                    Resolve_Current_Action_Event{},
                )
            } else {
                append(&gs.event_queue, Resolve_Current_Action_Event{})
            }
        }


    case Minion_Spawn_Event:
        space := &gs.board[var.target.x][var.target.y]
        space.flags -= {.Token}
        space.flags += {var.minion_type}
        if var.minion_type == .Heavy_Minion {
            space.flags += {.Immune}
        }
        space.unit_team = var.team

        gs.minion_counts[var.team] += 1
        #reverse for minion_type, index in gs.dead_minions[var.team] {
            if minion_type == var.minion_type {
                ordered_remove(&gs.dead_minions[var.team], index)
                break
            }
        }

    case Minion_Blocked_Event:
        space := &gs.board[var.target.x][var.target.y]
        log.assert(space.flags & (SPAWNPOINT_FLAGS - {.Hero_Spawnpoint}) != {}, "Minion spawn blocked at non-spawnpoint!")
        append(&gs.blocked_spawns[space.spawnpoint_team], var.target)

    case Hero_Defeated_Event:

        // @Todo: remove active effects on death
        defeated := get_player_by_id(gs, var.defeated)
        defeated_hero := &defeated.hero
        defeated_hero.dead = true
        defeater := get_player_by_id(gs, var.defeater)
        gs.heroes_defeated_this_round += 1

        if defeated_card, ok := find_played_card(gs, var.defeated); ok {
            if var.defeated == gs.my_player_id && len(gs.interrupt_stack) > 0 {
                gs.interrupt_stack[0].previous_stage = .Resolved
            } else { 
                defeated.stage = .Resolved
            }
            resolve_card(gs, defeated_card)
        }        

        gs.board[defeated_hero.location.x][defeated_hero.location.y].flags -= {.Hero}

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
        gs.board[var.location.x][var.location.y].flags += {.Hero}
        gs.board[var.location.x][var.location.y].hero_id = player.hero.id
        gs.board[var.location.x][var.location.y].unit_team = player.team
        gs.board[var.location.x][var.location.y].owner = var.respawner

    case Add_Active_Effect_Event:

        action := get_action_at_index(gs, var.from_action_index)
        active_effect_action := action.variant.(Add_Active_Effect_Action)
        effect := active_effect_action.effect
        effect.parent_card_id = var.from_action_index.card_id

        log.infof("Adding active effect: %v", effect.kind)
        gs.ongoing_active_effects[effect.kind] = effect

    case Remove_Active_Effect_Event:
        delete_key(&gs.ongoing_active_effects, var.effect_kind)

    case Quantity_Chosen_Event:
        // action := get_current_action(gs)
        // choose_quantity_action := &action.variant.(Choose_Quantity_Action)
        // cqa.result = var.quantity
        add_action_value(gs, Chosen_Quantity{var.quantity})
        append(&gs.event_queue, Resolve_Current_Action_Event{})

    case Choice_Taken_Event:
        action_index := get_my_player(gs).hero.current_action_index
        action := get_action_at_index(gs, action_index)
        choice_action := action.variant.(Choice_Action)
        if choice_action.cannot_repeat do add_action_value(gs, Choice_Taken{var.choice_index}, index = action_index)
        append(&gs.event_queue, Resolve_Current_Action_Event{var.jump_index})

    case Add_Global_Variable_Event:
        append(&gs.global_memory, var.value)

    case Begin_Interrupt_Event:
        interrupt := var.interrupt
        if interrupt.interrupted_player != gs.my_player_id {  // The interruptee should already have added to their own interrupt stack in become_interrupted
            previous_stage := get_my_player(gs).stage         // Therefore we only add an interrupt to the stack if we are not the interuuptee
            expanded_interrupt := Expanded_Interrupt {
                interrupt = interrupt,
                previous_stage = previous_stage,
                previous_action_index = get_my_player(gs).hero.current_action_index,
            }
            append(&gs.interrupt_stack, expanded_interrupt)
        }

        if interrupt.interrupting_player == gs.my_player_id {
            get_my_player(gs).stage = .Interrupting

            switch &interrupt_variant in gs.interrupt_stack[len(gs.interrupt_stack) - 1].interrupt.variant {
            case Action_Index:
                get_my_player(gs).hero.current_action_index = interrupt_variant
                append(&gs.event_queue, Begin_Next_Action_Event{})
            case Wave_Push_Interrupt:
                broadcast_game_event(gs, Begin_Wave_Push_Event{interrupt_variant.pushing_team})
            case Attack_Interrupt:
                get_my_player(gs).hero.current_action_index = {sequence = .Basic_Defense, index = 0}
                append(&gs.event_queue, Begin_Next_Action_Event{})
            }
        } else {
            get_my_player(gs).stage = .Interrupted
        }

    case Resolve_Interrupt_Event:
        log.assert(len(gs.interrupt_stack) > 0, "Interrupt resolved with no interrupt on the stack!")
        most_recent_interrupt := pop(&gs.interrupt_stack)
        get_my_player(gs).stage = most_recent_interrupt.previous_stage
        get_my_player(gs).hero.current_action_index = most_recent_interrupt.previous_action_index
        if most_recent_interrupt.interrupt.interrupted_player == gs.my_player_id {
            if most_recent_interrupt.global_resolution {
                broadcast_game_event(gs, most_recent_interrupt.on_resolution)
            } else {
                append(&gs.event_queue, most_recent_interrupt.on_resolution)
            }
        }

    case Update_Tiebreaker_Event:
        gs.tiebreaker_coin = var.tiebreaker
        
    case Begin_Card_Selection_Event:
        for &player in gs.players {
            player.stage = .Selecting
        }
        gs.stage = .Selection
        gs.confirmed_players = 0
        gs.tooltip = "Choose a card to play and then confirm it."

        // Streamline card selection if player has 0 or 1 cards
        hand_card_count := 0
        hand_card: Maybe(Card_ID) = nil

        for card in get_my_player(gs).hero.cards {
            if card.state == .In_Hand {
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
        player.stage = .Confirmed
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
        gs.stage = .Resolution

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
        team_captain := gs.team_captains[var.team]
        if var.team == get_my_player(gs).team && gs.my_player_id == team_captain {
            gs.tooltip = "Tied initiative: Choose which player on your team acts first."
            for tied_id, index in var.tied_player_ids {
                if index == var.num_ties do break
                add_side_button(gs, get_username(gs, tied_id), Begin_Player_Resolution_Event{tied_id}, global = true)
            }
        } else {
            gs.tooltip = "Waiting for the team captain to resolve tied initiative."
        }

    case Begin_Player_Resolution_Event:
        gs.players[var.player_id].stage = .Resolving
        gs.tooltip = "Waiting for other players to resolve their cards."
        clear_side_buttons(gs)
        if var.player_id != gs.my_player_id do break

        gs.action_count = 0

        // Find the played card
        card, ok := find_played_card(gs)
        log.assert(ok, "No played card when player begins their resolution!")

        get_my_player(gs).hero.current_action_index = {card_id = card.id, sequence=.First_Choice}

        if get_my_player(gs).hero.dead {
            become_interrupted (
                gs,
                gs.my_player_id,
                Action_Index{sequence = .Respawn, index = 0},
                Begin_Next_Action_Event{},
            )
            break
        }

        append(&gs.event_queue, Begin_Next_Action_Event{})

    case Begin_Next_Action_Event:

        gs.action_count += 1

        action_index := get_my_player(gs).hero.current_action_index
        action := get_action_at_index(gs, action_index)

        if action == nil || (get_my_player(gs).hero.dead && action_index.sequence != .Respawn) {  // Didn't respawn bozo
            end_current_action_sequence(gs)
            break
        }
        
        calc_context := Calculation_Context{card_id = action_index.card_id}
        optional := calculate_implicit_condition(gs, action.optional)

        skip_index := action.skip_index
        if skip_index == {} do skip_index = {sequence = .Halt}
    
        gs.tooltip = action.tooltip
        log.infof("ACTION: %v", reflect.union_variant_typeid(action.variant))

        clear_side_buttons(gs)
        if !validate_action(gs, action_index) {
            append(&gs.event_queue, Resolve_Current_Action_Event{skip_index})
            break
        }

        if optional {
            add_side_button(gs, "Skip" if action.skip_name == nil else action.skip_name, Resolve_Current_Action_Event{skip_index})
        }

        switch &action_type in action.variant {
        case Movement_Action:
            add_side_button(gs, "Reset move", Cancel_Event{})

            path := get_top_action_value_of_type(gs, Path)
            top_space := path.spaces[len(path.spaces) - 1]
            target_valid := !action.targets[top_space.x][top_space.y].invalid
            if target_valid {
                add_side_button(gs, "Confirm move", Resolve_Current_Action_Event{})
            }

        case Choose_Target_Action:
            if .Up_To in action_type.flags {
                add_side_button(gs, "Confirm", Resolve_Current_Action_Event{})
            } else if count_members(&action.targets) == calculate_implicit_quantity(gs, action_type.num_targets, calc_context) && !optional {
                iter := make_target_set_iterator(&action.targets)
                for _, space in target_set_iter_members(&iter) {
                    add_action_value(gs, space, label = action_type.label)
                }
                append(&gs.event_queue, Resolve_Current_Action_Event{})
            }

        case Choice_Action:
            choices_added: int
            event: Choice_Taken_Event

            for choice, choice_index in action_type.choices {
                if choice.valid {
                    jump_index := choice.jump_index
                    if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
                    event = Choice_Taken_Event{choice_index, jump_index}
                    add_side_button(gs, choice.name, event)
                    choices_added += 1
                }
            }

            if choices_added == 1 {
                append(&gs.event_queue, event)
            }

        case Choose_Quantity_Action:
            lower_bound := calculate_implicit_quantity(gs, action_type.bounds[0], calc_context)
            upper_bound := calculate_implicit_quantity(gs, action_type.bounds[1], calc_context)
            if upper_bound == lower_bound {
                append(&gs.event_queue, Quantity_Chosen_Event{lower_bound})
                break
            }
            for quantity in lower_bound..=upper_bound {
                add_side_button(gs, number_names[quantity], Quantity_Chosen_Event{quantity})
            }

        case Push_Action:
            origin := calculate_implicit_target(gs, action_type.origin, calc_context)
            targets := calculate_implicit_target_slice(gs, action_type.targets, calc_context)
            num_spaces := calculate_implicit_quantity(gs, action_type.num_spaces, calc_context)

            for target in targets {
                calc_context.target = target
                // This shouldn't really happen
                if !calculate_implicit_condition(gs, Target_In_Straight_Line_With{origin}, calc_context) {
                    log.info("Invalid push????")
                    continue
                }
                
                direction := get_norm_direction(origin, target)
                latest_valid_target := target
                for _ in 0..<num_spaces {
                    next_target := latest_valid_target + direction
                    if target_contains_any(gs, next_target, OBSTACLE_FLAGS) do break
                    latest_valid_target = next_target
                }
    
                broadcast_game_event(gs, Entity_Translocation_Event{target, latest_valid_target})
            }
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Attack_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            space := &gs.board[target.x][target.y]
            card_data, ok := get_card_data_by_id(gs, action_index.card_id)
            log.assert(ok, "Could not get data for attacker's card!!")
            attack_strength := calculate_implicit_quantity(gs, action_type.strength, calc_context)
            log.infof("Attack strength: %v", attack_strength)
            // Here we assume the target must be an enemy. Enemy should always be in the selection flags for attacks.
            if MINION_FLAGS & space.flags != {} {
                broadcast_game_event(gs, Minion_Defeat_Event{target, gs.my_player_id})
            } else {
                owner := space.owner
                become_interrupted (
                    gs,
                    owner,
                    Attack_Interrupt {
                        strength = attack_strength,
                        flags = action_type.flags + ({.Ranged} if card_data.values[.Range] > 0 else {}),
                    },
                    Resolve_Current_Action_Event{},
                )
            }

        case Force_Discard_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            space := gs.board[target.x][target.y]
            log.assert(.Hero in space.flags, "Forced a space without a hero to discard!")
            owner := space.owner
            become_interrupted (
                gs,
                owner,
                Action_Index{sequence = .Discard_If_Able} if !action_type.or_is_defeated else Action_Index{sequence = .Discard_Or_Die},
                Resolve_Current_Action_Event{},
            )
        
        case Add_Active_Effect_Action:
            broadcast_game_event(gs, Add_Active_Effect_Event{action_index})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Halt_Action:
            end_current_action_sequence(gs)

        case Minion_Defeat_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            broadcast_game_event(gs, Minion_Defeat_Event{target, gs.my_player_id})

        case Minion_Removal_Action:
            minions_to_remove := calculate_implicit_target_slice(gs, action_type.targets)
            removal_event: Minion_Removal_Event
            removal_event.num_targets = len(minions_to_remove)
            removal_event.removing_player = gs.my_player_id
            for target, index in minions_to_remove {
                removal_event.targets[index] = target
            }
            broadcast_game_event(gs, removal_event)
            
        case Jump_Action:
            jump_index := calculate_implicit_action_index(gs, action_type.jump_index, calc_context)
            // jump_index.card_id = action_index.card_id
            append(&gs.event_queue, Resolve_Current_Action_Event{jump_index})

        case Repeat_Action:
            repeat_count, _, ok := try_get_top_action_value_of_type(gs, Repeat_Count)
            if !ok {
                add_action_value(gs, Repeat_Count{1})
            } else {
                repeat_count.count += 1
            }
            jump_index := action_index
            jump_index.index = 0
            append(&gs.event_queue, Resolve_Current_Action_Event{jump_index})
            
        case Minion_Spawn_Action:
            target := calculate_implicit_target(gs, action_type.location, calc_context)
            minion_type := calculate_implicit_space_flag(gs, action_type.minion_type, calc_context)

            my_team := get_my_player(gs).team
            if len(gs.blocked_spawns[my_team]) > 0 {
                pop(&gs.blocked_spawns[my_team])
            }

            broadcast_game_event(gs, Minion_Spawn_Event{target, minion_type, my_team})
            append(&gs.event_queue, Resolve_Current_Action_Event{})
            
        case Discard_Card_Action:
            card_id := calculate_implicit_card_id(gs, action_type.card)
            broadcast_game_event(gs, Card_Discarded_Event{card_id})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Defend_Action:
            can_defend := calculate_implicit_condition(gs, Card_Can_Defend{}, calc_context)
            if can_defend do append(&gs.event_queue, Resolve_Current_Action_Event{})
            else do append(&gs.event_queue, Resolve_Current_Action_Event{Action_Index{sequence = .Die}})            

        case Retrieve_Card_Action:
            card_id := calculate_implicit_card_id(gs, action_type.card)
            broadcast_game_event(gs, Card_Retrieved_Event{card_id})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Gain_Coins_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            gain := calculate_implicit_quantity(gs, action_type.gain, calc_context)

            space := &gs.board[target.x][target.y]
            log.assert(.Hero in space.flags, "Tried to give coins to a space without a hero!")

            player_base := get_player_by_id(gs, space.owner).base
            player_base.hero.coins += gain
            broadcast_game_event(gs, Update_Player_Data_Event{player_base})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

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

        case Place_Action:
            source := calculate_implicit_target(gs, action_type.source, calc_context)
            destination := calculate_implicit_target(gs, action_type.destination, calc_context)
            broadcast_game_event(gs, Entity_Translocation_Event{source, destination})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Swap_Action:
            targets := calculate_implicit_target_slice(gs, action_type.targets, calc_context)
            log.assert(len(targets) == 2, "Attempted to swap with incorrect number of targets!!!")

            broadcast_game_event(gs, Entity_Swap_Event{targets[0], targets[1]})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Give_Marker_Action:
            target := calculate_implicit_target(gs, action_type.target, calc_context)
            owner := gs.board[target.x][target.y].owner
            broadcast_game_event(gs, Give_Marker_Event{owner, action_type.marker})
            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Save_Variable_Action:
            switch variable in action_type.variable {
            case Implicit_Condition:
                boolean := calculate_implicit_condition(gs, variable, calc_context)
                add_action_value(gs, Saved_Boolean{boolean}, label = action_type.label, global = action_type.global)
            case Implicit_Quantity:
                integer := calculate_implicit_quantity(gs, variable, calc_context)
                add_action_value(gs, Saved_Integer{integer}, label = action_type.label, global = action_type.global)
            case:
                add_action_value(gs, nil, label = action_type.label, global = action_type.global)
            }

            append(&gs.event_queue, Resolve_Current_Action_Event{})

        case Choose_Dead_Minion_Type_Action:
            my_team := get_my_player(gs).team
            log.assert(len(gs.dead_minions[my_team]) > 0, "Cannot choose a dead minion type with no dead minions!") 
            more_than_one_type := false
            for minion_type in gs.dead_minions[my_team] {
                if minion_type != gs.dead_minions[my_team][0] {
                    more_than_one_type = true
                    break
                }
            }
            if !more_than_one_type {
                add_action_value(gs, Chosen_Minion_Type{gs.dead_minions[my_team][0]})
                append(&gs.event_queue, Resolve_Current_Action_Event{})
            }

        case Gain_Item_Action:
            my_player := get_my_player(gs)
            my_hero := &my_player.hero
            card_id := calculate_implicit_card_id(gs, action_type.card_id)
            my_hero.items[my_hero.item_count] = card_id
            my_hero.item_count += 1
            broadcast_game_event(gs, Update_Player_Data_Event{})
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
            result := get_top_action_value_of_type(gs, Target)
            broadcast_game_event(gs, Entity_Translocation_Event{get_my_player(gs).hero.location, result^})
        case Movement_Action:
            path := get_top_action_value_of_type(gs, Path)
            defer {
                delete(path.spaces)
                path.spaces = nil
                path.num_locked_spaces = 0
            }
            if _, ok := var.jump_index.?; ok do break  // Movement Skipped
            for space in path.spaces {
                // Stuff that happens on move through goes here
                log.debugf("Traversed_space: %v", space)
            }

            starting_space := path.spaces[0]
            ending_space := path.spaces[len(path.spaces) - 1]
            broadcast_game_event(gs, Entity_Translocation_Event{starting_space, ending_space})
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

        if get_action_at_index(gs, next_index) == nil {
            next_index.sequence = .Halt
        }

        get_my_player(gs).hero.current_action_index = next_index

        append(&gs.event_queue, Begin_Next_Action_Event{})

    case End_Resolution_Event:
        clear_side_buttons(gs)
        clear(&gs.action_memory)
        gs.action_count = 0

        gs.players[var.player_id].stage = .Resolved

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
            if region_id == .None || region_id == gs.current_battle_zone do continue
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
                Action_Index{sequence = .Minion_Outside_Zone, index = 0},
                Check_Minions_Outside_Zone_Event{},
            )
        } else if non_tb_team := get_enemy_team(gs.tiebreaker_coin); needs_interrupt[non_tb_team] {
            become_interrupted (
                gs,
                gs.team_captains[non_tb_team],
                Action_Index{sequence = .Minion_Outside_Zone, index = 0},
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

        if gs.turn_counter < 4 {  // @Magic (?)
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
        gs.stage = .Minion_Battle

        if !gs.is_host do break

        minion_difference := gs.minion_counts[.Red] - gs.minion_counts[.Blue]
        // pushing_team := .Red if minion_difference > 0 else .Blue
        // pushed_team := get_enemy_team(pushing_team)
        if abs(minion_difference) > 0 {
            pushing_team: Team = .Red if minion_difference > 0 else .Blue
            pushed_team := get_enemy_team(pushing_team)
            if abs(minion_difference) >= gs.minion_counts[pushed_team] {
                become_interrupted (
                    gs,
                    gs.my_player_id,
                    Wave_Push_Interrupt{pushing_team},
                    Begin_Upgrading_Event{},
                    global_resolution = true,
                )
            } else {
                become_interrupted (
                    gs,
                    gs.team_captains[pushed_team],
                    Action_Index{sequence = .Minion_Removal},
                    Begin_Upgrading_Event{},
                    global_resolution = true,
                )
            }
        } else {
            broadcast_game_event(gs, Begin_Upgrading_Event{})
        }

    case Begin_Wave_Push_Event:
        // Check if game over

        // log.assert(is_host, "Client should never reach here!!!")

        gs.wave_counters -= 1

        prev_battle_zone := gs.current_battle_zone

        gs.current_battle_zone += Region_ID(1) if var.pushing_team == .Red else Region_ID(-1)

        if gs.wave_counters == 0 || gs.current_battle_zone == .Red_Throne || gs.current_battle_zone == .Blue_Throne {
            // Win on base push or last push
            append(&gs.event_queue, Game_Over_Event{var.pushing_team})
            break
        }

        // Remove all minions in current battle zone
        for target in zone_indices[prev_battle_zone] {
            space := &gs.board[target.x][target.y]
            space.flags -= MINION_FLAGS
        }

        for team in Team {
            gs.minion_counts[team] = 0
            clear(&gs.dead_minions[team])
        }

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
                Action_Index{sequence = .Minion_Spawn, index = 0},
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
        clear(&gs.global_memory)

        // Return markers
        for &player in gs.players {
            player.hero.markers = {}
        }

        // Remove all tokens
        for &arr in gs.board {
            for &space in arr {
                space.flags -= {.Token}
            }
        }

        retrieve_all_cards(gs)
        gs.upgraded_players = 0

        my_player := get_my_player(gs)
        my_hero := &my_player.hero

        if my_hero.coins < my_hero.level || my_hero.level == 8 {
            // log.infof("Pity coin collected. Current coin count: %v", get_my_player(gs).hero.coins)
            my_hero.coins += 1
            broadcast_game_event(gs, End_Upgrading_Event{gs.my_player_id})
        } else {
            append(&gs.event_queue, Begin_Next_Upgrade_Event{})
        }

    case Begin_Next_Upgrade_Event:
        my_player := get_my_player(gs)
        my_hero := &my_player.hero

        my_player.stage = .Upgrading
        clear_side_buttons(gs)
        gs.tooltip = "Choose a card to upgrade."
        if my_hero.coins >= get_my_player(gs).hero.level && my_hero.level < 8 {
            my_hero.coins -= my_hero.level
            my_hero.level += 1
            log.infof("Player levelled up! Current level: %v", get_my_player(gs).hero.level)
        } else {
            broadcast_game_event(gs, End_Upgrading_Event{gs.my_player_id})
        }

    case End_Upgrading_Event:

        gs.players[var.player_id].stage = .Upgraded

        if var.player_id == gs.my_player_id {
            gs.tooltip = "Waiting for other players to finish upgrading."
        }
        gs.upgraded_players += 1

        if gs.upgraded_players == len(gs.players) {
            broadcast_game_event(gs, Update_Player_Data_Event{get_my_player(gs).base})
            gs.turn_counter = 0
            gs.heroes_defeated_this_round = 0
            if gs.is_host {
                broadcast_game_event(gs, Begin_Card_Selection_Event{})
            }
        }

    case Game_Over_Event:
        // not too much fanfare here
        log.infof("%v team has won!", var.winning_team)
        game_over_string := fmt.aprintf("%v team has won!", var.winning_team)
        add_toast(gs, game_over_string, 10)
        gs.game_over = true
    }
}
