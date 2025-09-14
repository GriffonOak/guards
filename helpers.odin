package guards

import "base:intrinsics"
import rl "vendor:raylib"
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
        if card.state == .PLAYED {
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

color_lerp :: proc(a, b: rl.Color, t: $T) -> (out: rl.Color) {
    for val, index in a {
        out[index] = u8(t * T(b[index]) + (1-t) * T(val))
    }
    return out
}

translocate_unit :: proc(gs: ^Game_State, src, dest: Target) {
    src_space := &gs.board[src.x][src.y]
    dest_space := &gs.board[dest.x][dest.y]

    src_transient_flags := src_space.flags - PERMANENT_FLAGS
    src_space.flags -= src_transient_flags

    dest_space.flags += src_transient_flags
    dest_space.unit_team = src_space.unit_team
    dest_space.hero_id = src_space.hero_id

    if .HERO in src_transient_flags {
        dest_space.owner = src_space.owner
        get_player_by_id(gs, dest_space.owner).hero.location = dest
    }
}

calculate_hexagonal_distance :: proc(a, b: Target) -> int {
    diff := a - b
    if diff.x * diff.y <= 0 {
        return int(max(abs(diff.x), abs(diff.y)))
    } else {
        return int(abs(diff.x) + abs(diff.y))
    }
}

get_first_set_bit :: proc(bs: bit_set[$T]) -> Maybe(T) where intrinsics.type_is_enum(T) {
    for enum_type in T {
        if enum_type in bs do return enum_type
    }
    return nil
}

get_enemy_team :: proc(team: Team) -> Team {

    return .BLUE if team == .RED else .RED
}

end_current_action_sequence :: proc(gs: ^Game_State) {
    #partial switch get_my_player(gs).stage {
    case .RESOLVING:
        broadcast_game_event(gs, End_Resolution_Event{gs.my_player_id})
    case .INTERRUPTING:
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
        player_card_data, ok2 := get_card_data_by_id(gs, player_card)
        log.assert(ok2, "Could not find card data!")

        effective_initiative := player_card_data.initiative + count_hero_items(gs, get_player_by_id(gs, player_id).hero, .INITIATIVE)
    
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
        flags = {.IGNORING_IMMUNITY},
    })
    adjacent_targets_iter := make_target_set_iterator(&adjacent_targets)
    for _, adjacent in target_set_iter_members(&adjacent_targets_iter) {
        space := gs.board[adjacent.x][adjacent.y]
        if space.flags & {.MELEE_MINION, .HEAVY_MINION} != {} {
            minion_modifiers += 1 if space.unit_team == player.team else -1
        }
    }

    log.infof("Melee & heavy modifier: %v", minion_modifiers)

    // Idk if the ranged minion would ever be immune but it doesn't hurt I guess
    nearby_targets := make_arbitrary_targets(gs, {
        conditions = {Target_Within_Distance{ origin = Self{}, bounds = {1, 2}}}, 
        flags = {.IGNORING_IMMUNITY},
    })
    nearby_targets_iter := make_target_set_iterator(&nearby_targets)
    for _, nearby in target_set_iter_members(&nearby_targets_iter) {
        space := gs.board[nearby.x][nearby.y]
        if .RANGED_MINION in space.flags && space.unit_team != player.team {
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