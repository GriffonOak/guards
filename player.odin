package guards



Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    CHOOSING_ACTION,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

Hero_ID :: enum {
    NONE,
    XARGATHA,
}

Hero :: struct {
    id: Hero_ID,
    location: IVec2,

    current_action_index: int,
    action_list: []Action,
    // target_list: map[Target]Void,
    // num_locked_targets: int,
    // chosen_targets: [dynamic]Target,
}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,  // soon, my love
    hero: Hero,
    
    team: Team,
}


player := Player {
    stage = .SELECTING,
    hero = Hero{
        id = .XARGATHA
    },
    team = .RED
}

player2 := Player {
    stage = .SELECTING,
    hero = Hero {
        id = .NONE,
    },
    team = .BLUE,
}
