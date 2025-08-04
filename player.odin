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

Action_Temp :: enum {
    HOLD,
    MOVEMENT,
    FAST_TRAVEL,
}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,
    hero: Hero_ID,
    hero_location: IVec2,
    team: Team,
    action_button_count: int,

    current_action: Action_Temp,

    target_list: []Target,
    chosen_targets: [dynamic]Target,
}

Hero_ID :: enum {
    NONE,
    XARGATHA,
}

// Hero :: struct {
//     hero_id: Hero_ID,
// }


player := Player {
    stage = .SELECTING,
    hero = .XARGATHA,
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