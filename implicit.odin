package guards

import "core:log"

Card_Creating_Effect :: struct {
    effect: Active_Effect_ID,
}

Previous_Card_Choice :: struct {}

Implicit_Card :: union {
    Card_ID,
    Card_Creating_Effect,
    Previous_Card_Choice,
}



Card_Reach :: struct {
    card: Implicit_Card,
}

Card_Value :: struct {
    card: Implicit_Card,
    kind: Ability_Kind,
}

Sum :: []Implicit_Quantity

Product :: []Implicit_Quantity

Count_Targets :: []Selection_Criterion

// Current_Turn :: struct {}

Turn_Played :: struct {
    card: Implicit_Card,
}

Minion_Difference :: struct {}

Implicit_Quantity :: union {
    int,
    Card_Reach,
    Card_Value,
    Sum,
    Count_Targets,
    // Current_Turn,
    Turn_Played,
    Minion_Difference,
}



Implicit_Target_Set :: union {
    Target_Set,
    []Selection_Criterion,
}



Self :: struct {}

Previous_Choice :: struct {}

Top_Blocked_Spawnpoint :: struct {}

Implicit_Target :: union {
    Target,
    Self,
    Previous_Choice,
    Top_Blocked_Spawnpoint,
}



Greater_Than :: struct {
    term_1, term_2: Implicit_Quantity,
}

And :: []Implicit_Condition

Primary_Is_Not :: struct {
    kind: Ability_Kind,
}

Blocked_Spawnpoints_Remain :: struct {}

Alive :: struct {}

Implicit_Condition :: union {
    bool,
    Greater_Than,
    Primary_Is_Not,
    And,
    Blocked_Spawnpoints_Remain,
    Alive,
}



calculate_implicit_quantity :: proc(implicit_quantity: Implicit_Quantity) -> (out: int) {
    switch quantity in implicit_quantity {
    case int: return quantity

    case Card_Reach:
        // @Item Need to add items here also at some point
        card := calculate_implicit_card(quantity.card)
        switch reach in card.reach{
        case Range: out = int(reach)
        case Radius: out = int(reach)
        case: assert(false)
        } 

    case Card_Value:
        card := calculate_implicit_card(quantity.card)
        return card.values[quantity.kind]

    case Sum:
        for summand in quantity do out += calculate_implicit_quantity(summand)

    case Count_Targets:
        targets := make_arbitrary_targets(quantity, context.temp_allocator)
        return len(targets)

    case Turn_Played:
        card := calculate_implicit_card(quantity.card)
        return card.turn_played

    // case Current_Turn:
    //     return game_state.turn_counter

    case Minion_Difference:
        return abs(game_state.minion_counts[.RED] - game_state.minion_counts[.BLUE])

    }
    return 
}

calculate_implicit_target :: proc(implicit_target: Implicit_Target) -> (out: Target) {
    switch target in implicit_target {
    case Target: out = target
    case Self: out = get_my_player().hero.location
    case Previous_Choice:
        index := get_my_player().hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(index)
            if variant, ok := action.variant.(Choose_Target_Action); ok {
                out = variant.result[0]
                return
            }
        }
    case Top_Blocked_Spawnpoint:
        my_team := get_my_player().team
        num_blocked_spawns := len(blocked_spawns[my_team])
        log.assert(num_blocked_spawns > 0, "No blocked spawns!!!!!")
        return blocked_spawns[my_team][num_blocked_spawns - 1]
    }
    return
}

calculate_implicit_target_set :: proc(implicit_set: Implicit_Target_Set, allocator := context.allocator) -> Target_Set {
    switch set in implicit_set {
    case Target_Set: return set
    case []Selection_Criterion: return make_arbitrary_targets(set, allocator)
    }
    return nil
}

calculate_implicit_condition :: proc(implicit_condition: Implicit_Condition) -> bool {
    switch condition in implicit_condition {
    case bool: return condition
    case Greater_Than: return calculate_implicit_quantity(condition.term_1) > calculate_implicit_quantity(condition.term_2)
    case Primary_Is_Not: 
        played_card, ok := find_played_card()
        log.assert(ok, "Could not find the played card when checking for its primary type!")
        return played_card.primary != condition.kind
    case And:
        out := true
        for extra_condition in condition do out &&= calculate_implicit_condition(extra_condition)
        return out
    case Blocked_Spawnpoints_Remain:
        my_team := get_my_player().team
        return len(blocked_spawns[my_team]) > 0
    case Alive:
        return !get_my_player().hero.dead
    }
    return false
}

calculate_implicit_card :: proc(implicit_card: Implicit_Card) -> ^Card {
    switch card in implicit_card {
    case Card_ID:
        card_pointer, ok := get_card_by_id(card)
        log.assert(ok, "Can't find card by ID")
        return card_pointer
    case Card_Creating_Effect:
        card_pointer, ok := get_card_by_id(game_state.ongoing_active_effects[card.effect].parent_card_id)
        log.assert(ok, "Can't find card ID")
        return card_pointer
    case Previous_Card_Choice:
        index := get_my_player().hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(index)
            if variant, ok := action.variant.(Choose_Card_Action); ok {
                card, ok2 := get_card_by_id(variant.result)
                log.assert(ok2, "Previous choice of card was not valid!!!!!!")
                return card
            }
        }
    }
    played_card, ok := find_played_card()
    log.assert(ok, "Could not find played card when calculating an implicit card")
    return played_card  // Default to returning the played card
}