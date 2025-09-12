package guards

import "core:log"

Previous_Card_Choice :: struct {}

Implicit_Card :: union {
    Card_ID,
    Previous_Card_Choice,
}


Card_Reach :: struct {}

Card_Value :: struct {
    kind: Ability_Kind,
}

Sum :: []Implicit_Quantity

Product :: []Implicit_Quantity

Count_Targets :: Selection_Criteria

Turn_Played :: struct {}

Minion_Difference :: struct {}

Ternary :: struct {
    terms: []Implicit_Quantity,
    condition: []Implicit_Condition,
}

Implicit_Quantity :: union {
    int,
    Card_Reach,
    Card_Value,
    Sum,
    Count_Targets,
    Turn_Played,
    Minion_Difference,
    Ternary,
}

Calculation_Context :: struct {
    card_id: Card_ID,
    origin, target: Target,
}

Self :: struct {}

Previous_Choice :: struct {}

Top_Blocked_Spawnpoint :: struct {}

Card_Owner :: struct {}

Implicit_Target :: union {
    Target,
    Self,
    Previous_Choice,
    Top_Blocked_Spawnpoint,
    Card_Owner,
}

Previous_Choices :: struct {}

Implicit_Target_Slice :: union {
    []Target,
    Previous_Choices,
}

Greater_Than :: []Implicit_Quantity

And :: []Implicit_Condition

Primary_Is_Not :: struct {
    kind: Ability_Kind,
}

Blocked_Spawnpoints_Remain :: struct {}

Alive :: struct {}

Within_Distance :: struct {
    origin: []Implicit_Target,
    bounds: []Implicit_Quantity,
}

Adjacent := Within_Distance{{Self{}}, {1, 1}}

Closest_Spaces :: struct {
    origin: []Implicit_Target,
}

Contains_Any :: struct { flags: Space_Flags }
Contains_No  :: struct { flags: Space_Flags }
Contains_All :: struct { flags: Space_Flags }

Is_Enemy_Unit :: struct {}
Is_Friendly_Unit :: struct {}
Is_Losing_Team_Unit :: struct {}
Is_Enemy_Of :: struct {
    target: []Implicit_Target,
}
Is_Friendly_Spawnpoint :: struct {}
Not_Previously_Targeted :: struct {}

Ignoring_Immunity :: struct {}
In_Battle_Zone :: struct {}
Outside_Battle_Zone :: struct {}
Empty :: struct {}

Implicit_Condition :: union {
    bool,
    Greater_Than,
    Primary_Is_Not,
    And,
    Blocked_Spawnpoints_Remain,
    Alive,
    Within_Distance,
    // Closest_Spaces,  // Important to list this one last in any list of criteria
    Contains_Any,
    Contains_No,
    Contains_All,
    Is_Enemy_Unit,
    Is_Friendly_Unit,
    Is_Losing_Team_Unit,
    Is_Enemy_Of,
    Is_Friendly_Spawnpoint,
    // Not_Previously_Targeted,
    // Ignoring_Immunity,
    In_Battle_Zone,
    Outside_Battle_Zone,
    Empty,
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

    case Turn_Played:
        log.assert(calc_context.card_id != {}, "Invalid card when trying to calculate turn played", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card when trying to calculate turn played", loc)
        return card.turn_played

    // case Current_Turn:
    //     return gs.turn_counter

    case Minion_Difference:
        return abs(gs.minion_counts[.RED] - gs.minion_counts[.BLUE])

    case Ternary:
        log.assert(len(quantity.terms) == 2, "Ternary operator that does not have 2 terms!", loc)
        log.assert(len(quantity.condition) == 1, "Ternary operator that does not have 1 condition!", loc)
        if calculate_implicit_condition(gs, quantity.condition[0], calc_context, loc) {
            return calculate_implicit_quantity(gs, quantity.terms[0], calc_context, loc)
        } else {
            return calculate_implicit_quantity(gs, quantity.terms[1], calc_context, loc)
        }
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
    case Primary_Is_Not:
        log.assert(calc_context.card_id != {}, "Could not find the played card when checking for its primary type!")
        played_card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card data when checking for its primary type!")
        return played_card_data.primary != condition.kind
    case And:
        out := true
        for extra_condition in condition do out &&= calculate_implicit_condition(gs, extra_condition, calc_context, loc)
        return out
    case Blocked_Spawnpoints_Remain:
        my_team := get_my_player(gs).team
        return len(gs.blocked_spawns[my_team]) > 0
    case Alive:
        return !get_my_player(gs).hero.dead

    case Within_Distance:
        log.assert(space_ok, "Invalid target!", loc)

        log.assert(len(condition.origin) == 1, "Incorrect argument count for within distance condition", loc)
        log.assert(len(condition.bounds) == 2, "Incorrect argument count for bounds", loc)

        origin := calculate_implicit_target(gs, condition.origin[0], calc_context)
        min_dist := calculate_implicit_quantity(gs, condition.bounds[0], calc_context)
        max_dist := calculate_implicit_quantity(gs, condition.bounds[1], calc_context)

        distance := calculate_hexagonal_distance(origin, calc_context.target)
        return distance <= max_dist && distance >= min_dist

    case Contains_Any:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection != {}

    case Contains_All:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection == condition.flags
    
    case Contains_No:
        log.assert(space_ok, "Invalid target!")
        intersection := space.flags & condition.flags
        return intersection == {}

    // @Note these don't actually test whether a unit is present in the space, only that the teams are the same / different
    case Is_Enemy_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team != space.unit_team

    case Is_Friendly_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team == space.unit_team

    case Is_Losing_Team_Unit:
        log.assert(space_ok, "Invalid target!")
        losing_team: Team = .RED if gs.minion_counts[.RED] < gs.minion_counts[.BLUE] else .BLUE
        return losing_team == space.unit_team

    case Is_Enemy_Of:
        log.assert(space_ok, "Invalid target!")
        log.assert(len(condition.target) == 1, "Incorrectly formatted term")
        other_target := calculate_implicit_target(gs, condition.target[0], calc_context)
        other_space := gs.board[other_target.x][other_target.y]
        return other_space.unit_team != space.unit_team

    case Is_Friendly_Spawnpoint:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team == space.spawnpoint_team

    case In_Battle_Zone:
        log.assert(space_ok, "Invalid target!")
        return space.region_id == gs.current_battle_zone

    case Outside_Battle_Zone:
        log.assert(space_ok, "Invalid target!")
        return space.region_id != gs.current_battle_zone

    case Empty:
        log.assert(space_ok, "Invalid target!")
        return space.flags & OBSTACLE_FLAGS == {}
    }
    return false
}

calculate_implicit_card :: proc(gs: ^Game_State, implicit_card: Implicit_Card) -> ^Card {
    switch card in implicit_card {
    case Card_ID:
        card_pointer, ok := get_card_by_id(gs, card)
        log.assert(ok, "Can't find card by ID")
        return card_pointer
    case Previous_Card_Choice:
        index := get_my_player(gs).hero.current_action_index
        index.index -= 1
        for ; true; index.index -= 1 {
            action := get_action_at_index(gs, index)
            if variant, ok := action.variant.(Choose_Card_Action); ok {
                card, ok2 := get_card_by_id(gs, variant.result)
                log.assert(ok2, "Previous choice of card was not valid!!!!!!")
                return card
            }
        }
    }
    played_card, ok := find_played_card(gs)
    log.assert(ok, "Could not find played card when calculating an implicit card")
    return played_card  // Default to returning the played card
}