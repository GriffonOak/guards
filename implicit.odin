package guards

import "core:log"
import "core:reflect"

// My_Player_ID :: struct {}

// Implicit_Player_ID :: union {
//     Player_ID,
//     My_Player_ID,
// }

Calculation_Context :: struct {
    card_id: Card_ID,
    action_index: Action_Index,  // @Note this also carries a card id, wonder if these could be combined
    target, prev_target: Target,
}


/// IMPLICIT SPACE FLAG


Top_Blocked_Spawnpoint_Type :: struct {}

Previously_Chosen_Dead_Minion :: struct {}

Implicit_Space_Flag :: union {
    Space_Flag,
    Top_Blocked_Spawnpoint_Type,
    Previously_Chosen_Dead_Minion,
}


/// IMPLICIT CARD ID

Previous_Card_Choice :: struct {}

Rightmost_Resolved_Card :: struct {}

Implicit_Card_ID :: union {
    Card_ID,
    Previous_Card_Choice,
    Rightmost_Resolved_Card,
}



/// IMPLICIT QUANTITY

Card_Value :: struct {
    kind: Card_Value_Kind,
}

Sum     :: distinct []Implicit_Quantity
Product :: distinct []Implicit_Quantity
Min     :: distinct []Implicit_Quantity

Distance_Between :: distinct []Implicit_Target

Choices_Taken :: struct {}

Count_Targets :: []Implicit_Condition

Count_Hero_Coins :: struct {
    target: Implicit_Target,
}

My_Team_Total_Dead_Minions :: struct {}

My_Level :: struct {}

Player_ID_Of :: struct {
    target: Implicit_Target,
}

Labelled_Global_Variable :: struct {
    label: Action_Value_Label,
}

Count_Card_Targets :: distinct []Implicit_Condition

Card_Turn_Played :: struct {}

Target_Distance_To :: struct {
    origin: Implicit_Target,
}

Minion_Difference :: struct {}

Minion_Modifiers :: struct {}

Heroes_Defeated_This_Round :: struct {}

Ternary :: struct {
    terms: []Implicit_Quantity,
    condition: Implicit_Condition,
}

Previous_Quantity_Choice :: struct {}

Current_Turn :: struct {}

Implicit_Quantity :: union {
    int,
    Minion_Difference,
    Minion_Modifiers,
    Heroes_Defeated_This_Round,
    My_Team_Total_Dead_Minions,
    My_Level,
    Player_ID_Of,
    Labelled_Global_Variable,
    Sum,
    Product,
    Min,
    Count_Targets,
    Count_Card_Targets,
    Ternary,
    Previous_Quantity_Choice,
    Current_Turn,
    Distance_Between,
    Repeat_Count,
    Choices_Taken,

    // Requires target in context
    Count_Hero_Coins,

    // Requires card in context
    Card_Value,
    Card_Turn_Played,

    // Requires a target in context
    Target_Distance_To,
}

Current_Target :: struct{}
Previous_Target :: struct {}

Self :: struct {}

Previously_Chosen_Target :: struct {}

Labelled_Local_Variable :: struct {
    label: Action_Value_Label,
}

Attacker :: struct {}

Top_Blocked_Spawnpoint :: struct {}

Card_Owner :: struct {}

Implicit_Target :: union {
    Target,
    Self,
    Current_Target,
    Previous_Target,
    Previously_Chosen_Target,
    Labelled_Local_Variable,
    Top_Blocked_Spawnpoint,

    // Requires attack interrupt in interrupt stack
    Attacker,

    // Requires card in context
    Card_Owner,
}



/// IMPLICIT TARGET SLICE

Previous_Choices :: struct {}

Implicit_Target_Slice :: union {
    []Target,
    []Implicit_Target,
    Previous_Choices,
}


/// IMPLICIT CONDITIONS

Greater_Than :: distinct []Implicit_Quantity
Equal        :: distinct []Implicit_Quantity

And :: distinct []Implicit_Condition
Or  :: distinct []Implicit_Condition
Not :: distinct []Implicit_Condition

Blocked_Spawnpoints_Remain :: struct {}

Alive :: struct {}

Are_Enemies :: struct {
    target1, target2: Implicit_Target,
}

Contains_Any :: struct { target: Implicit_Target, flags: Space_Flags }

Target_Within_Distance :: struct {
    origin: Implicit_Target,
    bounds: []Implicit_Quantity,
}

Target_In_Straight_Line_With :: struct {
    origin: Implicit_Target,
}

Target_Is :: struct {
    target: Implicit_Target,
}

Target_Contains_Any :: struct { flags: Space_Flags }
Target_Empty :: struct {}

Target_Is_Enemy_Unit :: struct {}
Target_Is_Friendly_Unit :: struct {}
Target_Is_Losing_Team_Unit :: struct {}
Target_Is_Enemy_Of :: struct {
    target: Implicit_Target,
}
Target_Is_Friendly_Spawnpoint :: struct {}

Target_In_Battle_Zone :: struct {}
Target_Outside_Battle_Zone :: struct {}

Card_State_Is :: struct {
    state: Card_State,
}

Card_Primary_Is :: struct {
    kind: Primary_Kind,
}

Card_Color_Is :: struct {
    color: Card_Color,
}

Card_Owner_Is :: struct {
    owner: Implicit_Target,
}

Card_Can_Defend :: struct {}

Attack_Contains_Flag :: struct {
    flag: Attack_Flag,
}

Previously_Saved_Boolean :: struct {
    label: Action_Value_Label,
}

Action_Index_Sequence_Is :: struct {
    sequence_id: Action_Sequence_ID,
}

Action_Index_Card_Primary_Is :: struct {
    primary_kind: Primary_Kind,
}

Action_Index_Card_Color_Is :: struct {
    color: Card_Color,
}

Action_Variant_At_Index_Is :: struct {
    action_variant_typeid: typeid,
}

Implicit_Condition :: union {
    bool,
    Greater_Than,
    Equal,
    And,
    Or,
    Not,
    Blocked_Spawnpoints_Remain,
    Alive,
    Previously_Saved_Boolean,
    Are_Enemies,
    Contains_Any,

    // Requires target in calc_context
    Target_Within_Distance,
    Target_Contains_Any,
    Target_Empty,
    Target_Is_Enemy_Unit,
    Target_Is_Friendly_Unit,
    Target_Is_Losing_Team_Unit,
    Target_Is_Enemy_Of,
    Target_Is_Friendly_Spawnpoint,
    Target_In_Battle_Zone,
    Target_Outside_Battle_Zone,
    Target_In_Straight_Line_With,
    Target_Is,

    // Requires card in calc context
    Card_State_Is,
    Card_Primary_Is,
    Card_Color_Is,
    Card_Owner_Is,
    Card_Can_Defend,

    // Requires action index in calc context
    Action_Index_Sequence_Is,
    Action_Index_Card_Primary_Is,
    Action_Index_Card_Color_Is,
    Action_Variant_At_Index_Is,

    // Requires an attack in the interrupt stack
    Attack_Contains_Flag,
}



/// IMPLICIT ACTION INDEX

Card_Defense_Index :: struct {
    implicit_card_id: Implicit_Card_ID,
}

Other_Card_Primary :: struct {
    implicit_card_id: Implicit_Card_ID,
}

Implicit_Action_Index :: union {
    Action_Index,
    Card_Defense_Index,
    Other_Card_Primary,
}

calculate_implicit_space_flag :: proc(
    gs: ^Game_State,
    implicit_space_flag: Implicit_Space_Flag,
    calc_context: Calculation_Context,
) -> Space_Flag {
    switch flag in implicit_space_flag {
    case Space_Flag: return flag
    case Top_Blocked_Spawnpoint_Type:
        spawnpoint := calculate_implicit_target(gs, Top_Blocked_Spawnpoint{}, calc_context)
        space := gs.board[spawnpoint.x][spawnpoint.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.Hero_Spawnpoint})
        log.assert(spawnpoint_flags != {}, "Invalid top blocked spawnpoint or something")
        spawnpoint_type := get_first_set_bit(spawnpoint_flags).?
        return spawnpoint_to_minion[spawnpoint_type]
    case Previously_Chosen_Dead_Minion:
        return get_top_action_value_of_type(gs, Chosen_Minion_Type).minion_type
    }
    return .Terrain  // (?)
}


calculate_implicit_quantity :: proc(
    gs: ^Game_State,
    implicit_quantity: Implicit_Quantity,
    calc_context: Calculation_Context = {},
    loc := #caller_location
) -> (out: int) {

    switch quantity in implicit_quantity {
    case int: return quantity

    case Sum:
        for summand in quantity do out += calculate_implicit_quantity(gs, summand, calc_context, loc)
    
    case Product:
        out = 1
        for multiplier in quantity do out *= calculate_implicit_quantity(gs, multiplier, calc_context, loc)

    case Min:
        out = max(int)
        for implicit_value in quantity {
            value := calculate_implicit_quantity(gs, implicit_value, calc_context, loc)
            if value < out do out = value
        }

    case Count_Targets:
        selection_criteria := Selection_Criteria {
            conditions = quantity,
            flags = {.Ignoring_Immunity},
        }
        targets := make_arbitrary_targets(gs, selection_criteria, calc_context)
        return count_members(&targets)

    case Count_Card_Targets:
        targets := make_card_targets(gs, cast([]Implicit_Condition) quantity, calc_context)
        out = len(targets)
        delete(targets)

    case Minion_Difference:
        return abs(gs.minion_counts[.Red] - gs.minion_counts[.Blue])

    case Ternary:
        log.assert(len(quantity.terms) == 2, "Ternary operator that does not have 2 terms!", loc)
        if calculate_implicit_condition(gs, quantity.condition, calc_context, loc) {
            return calculate_implicit_quantity(gs, quantity.terms[0], calc_context, loc)
        } else {
            return calculate_implicit_quantity(gs, quantity.terms[1], calc_context, loc)
        }

    case Previous_Quantity_Choice:
        return get_top_action_value_of_type(gs, Chosen_Quantity).quantity

    case Repeat_Count:
        repeat_count, _, ok := try_get_top_action_value_of_type(gs, Repeat_Count)
        if !ok {
            return 0
        }
        return repeat_count.count

    case Choices_Taken:
        for value in gs.action_memory {
            if _, ok := value.variant.(Choice_Taken); ok {
                out += 1
            }
        }

    case Minion_Modifiers: 
        return calculate_minion_modifiers(gs)

    case Heroes_Defeated_This_Round:
        return gs.heroes_defeated_this_round

    case My_Team_Total_Dead_Minions:
        my_player := get_my_player(gs)
        return len(gs.dead_minions[my_player.team])

    case My_Level:
        my_player := get_my_player(gs)
        return my_player.hero.level

    case Player_ID_Of:
        target := calculate_implicit_target(gs, quantity.target, calc_context)
        space := gs.board[target.x][target.y]
        return space.owner

    case Labelled_Global_Variable:
        action_value := get_top_global_variable_by_label(gs, quantity.label)
        log.assert(action_value != nil, "Could not find global variable with label!", loc)
        return action_value.variant.(Saved_Integer).integer

    case Current_Turn:
        return gs.turn_counter

    case Count_Hero_Coins:
        target := calculate_implicit_target(gs, quantity.target, calc_context, loc)
        space := gs.board[target.x][target.y]
        if .Hero not_in space.flags do return 0
        // log.assert(.Hero in space.flags, "Tried to count hero coins in a space with no hero!")
        player := get_player_by_id(gs, space.owner)
        return player.hero.coins

    case Distance_Between:
        log.assert(len(quantity) == 2, "Improperly formatted quantity!")
        target1 := calculate_implicit_target(gs, quantity[0], calc_context)
        target2 := calculate_implicit_target(gs, quantity[1], calc_context)
        return calculate_hexagonal_distance(target1, target2)

    case Target_Distance_To:
        log.assert(calc_context.target != INVALID_TARGET, "Target invalid!!!")
        origin := calculate_implicit_target(gs, quantity.origin, calc_context)
        return calculate_hexagonal_distance(calc_context.target, origin)

    case Card_Value:
        log.assert(calc_context.card_id != {}, "Invalid card ID when calculating value", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card ID when calculating value", loc)
        hero := get_player_by_id(gs, calc_context.card_id.owner_id).hero
        value := card_data.values[quantity.kind]
        value += count_hero_items(gs, hero, quantity.kind)

        poison_value_kinds := bit_set[Card_Value_Kind]{.Attack, .Defense, .Initiative}
        if .Tigerclaw_Weak_Poison in hero.markers && quantity.kind in poison_value_kinds {
            value -= 1
        }
        if .Tigerclaw_Strong_Poison in hero.markers && quantity.kind in poison_value_kinds {
            value -= 2
        }

        for _, effect in gs.ongoing_active_effects {
            effect_calc_context := Calculation_Context{target = hero.location, card_id = effect.parent_card_id}
            if !effect_timing_valid(gs, effect.timing, effect_calc_context) do continue
            for outcome in effect.outcomes {
                augment_value, ok2 := outcome.(Augment_Card_Value)
                if !ok2 do continue
                target_valid := calculate_implicit_condition(gs, And(effect.affected_targets), effect_calc_context)
                if !target_valid do continue
                
                if quantity.kind == augment_value.value_kind {
                    value += augment_value.augment
                }
            }
        }

        return value

    case Card_Turn_Played:
        log.assert(calc_context.card_id != {}, "Invalid card when trying to calculate turn played", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Invalid card when trying to calculate turn played", loc)
        return card.turn_played

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

    case Current_Target: 
        log.assert(calc_context.target != {}, "Invalid stack target!", loc)
        return calc_context.target

    case Previous_Target:
        log.assert(calc_context.prev_target != {}, "Invalid stack target!", loc)
        return calc_context.prev_target
    case Self: out = get_my_player(gs).hero.location

    case Previously_Chosen_Target:
        return get_top_action_value_of_type(gs, Target)^

    case Labelled_Local_Variable:
        return get_top_action_value_of_type(gs, Target, label = target.label)^

    case Top_Blocked_Spawnpoint:
        my_team := get_my_player(gs).team
        num_blocked_spawns := len(gs.blocked_spawns[my_team])
        log.assert(num_blocked_spawns > 0, "No blocked spawns!!!!!", loc)
        return gs.blocked_spawns[my_team][num_blocked_spawns - 1]

    case Attacker:
        interrupt, _, ok := find_attack_interrupt(gs)
        log.assert(ok, "No attack interrupt in stack when trying to determine attacker!")
        hero := get_player_by_id(gs, interrupt.interrupted_player).hero
        return hero.location
    
    case Card_Owner:
        log.assert(calc_context.card_id != {}, "Cannot find the owner of an invalid card!", loc)
        return get_player_by_id(gs, calc_context.card_id.owner_id).hero.location
    }
    return
}

calculate_implicit_target_slice :: proc(
    gs: ^Game_State,
    implicit_slice: Implicit_Target_Slice,
    calc_context: Calculation_Context = {}
) -> []Target {
    switch slice in implicit_slice {
    case []Target: return slice

    case []Implicit_Target:
        out := make([]Target, len(slice), context.temp_allocator)
        for implicit_target, index in slice {
            out[index] = calculate_implicit_target(gs, implicit_target, calc_context)
        }
        return out

    case Previous_Choices:
        // index := get_my_player(gs).hero.current_action_index
        // index.index -= 1
        // for ; true; index.index -= 1 {
        //     action := get_action_at_index(gs, index)
        //     if variant, ok := action.variant.(Choose_Target_Action); ok {
        //         return variant.result[:]
        //     }
        // }
        action_values := get_top_action_slice_of_type(gs, Target)
        out := make([]Target, len(action_values), context.temp_allocator)
        for value, index in action_values {
            out[index] = value.variant.(Target)
        }
        return out
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
    case Equal:
        log.assert(len(condition) == 2, "Equal condition check that does not have 2 elements!", loc)
        return calculate_implicit_quantity(gs, condition[0], calc_context, loc) == calculate_implicit_quantity(gs, condition[1], calc_context, loc)
    case And:
        // Short-circuting!
        for extra_condition in condition {
            if !calculate_implicit_condition(gs, extra_condition, calc_context, loc) do return false
        }
        return true
    case Or:
        // Short-circuting!
        for extra_condition in condition {
            if calculate_implicit_condition(gs, extra_condition, calc_context, loc) do return true
        }
        return false
    case Not:
        log.assert(len(condition) == 1, "Improperly formatted not statement!", loc)
        return !calculate_implicit_condition(gs, condition[0], calc_context, loc)
    case Blocked_Spawnpoints_Remain:
        my_team := get_my_player(gs).team
        return len(gs.blocked_spawns[my_team]) > 0
    case Alive:
        return !get_my_player(gs).hero.dead
    case Are_Enemies:
        target1 := calculate_implicit_target(gs, condition.target1, calc_context)
        target2 := calculate_implicit_target(gs, condition.target2, calc_context)
        space1 := gs.board[target1.x][target1.y]
        space2 := gs.board[target2.x][target2.y]
        return space1.unit_team != space2.unit_team

    case Target_Within_Distance:
        log.assert(space_ok, "Invalid target!", loc)
        origin := calculate_implicit_target(gs, condition.origin, calc_context)

        // log.assert(len(condition.origin) == 1, "Incorrect argument count for within distance condition", loc)
        log.assert(len(condition.bounds) == 2, "Incorrect argument count for bounds", loc)

        min_dist := calculate_implicit_quantity(gs, condition.bounds[0], calc_context)
        max_dist := calculate_implicit_quantity(gs, condition.bounds[1], calc_context)

        distance := calculate_hexagonal_distance(origin, calc_context.target)
        return distance <= max_dist && distance >= min_dist

    case Contains_Any:
        target := calculate_implicit_target(gs, condition.target, calc_context)
        return target_contains_any(gs, target, condition.flags)

    case Target_Contains_Any:
        log.assert(space_ok, "Invalid target!")
        return target_contains_any(gs, calc_context.target, condition.flags)

    case Target_Empty:
        log.assert(space_ok, "Invalid target!")
        return !target_contains_any(gs, calc_context.target, OBSTACLE_FLAGS)

    // @Note these don't actually test whether a unit is present in the space, only that the teams are the same / different
    case Target_Is_Enemy_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team != space.unit_team

    case Target_Is_Friendly_Unit:
        log.assert(space_ok, "Invalid target!")
        return get_my_player(gs).team == space.unit_team

    case Target_Is_Losing_Team_Unit:
        log.assert(space_ok, "Invalid target!")
        losing_team: Team = .Red if gs.minion_counts[.Red] < gs.minion_counts[.Blue] else .Blue
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
        return delta.x == 0 || delta.y == 0 || delta.x == -delta.y

    case Target_Is:
        log.assert(space_ok, "Invalid target!")
        target := calculate_implicit_target(gs, condition.target, calc_context)
        return calc_context.target == target


    case Card_Primary_Is:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card data when checking for its primary type!", loc)
        return card_data.primary == condition.kind
    
    case Card_Color_Is:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        return calc_context.card_id.color == condition.color

    case Card_State_Is:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card when checking for its state!", loc)
        return card.state == condition.state

    case Card_Owner_Is:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        card, ok := get_card_by_id(gs, calc_context.card_id)
        log.assert(ok, "Could not find the card when checking for its owner!", loc)
        // player_id := calculate_implicit_player_id(condition.owner, calc_context, loc)
        player_location := calculate_implicit_target(gs, condition.owner, calc_context)
        player_space := gs.board[player_location.x][player_location.y]
        return player_space.owner == card.owner_id

    case Card_Can_Defend:
        log.assert(calc_context.card_id != {}, "Invalid card ID for condition that requires it!", loc)
        _, attack_interrupt, ok := find_attack_interrupt(gs)
        log.assert(ok, "Trying to determine defense when there is no attack!", loc)
        
        card_data, ok2 := get_card_data_by_id(gs, calc_context.card_id)
        log.assert(ok2, "Could not get card data when defending!", loc)

        if (.Disallow_Primary_Defense in attack_interrupt.flags) &&
            (card_data.primary == .Defense || card_data.primary == .Defense_Skill) {
            return false
        }

        defense_index := calculate_implicit_action_index(gs, Card_Defense_Index{calc_context.card_id}, calc_context)
        action := get_action_at_index(gs, defense_index)
        defense_action := action.variant.(Defend_Action)

        if defense_action.block_condition != nil {
            return calculate_implicit_condition(gs, defense_action.block_condition, calc_context)
        }
        defense_strength := calculate_implicit_quantity(gs, defense_action.strength, calc_context)
        return defense_strength >= attack_interrupt.strength

    case Action_Index_Sequence_Is:
        log.assert(calc_context.action_index != {}, "No action index!", loc)
        return calc_context.action_index.sequence == condition.sequence_id

    case Action_Index_Card_Primary_Is:
        log.assert(calc_context.action_index != {}, "No action index!", loc)
        card_data, ok := get_card_data_by_id(gs, calc_context.action_index.card_id)
        log.assert(ok, "Could not get data for card in action index!!!", loc)
        return card_data.primary == condition.primary_kind

    case Action_Index_Card_Color_Is:
        log.assert(calc_context.action_index != {}, "No action index!", loc)
        return calc_context.action_index.card_id.color == condition.color

    case Action_Variant_At_Index_Is:
        log.assert(calc_context.action_index != {}, "No action Index!", loc)
        action := get_action_at_index(gs, calc_context.action_index, loc)
        return reflect.union_variant_typeid(action.variant) == condition.action_variant_typeid

    case Attack_Contains_Flag:
        _, attack_interrupt, ok := find_attack_interrupt(gs)
        log.assert(ok, "Could not find the attack interrupt when checking its flags!", loc)
        return condition.flag in attack_interrupt.flags

    case Previously_Saved_Boolean:
        saved_boolean, _, ok := try_get_top_action_value_of_type(gs, Saved_Boolean)
        log.assert(ok, "Could not find saved boolean!")
        return saved_boolean.boolean
    }
    return false
}

calculate_implicit_card_id :: proc(gs: ^Game_State, implicit_card_id: Implicit_Card_ID) -> Card_ID {
    switch card_id in implicit_card_id {
    case Card_ID:
        return card_id
    case Previous_Card_Choice:
        return get_top_action_value_of_type(gs, Card_ID)^
    case Rightmost_Resolved_Card:
        out: Card_ID
        highest_turn := -1
        cards := get_my_player(gs).hero.cards
        for card in cards {
            if card.state == .Resolved && card.turn_played > highest_turn {
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
        card_id := calculate_implicit_card_id(gs, index.implicit_card_id)
        card_data, ok := get_card_data_by_id(gs, card_id)
        log.assert(ok, "Invalid card ID!!")
        #partial switch card_data.primary {
        case .Defense: 
            return Action_Index{.Primary, card_id, 0}
        case .Defense_Skill:
            log.assert(false, "TODO")  // @Todo
            return {}
        }
        return {.Basic_Defense, card_id, 3}  // @Magic: index of Defense_Action in basic_defense_action
    case Other_Card_Primary:
        other_card_id := calculate_implicit_card_id(gs, index.implicit_card_id)
        if other_card_id == {} do return {sequence = .Invalid}
        return {sequence = .Primary, card_id = other_card_id, index = 0}
    }
    return {}
}

// calculate_implicit_player_id :: proc(
//     gs: ^Game_State,
//     implicit_player_id: Implicit_Player_ID,
//     calc_context: Calculation_Context,
//     loc := #caller_location
// ) -> Player_ID {

// }