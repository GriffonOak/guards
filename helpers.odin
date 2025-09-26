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

color_lerp :: proc(a, b: rl.Color, t: $T) -> (out: rl.Color) {
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

        effective_initiative := calculate_implicit_quantity(gs, Card_Value{.INITIATIVE}, {card_id = player_card.id})
    
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
        if space.flags & {.Melee_Minion, .Heavy_Minion} != {} {
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

// can_defend :: proc(defense_strength: Implicit_Quantity, flags: Defense_Flags) -> bool{
//     log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)

//     attack_strength := -1e6
//     minion_modifiers := -1e6
//     search_interrupts: #reverse for expanded_interrupt in gs.interrupt_stack {
//         #partial switch interrupt_variant in expanded_interrupt.interrupt.variant {
//         case Attack_Interrupt:
//             attack_strength = interrupt_variant.strength
//             break search_interrupts
//         }
//     }
//     log.assert(attack_strength != -1e6, "No attack found in interrupt stack!!!!!", loc)

//     log.infof("Defending attack of %v, minions %v, card value %v", attack_strength, minion_modifiers)

//     // We do it this way so that defense items get calculated
//     defense_strength := calculate_implicit_quantity(gs, Card_Value{.DEFENSE}, calc_context)
//     return defense_strength + minion_modifiers >= attack_strength
// }