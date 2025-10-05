package guards

import "base:intrinsics"
// import "core:fmt"

import "core:log"



breakpoint :: proc() {
    // x: int
    // x += 0
}

assert_variant :: proc(u: ^$U, $V: typeid, loc := #caller_location) -> ^V where intrinsics.type_is_union(U) && intrinsics.type_is_variant_of(U, V) {
    out, ok := &u.(V)
    log.assertf(ok, "Type assertion failed: %v to %v", u, typeid_of(V), loc = loc)
    return out
}

assert_variant_rdonly :: proc(u: $U, $V: typeid, loc := #caller_location) -> V where intrinsics.type_is_union(U) && intrinsics.type_is_variant_of(U, V) {
    out, ok := u.(V)
    log.assertf(ok, "Type assertion failed: %v to %v", u, typeid_of(V), loc = loc)
    return out
}

find_played_card :: proc(gs: ^Game_State, player_id: Player_ID = -1, loc := #caller_location) -> (^Card, bool) {
    player_id := player_id
    if player_id == -1 do player_id = gs.my_player_id
    player := get_player_by_id(gs, player_id)
    for &card in player.hero.cards {
        if card.state == .Played {
            return &card, true
        }
    }
    return nil, false
}

retrieve_my_cards :: proc(gs: ^Game_State) {

    player := get_my_player(gs)

    for &card in player.hero.cards {
        retrieve_card(gs, &card)
    }
}

retrieve_all_cards :: proc(gs: ^Game_State) {
    for &player in gs.players {
        for &card in player.hero.cards {
            retrieve_card(gs, &card)
        }
    }
}

lerp :: proc(a, b: $T, t: $T2) -> T {
    return b * t + a * (1-t)
}

color_lerp :: proc(a, b: Colour, t: $T) -> (out: Colour) {
    for val, index in a {
        out[index] = u8(t * T(b[index]) + (1-t) * T(val))
    }
    return out
}

calculate_hexagonal_distance :: proc(a, b: Target) -> int {
    diff := transmute([2]i8) a - transmute([2]i8) b
    if diff.x * diff.y <= 0 {
        return int(max(abs(diff.x), abs(diff.y)))
    } else {
        return int(abs(diff.x) + abs(diff.y))
    }
}

get_norm_direction :: proc(a, b: Target) -> Target {
    if a == b do return {}
    direction := transmute([2]i8) (b - a)
    norm_direction := direction / max(abs(direction.x), abs(direction.y))
    return transmute([2]u8) norm_direction
}

find_attack_interrupt :: proc(gs: ^Game_State) -> (Expanded_Interrupt, Attack_Interrupt, bool) {
    #reverse for expanded_interrupt in gs.interrupt_stack {
        #partial switch interrupt_variant in expanded_interrupt.interrupt.variant {
        case Attack_Interrupt:
            return expanded_interrupt, interrupt_variant, true
        }
    }
    return {}, {}, false
}

get_first_set_bit :: proc(bs: bit_set[$T]) -> Maybe(T) where intrinsics.type_is_enum(T) {
    for enum_type in T {
        if enum_type in bs do return enum_type
    }
    return nil
}

get_enemy_team :: proc(team: Team) -> Team {

    return .Blue if team == .Red else .Red
}

end_current_action_sequence :: proc(gs: ^Game_State) {
    #partial switch get_my_player(gs).stage {
    case .Resolving:
        broadcast_game_event(gs, End_Resolution_Event{gs.my_player_id})
    case .Interrupting:
        broadcast_game_event(gs, Resolve_Interrupt_Event{})
    }
}

get_next_turn_event :: proc(gs: ^Game_State) -> Event {
    
    highest_initiative: int = -1
    highest_player: Player

    gs.initiative_tied = false

    tie: Resolve_Same_Team_Tied_Event

    for player, player_id in gs.players {
        player_card, ok := find_played_card(gs, player_id)
        if !ok do continue

        effective_initiative := calculate_implicit_quantity(gs, Card_Value{.Initiative}, {card_id = player_card.id})
    
        if effective_initiative > highest_initiative {
            highest_initiative = effective_initiative
            highest_player = player
            tie = {}
        } else if effective_initiative == highest_initiative {
            if player.team != highest_player.team {
                gs.initiative_tied = true
                if player.team == gs.tiebreaker_coin {
                    highest_initiative = effective_initiative
                    highest_player = player  // @Note: need to consider ties between players on the same team
                    tie = {}
                }
            } else {
                if tie.num_ties == 0 {
                    tie.team = player.team
                    tie.tied_player_ids[0] = highest_player.id
                    tie.tied_player_ids[1] = player_id
                    tie.num_ties = 2
                } else {
                    tie.tied_player_ids[tie.num_ties] = player_id
                    tie.num_ties += 1
                }
            }
        }
    }

    if highest_initiative == -1  {
        return Resolutions_Completed_Event{}
    } else if tie.num_ties > 0 {
        return tie
    }
    return Begin_Player_Resolution_Event{highest_player.id}
}

calculate_minion_modifiers :: proc(gs: ^Game_State) -> int {
    minion_modifiers := 0
    player := get_my_player(gs)

    adjacent_targets := make_arbitrary_targets(gs, {
        conditions = {Target_Within_Distance{Self{}, {1, 1}}},
        flags = {.Ignoring_Immunity},
    })
    adjacent_targets_iter := make_target_set_iterator(&adjacent_targets)
    for _, adjacent in target_set_iter_members(&adjacent_targets_iter) {
        space := gs.board[adjacent.x][adjacent.y]
        if space.flags & {.Melee_Minion, .Heavy_Minion} != {} {
            minion_modifiers += 1 if space.unit_team == player.team else -1
        }
    }

    log.infof("Melee & heavy modifier: %v", minion_modifiers)

    // Idk if the ranged minion would ever be immune but it doesn't hurt I guess
    nearby_targets := make_arbitrary_targets(gs, {
        conditions = {Target_Within_Distance{ origin = Self{}, bounds = {1, 2}}}, 
        flags = {.Ignoring_Immunity},
    })
    nearby_targets_iter := make_target_set_iterator(&nearby_targets)
    for _, nearby in target_set_iter_members(&nearby_targets_iter) {
        space := gs.board[nearby.x][nearby.y]
        if .Ranged_Minion in space.flags && space.unit_team != player.team {
            minion_modifiers -= 1
        }
    }

    log.infof("Minion modifier: %v", minion_modifiers)
    return minion_modifiers
}

add_marker :: proc(gs: ^Game_State) {
    when ODIN_DEBUG {
        append(&gs.event_queue, Marker_Event{})
    }
}

add_action_value :: proc(
    gs: ^Game_State,
    value: Action_Value_Variant,
    index: Action_Index = {},
    label: Action_Value_Label = .None,
) {
    // depth := len(gs.interrupt_stack)
    index := index
    if index == {} {
        index = get_my_player(gs).hero.current_action_index
    }
    append(&gs.action_memory, Action_Value {
        action_index = index,
        // depth = depth,
        label = label,
        variant = value,
    })
}

get_memory_slice_for_index :: proc(gs: ^Game_State, index: Action_Index) -> []Action_Value {
    end_index := len(gs.action_memory) - 1
    for end_index >= 0 && gs.action_memory[end_index].action_index != index {
        end_index -= 1
    }

    start_index := end_index
    for start_index >= 0 && gs.action_memory[start_index].action_index == index {
        start_index -= 1 
    }
    start_index += 1
    end_index += 1
    if end_index > len(gs.action_memory) || start_index >= len(gs.action_memory) do return {}
    return gs.action_memory[start_index:end_index]
}

clear_top_memory_slice :: proc(gs: ^Game_State) {
    top_index := get_my_player(gs).hero.current_action_index 

    start_index := len(gs.action_memory) - 1
    for start_index >= 0 && gs.action_memory[start_index].action_index == top_index {
        start_index -= 1 
    }
    start_index += 1
    // if start_index >= len(gs.action_memory) do return
    resize(&gs.action_memory, len(gs.action_memory) - start_index)
    // return gs.action_memory[start_index:end_index]
}

get_top_memory_slice :: proc(gs: ^Game_State) -> []Action_Value {
    top_index := get_my_player(gs).hero.current_action_index
    return get_memory_slice_for_index(gs, top_index)
}

// You need to be sure this exists otherwise it will crash
get_top_action_value_of_type :: proc(
    gs: ^Game_State, $T: typeid, label: Action_Value_Label = .None
) -> ^T where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    value, _, ok := try_get_top_action_value_of_type(gs, T, label)
    log.assert(ok, "Invalid type assertion for action value!")
    return value
}

try_get_top_action_value_of_type :: proc(
    gs: ^Game_State, $T: typeid, label: Action_Value_Label = .None
) -> (^T, Action_Index, bool) where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    #reverse for &value in gs.action_memory {
        if label != .None && value.label != label do continue
        typed_value, ok := &value.variant.(T)
        if ok do return typed_value, value.action_index, true
    }
    return nil, {}, false
}

get_top_action_slice_of_type :: proc(gs: ^Game_State, $T: typeid) -> []Action_Value where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    start_index, end_index := -1, -1
    action_index: Action_Index
    #reverse for &value, index in gs.action_memory {
        _, ok := &value.variant.(T)
        if ok {
            end_index = index
            action_index = value.action_index
            break
        }
    }
    #reverse for &value, index in gs.action_memory[:end_index] {
        _, ok := &value.variant.(T)
        if !ok || value.action_index != action_index {
            start_index = index
            break
        }
    }
    return gs.action_memory[start_index + 1 : end_index + 1]
}