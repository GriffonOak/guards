package guards

// hold_list := Action_List {
//     0, 
//     {Hold_Action{}}
// }

// fast_travel_list := Action_List {
//     0, {Fast_Travel_Action{}}
// }

// movement_list := Action_List {
//     0, {Movement_Action{}}
// }

// Hold_Action :: struct {}

// Movement_Action :: struct {
//     max_distance: int
// }

// Fast_Travel_Action :: struct {}

// Action_Step :: union {
//     Hold_Action,
//     Movement_Action,
//     Fast_Travel_Action,
// }

// Action_List :: struct {
//     current_action: int,
//     actions: []Action_Step
// }

// Self :: struct {}

// Target_Origin :: union {
//     IVec2,
//     Self,
// }

// Movement_Value :: struct {}

// Amount :: union {
//     int, 
//     Movement_Value,
// }

// Movement_Targets :: struct {
//     origin: Target_Origin,
//     min, max: Amount,
// }

// Selection_Criteria :: union {
//     Movement_Targets
// }

// Get_Target_Selection :: struct {
//     amount: int,
//     criteria: Selection_Criteria,
//     targets: [dynamic]Target
// }

// basic_movement_action := Action {
//     Get_Target_Selection {
//         1, Movement_Targets{Self{},  0, Movement_Value},
//         {},
//     },
//     Move{Self, 0}
    
// }

Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    CHOOSING_ACTION,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

// Action_Temp :: enum {
//     HOLD,
//     MOVEMENT,
//     FAST_TRAVEL,
// }

Self :: struct {}

Hold_Action :: struct {}

Action_Target :: union {
    Self,
    Target,
}

Movement_Action :: struct {
    target: Action_Target,
    distance: int
}

Fast_Travel_Action :: struct {}

Clear_Action :: struct {}

Action_Temp :: union {
    Hold_Action,
    Movement_Action,
    Fast_Travel_Action,
    Clear_Action,
}

basic_fast_travel_action := Fast_Travel_Action {}

basic_hold_action := Hold_Action{}

basic_movement_action := Movement_Action {
    Self{},
    0
}

basic_clear_action := Clear_Action{}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,
    hero: Hero,
    
    team: Team,
    action_button_count: int,

}

Hero_ID :: enum {
    NONE,
    XARGATHA,
}

Hero :: struct {
    id: Hero_ID,
    location: IVec2,

    current_action: Action_Temp,
    target_list: []Target,
    num_locked_targets: int,
    chosen_targets: [dynamic]Target,
}


player := Player {
    stage = .SELECTING,
    hero = Hero{
        id = .XARGATHA
    },
    team = .RED
}

// start_next_action :: proc(actions: Action_List) {
//     current_action := actions.actions[actions.current_action]
//     switch var in current_action {
//     case Hold_Action:
//         append(&event_queue, End_Resolution_Event{})
//     case Movement_Action, Fast_Travel_Action:
//     }
// }