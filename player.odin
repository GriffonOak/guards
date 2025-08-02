package guards

Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,
    hero: Hero_ID,
    team: Team,
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