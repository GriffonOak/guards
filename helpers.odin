package guards

import "base:intrinsics"
// import "core:fmt"

import "core:log"
import sa "core:container/small_array"



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

retrieve_all_cards :: proc(gs: ^Game_State) {
    for &player in gs.players {
        for &card in player.hero.cards {
            change_card_state(gs, &card, .In_Hand)
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

target_contains_any :: proc(gs: ^Game_State, target: Target, flags: Space_Flags) -> bool {
    space := gs.board[target.x][target.y]
    if flags & space.flags != {} do return true
    for _, effect in gs.ongoing_active_effects {
        effect_card_id := sa.get(effect.generating_cards, 0)
        effect_calc_context := Calculation_Context{target = target, card_id = effect_card_id}
        if !effect_timing_valid(gs, effect.timing, effect_calc_context) do continue
        for outcome in effect.outcomes {
            counts_as, ok := outcome.(Target_Counts_As)
            if !ok do continue
            if flags & counts_as.flags == {} do continue
            if calculate_implicit_condition(gs, And(effect.affected_targets), effect_calc_context) {
                return true
            }
        }
    }
    return false
}

effect_timing_valid :: proc(gs: ^Game_State, timing: Effect_Timing, calc_context: Calculation_Context = {}) -> bool {
    #partial switch timing_variant in timing {
    case Round: return true
    case Single_Turn: return calculate_implicit_quantity(gs, timing_variant, calc_context) == gs.turn_counter
    }
    return false
}

card_is_valid_upgrade_option :: proc(gs: ^Game_State, card: Card) -> bool {
    my_hero := get_my_player(gs).hero
    if card.hero_id != my_hero.id do return false
    if card.color == .Gold || card.color == .Silver || card.state != .In_Deck do return false
    lowest_tier: int = 1e6
    for other_card in my_hero.cards {
        if other_card.tier == 0 do continue
        lowest_tier = min(lowest_tier, other_card.tier)
    }
    if my_hero.cards[card.color].tier != lowest_tier do return false
    if lowest_tier == 3 || card.tier != lowest_tier + 1 do return false
    return true
}

get_max_wave_counters :: proc(length: Game_Length) -> int{
    return 3 if length == .Quick else 5
}

get_max_life_counters :: proc(gs: ^Game_State, length: Game_Length) -> int {
    num_players := len(gs.players)
    if length == .Quick {
        return 4 if num_players <= 4 else 5
    } else {
        return 6 if num_players <= 4 else 8
    }
}