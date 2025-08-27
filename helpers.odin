package guards

import "base:intrinsics"
import rl "vendor:raylib"
// import "core:fmt"

import "core:log"



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

find_played_card_id :: proc(player_id: Player_ID = my_player_id, loc := #caller_location) -> (Card_ID, bool) {
    card, ok := find_played_card(player_id)
    if !ok do return {}, false
    return make_card_id(card^, player_id), true
}

find_played_card :: proc(player_id: Player_ID = my_player_id, loc := #caller_location) -> (^Card, bool) {
    player := get_player_by_id(player_id)
    for &card in player.hero.cards {
        if card.state == .PLAYED {
            return &card, true
        }
    }
    return nil, false
}

retrieve_my_cards :: proc() {

    player := get_my_player()

    for &card in player.hero.cards {
        retrieve_card(&card)
    }
}

retrieve_all_cards :: proc() {
    for &player in game_state.players {
        for &card in player.hero.cards {
            retrieve_card(&card)
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

translocate_unit :: proc(src, dest: Target) {
    src_space := &board[src.x][src.y]
    dest_space := &board[dest.x][dest.y]

    src_transient_flags := src_space.flags - PERMANENT_FLAGS
    src_space.flags -= src_transient_flags

    dest_space.flags += src_transient_flags
    dest_space.unit_team = src_space.unit_team
    dest_space.hero_id = src_space.hero_id

    if .HERO in src_transient_flags {
        dest_space.owner = src_space.owner
        get_player_by_id(dest_space.owner).hero.location = dest
    }
}

calculate_hexagonal_distance :: proc(a, b: IVec2) -> int {
    diff := a - b
    if diff.x * diff.y <= 0 {
        return max(abs(diff.x), abs(diff.y))
    } else {
        return abs(diff.x) + abs(diff.y)
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

end_current_action_sequence :: proc() {
    #partial switch get_my_player().stage {
    case .RESOLVING:
        broadcast_game_event(End_Resolution_Event{my_player_id})
    case .INTERRUPTING:
        broadcast_game_event(Resolve_Interrupt_Event{})
    }
}

get_next_turn_event :: proc() -> Event {
    
    highest_initiative: int = -1
    highest_player: Player

    initiative_tied = false

    for player, player_id in game_state.players {
        player_card, ok := find_played_card(player_id)
        if !ok do continue

        effective_initiative := player_card.initiative + count_hero_items(get_player_by_id(player_id).hero, .INITIATIVE)
    
        if effective_initiative > highest_initiative {
            highest_initiative = player_card.initiative
            highest_player = player
        } else if effective_initiative == highest_initiative {
            if player.team != highest_player.team {
                initiative_tied = true
                if player.team == game_state.tiebreaker_coin {
                    highest_initiative = effective_initiative
                    highest_player = player  // @Note: need to consider ties between players on the same team
                }
            }
        }
    }

    if highest_initiative == -1  {
        return Resolutions_Completed_Event{}
    }
    return Begin_Player_Resolution_Event{highest_player.id}
}

calculate_minion_modifiers :: proc() -> int {
    minion_modifiers := 0
    player := get_my_player()
    context.allocator = context.temp_allocator
    for adjacent in make_arbitrary_targets({Within_Distance{Self{}, 1, 1}, Ignoring_Immunity{}}) {
        space := board[adjacent.x][adjacent.y]
        if space.flags & {.MELEE_MINION, .HEAVY_MINION} != {} {
            minion_modifiers += 1 if space.unit_team == player.team else -1
        }
    }

    log.infof("Melee & heavy modifier: %v", minion_modifiers)

    for adjacent in make_arbitrary_targets({Within_Distance{Self{}, 1, 2}}) {
        space := board[adjacent.x][adjacent.y]
        if .RANGED_MINION in space.flags && space.unit_team != player.team {
            minion_modifiers -= 1
        }
    }

    log.infof("Minion modifier: %v", minion_modifiers)
    return minion_modifiers
}