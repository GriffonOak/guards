package guards



Card_Reach :: struct {}

Implicit_Quantity :: union {
    int,
    Card_Reach,
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
    distance: int,
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

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Clear_Action,
    Choose_Target_Action,
}

Action :: struct {
    variant: Action_Variant,
    targets: Target_Set,
}



basic_fast_travel_action := []Action{{variant=Fast_Travel_Action{}}}

basic_hold_action := []Action{}

basic_movement_action := []Action{
    {
        variant = Movement_Action {
            target   = Self{},
            distance = 0,
        }
    }
}

basic_clear_action := []Action{{variant = Clear_Action{}}}



get_current_action :: proc(hero: ^Hero) -> ^Action {
    if hero.current_action_index >= len(hero.action_list) do return nil
    return &hero.action_list[hero.current_action_index]
}