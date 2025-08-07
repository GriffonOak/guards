package guards



Player_Stage :: enum {
    NONE,
    SELECTING,
    CONFIRMED,
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
    hero = Hero{
        id = .XARGATHA
    },
    team = .RED
}

player2 := Player {
    hero = Hero {
        id = .NONE,
    },
    team = .BLUE,
}
