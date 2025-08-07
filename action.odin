package guards



Card_Reach :: struct {}

Card_Primary_Value :: struct {}

Card_Secondary_Value :: struct {
    kind: Ability_Kind
}

Implicit_Quantity :: union {
    int,
    Card_Reach,
    Card_Primary_Value,
    Card_Secondary_Value,
}

Within_Distance :: struct {
    origin: Implicit_Target,
    min: Implicit_Quantity,
    max: Implicit_Quantity,
}

Contains_Any :: Space_Flags
Contains_All :: Space_Flags

Is_Enemy_Unit :: struct {}

Selection_Criterion :: union {
    Within_Distance,
    Contains_Any,
    // Contains_All,
    Is_Enemy_Unit,
}


Path :: struct {
    num_locked_spaces: int,
    spaces: [dynamic]Target,
}

Movement_Action :: struct {
    target: Implicit_Target,
    distance: Implicit_Quantity,
    valid_destinations: Implicit_Target_Set,

    path: Path
}

Fast_Travel_Action :: struct {
    result: Target,
}

Clear_Action :: struct {}

Choose_Target_Action :: struct {
    criteria: []Selection_Criterion,

    result: Target,
}

Optional_Action :: struct {
    entered: bool,
    step_index: int,
    steps: []Action,
}

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Clear_Action,
    Choose_Target_Action,
    Optional_Action,
}

Action :: struct {
    tooltip: cstring,
    variant: Action_Variant,
    targets: Target_Set,
}



basic_fast_travel_action := []Action {
    {
        tooltip = "Choose a space to fast travel to.",
        variant = Fast_Travel_Action{}
    }
}

basic_hold_action := []Action {}

basic_movement_action := []Action {
    {
        tooltip = "Choose a space to move to.",
        variant = Movement_Action {
            target   = Self{},
            distance = Card_Secondary_Value{.MOVEMENT},
        }
    }
}

basic_clear_action := []Action {
    {
        tooltip = "Choose any number of tokens adjacent to you to remove.",
        variant = Clear_Action{}
    }
}

get_current_action :: proc(hero: ^Hero) -> ^Action {
    return get_current_action_from_list(hero.action_list, hero.current_action_index)
}

get_current_action_from_list :: proc(list: []Action, index: int) -> ^Action {
    if index >= len(list) do return nil
    #partial switch variant in list[index].variant {
    case Optional_Action:
        if variant.entered && variant.step_index < len(variant.steps) {
            return get_current_action_from_list(variant.steps, variant.step_index)
        }
    }
    return &list[index]
}

walk_to_next_action :: proc(hero: ^Hero) -> bool {
    return walk_next_action_list(hero.action_list, &hero.current_action_index)
}

walk_next_action_list :: proc(list: []Action, index: ^int) -> bool {
    current_action := &list[index^]
    #partial switch &variant in current_action.variant {
    case Optional_Action:
        if !variant.entered {
            variant.entered = true
            return true
        }
        if variant.step_index < len(variant.steps) && walk_next_action_list(variant.steps, &variant.step_index) do return true
    }

    index^ += 1
    return index^ <= len(list)

}

get_previous_action :: proc(hero: ^Hero) -> ^Action {
    return get_previous_action_from_list(hero.action_list, hero.current_action_index)
}

get_previous_action_from_list :: proc(list: []Action, index: int) -> ^Action {
    if index >= len(list) do return nil
    #partial switch variant in list[index].variant {
    case Optional_Action:
        if variant.entered && variant.step_index < len(variant.steps) {
            return get_previous_action_from_list(variant.steps, variant.step_index)
        }
    }
    return &list[index - 1]
}