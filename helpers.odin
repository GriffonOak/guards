package guards

import "base:intrinsics"
import rl "vendor:raylib"
import "core:fmt"

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

find_played_card_elements :: proc(panic := true, loc := #caller_location) -> (element: ^UI_Element, card_element: ^UI_Card_Element) {
    for &ui_element in ui_stack[1:][:5] {
        card_element = assert_variant(&ui_element.variant, UI_Card_Element)
        card, ok := get_card_by_id(card_element.card_id)
        log.assert(ok || !panic, "Card element had no assigned card!", loc = loc)
        if ok && card.state == .PLAYED {
            return &ui_element, card_element
        }
    }
    log.assert(!panic, "No played card!", loc = loc)
    return nil, nil
}

find_played_card_id :: proc(loc := #caller_location) -> Card_ID {

    _, card_elem := find_played_card_elements(loc = loc)
    return card_elem.card_id
}

find_played_card :: proc(loc := #caller_location) -> ^Card{
    card, ok := get_card_by_id(find_played_card_id())
    return card
}

retrieve_cards :: proc() {
    // @Cleanup this should be rewritten

    for &ui_element in ui_stack[1:][:5] {
        card_element := assert_variant(&ui_element.variant, UI_Card_Element)
        card, ok := get_card_by_id(card_element.card_id)
        log.assert(ok, "element with no card blah blah")
        ui_element.bounding_rect = card_hand_position_rects[card.color]
        card.state = .IN_HAND
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

translocate_unit :: proc(src, dest: IVec2) {
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
    if team == .NONE do return .NONE

    return .BLUE if team == .RED else .RED
}