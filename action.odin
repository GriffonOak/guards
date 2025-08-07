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

Choice :: struct {
    name: cstring,
    jump_index: int,
}

Choice_Action :: struct {
    choices: []Choice,
    result: int,
}

Halt_Action :: struct {}

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Clear_Action,
    Choose_Target_Action,
    Choice_Action,
    Halt_Action,
}

Action :: struct {
    tooltip: cstring,
    optional: bool,
    skip_index: int,
    variant: Action_Variant,
    targets: Target_Set,
}

player_movement_tooltip: cstring = "Choose a space to move to."

basic_fast_travel_action := []Action {
    {
        tooltip = "Choose a space to fast travel to.",
        variant = Fast_Travel_Action{}
    }
}

basic_hold_action := []Action {}

basic_movement_action := []Action {
    {
        tooltip = player_movement_tooltip,
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
    return &hero.action_list[hero.current_action_index]
}
