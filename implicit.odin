package guards

import "core:log"

Previous_Card_Choice :: struct {}

Rightmost_Resolved_Card :: struct {}

Implicit_Card_ID :: union {
    Card_ID,
    Previous_Card_Choice,
    Rightmost_Resolved_Card,
}


Card_Reach :: struct {}

Card_Value :: struct {
    kind: Ability_Kind,
}

Sum :: []Implicit_Quantity

Product :: []Implicit_Quantity

Count_Targets :: Selection_Criteria

Card_Turn_Played :: struct {}

Minion_Difference :: struct {}

Minion_Modifiers :: struct {}

Ternary :: struct {
    terms: []Implicit_Quantity,
    condition: Implicit_Condition,
}

Target_Count_Discarded_Cards :: struct {}

Implicit_Quantity :: union {
    int,
    Minion_Difference,
    Minion_Modifiers,
    Sum,
    Count_Targets,
    Ternary,

    // Requires target in context (although maybe it shouldn't?)
    Target_Count_Discarded_Cards,

    // 
    Card_Reach,
    Card_Value,
    Card_Turn_Played,
}

Calculation_Context :: struct {
    card_id: Card_ID,
    target, prev_target: Target,
}

That_Target :: struct {}

Self :: struct {}

Previous_Choice :: struct {}

Top_Blocked_Spawnpoint :: struct {}

Card_Owner :: struct {}

Implicit_Target :: union {
    Target,
    That_Target,
    Self,
    Previous_Choice,
    Top_Blocked_Spawnpoint,

    // Requires card in context
    Card_Owner,
}

Previous_Choices :: struct {}

Implicit_Target_Slice :: union {
    []Target,
    Previous_Choices,
}


/// IMPLICIT CONDITIONS

Greater_Than :: []Implicit_Quantity

And :: []Implicit_Condition

Blocked_Spawnpoints_Remain :: struct {}

Alive :: struct {}

Target_Within_Distance :: struct {
    origin: Implicit_Target,
    bounds: []Implicit_Quantity,
}

Target_In_Straight_Line_With :: struct {
    origin: Implicit_Target,
}

Target_Contains_Any :: struct { flags: Space_Flags }
Target_Contains_No  :: struct { flags: Space_Flags }
Target_Contains_All :: struct { flags: Space_Flags }

Target_Is_Enemy_Unit :: struct {}
Target_Is_Friendly_Unit :: struct {}
Target_Is_Losing_Team_Unit :: struct {}
Target_Is_Enemy_Of :: struct {
    target: Implicit_Target,
}
Target_Is_Friendly_Spawnpoint :: struct {}
Not_Previously_Targeted :: struct {}

Target_In_Battle_Zone :: struct {}
Target_Outside_Battle_Zone :: struct {}

Target_Empty :: Target_Contains_No{OBSTACLE_FLAGS}

// Card_Can_Defend :: struct{
//     strength: int,
// }

Card_State_Is :: struct {
    state: Card_State,
}

Card_Primary_Is_Not :: struct {
    kind: Ability_Kind,
}


Implicit_Condition :: union {
    bool,
    Greater_Than,
    And,
    Blocked_Spawnpoints_Remain,
    Alive,

    // Requires target in calc_context
    Target_Within_Distance,
    Target_Contains_Any,
    Target_Contains_No,
    Target_Contains_All,
    Target_Is_Enemy_Unit,
    Target_Is_Friendly_Unit,
    Target_Is_Losing_Team_Unit,
    Target_Is_Enemy_Of,
    Target_Is_Friendly_Spawnpoint,
    Target_In_Battle_Zone,
    Target_Outside_Battle_Zone,
    Target_In_Straight_Line_With,

    // Requires card in calc context
    // Card_Can_Defend,
    Card_State_Is,
    Card_Primary_Is_Not,
}

Card_Defense_Index :: struct {}

Other_Card_Primary :: struct {
    implicit_card_id: Implicit_Card_ID,
}

Implicit_Action_Index :: union {
    Action_Index,
    Card_Defense_Index,
    Other_Card_Primary,
}



calculate_implicit_quantity :: proc(
    gs: ^Game_State,
    implicit_quantity: Implicit_Quantity,
    calc_context: Calculation_Context = {},
    loc := #caller_location
) -> (out: int) {

    switch quantity in implicit_quantity {
    case int: return quantity
    case Card_Reach:

        log.assert(calc_context.card_id != {}, "Invalid card ID when calculating reach", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card ID when calculating reach", loc)
        switch reach in card_data.reach {
        case Range:out = int(reach) + count_hero_items(gs, get_player_by_id(gs, calc_context.card_id.owner_id).hero, .RANGE)
        case Radius: out = int(reach) + count_hero_items(gs, get_player_by_id(gs, calc_context.card_id.owner_id).hero, .RADIUS)
        case: log.assert(false, "tried to calculate nil card reach!", loc)
        } 

    case Card_Value:
        log.assert(calc_context.card_id != {}, "Invalid card ID when calculating value", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card ID when calculating value", loc)
        hero := get_player_by_id(gs, calc_context.card_id.owner_id).hero
        value := card_data.values[quantity.kind]
        #partial switch quantity.kind {
        case .ATTACK: value += count_hero_items(gs, hero, .ATTACK)
        case .DEFENSE: value += count_hero_items(gs, hero, .DEFENSE)
        case .MOVEMENT: value += count_hero_items(gs, hero, .MOVEMENT)
        }
        return value

    case Sum:
        for summand in quantity do out += calculate_implicit_quantity(gs, summand, calc_context, loc)

    case Count_Targets:
        targets := make_arbitrary_targets(gs, quantity, calc_context)
        return count_members(&targets)

    case Card_Turn_Played:
        log.assert(calc_context.card_id != {}, "Invalid card when trying to calculate turn played", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card when trying to calculate turn played", loc)
        return card.turn_played

    case Minion_Difference:
        return abs(gs.minion_counts[.RED] - gs.minion_counts[.BLUE])

    case Ternary:
        log.assert(len(quantity.terms) == 2, "Ternary operator that does not have 2 terms!", loc)
        if calculate_implicit_condition(gs, quantity.condition, calc_context, loc) {
            return calculate_implicit_quantity(gs, quantity.terms[0], calc_context, loc)
        } else {
            return calculate_implicit_quantity(gs, quantity.terms[1], calc_context, loc)
        }

    case Target_Count_Discarded_Cards:
        log.assert(calc_context.target != {}, "Invalid target when trying to count discarded cards!")
        space := gs.board[calc_context.target.x][calc_context.target.y]
        if .HERO not_in space.flags do return
        cards := get_player_by_id(gs, space.owner).hero.cards
        for card in cards {
            if card.state == .DISCARDED do out += 1
        }

    case Minion_Modifiers: 
        return calculate_minion_modifiers(gs)

    }
    return 
}

calculate_implicit_target :: proc(
    gs: ^Game_State,
    implicit_target: Implicit_Target,
    calc_context: Calculation_Context = {},
    loc := #caller_location
) -> (out: Target) {
    switch target in implicit_target {
    case Target: out = target
    case That_Target:
        log.assert(calc_context.prev_target != {}, "Invalid stack target!", loc)
        return calc_context.prev_target
    case Self: out = get_my_player(gs).hero.location
    case Previous_Choice:
        index := get_my_player(gs).hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(gs, index)
            if variant, ok := action.variant.(Choose_Target_Action); ok {
                out = variant.result[0]
                return
            }
        }
    case Top_Blocked_Spawnpoint:
        my_team := get_my_player(gs).team
        num_blocked_spawns := len(gs.blocked_spawns[my_team])
        log.assert(num_blocked_spawns > 0, "No blocked spawns!!!!!", loc)
        return gs.blocked_spawns[my_team][num_blocked_spawns - 1]
    case Card_Owner:
        log.assert(calc_context.card_id != {}, "Cannot find the owner of an invalid card!", loc)
        return get_player_by_id(gs, calc_context.card_id.owner_id).hero.location
    }
    return
}

calculate_implicit_target_slice :: proc(gs: ^Game_State, implicit_slice: Implicit_Target_Slice) -> []Target {
    switch slice in implicit_slice {
    case []Target: return slice
    case Previous_Choices:
        index := get_my_player(gs).hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(gs, index)
            if variant, ok := action.variant.(Choose_Target_Action); ok {
                return variant.result[:]
            }
        }
    }
    return {}
}

calculate_implicit_condition :: proc (
    gs: ^Game_State,
    implicit_condition: Implicit_Condition,
    calc_context: Calculation_Context = {},
    loc := #caller_location
) -> bool {

    space_ok := calc_context.target != {}
    space: Space
    if space_ok {
        space = gs.board[calc_context.target.x][calc_context.target.y]
    }

    switch condition in implicit_condition {
    case bool: return condition
    // Check this
    case Greater_Than:
        log.assert(len(condition) == 2, "Greater Than condition check that does not have 2 elements!", loc)
        return calculate_implicit_quantity(gs, condition[0], calc_context, loc) > calculate_implicit_quantity(gs, condition[1], calc_context, loc)
    case And:
        out := true
        for extra_condition in condition do out &&= calculate_implicit_condition(gs, extra_condition, calc_context, loc)
        return out
    case Blocked_Spawnpoints_Remain:
        my_team := get_my_player(gs).team
        return len(gs.blocked_spawns[my_team]) > 0
    case Alive:
        return !get_my_player(gs).hero.dead

    case Target_Within_Distance:
        log.assert(space_ok, "Invalid target!", loc)
        origin := calculate_implicit_target(gs, condition.origin, calc_context)

        // log.assert(len(condition.origin) == 1, "Incorrect argument count for within distance condition", loc)
        log.assert(len(condition.bounds) == 2, "Incorrect argument count for bounds", loc)

        min_dist := calculate_implicit_quantity(gs, condition.bounds[0], calc_context)
        max_dist := calculate_implicit_quantity(gs, condition.bounds[1], calc_context)

        distance := calculate_hexagonal_distance(origin, calc_context.target)
        return distance <= max_dist && distance >= min_dist

    case Target_Contains_Any:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection != {}

    case Target_Contains_All:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection == condition.flags
    
    case Target_Contains_No:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection == {}

    // @Note these don't actually test whether a unit is present in the space, only that the teams are the same / different
    case Target_Is_Enemy_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team != space.unit_team

    case Target_Is_Friendly_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team == space.unit_team

    case Target_Is_Losing_Team_Unit:
        log.assert(space_ok, "Invalid target!")
        losing_team: Team = .RED if gs.minion_counts[.RED] < gs.minion_counts[.BLUE] else .BLUE
        return losing_team == space.unit_team

    case Target_Is_Enemy_Of:
        log.assert(space_ok, "Invalid target!")
        other_target := calculate_implicit_target(gs, condition.target, calc_context)
        other_space := gs.board[other_target.x][other_target.y]
        return other_space.unit_team != space.unit_team

    case Target_Is_Friendly_Spawnpoint:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team == space.spawnpoint_team

    case Target_In_Battle_Zone:
        log.assert(space_ok, "Invalid target!")
        return space.region_id == gs.current_battle_zone

    case Target_Outside_Battle_Zone:
        log.assert(space_ok, "Invalid target!")
        return space.region_id != gs.current_battle_zone

    case Target_In_Straight_Line_With:
        log.assert(space_ok, "Invalid target!")
        origin := calculate_implicit_target(gs, condition.origin, calc_context)

        delta := calc_context.target - origin
        return delta.x == 0 || delta.y == 0 || delta.x == - delta.y

    case Card_Primary_Is_Not:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card data when checking for its primary type!", loc)
        return card_data.primary != condition.kind

    case Card_State_Is:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card when checking for its state!", loc)
        return card.state == condition.state

    // case Card_Can_Defend:
        // log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)

        // attack_strength := -1e6
        // minion_modifiers := -1e6
        // search_interrupts: #reverse for expanded_interrupt in gs.interrupt_stack {
        //     #partial switch interrupt_variant in expanded_interrupt.interrupt.variant {
        //     case Attack_Interrupt:
        //         attack_strength = interrupt_variant.strength
        //         minion_modifiers = interrupt_variant.minion_modifiers
        //         break search_interrupts
        //     }
        // }
        // log.assert(attack_strength != -1e6, "No attack found in interrupt stack!!!!!", loc)

        // log.infof("Defending attack of %v, minions %v, card value %v", attack_strength, minion_modifiers)

        // // We do it this way so that defense items get calculated
        // defense_strength := calculate_implicit_quantity(gs, Card_Value{.DEFENSE}, calc_context)
        // return defense_strength + minion_modifiers >= attack_strength
    }
    return false
}

calculate_implicit_card_id :: proc(gs: ^Game_State, implicit_card_id: Implicit_Card_ID) -> Card_ID {
    switch card_id in implicit_card_id {
    case Card_ID:
        return card_id
    case Previous_Card_Choice:
        index := get_my_player(gs).hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(gs, index)
            if variant, ok := action.variant.(Choose_Card_Action); ok {
                return variant.result
            }
        }
    case Rightmost_Resolved_Card:
        out: Card_ID
        highest_turn := -1
        cards := get_my_player(gs).hero.cards
        for card in cards {
            if card.state == .RESOLVED && card.turn_played > highest_turn {
                out = card.id
                highest_turn = card.turn_played
            }
        }
        return out
    }
    played_card, ok := find_played_card(gs)
    log.assert(ok, "Could not find played card when calculating an implicit card")
    return played_card  // Default to returning the played card
}

calculate_implicit_action_index :: proc(gs: ^Game_State, implicit_index: Implicit_Action_Index, calc_context: Calculation_Context = {}) -> Action_Index {
    switch index in implicit_index {
    case Action_Index:
        return index
    case Card_Defense_Index:
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card ID!!")
        #partial switch card_data.primary {
        case .DEFENSE: 
            return Action_Index{.PRIMARY, calc_context.card_id, 0}
        case .DEFENSE_SKILL:
            log.assert(false, "TODO")  // @Todo
            return {}
        }
        return {.BASIC_DEFENSE, calc_context.card_id, 3}  // @Magic: index of Defense_Action in basic_defense_action
    case Other_Card_Primary:
        other_card_id := calculate_implicit_card_id(gs, index.implicit_card_id)
        if other_card_id == {} do return {sequence = .INVALID}
        return {sequence = .PRIMARY, card_id = other_card_id, index = 0}
    }
    return {}
}