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




Movement_Action :: struct {
    target: Implicit_Target,
    distance: int,
}

Fast_Travel_Action :: struct {}

Clear_Action :: struct {}

Choose_Target_Action :: struct {
    criteria: []Selection_Criterion,
    result: Target,
}

Action_Temp :: union {
    Movement_Action,
    Fast_Travel_Action,
    Clear_Action,
    Choose_Target_Action,
}



basic_fast_travel_action := []Action_Temp{Fast_Travel_Action{}}

basic_hold_action := []Action_Temp{}

basic_movement_action := []Action_Temp{
    Movement_Action {
        Self{},
        0,
    },
}

basic_clear_action := []Action_Temp{Clear_Action{}}



get_current_action :: proc(hero: ^Hero) -> ^Action_Temp {
    if hero.current_action_index >= len(hero.action_list) do return nil
    return &hero.action_list[hero.current_action_index]
}