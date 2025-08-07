package guards

import "base:intrinsics"
import rl "vendor:raylib"
import "core:fmt"



assert_variant :: proc(u: ^$U, $V: typeid) -> ^V where intrinsics.type_is_union(U) && intrinsics.type_is_variant_of(U, V) {
    out, ok := &u.(V)
    assert(ok)
    return out
}

find_played_card :: proc() -> (element: ^UI_Element, card_element: ^UI_Card_Element) {
    for &ui_element in ui_stack[1:][:5] {
        card_element = assert_variant(&ui_element.variant, UI_Card_Element)
        if card_element.card.state == .PLAYED {
            return &ui_element, card_element
        }
    }
    return nil, nil
}

retrieve_cards :: proc() {
    for &ui_element in ui_stack[1:][:5] {
        card_element := assert_variant(&ui_element.variant, UI_Card_Element)
        ui_element.bounding_rect = card_hand_position_rects[card_element.card.color]
        card_element.card.state = .IN_HAND
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
        dest_space.owner.hero.location = dest

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

calculate_implicit_quantity :: proc(implicit_quantity: Implicit_Quantity) -> (out: int) {
    switch quantity in implicit_quantity {
    case int: out = quantity

    case Card_Reach:
        _, card_elem := find_played_card()
        assert(card_elem != nil)
        // @Item Need to add items here also at some point
        switch reach in card_elem.card.reach{
        case Range: out = int(reach)
        case Radius: out = int(reach)
        case: assert(false)
        } 

    case Card_Primary_Value:
        _, card_elem := find_played_card()
        assert(card_elem != nil)
        return card_elem.card.value

    case Card_Secondary_Value:
        _, card_elem := find_played_card()
        assert(card_elem != nil)
        return card_elem.card.secondaries[quantity.kind]
    }
    return 
}

calculate_implicit_target :: proc(implicit_target: Implicit_Target) -> (out: Target) {
    switch target in implicit_target {
    case Target: out = target
    case Self: out = player.hero.location
    case Previous_Choice:
        prev_action := get_previous_action(&player.hero).variant.(Choose_Target_Action)
        out = prev_action.result
    }
    return
}

calculate_implicit_target_set :: proc(implicit_set: Implicit_Target_Set) -> Target_Set {
    switch set in implicit_set {
    case Target_Set: return set
    case []Selection_Criterion: return make_arbitrary_targets(..set)
    }
    return nil
}

get_first_set_bit :: proc(bs: bit_set[$T]) -> Maybe(T) where intrinsics.type_is_enum(T) {
    for enum_type in T {
        if enum_type in bs do return enum_type
    }
    return nil
}