package guards

hold_list := Action_List {
    0, 
    {Hold_Action{}}
}

Hold_Action :: struct {}

Action_Step :: union {
    Hold_Action
}

Action_List :: struct {
    current_action: int,
    actions: []Action_Step
}

Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    CHOOSING_ACTION,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,
    hero: Hero_ID,
    hero_location: IVec2,
    team: Team,
    action_button_count: int,

    resolution_list: Action_List,

    target_list : []IVec2
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

start_next_action :: proc(actions: Action_List) {
    current_action := actions.actions[actions.current_action]
    switch var in current_action {
        case Hold_Action:
            append(&event_queue, End_Resolution_Event{})
    }
}